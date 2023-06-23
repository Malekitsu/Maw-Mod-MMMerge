if ItemRework==true then
function events.GenerateItem(t)
	--get party average level
	partyExperience = 0
	Handled = false
	for i = 0, 3 do
		partyExperience = partyExperience + Party.Players[i].Experience
	end
	
	averagePlayerExperience = partyExperience / 4
	
	partyLevel = math.floor((1 + math.sqrt(1 + (4 * averagePlayerExperience / 500))) / 2)
	
	--buff if item is weak
	if t.Strength*20<partyLevel and t.Strength<6 then
		roll=math.random(1,t.Strength*20)
		if roll<(partyLevel-t.Strength*20) then
			t.Strength=math.min(t.Strength+1,6)
		end
		
		if partyLevel>t.Strength*20+20 and t.Strength<6 then
		roll=math.random(1,t.Strength*20+20)
			if roll<(partyLevel-(t.Strength*20+20)) then
				t.Strength=math.min(t.Strength+1,6)
			end	
		end
	end
	--nerf if item is strong
	if partyLevel<(t.Strength-3)*20 and t.Strength<7 then
		t.Strength=t.Strength-1
	end
	if (t.Strength-1)*20>partyLevel and t.Strength>2 and t.Strength<7 then
		roll=math.random((t.Strength-3)*20,(t.Strength-2)*20)
		if roll>partyLevel then
			t.Strength=t.Strength-1
		end
	end
end

function events.ItemGenerated(t)	
	if t.Number<=151 or (t.Number>=803 and t.Number<=936) or (t.Number>=1603 and t.Number<=1736) then
		--give bonus a chance to proc even if bonus2 is already in the item
		if t.Bonus2~=0 then
		bonusprocChance=math.random(1,100)
			if bonusprocChance<=40 and t.Strength~=1 or (t.Strength==6 and bonusprocChance<=75) then
				t.Bonus = math.random(1,14)
				local bonuses = {{1, 5}, {3, 8}, {6, 12}, {10, 17}, {15, 25}}
				local bonus = bonuses[t.Strength - 1]
				t.BonusStrength = math.random(bonus[1], bonus[2])
			end
		end
		--extra bonus proc
		extraBonusChance={30,40,50,50,50,50}
		extraBonusPowerLow={1,1,3,6,10,15}
		extraBonusPowerHigh={3,5,8,12,17,25}
		ChargesProc=math.random(1,100)
		if ChargesProc<=extraBonusChance[t.Strength] then
			lowerLimit=t.Strength
			t.Charges = math.random(14 * extraBonusPowerLow[t.Strength]-13, 14 * extraBonusPowerHigh[t.Strength])
			--make it standard bonus if no standard bonus
			if t.Bonus==0 then
				t.Bonus=t.Charges%14+1
				t.BonusStrength=math.ceil(t.Charges/14)
				t.Charges=0
			end
		end
		
		--of x spell proc chance
		if t.Number>=120 and t.Number<=134 and t.Bonus2~=0 and t.Strength < 6 then
			roll=math.random(1,100)
			if roll<(t.Strength-1)*10 then
				t.Bonus2=math.random(26,34)
			end
		end
		
		--chance for ancient item, only if bonus 2 is spawned
		if t.Bonus2~=0 then 
			ancient=math.random(1,50)
			if ancient<=t.Strength-3 then
				t.Charges=math.random(364,560)
				t.Bonus=math.random(1,14)
				t.BonusStrength=math.random(26,40)
				if t.Number>=94 and t.Number<=99 then
				t.ExtraData=3000+math.random(40,50)
				end
			end
		end
		
		--primordial item
		primordial=math.random(1,200)
		if primordial<=t.Strength-4 then
			t.Charges=math.random(547,560)
			t.Bonus=math.random(1,14)
			t.BonusStrength=40
			if t.Number>60 then
				t.Bonus2=math.random(1,2)
				else
				t.Bonus2=41
			end
		end	
		--buff to hp and mana items
		if t.Bonus==8 or t.Bonus==9 then
			t.BonusStrength=t.BonusStrength*2
		end
		if t.Charges%14==7 or t.Charges%14==8 then
			t.Charges=t.Charges+14*math.ceil(t.Charges/14)
		end
	end
end



