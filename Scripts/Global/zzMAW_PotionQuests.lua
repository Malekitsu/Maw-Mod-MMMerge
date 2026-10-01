--Black potion turn-ins (Thistle 181, Rihansi 203, Talion 212, Kelvin 234, Galvinus 246) are
--rewritten in GLOBAL.lua (QUEST FIX), but MMMerge registers its own handlers for the same events
--in StdQuestsFunctions.lua (PotionHuntQuest), which loads after GLOBAL.lua. evt.global[n] = f adds
--a handler rather than replacing one, so both ran: after MAW's handler the merge's took a second
--set of reagents and gave a second potion, or showed "missing ingredients" over MAW's message.
--This file loads after both and removes the merge's handler from those events.
for _, n in ipairs{181, 203, 212, 234, 246} do
	local ev = evt.Global[n]
	local f = ev.Last
	if f and debug.getinfo(f, "S").source:find("StdQuestsFunctions", 1, true) then
		ev.remove(f)
	end
end
