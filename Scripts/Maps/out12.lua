
-- Correct load map event.
Game.MapEvtLines:RemoveEvent(1)
local function event1()
	Sleep(1000, 1000)

	local QB = Party.QBits
	local need_speak = not QB[775] and (QB[616] or QB[635])

	if need_speak then
		QB[775] = true

		if QB[616] then
			evt.SetNPCGreeting{462, 316}
		elseif QB[635] then
			evt.SetNPCGreeting{462, 317}
		end

		if Mouse.Item.Number ~= 0 then
			Mouse:ReleaseItem()
		end

		Mouse.Item.Number = 866
		Mouse.Item.Identified = true

		evt.SpeakNPC{462}
	end
end

function events.AfterLoadMap()
	coroutine.resume(coroutine.create(event1))
end
