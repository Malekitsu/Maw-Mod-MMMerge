local max, min, floor, ceil, sqrt = math.max, math.min, math.floor, math.ceil, math.sqrt
local StatNames = {[32] = 144, [33] = 116, [34] = 163, [35] = 75, [36] = 211, [37] = 1, [38] = 136}

-- Horseshoe

local function Horseshoe(Target, Item)
	Target.SkillPoints = Target.SkillPoints + 2
	Target:ShowFaceAnimation(36)
	Game.ShowStatusText(Game.GlobalTxt[125])
	return 2
end

evt.UseItemEffects[1448] = Horseshoe
evt.UseItemEffects[2083] = Horseshoe

-- Genie lamp

local function GenieLamp(Target, Item, PlayerId)

	local Reward, RewName
	local RewardString = "+%s %s !"
	local Mul = floor(sqrt(Target.LuckBase/10))
	local result = Mul + math.random(1, 7)

	if result == 1 then
		-- worst results
		evt.ForPlayer(PlayerId).Add{math.random(119, 123), 1}
	elseif result == 2 then
		-- random poison
		evt.ForPlayer(PlayerId).Add{math.random(113, 118), 1}
	elseif result == 3 then
		-- random harmless condition
		evt.ForPlayer(PlayerId).Add{math.random(107, 112), 1}
	elseif result == 4 then
		-- Gold
		evt.Add{21, math.random(1, 3) * 1000 * max(Mul, 1)}
	elseif result == 5 then
		-- Experience
		Reward = math.random(2, 5) * 1000 * max(Mul, 1)
		RewName = Game.GlobalTxt[83]
		evt.ForPlayer(PlayerId).Add{13, Reward}
	elseif result == 6 then
		-- SkillPoints
		Reward = math.random(2, 4) + Mul
		RewName = Game.GlobalTxt[207]
		evt.ForPlayer(PlayerId).Add{245, Reward}
	elseif result >= 7 then
		-- random base stat
		local Stat = math.random(32, 38)
		Reward = math.random(1, 3) + Mul
		RewName = Game.GlobalTxt[StatNames[Stat]]
		evt.ForPlayer(PlayerId).Add{Stat, Reward}
		if result > 7 then
			-- random item and Day of Gods buff
			Mouse.Item.Number = 0
			evt.GiveItem{5,0,0}
			CastSpellDirect(83, 10, 4)
			return 0
		end
	end

	if result > 4 then
		Game.ShowStatusText(RewardString:format(Reward, RewName))
	end

	if result > 7 then
		Target:ShowFaceAnimation(36)
		return 2
	else
		Mouse.Item.Number = 0
		return 0
	end

end

evt.UseItemEffects[1418] = GenieLamp
evt.UseItemEffects[2103] = GenieLamp

-- Eatable items
local function EatItem()
	Party.Food = Party.Food + 1
	Game.ShowStatusText(string.replace(Game.GlobalTxt[502], "%lu", "1"))
	Game.PlaySound(144)
	return 1
end

evt.UseItemEffects[1002] = EatItem
evt.UseItemEffects[1764] = EatItem
evt.UseItemEffects[1432] = EatItem
evt.UseItemEffects[2104] = EatItem

-- Deck of fate
local StatByMonth = {[0] = 32,33,34,35,36,37,38,46,47,48,49,52}
local StatNames = {[0] = 144,116,163,75,211,1,136,24,202,194,208,204}

evt.UseItemEffects[2067] = function(Target, Item, PlayerId)
	local stat, result = StatByMonth[Game.Month], Game.WeekOfMonth + 1
	evt.ForPlayer(PlayerId).Add{stat, result}
	Game.ShowStatusText("+" .. tostring(result) .. " " .. Game.GlobalTxt[StatNames[Game.Month]] .. "!")
	return 2
end

-- Temple in a bottle
evt.UseItemEffects[1452] = function(Target, Item, PlayerId)
	if Map.Name ~= "7nwc.blv" then
		vars.TempleInABottleEnteredFrom = {Party.X, Party.Y, Party.Z, 0,0,0,0,0, Map.Name}
	end
	ExitCurrentScreen(false, true)
	evt.MoveToMap{0,0,0,0,0,0,0,0,"7nwc.blv"}
	return 0
end

-- Dimension door spell scroll
local function DimensionDoor()
	TownPortalControls.GenDimDoor()
	TownPortalControls.SwitchTo(4)
	Game.GlobalTxt[10] = " "
	ExitCurrentScreen(false, true)
	CastSpellDirect(31, 10, 4) -- avoid any condition checks. -- CastSpellScroll(31)
	Mouse.Item.Number = 0
	Timer(TownPortalControls.RevertTPSwitch, const.Minute, Game.Time+const.Minute, false, false)
	return 0
end

evt.UseItemEffects[190] = DimensionDoor

-- Elven mushrom
evt.UseItemEffects[1011] = function(Target, Item, PlayerId)
	local PL = Party[PlayerId]
	PL.SP = min(PL.SP + 50, PL:GetFullSP())
	evt.ForPlayer(PlayerId).Set{112,1}
	return 1
end

-- Item sounds

local ItemSounds = {
	[1434] = 130, -- Lute
	[1436] = 132, -- Trumpet
	[2081] = 151, -- Tanir's bell
	[2082] = 148, -- Gong
	[2095] = 152, -- Chime
	[2098] = 149, -- Flute
	[2099] = 150, -- Harp
}
Game.ItemSounds = ItemSounds

local function ItemSound(Target, Item, PlayerId)
	Target:ShowFaceAnimation(14)
	Game.PlaySound(ItemSounds[Item.Number])
	return 0
end

for k, v in pairs(ItemSounds) do
	evt.UseItemEffects[k] = ItemSound
end
