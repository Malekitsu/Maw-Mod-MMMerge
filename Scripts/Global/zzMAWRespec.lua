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
	end
	respecMastery(id)
	local refund=0
	local p=Party[id]
	for i=0, p.Skills.High do
		local skill=SplitSkill(p.Skills[i])
		if skill>1 then
			if i>=12 and i<=23 then
				local lastSkill=2
				--reset mastery
				for i=12,20 do
					p.Skills[i]=SplitSkill(p.Skills[i])
				end	
				while lastSkill>1 do
					maxSkill=0
					count=1	
					for v=12,20 do
						if p.Skills[v]>maxSkill then
							maxSkill = p.Skills[v]
							maxIndex=v
							count=1
						elseif p.Skills[v]==maxSkill then
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
	end
	--custom skills
	local s=SplitSkill(Skillz.get(p,50))
	p.SkillPoints=p.SkillPoints+ math.max(s*(s+1)/2-1,0)
	Skillz.set(p,50,1)
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
