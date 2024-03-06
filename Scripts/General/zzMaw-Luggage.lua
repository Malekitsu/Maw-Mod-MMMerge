local NUMPAD0 = 96
local ADD= 107
local SUBTRACT= 109
local OEM_PLUS= 187
local OEM_MINUS= 189

local count = 5


function events.KeyDown(t)

    if (Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103) or Game.CurrentScreen==13 then
		me = Party[Game.CurrentPlayer]
		--[[
		if t.Key >= NUMPAD0 and t.Key < NUMPAD0 + 10 then
			mem.dll.Luggage.activate(me ,t.Key - NUMPAD0 )
		end
		]]
		page = mem.dll.Luggage.current(me)
		if t.Key == OEM_MINUS then
		changeBag(me , (page-1)%count)
		end
		if t.Key == OEM_PLUS then
			changeBag(me , (page+1)%count)
		end
		if Party.High==0 then
			if t.Key>=49 and t.Key<=48+count then
				changeBag(me , t.Key-49)
			end
		end		
	end
end

function events.GameInitialized2()
	for i=1,count do
		CustomUI.CreateButton{
			IconUp = "RanNum" .. i .. "n",
			IconDown = "RanNum" .. i .. "s",
			Screen = 7,
			Layer = 1,
			X =	472+(i-1)%5*30 +15,
			Y =	373+((i-1)-(i-1)%5)/5 *80,
			Masked = true,
			Action = function() changeBag(Party[Game.CurrentPlayer], i-1) end,
		}
	end
	for i=1,3 do
		CustomUI.CreateButton{
			IconUp = "RanNum" .. i .. "n",
			IconDown = "RanNum" .. i .. "s",
			Screen = 7,
			Layer = 1,
			X =	360+30*(8-count)+i*45,
			Y =	0,
			Masked = true,
			Action = function() changeEq(Party[Game.CurrentPlayer], i-1) end,
		}
	end
end

local function failure()
	Game.ShowStatusText("It is not possible")
	evt.PlaySound(27)
end



function changeBag(pl, bag)
	if mem.dll.Luggage.activate(pl , bag) == 0 then failure() end
end

function changeEq(pl, eq)
	if mem.dll.Luggage.activate2(pl , eq)== 0 then failure() end
end


local base = 0
function structs.f.LuggageFrame(define)

--[[	
	define[base+ 0x0].array(1, 138).struct(structs.Item) 'Items'
	define[base+0x1368].array(1, 126).i4 'Inventory'
	define[base+0x1560].array(1, 16).i4 'EquippedItems'
	]]
	
	
	define
	.array(1, 138).struct(structs.Item) 'Items'
	.array(1, 126).i4 'Inventory'
	.array(1, 16).i4 'EquippedItems'
	
	
	return define
end

--[[
function structs.LuggageFrame.new()
    local instance = {
        Items = {},           -- Initialize with an empty table or any default values
        Inventory = {},       -- Initialize with an empty table or any default values
        EquippedItems = {}    -- Initialize with an empty table or any default values
    }

    setmetatable(instance, { __index = structs.LuggageFrame })  -- Set the metatable for the instance

    return instance
end
]]

function peekBag(pl, bag)
	base = mem.dll.Luggage.LuggageSlot(pl , bag)
	frame =  structs.LuggageFrame:new(base)
	-- return structs.LuggageFrame(frame)
	return frame
end