--apply charges effect
function events.CalcStatBonusByItems(t)
	for it in t.Player:EnumActiveItems() do
		if it.Charges ~= nil then
			stat=it.Charges%14
			bonus=math.ceil(it.Charges/14)
			if t.Stat==stat then
				t.Result = t.Result + bonus
			end
		end
	end
end

----------------------
--weapon rework
----------------------
function events.GameInitialized2()
--Weapon upscaler 


for i=1,65 do
upTierDifference=0
downTierDifference=0
downDamage=0
--set goal damage for weapons (end game weapon damage)
goalDamage=50
if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" then
	goalDamage=goalDamage*2
end
currentDamage = (Game.ItemsTxt[i].Mod1DiceCount *Game.ItemsTxt[i]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i].Mod2 

	for v=1,4 do
		if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[i+v].NotIdentifiedName then
		upTierDifference=upTierDifference+1
		end
		if Game.ItemsTxt[i].NotIdentifiedName==Game.ItemsTxt[math.max(i-v,0)].NotIdentifiedName then
		downTierDifference=downTierDifference+1
		downDamage = (Game.ItemsTxt[i-v].Mod1DiceCount *Game.ItemsTxt[i-v]. Mod1DiceSides + 1)/2+Game.ItemsTxt[i-v].Mod2
		elseif downTierDifference==0 then
				downDamage = currentDamage
		end
	end

--calculate expected value
tierRange=upTierDifference+downTierDifference+1
damageRange=goalDamage-downDamage
expectedDamageIncrease=damageRange^(downTierDifference/(tierRange-1))
Game.ItemsTxt[i].Mod1DiceSides = Game.ItemsTxt[i].Mod1DiceSides + (expectedDamageIncrease / Game.ItemsTxt[i].Mod1DiceCount)
Game.ItemsTxt[i].Mod2=expectedDamageIncrease/2

end 

--do same for artifacts
for i=400,405 do
goalDamage=75
if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" then
	goalDamage=goalDamage*2
end
downDamage=(Game.ItemsTxt[i].Mod1DiceCount *Game.ItemsTxt[i]. Mod1DiceSides + 1)/2
damageRange=goalDamage-downDamage
Game.ItemsTxt[i].Mod1DiceSides = Game.ItemsTxt[i].Mod1DiceSides + (damageRange / Game.ItemsTxt[i].Mod1DiceCount)
Game.ItemsTxt[i].Mod2=goalDamage/2
end

for i=415,420 do
goalDamage=75
if Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Axe" or Game.ItemsTxt[i].NotIdentifiedName == "Two-Handed Sword" then
	goalDamage=goalDamage*2
end
downDamage=(Game.ItemsTxt[i].Mod1DiceCount *Game.ItemsTxt[i]. Mod1DiceSides + 1)/2
damageRange=goalDamage-downDamage
Game.ItemsTxt[i].Mod1DiceSides = Game.ItemsTxt[i].Mod1DiceSides + (damageRange / Game.ItemsTxt[i].Mod1DiceCount)
Game.ItemsTxt[i].Mod2=goalDamage/2
end
--armors fix
Game.ItemsTxt[71].Mod2=2
Game.ItemsTxt[72].Mod2=7
Game.ItemsTxt[73].Mod2=16
Game.ItemsTxt[74].Mod2=28
Game.ItemsTxt[75].Mod2=44

Game.ItemsTxt[76].Mod2=8
Game.ItemsTxt[77].Mod2=24
Game.ItemsTxt[78].Mod2=60

Game.ItemsTxt[79].Mod2=3
Game.ItemsTxt[80].Mod2=5
Game.ItemsTxt[81].Mod2=9
Game.ItemsTxt[82].Mod2=18
Game.ItemsTxt[83].Mod2=33
Game.ItemsTxt[84].Mod2=2
Game.ItemsTxt[85].Mod2=5
Game.ItemsTxt[86].Mod2=9
Game.ItemsTxt[87].Mod2=18
Game.ItemsTxt[88].Mod2=33

Game.ItemsTxt[406].Mod2=46
Game.ItemsTxt[407].Mod2=64
Game.ItemsTxt[408].Mod2=38

Game.ItemsTxt[421].Mod2=60
Game.ItemsTxt[422].Mod2=77
Game.ItemsTxt[423].Mod2=61



