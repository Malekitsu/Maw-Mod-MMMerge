-- turn-based mode is off in multiplayer: the key that toggles it is swallowed,
-- and anything that still switches it on is switched back off on the next tick
local events = Multiplayer.events

local DISABLED_TEXT = "Turn-based mode is not available in multiplayer."

local function StopTurnBasedMode()
	if Game.TurnBased then
		Game.TurnBased = false
		mem.call(0x4063a9, 1, 0x509c98, 1)
		events.call("TurnBasedStopped")
	end
end
Multiplayer.StopTurnBasedMode = StopTurnBasedMode

local function enforce()
	if Game.TurnBased then
		StopTurnBasedMode()
		Game.ShowStatusText(DISABLED_TEXT)
	end
end

function events.KeyDown(t)
	if not t.Handled and t.Key == const.Keys.RETURN and Game.CurrentScreen == 0 then
		t.Handled = true
		t.Key = 0
		Game.ShowStatusText(DISABLED_TEXT)
	end
end

Multiplayer.utils.TickCounter(enforce, 1)
events.MultiplayerStarted = enforce

Multiplayer.debug.CanEndPartyMovePhase = function()
	return false
end
