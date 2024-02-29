local NUMPAD0 = 96
local ADD= 107
local SUBTRACT= 109
local OEM_PLUS= 187
local OEM_MINUS= 189

local count = 5


function events.KeyDown(t)

    if Game.CurrentScreen == 7 and Game.CurrentCharScreen == 103 then
		me = Party[Game.CurrentPlayer]
		--[[
		if t.Key >= NUMPAD0 and t.Key < NUMPAD0 + 10 then
			mem.dll.Luggage.activate(me ,t.Key - NUMPAD0 )
		end
		]]
		page = mem.dll.Luggage.current(me)
		if t.Key == OEM_MINUS then
		mem.dll.Luggage.activate(me , (page-1)%count)
		end
		if t.Key == OEM_PLUS then
			mem.dll.Luggage.activate(me , (page+1)%count)
		end
	end
end