------------
--tooltips
------------
Game.SpcItemsTxt[3].BonusStat="Adds 6-8 points of Cold damage."
Game.SpcItemsTxt[4].BonusStat="Adds 18-24 points of Cold damage."
Game.SpcItemsTxt[5].BonusStat="Adds 36-48 points of Cold damage."
Game.SpcItemsTxt[6].BonusStat="Adds 4-10 points of Electrical damage."
Game.SpcItemsTxt[7].BonusStat="Adds 12-30 points of Electrical damage."
Game.SpcItemsTxt[8].BonusStat="Adds 24-60 points of Electrical damage."
Game.SpcItemsTxt[9].BonusStat="Adds 2-12 points of Fire damage."
Game.SpcItemsTxt[10].BonusStat="Adds 6-36 points of Fire damage."
Game.SpcItemsTxt[11].BonusStat="Adds 12-72 points of Fire damage."
Game.SpcItemsTxt[12].BonusStat="Adds 10 points of Body damage."
Game.SpcItemsTxt[13].BonusStat="Adds 24 points of Body damage."
Game.SpcItemsTxt[14].BonusStat="Adds 48 points of Body damage."

end

--ENCHANTS HERE
--MELEE bonuses
enchantbonusdamage = {}
enchantbonusdamage[4] = 2
enchantbonusdamage[5] = 3
enchantbonusdamage[6] = 4
enchantbonusdamage[7] = 2
enchantbonusdamage[8] = 3
enchantbonusdamage[9] = 4
enchantbonusdamage[10] = 2
enchantbonusdamage[11] = 3
enchantbonusdamage[12] = 4
enchantbonusdamage[13] = 2
enchantbonusdamage[14] = 3
enchantbonusdamage[15] = 4
enchantbonusdamage[46] = 4

function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
    if data and data.Player and t.DamageKind ~= 0 and data.Object == nil then
	n=1
	bonusDamage2=1
        for i = 0,1 do
			it=data.Player:GetActiveItem(i)
			bonusDamage=0
			-- calculation
			if it then
				if it.ExtraData==0 then
					if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46  then
					local bonusDamage1 = bonusDamage+enchantbonusdamage[it.Bonus2] or 0
					bonusDamage2=(bonusDamage2*bonusDamage1)^(1/n)
					n=n+1
					end
				end
			end
        end	
		
		if n~=0 and bonusDamage2~=0 then
		t.Result = bonusDamage2*t.Result
		end
    end
end

--bows 
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
    if data and data.Player and t.DamageKind ~= 0 and data.Object~=nil then
			if data.Object.Spell==100 then
			it=data.Player:GetActiveItem(2)
			-- calculation
			if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46 and it.ExtraData==0 then
			local bonusDamage = enchantbonusdamage[it.Bonus2] or 0
			t.Result=t.Result*bonusDamage
			end	
		end
	end
 end

spellbonusdamage={}
spellbonusdamage[13] = 10
spellbonusdamage[14] = 24
spellbonusdamage[15] = 48

aoespells = {6, 7, 8, 9, 10, 15, 22, 26, 32, 41, 43, 84, 92, 97, 98, 99}
function events.CalcSpellDamage(t)
data=WhoHitMonster()
	if data.Player then
		it=data.Player:GetActiveItem(1)
		if it then
			if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46 and it.ExtraData==0 then
				spellbonusdamage[4] = math.random(6, 8)
				spellbonusdamage[5] = math.random(18, 24)
				spellbonusdamage[6] = math.random(36, 48)
				spellbonusdamage[7] = math.random(4, 10)
				spellbonusdamage[8] = math.random(12, 30)
				spellbonusdamage[9] = math.random(24, 60)
				spellbonusdamage[10] = math.random(2, 12)
				spellbonusdamage[11] = math.random(6, 36)
				spellbonusdamage[12] = math.random(12, 72)
				spellbonusdamage[46] = math.random(40, 80)
				buffed=0
				bonusDamage = spellbonusdamage[it.Bonus2] or 0
				for i = 1, #aoespells do
					if aoespells[i] == t.Spell then
						t.Result = t.Result+bonusDamage/5
						buffed=1
						break
					end
				end
				if buffed==0 then
				t.Result = t.Result+bonusDamage
				end
			end
		end
	end
end



