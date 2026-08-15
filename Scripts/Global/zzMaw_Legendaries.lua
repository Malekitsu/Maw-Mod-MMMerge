function getDistanceToMonster(monster)
	return math.sqrt((Party.X - monster.X) * (Party.X - monster.X) + (Party.Y - monster.Y) * (Party.Y - monster.Y)) - monster.BodyRadius
end


function events.ItemAdditionalDamage(t)
	--[[empower enchants HANDLED IN THE FUNCTION BELOW
	local damage=0
	if enchantbonusdamage[t.Item.Bonus2] then
		local id=t.Player:GetIndex()
		local index=table.find(damageKindMap,enchantbonusdamage[t.Item.Bonus2].Type)
		local res=t.Monster.Resistances[index]%1000
		damage=calcEnchantDamage(t.Player, t.Item, res, true, false, "damage")
		local attackSpeedMult=getItemRecovery(t.Item, t.Player.LevelBase)/100
		t.Result=round(damage*attackSpeedMult)
		return
	end
	]]
	t.Result=0
end
--[11]="Killing a monster will recover you action time",

function changePlayer(id)
	RunNextTick(function()
		for i=0, Party.High do
			if Party[i]:GetIndex()==id then
				Game.CurrentPlayer=i
				return
			end
		end
	end)
end

--[13]="Immunity to all status effects from monsters",
function events.DoBadThingToPlayer(t)
	local pl=t.Player
	local id=pl:GetIndex()
	if vars.legendaries and vars.legendaries[id] and table.find(vars.legendaries[id], 13) then
		t.Allow = false
		--Game.ShowStatusText("Status Immunity")
	end
end

--[15]="Divine protection (instead of dying you go back to 25% HP, once every 5 minutes)",
function events.LoadMap(wasInGame)
	vars.legendaryProtectionCooldown=vars.legendaryProtectionCooldown or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		vars.legendaryProtectionCooldown[index]=vars.legendaryProtectionCooldown[index] or 0
	end
end


--[16]="Your highest resistance will always be used against non physical attacks",
--inside calcMawDamage


--[19]="Your weapon enchants now scales with the highest between might/int./pers.",
--inside calcspelldamage in maw spells and all across the code for tooltips

function calcManaShield(pl, damage)
	-- Get the player and their skill levels
	local s, m = SplitSkill(Skillz.get(pl, 51))
	local slot = 0
	local id = pl:GetIndex()
	for i = 0, Party.High do
		if Party[i]:GetIndex() == id then
			slot = i
			break
		end
	end

	-- Check if the Mana Shield is active for this player
	if s > 0 and vars.manaShield and vars.manaShield[slot] then
		local currentHP = pl.HP
		local totalHP = pl:GetFullHP()
		local mana = pl.SP

		-- Define thresholds and damage multipliers based on skill level
		local reduction = {0.25, 0.5, 0.75, 1, [0]=0}
		-- Calculate mana efficiency based on skill and mastery levels
		local manaEfficiency = manaShieldManaEfficiency(false, s)
		local absorbDamage=damage*reduction[m]
		local manaCost = round(absorbDamage/manaEfficiency)
		absorbDamage = math.min(absorbDamage,(mana*manaEfficiency))
		damage = round(damage - absorbDamage)
		pl.SP = math.max(pl.SP-manaCost, 0)
	end
	return damage
end

MANA_SHIELD_SKILL_CAP = 50

function manaShieldManaEfficiency(pl, skill)
	if pl then
		skill=SplitSkill(Skillz.get(pl, 51))
	end
	if skill == 50 then
		return 5
	end
	skill = math.min(skill, MANA_SHIELD_SKILL_CAP)
	return 1 + skill^1.4 / 60
end

--[[
local x=0
local y=0
local z=0
function GetTraveledDistance()
	local dist=getDistance(x,y,z)
	dist=math.round(dist*100)/100
	x=Party.X
	y=Party.Y
	z=Party.Z
	Game.ShowStatusText(dist)
end
function events.AfterLoadMap()
Timer(GetTraveledDistance, const.Minute/2)
end
]]
