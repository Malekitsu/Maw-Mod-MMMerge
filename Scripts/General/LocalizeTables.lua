
-- Script simply replaces text fields of tables with ones from "LocalizeTables.txt".
-- Sacrificing a bit of perfomance for a lot of conviniency of work with localizations.

local function lines_binary(file)
	local txt = file:read("*all")
	local t = txt:split('\r\n')
	local pos = 1

	return function()
		local line = t[pos]
		pos = pos + 1
		return line
	end
end

local function _RelocalizeTables(PathMask)

	for FilePath in path.find(PathMask) do

		local TxtTable = io.open(FilePath, "rb")

		if TxtTable then
			local Count = 0
			local Words
			local LineIt = lines_binary(TxtTable)
			LineIt() -- skip header

			if string.find(FilePath, "ItemsTxt.txt") then
				-- special behaivor for ItemsTxt
				local Items = Game.ItemsTxt
				for line in LineIt do
					Words = string.split(line, "\9")
					local Num = tonumber(Words[1])
					if Num then
						local Item = Items[Num]
						Item.Name 				= Words[2]
						Item.NotIdentifiedName	= Words[3]
						Item.Notes				= Words[4]
						Count = Count + 1
					end
				end
			elseif string.find(FilePath, "2DEvents.txt") then
				-- special behaivor for 2DEvents
				local Houses = Game.Houses
				for line in LineIt do
					Words = string.split(line, "\9")
					local Num = tonumber(Words[1])
					if Num then
						local House = Houses[Num]
						House.Name = Words[2]
						House.OwnerName	= Words[3]
						House.OwnerTitle = Words[4]
						House.EnterText = Words[5]
						Count = Count + 1
					end
				end
			elseif string.find(FilePath, "NPCNames.txt") then
				-- special behaivor for NPCNames
				local NPCNames = Game.NPCNames
				NPCNames.M = {}
				NPCNames.F = {}
				for line in LineIt do
					Words = string.split(line, "\9")
					if Words[1] and string.len(Words[1]) > 0 then
						table.insert(NPCNames["M"], Words[1])
					end
					if Words[2] and string.len(Words[2]) > 0 then
						table.insert(NPCNames["F"], Words[2])
					end
					Count = Count + 1
				end
			else
				local len = string.len
				local LastTable = ""
				for line in LineIt do
					Words = string.split(line, "\9")

					if Words[1] then
						local cTable	= Words[1] or ""
						local cId		= tonumber(Words[2])
						local cField	= tonumber(Words[3]) or Words[3] or ""
						local cText		= tonumber(Words[4]) or Words[4] or ""

						if len(cTable) > 0 then
							if Game[cTable] then
								LastTable = cTable
							else
								Log(Merge.Log.Error, "Invalid table name in localization file: %s - %s.", cTable, FilePath)
							end
						else
							cTable = LastTable
						end

						if len(cTable) > 0 and cId then
							if len(cField) > 0 then
								Game[cTable][cId][cField] = cText
							else
								Game[cTable][cId] = cText
							end
						end
					end

					Count = Count + 1
				end

				if #LastTable == 0 then
					Log(Merge.Log.Error, "No game tables listed in %s.", FilePath)
				end
			end

			io.close(TxtTable)
			Log(Merge.Log.Info, "Loaded localization file: %s : %s entries.", FilePath, Count)
		else
			Log(Merge.Log.Error, "Could not reead localization file: %s.", FilePath, Count)
		end
	end

	for i, v in Game.QuestsTxt do
		if #v == 0 then
			Game.QuestsTxt[i] = "0"
		end
	end

end

function RelocalizeTables()
	_RelocalizeTables("Data/*LocalizeTables.*txt")
	_RelocalizeTables("Data/Text localization/*.txt")
end

function events.ScriptsLoaded() -- declare localization event last
	events.GameInitialized2 = RelocalizeTables
end
