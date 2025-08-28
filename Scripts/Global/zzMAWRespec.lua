local npcID = {314, 413, 794}

function MakeRespecDude(npcID)
  QuestNPC = npcID
  Greeting{
    NPC = npcID,
    Text = "If you seek to pursuit a new path and reset your skills, you have come to the right place."
  }
  
  Quest{
	  Slot = 3,
	  Ungive = function(t) changeToRespec(npcID) end,
      Texts = {
          Topic = "Skill reset info",
          Ungive = "By agreeing to this, every skill you possess shall be returned to the beginning, to the level of a Novice, and all the points you've invested in these skills shall be returned to you. \n\nOnce your skill grows to the necessary level, mastery of it shall be bestowed upon you once more, should you have achieved it before.\n\nFor this service, a tribute of 1000 gold for each level you have achieved shall be required"  
	  }
  }


end


function changeToRespec(npcID)
  QuestNPC = npcID
  Quest{
  	  Slot = 3,
      Ungive = function(t) RespecSkills(npcID) end,
      Texts = {
          Topic = "I want to reset",
          Ungive = [[Your skill points has been reset!]],
      }
  }
end

function events.LoadMap() 
	for i=1,#npcID do
		MakeRespecDude(npcID[i])
	end
end

function RespecSkills(npcID)
	MakeRespecDude(npcID)
	local id=Game.CurrentPlayer
	if id<0 then return end
	local goldRequired=Party[id].LevelBase*1000
	if Party.Gold<goldRequired then
		Message("Not enough gold.")
		return
	else
		Party.Gold=Party.Gold-goldRequired
		if vars.AusterityMode then
			Party[0].Skills[const.Skills.IdentifyMonster] = JoinSkill(0, const.GM)
			Party[1].Skills[const.Skills.IdentifyMonster] = JoinSkill(0, const.GM)
			Party[2].Skills[const.Skills.IdentifyMonster] = JoinSkill(0, const.GM)
			Party[3].Skills[const.Skills.IdentifyMonster] = JoinSkill(0, const.GM)
			Party[4].Skills[const.Skills.IdentifyMonster] = JoinSkill(0, const.GM)
		end
	end
	respecMastery(id)
	local refund=0
	local spentOnAlchemy=0
	local p=Party[id]
	
	local shared=sharedSkills
	if table.find(shamanClass, p.Class) or table.find(seraphClass, p.Class) or table.find(dkClass, p.Class) or table.find(assassinClass, pl.Class) then
		shared={12,13,14,15,16,17,18,19,20,21,22}
	end
	for i=0, p.Skills.High do
		local skill=SplitSkill(p.Skills[i])
		if skill>1 and i~=const.Skills.Alchemy then
			if table.find(shared, i) then
				local lastSkill=2
				--reset mastery
				for j=1,#shared do
					p.Skills[shared[j]]=SplitSkill(p.Skills[shared[j]])
				end	
				while lastSkill>1 do
					maxSkill=0
					count=1	
					for v=1,#shared do
						if p.Skills[shared[v]]>maxSkill then
							maxSkill = p.Skills[shared[v]]
							maxIndex=shared[v]
							count=1
						elseif p.Skills[shared[v]]==maxSkill then
							count=count+1
						end
					end
					lastSkill=maxSkill
					refund=math.ceil(maxSkill/count)
					if lastSkill>1 then
						p.SkillPoints=p.SkillPoints+refund
						p.Skills[maxIndex]=p.Skills[maxIndex]-1
					end
				end
			else
				refund=skill*(skill+1)/2-1
				--reset to 1 and reset skill points
				if p.Skills[i]>0 then
					p.Skills[i]=1
				end
				p.SkillPoints=p.SkillPoints+refund
			end
		end
		if i == const.Skills.Alchemy and skill > 1 then
			spentOnAlchemy = skill*(skill+1)/2-1
		end
	end
	--custom skills
	for i=50,53 do
	local s=SplitSkill(Skillz.get(p,i))
		p.SkillPoints=p.SkillPoints+ math.max(s*(s+1)/2-1,0)
		if s>0 then
			Skillz.set(p,i,1)
		end
	end
	
	-- retroactive fix for mercs
	local shouldBeRefundedAmount = 0 - spentOnAlchemy
	for i=2, p.LevelBase do
		shouldBeRefundedAmount = shouldBeRefundedAmount + 4 + math.floor(i/10+1)
	end
	if p.SkillPoints < shouldBeRefundedAmount then
		p.SkillPoints = shouldBeRefundedAmount
	end
	Message("Your skill points has been reset!")
end

function respecMastery(id)
	local index=Party[id]:GetIndex()
	vars.oldPlayerMasteries=vars.oldPlayerMasteries or {}
	vars.oldPlayerMasteries[index]=vars.oldPlayerMasteries[index] or {}
	local p=Party[id]
	for i=0, p.Skills.High do
		local s, m = SplitSkill(p.Skills[i])
		vars.oldPlayerMasteries[index][i]=vars.oldPlayerMasteries[index][i] or 0
		vars.oldPlayerMasteries[index][i]=math.max(vars.oldPlayerMasteries[index][i], m)
	end
end
