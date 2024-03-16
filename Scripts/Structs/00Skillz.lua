local function hlp(Player)
		if mem.dll.skillz.PlayerID(Player)< 0 then
			Message("Invalid player call for Skillz.dll")
		end 
end

Skillz = {
	thanks = function() 
		Game.NeedRedraw = true 
		Sleep(1)
		Message( mem.string(mem.dll.skillz.thanks()))
		end,
	get = function(Player, skill_ID) 
		hlp(Player)
		return mem.dll.skillz.get(Player, skill_ID) end, 
	set = function(Player, skill_ID, value) 
		hlp(Player)
		mem.dll.skillz.set(Player, skill_ID, value) end,
	get2 = function(Player, skill_ID) 
		hlp(Player)
		return mem.dll.skillz.get2(Player, skill_ID) end, 
	set2 = function(Player, skill_ID, value) 
		hlp(Player)
		mem.dll.skillz.set2(Player, skill_ID, value) end,
		
	getName = function(skill_ID)
		return mem.string(mem.dll.skillz.getName(skill_ID))
	end,
		
	setName = function(skill_ID, Name)
		mem.dll.skillz.setName(skill_ID, Name)
	end,
	
	getDesc= function(skill_ID, desc_part)
		return mem.string(mem.dll.skillz.getDesc(skill_ID, desc_part))
	end,
	
	setDesc= function(skill_ID, desc_part, text)
		mem.dll.skillz.setDesc(skill_ID, desc_part, text)
	end,
	
	get_buffed = function(Player, skill_ID) 
		hlp(Player)
		return mem.dll.skillz.get_buffed(Player, skill_ID) end, 
	
	new_misc = function(skill_ID)
		mem.dll.skillz.new_misc(skill_ID)
	end,
	new_weapon = function(skill_ID)
		mem.dll.skillz.new_weapon(skill_ID)
	end,
	new_armor = function(skill_ID)
		mem.dll.skillz.new_armor(skill_ID)
	end,
	new_magic = function(skill_ID)
		mem.dll.skillz.new_magic(skill_ID)
	end,
	learn_at = function(skill_ID, HouseType)
		mem.dll.skillz.learn_at(skill_ID, HouseType)
	end,
	MasteryLimit=function(Player, skill_ID) 
		hlp(Player)
		return mem.dll.skillz.MasteryLimit(Player, skill_ID) 
	end,
	MasteryTable_get = function(race, clas, skill_ID)
	return mem.dll.skillz.MasteryLimit_raw(race, clas, skill_ID) end,
	MasteryTable_set = function(race, clas, skill_ID, modifier)
	mem.dll.skillz.MasteryLimit_raw(race, clas, skill_ID, modifier) end,
	CleanMastery=function(Player)
	return mem.dll.skillz.CleanMastery(Player) end
}

local thanked = false
function events.BeforeNewGameAutosave()
	if (not vars.Skillz_Thanked) then 
		refund = 0
		for _, pl in Party do
			refund = refund + Skillz.CleanMastery(pl)
		end
		refund = refund * 500
		if refund>0 then
			Party.AddGold(refund)
		end
	end

    if (not vars.Skillz_Thanked) and (not thanked) then 
        --Skillz.thanks()
        thanked = true
    end
    vars.Skillz_Thanked = true
end


function events.GameInitialized2()
	mem.dll.skillz.initPortraits(Game.CharacterPortraits)
end
-- Compatibility layer
local function GetMaxSkill(a, b, c) -- a - Race or Player structure, b - Class or skill id, c - skill id

		local Race, Class, Skill
		if type(a) == "number" then
			Race, Class, Skill = a, b, c
		else
			Race, Class, Skill = Game.CharacterPortraits[a.Face].Race, a.Class, b
		end
		return Skillz.MasteryTable_get(Race, Class, Skill)
end
	GetMaxSkillLevel	 = GetMaxSkill
	GetMaxAvailableSkill = GetMaxSkill
	
	
function JoinSkill2(sk, mas)
	return mas * 65536 + sk
end

function SplitSkill2(arg)
	sk = arg % 65536
	mas = (arg - sk) / 65536
	return sk, mas
end