--[[
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
    if data.Player and data.Object ~= nil and data.Object.Spell<100 then
		
		it=data.Player:GetActiveItem(0)
			
		--generate randoms
		enchantbonusdamage = {}
		enchantbonusdamage[4] = math.random(6, 8)
		enchantbonusdamage[5] = math.random(18, 24)
		enchantbonusdamage[6] = math.random(36, 48)
		enchantbonusdamage[7] = math.random(4, 10)
		enchantbonusdamage[8] = math.random(12, 30)
		enchantbonusdamage[9] = math.random(24, 60)
		enchantbonusdamage[10] = math.random(2, 12)
		enchantbonusdamage[11] = math.random(6, 36)
		enchantbonusdamage[12] = math.random(12, 72)
		enchantbonusdamage[46] = math.random(20, 80)
		-- calculation
		if (it.Bonus2 >= 4 and it.Bonus2 <= 15) or it.Bonus2 == 46 then
		bonusDamage2 = enchantbonusdamage[it.Bonus2] or 0
		t.Damage = t.Damage+bonusDamage2
		debug.Message(dump(t.Damage))
		end
    end	
end
--]]
---------------------
--multiple enchant tooltip
---------------------


mem.autohook(0x41C440, function(d)
	local t = {Item = structs.Item:new(d.ecx)}
	events.call("ShowItemTooltip", t)
end)

mem.autohook(0x41CE00, function(d)
	events.call("AfterShowItemTooltip")
end)




