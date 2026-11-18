-- Disable "Transport index.txt" and make "Travel locations.txt" unlimited:

local function SimpleReplacePtrs(t, CmdSize, OldOrigin, NewOrigin)
	local OldAddr
	for i, v in ipairs(t) do
		OldAddr = mem.u4[v + CmdSize]
		mem.u4[v + CmdSize] = NewOrigin + OldAddr - OldOrigin
	end
end

local StructsArrayStd = DataTables.StructsArray

function DataTables.StructsArray(arr, offs, t, str)

	if str and arr == Game.TransportLocations then

		local OldCount = Game.TransportLocations.count
		local NewCount = DataTables.ComputeRowCountInPChar(mem.topointer(str), 5) - 1

		if NewCount > OldCount then

			local NewPtr = mem.StaticAlloc(NewCount*32 + 4)
			local OldPtr = Game.TransportLocations["?ptr"]

			mem.IgnoreProtection(true)

			SimpleReplacePtrs({
				0x4b50e8 + 3, 0x4b50f2 + 2, 0x4b5196 + 2, 0x4b55bc + 4,
				0x4b55d4 + 2, 0x4b561c + 3, 0x4b563b + 3, 0x4bab81 + 3
				},
				0, OldPtr, NewPtr)

			mem.IgnoreProtection(false)

			internal.SetArrayUpval(Game.TransportLocations, "count", NewCount)
			internal.SetArrayUpval(Game.TransportLocations, "o", NewPtr)

		end

	elseif arr == Game.TransportIndex and Game.HouseRules then
		return
	end

	return StructsArrayStd(arr, offs, t, str)

end
