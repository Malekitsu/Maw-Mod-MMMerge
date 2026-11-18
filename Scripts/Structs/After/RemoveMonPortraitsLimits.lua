
local OldCount, NewCount = 60, 0
local PtrTablePtr 	= 0x4facd8
local NameTablePtr	= 0x4fb5b4

local function GenerateTable()

	local function SimpleParse(StartAddress, Count, LineSize, ItemSize)
		if ItemSize then
			UX = mem["u" .. ItemSize]
		else
			return nil
		end

		local Result = {}

		if LineSize == 1 then
			for i = 1, Count do
				Result[i] = UX[StartAddress+(i-1)*ItemSize]
			end
		else
			for iQ = 1, Count do
				Result[iQ] = {}
				for iI = 0, LineSize-1 do
					Result[iQ][iI] = UX[StartAddress + (iQ*LineSize + iI)*ItemSize]
				end
			end
		end

		return Result

	end

	local MonPorTable = io.open("Data/Tables/MonPortraits.txt", "w")
	local OrigPtrTab = SimpleParse(PtrTablePtr, 60, 1, 4)

	MonPorTable:write("#\9Pic index\9Note\n")

	for i, v in ipairs(OrigPtrTab) do

		local CurNPCPic

		if v == 0 then
			CurNPCPic = "0"
		else
			CurNPCPic = tonumber(string.sub(mem.string(v), 4))
		end

		MonPorTable:write(i .. "\9" .. CurNPCPic .. "\9" .. Game.MonstersTxt[i*3-2].Name .. "\n")

	end

	for i = 61, (Game.MonstersTxt.count - 1)/3 do
		MonPorTable:write(i .. "\9\9" .. Game.MonstersTxt[i*3-2].Name .. "\n")
	end

	MonPorTable:close()

end

local function LoadTable(File)

	local MonPorTable = io.open("Data/Tables/MonPortraits.txt", "r")

	local WrittenNames = {}
	local NameCnt, PtrCnt = 0, 0
	local CurName, NamePtr

	local LineIt = MonPorTable:lines()

	LineIt() -- skipping header.
	for line in LineIt do

		CurName = string.split(line, "\9")[2]
		CurName = string.split(CurName, ",")[1]
		CurName = string.replace(CurName, " ", "")

		if CurName == "0" or CurName == "" then
			NamePtr = 0
		else
			CurName = "NPC" .. string.sub("0000", 1, 4 - string.len(CurName)) .. CurName
			NamePtr = table.find(WrittenNames, CurName)

			if NamePtr then
				NamePtr = tonumber(string.sub(NamePtr, 4))
			else
				for i = 1, 7 do
					mem.u1[NameTablePtr + NameCnt*8 + i-1] = string.byte(CurName, i)
				end
				NamePtr = NameTablePtr + NameCnt*8
				WrittenNames["key" .. NamePtr] = CurName
				NameCnt = NameCnt + 1
			end
		end

		mem.u4[PtrTablePtr + PtrCnt*4] = NamePtr
		PtrCnt = PtrCnt + 1

	end
	MonPorTable:close()

end

local function RemoveLimits(PtrsCount, NamesCount)

	local NewSpacePtr = mem.StaticAlloc(PtrsCount*4 + NamesCount*8)

	PtrTablePtr	 = NewSpacePtr
	NameTablePtr = NewSpacePtr + PtrsCount * 4

	mem.IgnoreProtection(true)
	mem.u4[0x44205B + 3] = PtrTablePtr
	mem.u4[0x44207B + 3] = PtrTablePtr
	mem.IgnoreProtection(false)

end

function events.GameInitialized2()

	local MonPorTable = io.open("Data/Tables/MonPortraits.txt", "r")

	if MonPorTable then

		local MonPortraits = {}
		local CurName, Words, Names
		local NamesCount = 0
		local LineIt = MonPorTable:lines()
		Game.MonsterPortraits = MonPortraits

		LineIt() -- skipping header
		for line in LineIt do
			Words = string.split(line, "\9")
			Names = string.split(Words[2], ",")
			CurName = Names[1]

			if CurName ~= "0" and CurName ~= "" then
				NamesCount = NamesCount + 1
			end
			NewCount = NewCount + 1

			MonPortraits[NewCount] = {}
			for k,v in pairs(Names) do
				local Name = string.replace(v," ","")
				if string.len(Name) > 0 then
					local Num = tonumber(Name)
					if Num then
						table.insert(MonPortraits[NewCount], Num)
					end
				end
			end
		end

		if NewCount > OldCount then
			RemoveLimits(NewCount, NamesCount)
		end

		MonPorTable:close()

		LoadTable()

	else

		GenerateTable()

	end
end