--change tooltip
function events.GameInitialized2()
	
	--STAT NAMES for custom tooltip
	itemStatName = {}
	--colours

	itemStatName[1]=StrColor(255,0,0,"Might")
	itemStatName[2]=StrColor(255,128,0,"Intellect")
	itemStatName[3]=StrColor(0,127,255,"Personality")
	itemStatName[4]=StrColor(0,255,0,"Endurance")
	itemStatName[5]=StrColor(255,255,0,"Accuracy")
	itemStatName[6]=StrColor(127,0,255,"Speed")
	itemStatName[7]=StrColor(255,255,255,"Luck")
	itemStatName[8]=StrColor(0,255,0,"Hit Points")
	itemStatName[9]=StrColor(0,100,255,"Spell Points")
	itemStatName[10]=StrColor(230,204,128,"Armor Class")
	itemStatName[11]=StrColor(255,100,100,"Fire Resistance")
	itemStatName[12]=StrColor(255,255,100,"Elec Resistance")
	itemStatName[13]=StrColor(153,255,255,"Cold Resistance")
	itemStatName[14]=StrColor(0,153,0,"Poison Resistance")
	
	--menu stats
	if ColouredStats==true then
		Game.GlobalTxt[144]=StrColor(255,0,0,"Might")
		Game.GlobalTxt[116]=StrColor(255,128,0,"Intellect")
		Game.GlobalTxt[163]=StrColor(0,127,255,"Personality")
		Game.GlobalTxt[75]=StrColor(0,255,0,"Endurance")
		Game.GlobalTxt[1]=StrColor(255,255,0,"Accuracy")
		Game.GlobalTxt[211]=StrColor(127,0,255,"Speed")
		Game.GlobalTxt[136]=StrColor(255,255,255,"Luck")
		Game.GlobalTxt[108]=StrColor(0,255,0,"Hit Points")
		Game.GlobalTxt[212]=StrColor(0,100,255,"Spell Points")
		Game.GlobalTxt[12]=StrColor(230,204,128,"Armor Class")
		Game.GlobalTxt[87]=StrColor(255,100,100,"Fire")
		Game.GlobalTxt[71]=StrColor(255,255,100,"Elec")
		Game.GlobalTxt[43]=StrColor(153,255,255,"Cold")
		Game.GlobalTxt[166]=StrColor(0,153,0,"Poison")
	end
	
	
	itemName = {}
	itemDesc = {}
	enchantAdd = {}
	enchantAdd2 = {}
	Game.ItemsTxt[580].NotIdentifiedName="Reality Scroll"
	Game.ItemsTxt[580].Notes="The Reality Scroll is an ancient artifact of immense power, said to possess the ability to manipulate the fabric of reality.\nAccording to the legend, it went long gone, stolen by Kreegans.\nThere are instructions about a ritual, but its effects are unknown"
	Game.ItemsTxt[579].NotIdentifiedName="Celestial Amulet"
	Game.ItemsTxt[579].Notes=string.format("The celestial dragon amulet is a breathtaking artifact that glimmers with otherworldly radiance. Fashioned from an otherworldly metal that is said to have been forged in the heart of a star, the amulet is adorned with intricate engravings of celestial dragons in mid-flight, their wings outstretched as if to take to the heavens themselves. Wearing this amulet is said to imbue the wielder with immense power, allowing them to channel the energies of the cosmos and bend them to their will. But the amulet's true strength lies in its ability to protect its allies. With a mere thought, the wearer can summon a shield of celestial energy that envelops their comrades, shielding them from harm and granting them the strength to fight on. It is said that only the most noble and righteous of warriors are able to wield the celestial dragon amulet, and that those who do so are blessed with the favor of the Gods themselves.\n%s",StrColor(255,255,153,"+50 to all seven stats, protection to Death and Eradicate"))
	
		
	for i = 1, 578 do
	  itemName[i] = Game.ItemsTxt[i].Name
	end
	for i = 1, 134 do
	  itemDesc[i] = Game.ItemsTxt[i].Notes
	end
	--copy enchants
	for i=0,13 do
		enchantAdd[i]=Game.StdItemsTxt[i].NameAdd
	end
	for i=0, 58 do
		enchantAdd2[i]=Game.SpcItemsTxt[i].NameAdd
	end
	--new items	
	Game.ItemsTxt[580].Name = "Reality Scroll"
	Game.ItemsTxt[579].Name = "Celestial Dragon Amulet"
	--fix long tooltips causing crash 

	Game.SpcItemsTxt[40].BonusStat= "Drain target Life and Increased Weapon speed."
	Game.SpcItemsTxt[41].BonusStat= " +1 to All Statistics."
	Game.SpcItemsTxt[43].BonusStat=" +10 HP and Regenerate HP over time."
	Game.SpcItemsTxt[45].BonusStat= "Adds 40-80 points of Fire damage, +25 Might."
	Game.SpcItemsTxt[46].BonusStat= " +10 Spell points and SP Regeneration."
	Game.SpcItemsTxt[49].BonusStat= " +30 Fire Resistance and HP Regeneration."	 
	Game.SpcItemsTxt[53].BonusStat=" +15 Endurance and Regenerate HP over time."
	--new tooltips
	Game.SpcItemsTxt[17].BonusStat="Disease and Curse Immunity"
	Game.SpcItemsTxt[18].BonusStat="Insanity and fear Immunity"
	Game.SpcItemsTxt[19].BonusStat="Paralysis and SP drain Immunity"
	Game.SpcItemsTxt[20].BonusStat="Poison and weakness Immunity"
	Game.SpcItemsTxt[21].BonusStat="Sleep and Unconscious Immunity"
	Game.SpcItemsTxt[22].BonusStat="Stone and premature ageing Immunity"
	Game.SpcItemsTxt[24].BonusStat="Death and erad. Immunity, +5 Levels"
