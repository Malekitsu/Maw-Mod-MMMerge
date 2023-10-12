----------------------------------------------------------------------
--SERAPHIM
----------------------------------------------------------------------
--body magic will increase healing done on attack
--bunch of code for healing most injured player
function indexof(table, value)
	for i, v in ipairs(table) do
			if v == value then
				return i
			end
		end
	return nil
end
		
function events.CalcDamageToMonster(t)
	local data = WhoHitMonster()
		if data and data.Player and (data.Player.Class==55 or data.Player.Class==54 or data.Player.Class==53) and t.DamageKind==4 and data.Object==nil then
		--get body
		body=data.Player:GetSkill(const.Skills.Body)
		bodyS,bodyM=SplitSkill(body)

		--get spirit
		spirit=data.Player:GetSkill(const.Skills.Spirit)
		spiritS,spiritM=SplitSkill(spirit)
		
		
		
		-- Define the variables
		a={}
		a[0]=2
		a[1]=2
		a[2]=2
		a[3]=2
		a[4]=2
		for i=0,Party.High do
			if Party[i].Dead==0 and Party[i].Eradicated==0 then
				a[i] = Party[i].HP/Party[i]:GetFullHP()
			end
		end
		a, b, c, d, e= a[0], a[1], a[2], a[3], a[4] 
		-- Find the maximum value and its position
		min_value = math.min(a, b, c, d, e)
		min_index = indexof({a, b, c, d, e}, min_value)
		min_index = min_index - 1
		--Calculate heal value and apply
		levelBonus=2+math.min(t.Player.LevelBase,250)/50
		healValue=bodyS*levelBonus+spiritS*levelBonus
		personality=data.Player:GetPersonality()
		healValue=healValue*(1+personality/1000)
		--calculate crit
		critchance=data.Player:GetLuck()/15*10+50
		roll=math.random(1,1000)
		if roll<critchance then
			healValue=healValue*(1.5+personality*3/2000)
		end
		--apply heal
		evt[min_index].Add("HP",healValue)		
		--bug fix
		if Party[min_index].HP>0 then
		Party[min_index].Unconscious=0
		end
	end
		
end

--mind light increases melee damage

function events.CalcStatBonusBySkills(t)
	if t.Stat==const.Stats.MeleeDamageBase then
		if t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53 then
			light=t.Player.Skills[const.Skills.Light]
			lightS,lightM=SplitSkill(light)
			--get mind
			mind=t.Player.Skills[const.Skills.Mind]
			mindS,mindM=SplitSkill(mind)
			levelBonus=2+math.min(t.Player.LevelBase,250)/100
			damage=mindS*levelBonus + lightS*levelBonus
			t.Result=t.Result+damage
		end
	end
end

--AUTORESS SKILL

function events.LoadMap(wasInGame)
	vars.divineProtectionCooldown=vars.divineProtectionCooldown or {}
	for i=0,Party.High do
		local index=Party[i]:GetIndex()
		vars.divineProtectionCooldown[index]=vars.divineProtectionCooldown[index] or 0
	end
end

function events.CalcDamageToPlayer(t)

--divine protection
	if (t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53) and t.Player.Unconscious==0 and t.Player.Dead==0 and t.Player.Eradicated==0 then
		if vars.divineProtectionCooldown[t.PlayerIndex]==nil then
			vars.divineProtectionCooldown[t.PlayerIndex]=0
		end		
		if t.Result>=t.Player.HP and Game.Time>vars.divineProtectionCooldown[t.PlayerIndex] then
			totMana=t.Player:GetFullSP()
			currentMana=t.Player.SP
			treshold=totMana/4
			if currentMana>=treshold then
				t.Player.SP=t.Player.SP-(totMana/4)
				--calculate healing
				mastery=SplitSkill(t.Player.Skills[const.Skills.Thievery])
				heal=totMana
				for i=0,Party.High do
					if Party[i]:GetIndex()==t.PlayerIndex then
						evt[i].Add("HP",heal)
					end
				end
				vars.divineProtectionCooldown[t.PlayerIndex] = Game.Time + const.Minute * 150
				Game.ShowStatusText("Divine Protection saves you from lethal damage")
				t.Result=math.min(t.Result, t.Player.HP-1)
			end
		end	
	end
end


---deactivate offhand weapon
function events.CalcDamageToMonster(t)
	if (t.Player.Class==55 or t.Player.Class==54 or t.Player.Class==53) then
		data=WhoHitMonster()
		if data and data.Player then
			item=data.Player:GetActiveItem(0)
		end
		if item~=nil then
			if item:T().Skill==1 then
				t.Result=0
				Message("Seraphim aren't able to dual wield")
			end
		end
	end
end
