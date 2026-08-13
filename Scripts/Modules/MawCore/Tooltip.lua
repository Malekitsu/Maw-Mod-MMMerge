-- Tooltip.lua -- item tooltip section registry: ONE
-- BuildItemInformationBox handler running named sections in sort order
-- (sort keys mirror the old file load order; see the registrations at the
-- bottom). print(MawCore.Tooltip.describe()) lists them in-game.
--
-- Section fn(t) -> string appends to t.Description (bring your own "\n\n"),
-- or mutates t and returns nil, which is what most migrated bodies do.
--
-- Tooltip rendering knowledge (images, geometry, draw timing): GREENFIELD.md
-- par.6. The Structs handler in extraEditableDescriptions.lua stays raw and
-- still runs before every section.

local Tooltip = {}
MawCore.Tooltip = Tooltip

local Formulas = MawCore.Formulas

--Resistance enchants print as a %. The tooltip holds the RAW roll, so it has
--to be turned into stored power first -- a ring's counts half.
local function resistancePercent(roll, it)
	return Formulas.reductionPercent(Formulas.resistanceEnchantPower(roll, GetItemEquipStat(it)==10))
end

local sections = {}
local seq = 0

-- Tooltip.addSection("sockets", 500, fn) -- lower sort key = earlier in tooltip;
-- equal keys keep registration order.
function Tooltip.addSection(id, sort, fn)
	for _, s in ipairs(sections) do
		assert(s.id ~= id, ("tooltip: section %s already registered"):format(id))
	end
	seq = seq + 1
	sections[#sections + 1] = {id = id, sort = sort, seq = seq, fn = fn}
	table.sort(sections, function(a, b)
		if a.sort ~= b.sort then
			return a.sort < b.sort
		end
		return a.seq < b.seq
	end)
end

function Tooltip.remove(id)
	for i, s in ipairs(sections) do
		if s.id == id then
			table.remove(sections, i)
			return true
		end
	end
	return false
end

function Tooltip.describe()
	local out = {"tooltip sections:"}
	for _, s in ipairs(sections) do
		out[#out + 1] = ("  %4d %s"):format(s.sort, s.id)
	end
	if #sections == 0 then
		out[#out + 1] = "  (none)"
	end
	return table.concat(out, "\n")
end

function Tooltip.start()
	function events.BuildItemInformationBox(t)
		for _, s in ipairs(sections) do
			local text = s.fn(t)
			if text and t.Description then
				t.Description = t.Description .. text
			end
		end
	end
end


------------------------------------------------------------------------
-- Section bodies, verbatim from the legacy files named on each one; the
-- helpers they call are globals, so they run unchanged from here.
------------------------------------------------------------------------

-- was zzAlchemy.lua
local function tooltipPotions(t)
	local text=potionText[t.Item.Number]
	if type(text)=="function" then
		text=text(t.Item.Bonus)
	end
	if text then
		t.Description=text--REMOVED .. "\n(To drink, pick the potion up and right-click over a character's portrait.  To mix, pick the potion up and right-click over another potion.)"
	elseif t.Item.Number>=264 and t.Item.Number<=299 then
		t.Description="This potion has been removed"
	end
	if t.Item.Number==222 then
		t.Description=StrColor(255,255,153,"Heals " .. round(t.Item.Bonus^1.75)+10 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==223 then
		t.Description=StrColor(255,255,153,"Restores " .. round(t.Item.Bonus^1.6*2/3)+10 .. " Spell Points") .. "\n" .. t.Description
	end
	if t.Item.Number==232 then
		t.Description="Grants " .. StrColor(0,0,200,math.ceil(t.Item.Bonus^0.5/1.5) + 1) .. " bonus to Meditation skill for 6 hours."
	end
	if t.Item.Number==247 then
		t.Description=StrColor(255,255,153,"Heals " .. round(t.Item.Bonus^1.75*1.5)+20 .. " Hit Points") .. "\n" .. t.Description
	end
	if t.Item.Number==248 then
		t.Description=StrColor(255,255,153,"Restores " .. round(t.Item.Bonus^1.6)+20 .. " Spell Points") .. "\n" .. t.Description
	end
	if t.Item.Number==TRANSCENDENCE_POTION then
		local index=Party[math.min(math.max(Game.CurrentPlayer, 0), Party.High)]:GetIndex()
		local reached=vars.mawTranscendence and vars.mawTranscendence[index] or 0
		t.Description=t.Description .. "\n\nBest step already taken: " .. reached
			.. " (" .. GetTranscendenceSkillPoints(reached) .. " Skill Points)"
	end
		
	if table.find(potionUsingCharges,t.Item.Number) then
		local charges=t.Item.Charges-1
		if charges==-1 then
			charges=5
		end
		t.Description=StrColor(255,255,153,"Charges: " .. charges) .. "\n\n" .. t.Description
	end
	
	if potionRecipeText[t.Item.Number] then
		if extraDescription then
			t.Description=t.Description .. "\n\n" .. potionRecipeText[t.Item.Number]
		else
			t.Description=t.Description .. StrColor(100,100,100,"\n\nPress alt to show recipe list")
		end
	end
end

-- was zzAlchemy.lua
local function tooltipReagentPower(t)
	if reagentList[t.Item.Number] then
		local bonus=round(reagentList[t.Item.Number] *((t.Item.Bonus*0.25)/20+1)+t.Item.Bonus*0.75)
		t.Enchantment="Power: " .. bonus
	end
end

-- was zzAlchemy.lua
local function tooltipOrbsGems(t)
	if t.Item.Number>=1041 and t.Item.Number<=1060 then
		--[[
		if t.Name then
			if t.Item.BonusStrength==1 then
				t.Name=StrColor(178,255,255, "Ascended " .. t.Name) 
			end
		end
		]]
		if t.Description then
			local mult=math.max((Game.BolsterAmount-100)/2000+1,1)
			if vars.insanityMode then
				mult=1.4
			end
			if vars.madnessMode then
				mult=2
			end
			local tier=(t.Item.Number-1040)*mult
			local power = 3
			
			local twoHanded = tier * 4 * 2
			local bodyArmor = round(tier * 1.5 * 4)
			local helmEtc = round(tier * 1.25 * 4)
			local rings = round(tier * 0.75 * 4)
			
			
			t.Description = "A special Gem that allows to increase an item Enchant Strength (right-click on an item with a base enchant to use)\nAncient, Primordial and Legendary items have increased Max power.\n\nIt is possible to upgrade 3 gems into 1 of upper tier by pressing U in the inventory page.\n\nMax Power: " 
			.. StrColor(255, 128, 0, tostring(round(tier * 4))) --.. " (65% on AC)"
			.. "\nBonus: " .. StrColor(255, 128, 0, tostring(power)) 
			.. "\n\nItem Modifier:\nTwo Handed Weapons: " .. StrColor(255, 128, 0, twoHanded)
			.. "\nBody Armor: " .. StrColor(255, 128, 0, bodyArmor)
			.. "\nHelm-Boots-Gloves-Bow: " .. StrColor(255, 128, 0, helmEtc)
			.. "\nRings: " .. StrColor(255, 128, 0, rings)
		end
	end
	if t.Item.Number==1067 then
		if t.Description then
			if t.Item.BonusStrength<10 or t.Item.BonusStrength>1000 then
				t.Description="Oracle's Orb is a mysterious and powerful artifact, a large, purple orb with a haunting face suspended within its core. This enigmatic relic is known for storing legendary abilities upon items it enchants.\n\nRight click a legendary item to store its power"
			else
				t.Description="Oracle's Orb is a mysterious and powerful artifact, a large, purple orb with a haunting face suspended within its core. This enigmatic relic is known for storing legendary abilities upon items it enchants.\n\nAdds the following legendary power to an item:"
			end
			t.Description = t.Description .. "\n\n" .. StrColor(255,255,30,legendaryEffects[t.Item.BonusStrength])
		end
	end
	if t.Item.Number==1068 then
		if t.Description then				
			t.Description="\nThe Celestial Orb allows the transfer of celestial essence from one item to another, preserving the divine property while freeing the original item of its blessing.\n\n(right-click on a celestial item to extract its power charging the Celestial orb, then right-click on a non celestial item to transfer its power.)"
			if t.Item.BonusStrength==1 then
				t.Description = t.Description .. "\n\n" .. StrColor(120, 240, 255,"Celestial orb is charged and it's ready to grant celestial powers to any non-Artifact Equipment")
			end
		end
	end
	if t.Item.Number==1069 then
		if t.Description then				
			t.Description=t.Description .. StrColor(255,255,30, "\n\nIncreases Charges by " .. t.Item.BonusStrength)
		end
	end
end

-- was zzAlchemy.lua
local function tooltipCraftWithHeldItem(t)
	if Mouse.Item then
		UseItem(t.Item, Mouse.Item)
	end
end

-- was zzMaw-Items.lua
local function tooltipEnchantStats(t)
	if IsEnchantableItem(t.Item) then 

		local it=t.Item
		if t.Type then
			t.Type = t.Type
			
			updateCelestialItem(it)
			
			--add code to increase base stats based on bolster enchant
			--ARMORS
			if t.Item.MaxCharges>0 then
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat>=3 and equipStat<=9 then
				local ac3=txt.Mod2+txt.Mod1DiceCount 
					if ac3>0 then
						local lookup=0
						while Game.ItemsTxt[t.Item.Number].NotIdentifiedName==Game.ItemsTxt[t.Item.Number+lookup+1].NotIdentifiedName do 
							lookup=lookup+1
						end
						local ac=Game.ItemsTxt[t.Item.Number].Mod2+Game.ItemsTxt[t.Item.Number].Mod1DiceCount 
						local ac2=Game.ItemsTxt[t.Item.Number+lookup].Mod2+Game.ItemsTxt[t.Item.Number+lookup].Mod1DiceCount 
						local maxCharges=t.Item.MaxCharges
						--[[
						if vars.insanityMode then
							maxCharges=math.ceil(maxCharges*4/3)
						end
						--]]
						local bonusAC=Formulas.chargesArmorAC(ac2, maxCharges)
						--if t.Item.MaxCharges <= 20 then
							ac=ac3+round(bonusAC)
						--else
						--	local bonusAC=(ac+ac2)*(t.Item.MaxCharges/20)
						--	ac=ac3+round(bonusAC)
						--end		
						t.BasicStat= "Armor: +" .. ac
					end
				end
			end
			--WEAPONS (no charge gate: item-level damage shows on uncharged weapons too)
			do
				local txt=Game.ItemsTxt[t.Item.Number]
				local equipStat=txt.EquipStat
				if equipStat<=2 then
					--item-level weapon damage, same split as addWeaponRows
					local wDmg,wDice=GetWeaponDamage(t.Item)
					local split=wDmg-wDice
					local bonus=round(split/2)
					local sides=round((split/2+wDice)/math.max(txt.Mod1DiceCount,1))
					t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
				end
			end
			
			
			--add code to build enchant list
			t.Enchantment=""
			if t.Item.Bonus>0 then
				local power=t.Item.BonusStrength
				if t.Item.Bonus==8 or t.Item.Bonus==9 then
					local mult=GetSlotMult(it)
					power=round(power*(1+math.min(power/50/mult,5)))
				end
				if t.Item:T().EquipStat==5 and t.Item:T().Mod2==0 then
					power=math.ceil(power*1.5)
				end
				local resLegendary=false
				if t.Item.Bonus>=11 and t.Item.Bonus<=16 then
					local id=Game.CurrentPlayer
					if id>=0 and id<=Party.High then
						local index=Party[id]:GetIndex()
						if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 16) then
							power=power*1.5
							resLegendary=true
						end
					end
					power=resistancePercent(power+10, t.Item) .. "%"
				end
				if extraDescription then
					local it=t.Item
					local bolsterMult=math.max((Game.BolsterAmount-100)/2000+1,1)
					if vars.insanityMode then
						bolsterMult=1.4
					end
					if vars.madnessMode then
						bolsterMult=2
					end
					local maxValue=120 * bolsterMult
					if GetAncientTier(it)>0 then
						maxValue=math.min(maxValue+10,maxValue*1.2)
					end
					if HasLegendaryAffix(it) then
						maxValue=math.min(maxValue+20,maxValue*1.44)
					end
					local mult=slotMult[it:T().EquipStat] or 1
					if table.find(twoHandedAxes, it.Number) then
						mult=2
					end
					maxValue=round(maxValue*mult)
					if t.Item.Bonus>=11 and t.Item.Bonus<=16 then
						if resLegendary then
							maxValue=maxValue*1.5
						end
						maxValue=resistancePercent(maxValue+10, t.Item) .. "%"
					elseif t.Item.Bonus==8 or t.Item.Bonus==9 then
						local mult=GetSlotMult(t.Item)
						maxValue=round(maxValue*(1+math.min(maxValue/50/mult,5)))
					elseif t.Item.Bonus>=17 then
						maxValue=round(maxValue/10)
					end
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. power .. StrColor(100,100,100, " / " .. maxValue)
				else
					t.Enchantment = itemStatName[t.Item.Bonus] .. " +" .. power
				end
			end
			if HasEnc2(t.Item) then
				local bonus,strength=GetEnc2(t.Item)
				if bonus==8 or bonus==9 then
					local mult=GetSlotMult(it)
					strength=round(strength*(1+math.min(strength/50/mult,5)))
				end
				if t.Item:T().EquipStat==5 and t.Item:T().Mod2==0 then
					strength=math.ceil(strength*1.5)
				end				
				local resLegendary=false
				if bonus>=11 and bonus<=16 then
					local id=Game.CurrentPlayer
					if id>=0 and id<=Party.High then
						local index=Party[id]:GetIndex()
						if vars.legendaries and vars.legendaries[index] and table.find(vars.legendaries[index], 16) then
							strength=strength*1.5
							resLegendary=true
						end
					end
					strength=resistancePercent(strength+10, t.Item) .. "%"
				end
				if itemStatName[bonus] then
					if extraDescription then
						local it=t.Item
						local bolsterMult=math.max((Game.BolsterAmount-100)/2000+1,1)
						if vars.insanityMode then
							bolsterMult=1.4
						end
						if vars.madnessMode then
							bolsterMult=2
						end
						local maxValue=120 * bolsterMult
						if GetAncientTier(it)>0 then
							maxValue=math.min(maxValue+10,maxValue*1.2)
						end
						if HasLegendaryAffix(it) then
							maxValue=math.min(maxValue+20,maxValue*1.44)
						end
						local mult=slotMult[it:T().EquipStat] or 1
						if table.find(twoHandedAxes, it.Number) then
							mult=2
						end
						maxValue=round(maxValue*mult)
						if bonus>=11 and bonus<=16 then
							if resLegendary then
								maxValue=maxValue*1.5
							end
							maxValue=resistancePercent(maxValue+10, t.Item) .. "%"
						elseif bonus==8 or bonus==9 then
							local mult=GetSlotMult(t.Item)
							maxValue=round(maxValue*(1+math.min(maxValue/50/mult,5)))
						elseif bonus>=17 then
							maxValue=round(maxValue/10)
						end
						t.Enchantment = itemStatName[bonus] .. " +" .. strength .. StrColor(100,100,100, " / " .. maxValue) .. "\n" .. t.Enchantment
					else
						t.Enchantment = itemStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
					end
				end
			elseif t.Item.Bonus~=0 and t.Item.BonusStrength~=0 then
				if extraDescription then
					math.randomseed(t.Item.Number*10000+t.Item.MaxCharges*1000+t.Item.Bonus*100+t.Item.BonusStrength*10+t.Item.Charges)
					
					local mult=math.max((Game.BolsterAmount-100)/1000+1,1)
					local cap=100*mult
					local power=t.Item.BonusStrength
					if t.Item.Bonus==8 or t.Bonus==9 then
						power=math.floor((-100+(100^2+power*200)^0.5)/2)
					elseif t.Item.Bonus==10 then
						--power=power*1.5
					end
					local stat=RollEnchantType(t.Item, t.Item.Bonus)
					if stat==8 or stat==9 then
						GetSlotMult(t.Item)
						power=power*(1+math.min(power/50/mult,5))
					elseif stat==10 then
						--power=power*0.667
					end
					local slotMult=slotMult[t.Item:T().EquipStat] or 1
					cap=math.min(cap*slotMult,ENC2_MAX_STRENGTH)

					--was packed as stat*1000+strength and unpacked again on the
					--next line; the decimal round trip was what forced cap<=999
					local bonus=stat
					local strength=math.min(round(power*(1+0.25*math.random())),cap)
					if stat>=11 and stat<=16 then
						--second enchants grant the raw strength, no +10 (collectEnchant)
						strength=resistancePercent(strength, t.Item) .. "%"
					end
					txt=baseStatName[bonus] .. " +" .. strength .. "\n" .. t.Enchantment
					t.Enchantment = StrColor(100,100,100, txt)
					vars.extraShown=true
				end
			end
			if t.Item.Bonus==0 and t.Item.Bonus2==0 and not HasEnc2(t.Item) and extraDescription then
				if vars.enchantSeedList==nil then
				vars.enchantSeedList={}
					for i=0,2500 do
						vars.enchantSeedList[i]=math.random(1,100000)
					end
				end
				math.randomseed(vars.enchantSeedList[t.Item.Number]+t.Item.MaxCharges)
				if math.random(1,10)==1 then
					bonus=math.random(17,24)
				elseif GetItemEquipStat(t.Item)==10 then
					bonus=math.random(1,16)
				else
					bonus=math.random(1,10)
				end
				txt=baseStatName[bonus] .. " +X"
				t.Enchantment = StrColor(100,100,100, txt)
			end
		elseif t.Name then
			--add enchant Name
			t.Name = Game.ItemsTxt[t.Item.Number].Name
			if t.Item.Bonus2>0 then
				local enchString=Game.SpcItemsTxt[t.Item.Bonus2-1].NameAdd
				if string.match(enchString, "^%u") then
					t.Name= enchString .. " " .. t.Name
				else
					t.Name= t.Name .. " " .. enchString
				end
			elseif t.Item.Bonus>0 then
				t.Name= t.Name .. " " .. Game.StdItemsTxt[t.Item.Bonus-1].NameAdd
			end
			--choose colour
			local bonus=0
			if t.Item.Bonus>0 then
				bonus=bonus+1
			end
			if t.Item.Bonus2>0 then
				bonus=bonus+1
			end
			if HasEnc2(t.Item) then
				bonus=bonus+1
			end
			if IsCelestialItem(t.Item) then
				t.Name=StrColor(120, 240, 255,"Celestial " .. t.Name)
			elseif HasLegendaryAffix(t.Item) then
				t.Name=StrColor(255,255,30,"Legendary " .. t.Name)
			elseif IsPrimordialItem(t.Item) then
				t.Name=StrColor(255,0,0,"Primordial " .. t.Name)
			elseif IsAncientItem(t.Item) then
				t.Name=StrColor(255,128,0,"Ancient " .. t.Name)
			elseif bonus==3 then
				t.Name=StrColor(163,53,238,t.Name)
			elseif bonus==2 then
				t.Name=StrColor(0,150,255,t.Name)
			elseif bonus==1 then
				t.Name=StrColor(30,255,0,t.Name)
			else
				t.Name=StrColor(255,255,255,t.Name)
			end
		elseif t.Description then
			if HasLegendaryAffix(t.Item) then
				t.Description=""
			end
			local legAffix=GetLegendaryAffix(t.Item)
			if legendaryEffects[legAffix] then
				local legText=legendaryEffects[legAffix]
				if legAffix==21 then
					local count=0
					for i=0, Map.Monsters.High do
						if Map.Monsters[i].Active then
							local dist=getDistanceToMonster(Map.Monsters[i])
							if dist<=512 then
								count=count+1
							end
						end
					end
					local dmg=math.min(count*5,100)
					legText=legText .. "\nCurrent bonus Damage: " .. dmg .. "%"
				elseif legAffix==22 then
					local count=0
					for i=0, Map.Monsters.High do
						if Map.Monsters[i].Active then
							local dist=getDistanceToMonster(Map.Monsters[i])
							if dist<=512 then
								count=count+1
							end
						end
					end
					local red=round(math.min(1-0.97^count,0.5)*10000)/100
					legText=legText .. "\nCurrent Reduction: " .. red .. "%"
				end
				t.Description = StrColor(255,255,30,legText) .. t.Description
			end
			if t.Item.Bonus2>0 then	
				if (t.Item.MaxCharges>=0 and bonusEffects[t.Item.Bonus2]~= nil) or enchantList[t.Item.Bonus2] then
					text=checktext(t.Item.MaxCharges,t.Item.Bonus2,t.Item)
				else
					text=Game.SpcItemsTxt[t.Item.Bonus2-1].BonusStat
				end
				t.Description = StrColor(255,255,153,text) .. "\n\n" .. t.Description
			end
			if t.Item.Bonus>0 and t.Item.Bonus2==0 and extraDescription then
				local n, c, power, totB2, roll, tot, enchantNumber
				n=t.Item.Number
				c=Game.ItemsTxt[n].EquipStat
				math.randomseed(t.Item.Number*10000+t.Item.MaxCharges*1000+t.Item.Bonus*100+t.Item.BonusStrength*10+t.Item.Charges)
				if c<12 then
					power=6
					totB2=itemStrength[power][c]
					roll=math.random(1,totB2)
					tot=0
					for i=0,Game.SpcItemsTxt.High do
						if roll<=tot then
							enchantNumber=i
							goto continue
						elseif table.find(enchants[power], Game.SpcItemsTxt[i].Lvl) then
							tot=tot+Game.SpcItemsTxt[i].ChanceForSlot[c]
						end
					end	
				end
				:: continue ::
				if (t.Item.MaxCharges>=0 and bonusEffects[enchantNumber]~= nil) or enchantList[enchantNumber] then
					text=checktext(t.Item.MaxCharges,enchantNumber,t.Item)
				else
					text=Game.SpcItemsTxt[enchantNumber-1].BonusStat
				end
				t.Description = StrColor(100,100,100,text) .. "\n\n" .. t.Description
				vars.extraShown=true
			end
			if t.Item.Bonus>0 and t.Item.BonusStrength>0 then
				if not extraDescription and not vars.extraShown then
					t.Description = t.Description .. "\n\n" .. StrColor(100,100,100,"Press alt to show craftable stats")
				end
			end
		end
		if extraDescription and t.Description then
			local txt="\n\nItem Bonus Power: " .. t.Item.MaxCharges .. "/" .. GetItemChargesCap(t.Item)
			t.Description =t.Description .. StrColor(100,100,100, txt)
		end
	end
end

-- was zzMaw-Items.lua
local function tooltipArtifactScaling(t)
	if t.Description and (IsArtifactId(t.Item.Number)) then
		require("string")
		local pattern = "(%d+)"
		text=t.Description
		t.Description = text:gsub(pattern, function(match) return replaceNumber(match, t.Item.BonusExpireTime) end)
		local txt="\n\nScale with player level, up to level 550."
		if vars.madnessMode then
			txt="\n\nScale with player level, up to level 900."
		end
		if t.Item.BonusExpireTime>=1 then
			txt=StrColor(120, 240, 255,"\n\nArtifact Level: " .. t.Item.BonusExpireTime)
		end
		t.Description = t.Description .. txt
	end
end

-- was zzMaw-Items.lua
local function tooltipArtifactBaseStats(t)
	if IsArtifactId(t.Item.Number) or table.find(ancientWeapons,t.Item.Number) then 
		if t.Type then
			local id=Game.CurrentPlayer
			if id==-1 then
				id=0
			end
			local artifactMult=artifactPowerMult(Party[id].LevelBase, true, t.Item.BonusExpireTime)
			local txt=Game.ItemsTxt[t.Item.Number]
			local ac=math.ceil((txt.Mod2+txt.Mod1DiceCount)*artifactMult)
			if ac>0 then 			
				t.BasicStat= "Armor: +" .. ac
			end
			--WEAPONS
			artifactMult=artifactPowerMult(Party[id].LevelBase, false, t.Item.BonusExpireTime)
			local equipStat=txt.EquipStat
			if equipStat<=2 then
				local bonus=math.ceil(txt.Mod2*artifactMult)
				local sides=math.ceil(txt.Mod1DiceSides*artifactMult)
				t.BasicStat= "Attack: +" .. bonus .. "  " .. "Damage: " ..  txt.Mod1DiceCount .. "d" .. sides .. "+" .. bonus
			end
			local skill=t.Item:T().Skill
			if table.find(twoHandedAxes, t.Item.Number) or table.find(oneHandedAxes, t.Item.Number) then
				skill=3
			end
			if baseRecovery[skill] then
				local pl=Party[0]
				local id=Game.CurrentPlayer
				if id>0 and id<Party.High then
					pl=Party[id]
				end
				local playerLevel=pl.LevelBase
				t.Type = t.Type .. "\nAttack Speed: " .. getItemRecovery(t.Item, playerLevel)/100
			end
		end
	end
end

-- was zzMaw-Items.lua
local function tooltipStatCompare(t)
	--partyLevel=getPartyLevel()
	--maxItemBolster=(partyLevel)/5+20
	--failsafe
	--if Game.freeProgression and t.Item and t.Item.Charges==0 and t.Item.Bonus==0 and t.Item.Bonus2==0 and t.Item.MaxCharges>maxItemBolster then
	--	if not Game.freeProgression then
	--		maxItemBolster=maxItemBolster+10
	--	end
	--	t.Item.MaxCharges=round(partyLevel/5)
	--end
	if t.Description then
		local i=Game.CurrentPlayer
		if i==-1 or i>Party.High then return end
		local equipStat=t.Item:T().EquipStat
		if equipStat<=11 then 
			local pl=Party[i]
			local hp=pl.HP
			local sp=pl.SP
			local maxHP=vars.currentHPPool[i]
			local maxSP=vars.currentManaPool[i]
			local playerIndex=pl:GetIndex()
			local oldDPS1, oldDPS2, oldDPS3, oldVitality=calcPowerVitality(pl)
			--substitute item
			local slot=slotMap[equipStat]
			local itemBackup={}
			local it=pl:GetActiveItem(slot)
			if it then
				--backup item
				itemBackup["BodyLocation"]=it.BodyLocation
				itemBackup["Bonus"]=it.Bonus
				itemBackup["Bonus2"]=it.Bonus2
				itemBackup["BonusExpireTime"]=it.BonusExpireTime
				itemBackup["BonusStrength"]=it.BonusStrength
				itemBackup["Broken"]=it.Broken
				itemBackup["Charges"]=it.Charges
				itemBackup["Condition"]=it.Condition
				itemBackup["Hardened"]=it.Hardened
				itemBackup["Identified"]=it.Identified
				itemBackup["MaxCharges"]=it.MaxCharges
				itemBackup["Number"]=it.Number
				itemBackup["Owner"]=it.Owner
				itemBackup["Refundable"]=it.Refundable
				itemBackup["Stolen"]=it.Stolen
				itemBackup["TemporaryBonus"]=it.TemporaryBonus
				
				--substitute item
				it.BodyLocation=t.Item.BodyLocation
				it.Bonus=t.Item.Bonus
				it.Bonus2=t.Item.Bonus2
				it.BonusExpireTime=t.Item.BonusExpireTime
				it.BonusStrength=t.Item.BonusStrength
				it.Broken=t.Item.Broken
				it.Charges=t.Item.Charges
				it.Condition=t.Item.Condition
				it.Hardened=t.Item.Hardened
				it.Identified=t.Item.Identified
				it.MaxCharges=t.Item.MaxCharges
				it.Number=t.Item.Number
				it.Owner=t.Item.Owner
				it.Refundable=t.Item.Refundable
				it.Stolen=t.Item.Stolen
				it.TemporaryBonus=t.Item.TemporaryBonus
			else
				return
			end
			mawRefresh(playerIndex)
			mawRefresh(playerIndex)
			
			local newDPS1, newDPS2, newDPS3, newVitality=calcPowerVitality(pl)
			local increaseDPSPercent=round(math.max(newDPS1, newDPS2, newDPS3)/math.max(oldDPS1, oldDPS2, oldDPS3)*10000-10000)/100
			local increaseVitalityPercent=round(newVitality/oldVitality*10000-10000)/100
			if increaseDPSPercent<0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(255,0,0,increaseDPSPercent .. "%")
			elseif increaseDPSPercent>0 then
				t.Description = t.Description .. "\n\n" .. "Power: " .. StrColor(0,255,0,"+" .. increaseDPSPercent .. "%")
			end
			if increaseVitalityPercent<0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(255,0,0, increaseVitalityPercent .. "%")
			elseif increaseVitalityPercent>0 then
				t.Description = t.Description .. "\n" .. "Vitality: " .. StrColor(0,255,0,"+" .. increaseVitalityPercent .. "%")
			end
			--restore item
			it.BodyLocation=itemBackup["BodyLocation"]
			it.Bonus=itemBackup["Bonus"]
			it.Bonus2=itemBackup["Bonus2"]
			it.BonusExpireTime=itemBackup["BonusExpireTime"]
			it.BonusStrength=itemBackup["BonusStrength"]
			it.Broken=itemBackup["Broken"]
			it.Charges=itemBackup["Charges"]
			it.Condition=itemBackup["Condition"]
			it.Hardened=itemBackup["Hardened"]
			it.Identified=itemBackup["Identified"]
			it.MaxCharges=itemBackup["MaxCharges"]
			it.Number=itemBackup["Number"]
			it.Owner=itemBackup["Owner"]
			it.Refundable=itemBackup["Refundable"]
			it.Stolen=itemBackup["Stolen"]
			it.TemporaryBonus=itemBackup["TemporaryBonus"]
			mawRefresh(playerIndex)
			mawRefresh(playerIndex)
			--restore hp
			pl.HP=hp
			pl.SP=sp
			if GetLegendaryAffix(t.Item)==32 then
				buffManaLock()
			end
			vars.currentHPPool[i]=maxHP
			vars.currentManaPool[i]=maxSP
		end
	end
end

-- was zzMaw-Items.lua
local function tooltipLevelRequirement(t)
	if IsEnchantableItem(t.Item) then 
		if t.Description then
			
			local levelRequired=GetLevelRquirement(t.Item)
			local txt="\n\nLevel Required: " .. levelRequired 
			local id=Game.CurrentPlayer
			if id<0 or id>Party.High then
				id=0
			end
			local plLvl=Party[id].LevelBase
			if plLvl<levelRequired then
				txt=StrColor(255,0,0,txt)
			end
			if IsCelestialItem(t.Item) then
				txt=StrColor(120, 240, 255,"\n\nCelestial Items cannot be upgraded with crafting Gems or Cubes, but scale with player level, up to level 600.")
				if vars.madnessMode then
					txt=StrColor(120, 240, 255,"\n\nCelestial Items cannot be upgraded with crafting Gems or Cubes, but scale with player level, up to level 1000.")
				end
			end
			t.Description = t.Description .. txt
			
		end	
		
		--attack speed tooltip
		local skill=t.Item:T().Skill
		if table.find(twoHandedAxes, t.Item.Number) or table.find(oneHandedAxes, t.Item.Number) then
			skill=3
		end
		if t.Type and baseRecovery[skill] then
			t.Type = t.Type .. "\nAttack Speed: " .. getItemRecovery(t.Item, 0)/100
		end
	end
end

-- was zzMaw-Items.lua
local function tooltipFireAura(t)
	if t.Item:T().EquipStat==0 or t.Item:T().EquipStat==1 or t.Item:T().EquipStat==2 then 
		if t.Description then
			if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[4] then --fire aura
				if Game.CurrentPlayer>=0 and Game.CurrentPlayer<=Party.High then
					local pl=Party[Game.CurrentPlayer]
					local s, m, level=getBuffSkill(4)
					if m>=1 then
						local name={"Fire","Flame","Inferno","Hell",[0]=""}
						local damage=calcFireAuraDamage(pl, t.Item, 0, false, false, "tooltip")
						if damage then
							local txt=string.format(name[m] .. " Aura: adds " .. damage .. " Fire Damage to any attack\n\n")
							t.Description=StrColor(255,255,153,txt) .. t.Description
						end
					end
				end
			end
			if vars.MAWSETTINGS.buffRework=="ON" and vars.mawbuff[91] then --vampiric aura
				local s, m, level=getBuffSkill(91)
				if m>=1 then
					t.Description=StrColor(255,255,153,"Vampiric Aura: damage done will restore player HP.\n\n") .. t.Description
				end
			end
		end
	end
end

-- was zzMaw-Maps.lua
local function tooltipMapLevel(t)
	local it=t.Item
	if it.Number==290 and t.Enchantment then
		local baseMap=mapLevels[Game.MapStats[it.BonusStrength].Name]
		local baseLevel=round((baseMap.Low+baseMap.Mid+baseMap.High)/3)
		t.Enchantment="Map Level: " .. it.MaxCharges*10+20+baseLevel
		local power=0
		if it.Bonus==0 then
			if it.BonusExpireTime>0 then
				power=power+1
			end
			if it.Bonus2>0 then
				power=power+1
			end
			if it.Charges>0 then
				power=power+1
				if it.Charges>=1000 then
					power=power+1
				end
			end
		else
			power=it.Bonus
		end
		t.Enchantment=t.Enchantment .. StrColor(0, 127, 255,"\n+" .. round((it.MaxCharges*power+power*20)/8*1.5) .. "% craft items drop chances "  .. "\n+" .. round((it.MaxCharges*power+power*20)/4) .. "% item quality " .. "%\n+" .. round((it.MaxCharges*power+power*20)/3) .. "% monster density")	
	end
	if it.Number==290 and t.Name then
		t.Name=Game.MapStats[it.BonusStrength].Name .. " Map"
	end
	
	if it.Number==290 and t.Description then
		local power=it.MaxCharges
		local mapAffixes={
			[0]="",
			[1]="Monsters deal " .. getMapAffixPower(1, power) .. "% increased damage",
			[2]="Monsters have " .. getMapAffixPower(2, power) .. "% critical chance",
			[3]="Monsters have " .. getMapAffixPower(3, power) .. "% chance to cast fireball",
			[4]="Monsters have " .. getMapAffixPower(4, power) .. "% chance to cast dragon breath",
			[5]="Monsters reflect " .. getMapAffixPower(5, power) .. "% of physical damage",
			[6]="Monsters reflect " .. getMapAffixPower(6, power) .. "% of magic damage",
			[7]="Monsters regenerate " .. getMapAffixPower(7, power) .. "%HP per second",
			[8]="Monsters have " .. getMapAffixPower(8, power) .. "% chance to ignore status resistance",
			[9]="Monsters have " .. getMapAffixPower(9, power) .. "% chance to summon a monster upon death",
			[10]="Monsters deal " .. getMapAffixPower(10, power) .. "% of player hp as damage",
			[11]="Monsters have " .. getMapAffixPower(11, power) .. "% increased movement speed",
			[12]="Monsters resistances are increased by " .. getMapAffixPower(12, power),
			[13]="Monsters have " .. getMapAffixPower(13, power) .. "% extra chance to resist control effects",
			[14]="Monsters have " .. getMapAffixPower(14, power) .. "% chance to deal energy damage",
			[15]="Monsters have " .. getMapAffixPower(15, power) .. "% increased HP",
			[16]="Boss density increased by " .. getMapAffixPower(16, power) .. "%",
			[17]="Monsters have " .. getMapAffixPower(17, power) .. "% be an higher tier",
			[18]="Bosses have " .. getMapAffixPower(18, power) .. "% increased HP and damage",
			[19]="Monsters have " .. getMapAffixPower(19, power) .. "% chance to become a boss",
			[20]="Players critical chance reduced by " .. getMapAffixPower(20, power) .. "%",
			[21]="Players critical damage reduced by " .. getMapAffixPower(21, power) .. "%",
			[22]="Players HP/SP regen reduced by " .. getMapAffixPower(22, power) .. "%",
			[23]="Players physical damage reduced by " .. getMapAffixPower(23, power) .. "%",
			[24]="Players magic damage reduced by " .. getMapAffixPower(24, power) .. "%",
			[25]="Players movement speed reduced by " .. getMapAffixPower(25, power) .. "%",
			[26]="Players attack speed reduced by " .. getMapAffixPower(26, power) .. "%",
			[27]="Players spell recovery speed increased by " .. getMapAffixPower(27, power) .. "%",
			[28]="Players armor reduced by " .. getMapAffixPower(28, power) .. "%",
			[29]="Players resistances reduced by " .. getMapAffixPower(29, power) .. "%",
			[30]="Players have a " .. getMapAffixPower(30, power) .. "% chance to miss attacks",
			[31]="Healing reduced by " .. getMapAffixPower(31, power) .. "%",
			[32]="Leech reduced by " .. getMapAffixPower(32, power) .. "%",
			[33]="Buff effects reduced by " .. getMapAffixPower(33, power) .. "%",
		}
		
		local txt=""
		local bonus=it.Bonus
		if bonus==0 then
			bonus=4
		end
		if it.Charges>0 then
			if it.Charges>=1000 then
				if bonus>=4 then
					txt=StrColor(255,255,153,"- " .. mapAffixes[math.floor(it.Charges/1000)]) .. "\n\n" .. txt
				else
					txt=StrColor(100,100,100,"- " .. mapAffixes[math.floor(it.Charges/1000)]) .. "\n\n" .. txt
				end
			end
			if it.Charges%1000>0 then
				if bonus>=3 then
					txt=StrColor(255,255,153,"- " .. mapAffixes[it.Charges%1000]) .. "\n\n" .. txt
				else
					txt=StrColor(100,100,100,"- " .. mapAffixes[it.Charges%1000]) .. "\n\n" .. txt
				end
			end
		end
		if it.Bonus2>0 then
			if bonus>=2 then
				txt=StrColor(255,255,153,"- " .. mapAffixes[it.Bonus2]) .. "\n\n" .. txt
			else
				txt=StrColor(100,100,100,"- " .. mapAffixes[it.Bonus2]) .. "\n\n" .. txt
			end
		end
		if it.BonusExpireTime>0 then
			txt=StrColor(255,255,153,"- " .. mapAffixes[it.BonusExpireTime]) .. "\n\n" .. txt
		end
		t.Description="\n" .. txt .. "Creator's Hourglass and Eye of the void can be used to unlock new affixes, Pandora's Cube to change the Map and emerald of power to increase the map Level.\nUsing this map will teleport you to the entrance."
	end
end

-- was zzMaw-MultiBag.lua, removes bag buttons
local function tooltipMultibagButtons(t)
	for i=1,5 do
		multibagButton[i].Active=false
		RunNextTick(function()
			multibagButton[i].Active=true
		end)
	end
end

-- was zzMaw-Spells.lua
local mastery={"Novice","Expert","Master","Grandmaster"}
local function tooltipSkillBooks(t)
	local it=t.Item
	if it.Number>=971 and it.Number<980 then
		local identify=Game.ItemsTxt[it.BonusStrength].IdRepSt
		local m=1
		if identify>=15 then
			m=4
		elseif identify>=10 then
			m=3
		elseif identify>=5 then
			m=2
		end
		local id=Game.CurrentPlayer
		if id<0 or id>Party.High then return end
		local pl=Party[Game.CurrentPlayer]
		local s2,m2=SplitSkill(pl.Skills[t.Item.Number-959])
		if m2>=m then
			it.Number=it.BonusStrength
		end
		if t.Description then
			local name=Skillz.getName(t.Item.Number-959)
			t.Description=t.Description .. StrColor(255,0,0, "\n\nYou need at least " .. mastery[m] .. " skill in " ..  name .. " to open the book")
		end
	end
end

Tooltip.addSection("alchemy-potions", 100, tooltipPotions)
Tooltip.addSection("alchemy-reagent-power", 110, tooltipReagentPower)
Tooltip.addSection("alchemy-orbs-gems", 120, tooltipOrbsGems)
Tooltip.addSection("alchemy-craft-with-held-item", 130, tooltipCraftWithHeldItem)
Tooltip.addSection("items-enchant-stats", 200, tooltipEnchantStats)
Tooltip.addSection("items-artifact-scaling", 210, tooltipArtifactScaling)
Tooltip.addSection("items-artifact-base-stats", 220, tooltipArtifactBaseStats)
Tooltip.addSection("items-stat-compare", 230, tooltipStatCompare)
Tooltip.addSection("items-level-requirement", 240, tooltipLevelRequirement)
Tooltip.addSection("items-fire-aura", 250, tooltipFireAura)
Tooltip.addSection("maps-map-level", 300, tooltipMapLevel)
Tooltip.addSection("multibag-buttons", 310, tooltipMultibagButtons)
Tooltip.addSection("spells-skill-books", 320, tooltipSkillBooks)