end


	function events.ShowItemTooltip(item)
		if item.Item.Bonus~=0 and item.Item.Bonus2~=0 and item.Item.Charges~=0 then
		Game.StdItemsTxt[item.Item.Bonus-1].BonusStat=string.format("\n%s +%s\n%s",itemStatName[item.Item.Charges%14+1],math.ceil(item.Item.Charges/14), itemStatName[item.Item.Bonus])
			else if item.Item.Bonus~=0 and item.Item.Bonus2~=0 and item.Item.Charges==0 then
				Game.StdItemsTxt[item.Item.Bonus-1].BonusStat=string.format("\n%s", itemStatName[item.Item.Bonus])
				else if item.Item.Bonus~=0 and item.Item.Charges~=0 and item.Item.Bonus2==0 then
					Game.StdItemsTxt[item.Item.Bonus-1].BonusStat=string.format("\n%s +%s\n%s",itemStatName[item.Item.Charges%14+1],math.ceil(item.Item.Charges/14), itemStatName[item.Item.Bonus])
					else if item.Item.Bonus~=0 and item.Item.Charges==0 and item.Item.Bonus2==0 then
						Game.StdItemsTxt[item.Item.Bonus-1].BonusStat=string.format("%s",itemStatName[item.Item.Bonus])
					end
				end
			end
		end
		
	--Change item name and colour
	--number of bonuses
	bonuses=0
	if item.Item.Bonus~=0 then
	bonuses=bonuses+1
	end
	if item.Item.Charges~=0 then
	bonuses=bonuses+1
	end
	if item.Item.Bonus2~=0 then
	bonuses=bonuses+1
	end
	
	ancient=0
	bonus=item.Item.BonusStrength
	if item.Item.Bonus==8 or item.Item.Bonus==9 then
		bonus=bonus/2
	end
	extrabonus=math.ceil(item.Item.Charges/14)
	if item.Item.Charges%14==7 or item.Item.Charges%14==8 then
		extrabonus=extrabonus/2
	end
	if item.Item.Number<135 then	
		if (bonus>25 and extrabonus>25) or bonus+extrabonus>50 then
			Game.ItemsTxt[item.Item.Number].Name=StrColor(255,128,0,string.format("%s %s","Ancient", itemName[item.Item.Number]))	
			Game.StdItemsTxt[item.Item.Bonus-1].NameAdd = StrColor(255,128,0,enchantAdd2[item.Item.Bonus2-1])
			
			elseif bonuses==3 then
				Game.ItemsTxt[item.Item.Number].Name=StrColor(163,53,238,string.format("%s", itemName[item.Item.Number]))
				Game.StdItemsTxt[item.Item.Bonus-1].NameAdd = StrColor(163,53,238,enchantAdd2[item.Item.Bonus2-1])
			elseif bonuses==2 then
				Game.ItemsTxt[item.Item.Number].Name = StrColor(0,150,255,string.format("%s", itemName[item.Item.Number]))
				if item.Item.Bonus2==0 then
					Game.StdItemsTxt[item.Item.Bonus-1].NameAdd = StrColor(0,150,255,enchantAdd[item.Item.Bonus-1])
					elseif item.Item.Bonus2>0 then
						Game.StdItemsTxt[item.Item.Bonus-1].NameAdd = StrColor(0,150,255,enchantAdd2[item.Item.Bonus2-1])
				end
			elseif bonuses==1 then
				Game.ItemsTxt[item.Item.Number].Name=StrColor(30,255,0,string.format("%s", itemName[item.Item.Number]))
				if item.Item.Bonus>0 then
					Game.StdItemsTxt[item.Item.Bonus-1].NameAdd=StrColor(30,255,0,enchantAdd[item.Item.Bonus-1])
					elseif item.Item.Bonus2>0 then
						Game.SpcItemsTxt[item.Item.Bonus2-1].NameAdd = StrColor(30,255,0,enchantAdd2[item.Item.Bonus2-1])
				end
			elseif bonuses==0 then
				Game.ItemsTxt[item.Item.Number].Name=StrColor(255,255,255,string.format("%s", itemName[item.Item.Number]))
		end
	end
	--name colour for artifacts/relics
	if item.Item.Number>399 and item.Item.Number<430 then
		Game.ItemsTxt[item.Item.Number].Name=StrColor(230,204,128,string.format("%s", itemName[item.Item.Number]))
	end

	if bonus==40 and extrabonus==40 then
		Game.ItemsTxt[item.Item.Number].Name=StrColor(255,0,0,string.format("%s %s","Primordial", itemName[item.Item.Number]))
		if item.Item.Bonus>0 then
			Game.StdItemsTxt[item.Item.Bonus-1].NameAdd=StrColor(255,0,0,enchantAdd[item.Item.Bonus-1])
		end
		end
		
		--Bonus2
		if item.Item.Bonus2>0 and item.Item.Bonus>0 then
			Game.ItemsTxt[item.Item.Number].Notes=string.format("%s\n\n%s",StrColor(255,255,153,Game.SpcItemsTxt[item.Item.Bonus2-1].BonusStat),itemDesc[item.Item.Number])
			else
			Game.ItemsTxt[item.Item.Number].Notes=itemDesc[item.Item.Number]
		end
	--Crowns and HATS
		if item.Item.ExtraData~=nil then
			if item.Item.Number>=94 and item.Item.Number<=99 then
				local statbonus=item.Item.ExtraData%10000
					if statbonus>3000 then
					statbonus="Damage and Healing"
					else if statbonus>2000 then
						statbonus="Healing"
						else statbonus="Damage"
					end
				end		
				if item.Item.Bonus2==0 then
				Game.ItemsTxt[item.Item.Number].Notes=string.format("%s %s %s %s%s\n\n%s",StrColor(255,255,153,"Increases spell"),StrColor(255,255,153,statbonus),StrColor(255,255,153,"by:"),StrColor(255,255,153,item.Item.ExtraData%1000),StrColor(255,255,153,"%"),itemDesc[item.Item.Number])
				elseif item.Item.Bonus2>0 then
					Game.ItemsTxt[item.Item.Number].Notes=string.format("%s\n%s %s %s %s%s\n\n%s",StrColor(255,255,153,Game.SpcItemsTxt[item.Item.Bonus2-1].BonusStat),StrColor(255,255,153,"Increases spell"),StrColor(255,255,153,statbonus),StrColor(255,255,153,"by:"),StrColor(255,255,153,item.Item.ExtraData%1000),StrColor(255,255,153,"%"),itemDesc[item.Item.Number])
				end				
			elseif item.Item.Bonus2>0 and item.Item.Bonus>0 then
				Game.ItemsTxt[item.Item.Number].Notes=string.format("%s\n\n%s",StrColor(255,255,153,Game.SpcItemsTxt[item.Item.Bonus2-1].BonusStat),itemDesc[item.Item.Number])
			else
				Game.ItemsTxt[item.Item.Number].Notes=itemDesc[item.Item.Number]
			end
		end
		

		
	end
