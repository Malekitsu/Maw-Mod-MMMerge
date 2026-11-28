local Equip = {}
MawCore.Equip = Equip

local function isRace(pl, race)
	return Game.CharacterPortraits[pl.Face].Race == race
end

local function axeMastery(pl)
	local _, m = SplitSkill(pl.Skills[const.Skills.Axe])
	return m
end

local function isTwoHandedAxe(itemNumber)
	return table.find(twoHandedAxes, itemNumber) or table.find(halberdItems, itemNumber)
end

function Equip.oneHanded(pl, itemNumber)
	if isRace(pl, const.Race.Minotaur) and isTwoHandedAxe(itemNumber) then
		return true
	end
	return table.find(seraphClass, pl.Class) ~= nil and table.find(twoHandedSwords, itemNumber) ~= nil
end

function Equip.canOffhand(pl, itemNumber)
	local minotaur = isRace(pl, const.Race.Minotaur)
	if (minotaur or isRace(pl, const.Race.Dwarf)) and table.find(oneHandedAxes, itemNumber) then
		return axeMastery(pl) >= 2
	end
	if minotaur and isTwoHandedAxe(itemNumber) then
		return axeMastery(pl) >= 3
	end
	if table.find(seraphClass, pl.Class) and Game.ItemsTxt[itemNumber].Skill == const.Skills.Sword then
		return false
	end
end

function Equip.equipStat(pl, itemNumber)
	local equipStat = GetItemEquipStat(itemNumber)
	if equipStat == 1 and Equip.oneHanded(pl, itemNumber) then
		return 0
	end
	return equipStat
end

function Equip.start()
	function events.GameInitialized2()
		MawCore.Engine.setEquipRules(Equip.oneHanded, Equip.canOffhand)
		MawCore.Engine.setDollOffhandWeapon(function(itemNumber)
			return GetItemSkill(itemNumber) < const.Skills.Shield
		end)
		MawCore.Engine.setDollTwoHandedGrip(Equip.oneHanded)
	end
end