-----------------------------
---IMMUNITY REWORK
-----------------------------

--disease/curse
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 18 then
			if t.Thing==9 or t.Thing==10 or t.Thing==11 or t.Thing==1 then
			t.Allow=false
				if t.Thing==9 or t.Thing==10 or t.Thing==11 then
				Game.ShowStatusText(string.format("Enchantment protects %s from disease",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from curse",t.Player.Name))
				end
			end
		end
	end
end
--insanity/drainsp
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 19 then
			if t.Thing==5 or t.Thing==22 then
			t.Allow=false
				if t.Thing==5 then
				Game.ShowStatusText(string.format("Enchantment protects %s from insanity",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from spell drain",t.Player.Name))
				end

			end
		end
	end
end
--Paralysis/fear
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 20 then
			if t.Thing==12 or t.Thing==23 then
			t.Allow=false
				if t.Thing==12 then
				Game.ShowStatusText(string.format("Enchantment protects %s from paralysis",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from fear",t.Player.Name))
				end
			end
		end
	end
end
--poison/weak
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 21 then
			if t.Thing==6 or t.Thing==7 or t.Thing==8 or t.Thing==2 then
			t.Allow=false
				if t.Thing==6 or t.Thing==7 or t.Thing==8 then
				Game.ShowStatusText(string.format("Enchantment protects %s from poison",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from weakness",t.Player.Name))
				end
			end
		end
	end
end
--sleep/unconscious
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 22 then
			if t.Thing==3 or t.Thing==13 then
			t.Allow=false
				if t.Thing==3 then
				Game.ShowStatusText(string.format("Enchantment protects %s from sleep",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from unconscious",t.Player.Name))
				end
			end
		end
	end
end
--stone/age
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 23 then
			if t.Thing==15 or t.Thing==21 then
			t.Allow=false
				if t.Thing==15 then
				Game.ShowStatusText(string.format("Enchantment protects %s from stone",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from premature ageing",t.Player.Name))
				end
			end
		end
	end
end

--death/erad
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Bonus2 == 25 then
			if t.Thing==14 or t.Thing==16 then
			t.Allow=false
				if t.Thing==14 then
				Game.ShowStatusText(string.format("Enchantment protects %s from death",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Enchantment protects %s from eradication",t.Player.Name))
				end
			end
		end
	end
end





-- some spare code, just in case
--[[
function AfterShowItemTooltip()
  debug.Message(dump(t))
end]]
--celestial amulet
function events.DoBadThingToPlayer(t)
for it in t.Player:EnumActiveItems() do
		if it.Number == 579 then
			if t.Thing==16 or t.Thing==14 then
			t.Allow=false
				if t.Thing==14 then
				Game.ShowStatusText(string.format("Celestial Amulet protects %s from death",t.Player.Name))
				else 
				Game.ShowStatusText(string.format("Celestial Amulet protects %s from eradication",t.Player.Name))
				end
			end
		end
	end
end
function events.CalcStatBonusByItems(t)
	if t.Stat >= const.Stats.Might and t.Stat <= const.Stats.Luck then
		for it in t.Player:EnumActiveItems() do
			if it.Number == 579 then
				t.Result = t.Result + 50
			end
		end
	end
end



--------------------
--STATUS REWORK (needs to stay after status immunity
--------------------
if StatusRework==true then


function events.LoadMap(wasInGame)
local function poisonTimer() 

vars.poisonTime=vars.poisonTime or {}
	for i = 0, 3 do
		if Party[i].Poison3>0 then
			if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
			vars.poisonTime[i]=25
			end
			if vars.poisonTime[i]>0 then
			vars.poisonTime[i]=vars.poisonTime[i]-1
			end
			if vars.poisonTime[i]==0 then			
			Party[i].Poison3=0
			Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
			else
			Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.06)
			end 
		else if Party[i].Poison2>0 then
				if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
				vars.poisonTime[i]=25
				end
				if vars.poisonTime[i]>0 then
				vars.poisonTime[i]=vars.poisonTime[i]-1
				end
				if vars.poisonTime[i]==0 then			
				Party[i].Poison2=0
				Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
				else
				Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.04)
				end 
			else if Party[i].Poison1>0 then
					if vars.poisonTime[i]==nil or vars.poisonTime[i]==0 then
					vars.poisonTime[i]=25
					end
					if vars.poisonTime[i]>0 then
					vars.poisonTime[i]=vars.poisonTime[i]-1
					end
					if vars.poisonTime[i]==0 then			
					Party[i].Poison1=0
					Game.ShowStatusText(string.format("%s's poison effect expired",Party[i].Name))
					else
					Party[i].HP=Party[i].HP-math.ceil(Party[i].LevelBase*Game.Classes.HPFactor[Party[i].Class]*0.02)
					end 
				else vars.poisonTime[i]=0
				end
			end
		end
	end
end
Timer(poisonTimer, const.Minute) 
end

function events.DoBadThingToPlayer(t)
		if (t.Thing==6 or t.Thing==7 or t.Thing==8) and t.Allow then
		if vars.poisonTime[t.PlayerIndex]==nil or vars.poisonTime[t.PlayerIndex]==0 then
		vars.poisonTime[t.PlayerIndex]=25
		else
		vars.poisonTime[t.PlayerIndex]=math.min(vars.poisonTime[t.PlayerIndex]+5,50)
		end
	end
end

--hp and sp regen
function events.LoadMap(wasInGame)
local function restoreHPEnchant() 
	for _, pl in Party do 
	HPregen=0
	totHP=pl:GetFullHP()
		for it in pl:EnumActiveItems() do
			if it.Bonus2 == 37 or it.Bonus2==44 or it.Bonus2==50 or it.Bonus2==54 then		
				HPregen=math.max(HPregen+totHP*0.005,HPregen+1)	
			end
		end
	HPregen=math.max(HPregen-1,0)
	pl.HP=math.min(pl.HP+math.round(HPregen),totHP)
	end 
end
Timer(restoreHPEnchant, const.Minute*5) 


local function restoreSPEnchant() 
	for _, pl in Party do 
	SPregen=0
	totSP=pl:GetFullSP()
		for it in pl:EnumActiveItems() do
			if it.Bonus2 == 38 or it.Bonus2==47 or it.Bonus2==55 then		
				SPregen=math.max(SPregen+totSP*0.005,SPregen+1)
			end
		end
	SPregen=math.max(SPregen-1,0)
	pl.SP=math.min(pl.SP+math.round(SPregen),totSP)
	end 
end
Timer(restoreSPEnchant, const.Minute*5) 
end

end

--carnage fix
function events.CalcDamageToMonster(t)
    local data = WhoHitMonster()
	if data and data.Player and data.Object ~= nil then
		if data.Object.Item.Bonus2==3 then
			t.Result=t.Result/2
		end
	end
end
function events.GameInitialized2()
Game.SpcItemsTxt[2].BonusStat="Explosive Impact! (half damage)"
end
end