
	--0x4608c0
	local NewCode

	-- Change main menu soundtrack.
	mem.IgnoreProtection(true)
	mem.u1[0x46103c] = 16
	mem.u1[0x4bd38d] = 16
	mem.IgnoreProtection(false)

	-- Override water settings from mm8.ini
	Game.PatchOptions.HDWTRCount = 14
	Game.PatchOptions.HDWTRDelay = 15

	-- 0x4b067b - increase amount of house sound sets
	mem.asmpatch(0x4b067d, "add eax, 0xbb8")
	mem.asmpatch(0x4b0683, "imul eax, eax, 0xa")

	-- Other kinds of sounds:
	mem.asmpatch(0x4a9b23, "movzx eax, word [ds:edi+0x4c]")

	-- Disable standart lich-transformation by evt.Set{"ClassIs", X}
	-- Use Party[Y].Face = Z, and SetCharFace(Y, Z) instead.
	-- Y - char id in party, Z - portrait id form "Character portraits.txt".

	mem.asmpatch(0x447dba, "jmp 0x447def - 0x447dba")

	-- Disable mind and soul immunity setting after lich-transformation, use
	--		Party[X].Resistances[7].Base = 65000
	--		Party[X].Resistances[8].Base = 65000

	mem.asmpatch(0x447d9b, "jmp absolute 0x447dad")
	mem.asmpatch(0x447d43, "jmp absolute 0x4482eb")

	-- Fix crown of final dominion (Remove unstackable "Of Dark" bonus)
	mem.asmpatch(0x48e7b7, "jmp absolute 0x48ec2d")
	-- Eclipse
	mem.asmpatch(0x48e73f, "jmp absolute 0x48ec2d")
	-- Staff of elements
	mem.asmpatch(0x48e86c, "jmp absolute 0x48e890")
	-- Ring of fusion
	mem.asmpatch(0x48e8f3, "jmp absolute 0x48e8fc")

	-- Workaround for crash caused by exceed amount of loaded icons (>1000)
	-- Draw pending icon for items, which's icons could not be loaded.
	-- Need to find proper solution for this case.
	mem.asmpatch(0x410e06, "jmp absolute 0x410ec8")
	mem.asmpatch(0x410d76, [[
	xor eax, eax
	cmp dword [ds:ecx+0x11B7C], 0x3e7
	jge absolute 0x410ed1
	xor edi, edi
	cmp dword [ss:ebp+8], edi]])

	-- Reduce traveling cost from arena to four days and zero food.
	mem.asmpatch(0x446ee6, "push 0x0")
	mem.asmpatch(0x446f3c, "push 0x0")
	mem.nop(0x446f07, 3)

	-- Fix jumping on nonflat structures in outdoor maps.
	mem.asmpatch(0x47312d, [[
	cmp dword [ss:ebp-0x5c], ecx
	je @end

	mov eax, dword [ds:0xb7ca88]
	bt eax, 3
	jc @bad

	cmp dword [0xB21588], 100  ; max upward speed
	jg @bad
	cmp dword [0xB21588], -100  ; max downward speed
	jnl @end

	@bad:
	jmp absolute 0x47316c

	@end:
	]])

	-- fix flickering during crossing portals in indoor maps
	-- Use party Z instead of camera Z, when checking portals:
	mem.asmpatch(0x4af29c, "mov edx, dword [ds:0xB2155C]")
	-- Increase offset for MinX, MaxX, MinY, MaxY, MinZ
	mem.asmpatch(0x4af257, "push 0x7f")
	-- Increase offset for MaxZ
	mem.asmpatch(0x4af2ae, "add edi, 0x7f")

	-- Fix monsters flickering in indoor maps.
	function events.LoadMap()

		if not Map.IsIndoor() then
			return
		end

		local function fix(strData, strRoomData)
			local tData = mapvars[strData]
			if tData and type(tData) == "table" then
				for RoomId,Room in pairs(tData) do
					local RoomData = Map.Rooms[RoomId][strRoomData]
					for i,v in RoomData do
						RoomData[i] = -1
					end
					local count = 0
					for i,DataId in pairs(Room) do
						RoomData[i] = DataId
						count = count + 1
					end
					RoomData.count = count
				end
			else
				local cRoomId
				mapvars[strData] = {}
				for RoomId,Room in Map.Rooms do
					for i,DataId in Room[strRoomData] do
						cRoomId = Map.RoomFromPoint(Map[strRoomData][DataId])
						if cRoomId ~= RoomId and cRoomId ~= 0 then
							Room[strRoomData][i] = -1
						end
					end

					mapvars[strData][RoomId] = {}
					local RoomFix = mapvars[strData][RoomId]
					local pos = 0
					for i,v in Room[strRoomData] do
						if v >= 0 then
							RoomFix[pos] = v
							Room[strRoomData][pos] = v
							pos = pos + 1
						end
					end
					Room[strRoomData].count = pos
				end
			end
		end

		fix("RoomSpritesFix", "Sprites")
		fix("RoomLightsFix", "Lights")

		-- fix portals Z bounds
		local F
		for RoomId, Room in Map.Rooms do
			for _, FId in Room.Portals do
				F = Map.Facets[FId]
				F.MinZ = Room.MinZ
				F.MaxZ = Room.MaxZ
			end
		end

	end

	-- Fix evt.Question (was not supposed to be called outside houses in mm8, now it should)
	mem.asmpatch(0x4d9e95, [[
	test ecx, ecx
	je absolute 0x4d9f08
	test ecx, 3]])

	mem.asmpatch(0x44203a, [[
	mov dword [ds:ebp-0x8], eax
	cmp dword [ds:0x4f37d8], 0xd
	je absolute 0x44210a
	jmp absolute 0x44204a]])

	-- Don't show final cutscene, don't change map, just print image (cutscene can be shown by evt.ShowMovie)
	mem.asmpatch(0x4bd454, "push 4")
	mem.asmpatch(0x4bd88b, "jmp 0x4bd8c4 - 0x4bd88b")
	Game.PrintEndCard = function(Text, BackImg)
		if Text then
			Game.GlobalTxt[676] = Text
		end
		if BackImg then
			mem.copy(0x5014e0, BackImg, 11)
		end
		mem.call(0x4bd3e1)
	end

	-- Fix Day of the Gods, Deadly Swarm and Flying Fist spell selection for monsters.
	-- Note: if string variables are declared as local, only the last one will contain
	--   proper characters.
	DayGods, DeadlySwarm, FlyingFist = "Day-o-Gods", "Deadly", "Flying"
	mem.asmpatch(0x4524B3, [[
	jnz short @daygods
	push 0x44
	jmp absolute 0x4520EB
	@daygods:
	push ]] .. mem.topointer(DayGods) .. [[;
	push dword ptr [edi+4]
	call absolute 0x4DA920
	test eax, eax
	pop ecx
	pop ecx
	jnz @swarm
	push 0x53
	jmp absolute 0x4520EB
	@swarm:
	push ]] .. mem.topointer(DeadlySwarm) .. [[;
	push dword ptr [edi+4]
	call absolute 0x4DA920
	test eax, eax
	pop ecx
	pop ecx
	jnz @fist
	push 0x25
	jmp absolute 0x452485
	@fist:
	push ]] .. mem.topointer(FlyingFist) .. [[;
	push dword ptr [edi+4]
	call absolute 0x4DA920
	test eax, eax
	pop ecx
	pop ecx
	jnz absolute 0x4524BC
	push 0x4C
	jmp absolute 0x452485
	]])

	-- Show correct transition texts for mm6/7 maps.
	local TransTexts = {
	["7d18.blv"] = 9,
	["7d14.blv"] = 398,
	["d01.blv"] = 392,
	["7d16.blv"] = 412,
	["zddb01.blv"] = 22,
	["oracle.blv"] = 166,
	["sci-fi.blv"] = 451,
	["7d15.blv"] = 397,
	["d43.blv"] = 806,
	["d44.blv"] = 815,
	["d45.blv"] = 825,
	["d46.blv"] = 835,
	["d48.blv"] = 845,
	["d49.blv"] = 854,
	["mdt09.blv"] = 8,
	["mdt10.blv"] = 15,

	-- The Bandit Caves
	["mdt14.blv"] = 10,

	-- The Haunted Mansion
	["7d37.blv"] = 11,

	-- barrows
	["mdk01.blv"] = 12,
	["mdk02.blv"] = 12,
	["mdk03.blv"] = 12,
	["mdk04.blv"] = 12,
	["mdk05.blv"] = 12,
	["mdt01.blv"] = 12,
	["mdt02.blv"] = 12,
	["mdt03.blv"] = 12,
	["mdt04.blv"] = 12,
	["mdt05.blv"] = 12,
	["mdr01.blv"] = 12,
	["mdr02.blv"] = 12,
	["mdr03.blv"] = 12,
	["mdr04.blv"] = 12,
	["mdr05.blv"] = 12,

	}

	function events.GetTransitionText(t)
		local TextId = TransTexts[t.EnterMap]
		if TextId then
			t.TransId = TextId
		end
	end

	-- set const.Race
	const.Race = {
		Human 	 = 0,
		Vampire	 = 1,
		DarkElf	 = 2,
		Minotaur = 3,
		Troll	 = 4,
		Dragon	 = 5,
		Undead	 = 6,
		Elf		 = 7,
		Goblin	 = 8,
		Dwarf	 = 9,
		Zombie	 = 10
	}

	-- correct const.Class
	const.Class = {
		Archer			=	0,
		WarriorMage		=	1,
		MasterArcher	=	2,
		Sniper			=	3,
		Cleric			=	4,
		Priest			=	5,
		PriestLight		=	6,
		PriestDark		=	7,
		DarkElf			=	8,
		Patriarch		=	9,
		Dragon			=	10,
		GreatWyrm		=	11,
		Druid			=	12,
		GreatDruid		=	13,
		Warlock			=	14,
		ArchDruid		=	15,
		Knight			=	16,
		Cavalier		=	17,
		BlackKnight		=	18,
		Champion		=	19,
		Minotaur		=	20,
		MinotaurLord	=	21,
		Monk			=	22,
		Initiate		=	23,
		Master			=	24,
		Ninja			=	25,
		Paladin			=	26,
		Crusader		=	27,
		Hero			=	28,
		Villain			=	29,
		Ranger			=	30,
		Hunter			=	31,
		BountyHunter	=	32,
		RangerLord		=	33,
		Thief			=	34,
		Rogue			=	35,
		Assassin		=	36,
		Spy				=	37,
		Troll			=	38,
		WarTroll		=	39,
		Vampire			=	40,
		Nosferatu		=	41,
		Sorcerer		=	42,
		Wizard			=	43,
		Necromancer		=	44,
		Lich			=	45,
		ArchMage		=	46,
		nuAM			=	47,
		Peasant			=	48,
		nuPeas			=	49,
		HighPriest		=	50,
		MasterWizard	=	51,

	}

	-- Roster.txt processing
	mem.nop(0x494a67, 3)
	mem.hook(0x494a6a, function(d)

		local ClassConns = {

			necromancer  = 44,
			necromancer2 = 45,
			cleric 		 = 4,
			cleric2		 = 6,
			knight 		 = 16,
			knight2		 = 19,
			troll 		 = 38,
			troll2 		 = 39,
			minotaur 	 = 20,
			minotaur2 	 = 21,
			darkelf 	 = 8,
			darkelf2 	 = 9,
			vampire 	 = 40,
			vampire2 	 = 41,
			dragon 		 = 10,
			dragon2		 = 11
		} -- Use class indexes for rest.

		d.ecx = mem.u4[d.eax+8]
		local CurClassName = mem.string(d.ecx)
		d.eax = tonumber(CurClassName) or ClassConns[CurClassName] or const.Class[CurClassName] or 16

	end)

	-- Use Game.NPCNames during player selection to avoid screwing with names by gender.
	mem.hook(0x48e0f0, function(d)
		local NamesTable = Game.NPCNames[Game.CharacterPortraits[Party[0].Face].DefSex == 0 and "M" or "F"]
		Party[0].Name = NamesTable[math.random(1, #NamesTable)]
	end)

	-- negative value of FacetId leads to use facet itself instead of facet group.
	-- evt.SetFacetBit correction.
	mem.autohook(0x445d05, function(d)
		if Map.IsOutdoor() or d.ecx >= 0 or -d.ecx > Map.Facets.count -1 then return end
		d.ecx = math.abs(d.ecx)
		for k, v in pairs(const.FacetBits) do
			if v == d.edx then
				Map.Facets[d.ecx][k] = mem.u4[d.esp+4] == 1
				d.ecx = 0
			end
		end
	end)

	-- evt.SetTexture correction.
	mem.autohook(0x44597e, function(d)
		if d.ecx >= 0 then return end
		d.ecx = math.abs(d.ecx)
		local CurBitmap = mem.string(d.edx)
		local Facet = Map.Facets[d.ecx]
		if Facet.AnimatedTFT then
			for i,v in Game.TFTBin do
				if v.Name == CurBitmap then
					for a = i, i+255 do
						local TFT = Game.TFTBin[a]
						CurBitmap = TFT.Name
						CurBitmap = Game.BitmapsLod:LoadBitmap(CurBitmap)
						Game.BitmapsLod.Bitmaps[CurBitmap]:LoadBitmapPalette()
						TFT.Index = CurBitmap
						if not TFT.NotGroupEnd then
							break
						end
					end
					Facet.BitmapId = i
					break
				end
			end
		else
			CurBitmap = Game.BitmapsLod:LoadBitmap(CurBitmap)
			Game.BitmapsLod.Bitmaps[CurBitmap]:LoadBitmapPalette()
			Facet.BitmapId = CurBitmap
		end
		d.ecx = 0
	end)

	-- evt.SetSprite correction.
	mem.autohook(0x445bd2, function(d) --0x445bd2, 0x445bee
		if d.ecx >= 0  then return end
		d.ecx = math.abs(d.ecx)
		local DecName = mem.string(mem.u4[d.esp+4])
		Map.Sprites[d.ecx].Invisible = d.edx == 0
		if DecName ~= "0" then
			Map.Sprites[d.ecx].DecName = DecName
		end
	end)

	-- evt.SetLight correction.
	mem.autohook(0x445c9a, function(d)
		if d.ecx >= 0 then
			return
		end
		d.ecx = math.abs(d.ecx)
		Map.Lights[d.ecx].Off = d.edx == 0
		d.ecx = -1
	end)

	-- fixed in MMPatch 2.5
	-- Trigger "LeaveMap" event during traveling by boats/stables.
	--mem.autohook2(0x4b516b, function(d) -- 0x4bab72
	--	if Party.Gold >= d.ecx then
	--		internal.OnLeaveMap()
	--	end
	--end)

	-- Need to inspect this, sometimes gives crahes at spacebar action:
	mem.asmpatch(0x4685d9, [[
	movsx ecx, word [ds:ecx+0x6b1458]
	cmp ecx, 0x7fff
	jnz @end
	xor ecx, ecx
	@end:
	]])

	-- Need to inspect this, fix for ghost items in Party[*].Inventory array.
	mem.asmpatch(0x43c0f7, [[
	je absolute 0x43c105
	cmp eax, 138; limit of items in player's inventory
	jle @end
	mov dword [ds:esi], 0; erase wrong index
	jmp absolute 0x43c105
	@end:
	lea eax, [eax*8+eax];]])

	-- Need to inspect this: division by zero
	mem.asmpatch(0x4ad557, [[
	jg absolute 0x4ad5f0
	test ecx, ecx
	je absolute 0x4ad5f0;]])

	-- Need to inspect this, crashes in mm6 dungeons
	-- (something with facet lighting by objects)
	mem.asmpatch(0x408987, [[
	test esi, esi
	jl absolute 0x408b1a
	add esi, dword [ds:0x6F3C84];]])
	mem.asmpatch(0x408ca8, [[
	test esi, esi
	jl absolute 0x408e3b
	add esi, dword [ds:0x6F3C84];]])

	--mem.asmpatch(0x41a38a, [[
	--je absolute 0x41a4f1
	--cmp eax, dword [ds:0x454085];
	--jg absolute 0x41a4f1]])

	-- Reduce party move speed in TB mode, and reduce time for move taken to compensate
	do
		local mul = 5
		local old = 0x1a
		local factor = mul / old
		local BakSpeedModifiers = {}

		local function ToggleTBSpeed(state)
			if state then
				for i = 0, 1 do
					BakSpeedModifiers[i] = BakSpeedModifiers[i] or Game.SpeedModifiers[i]
					Game.SpeedModifiers[i] = factor
				end
			else
				for i, v in pairs(BakSpeedModifiers) do
					Game.SpeedModifiers[i] = v
				end
				table.clear(BakSpeedModifiers)
			end
		end

		local patch = "sub dword [ds:0x509cac], " .. mul
		for _, p in pairs{0x42E675, 0x42E6CB, 0x42EBD6, 0x42EC07} do
			mem.asmpatch(p, patch)
		end

		function events.TurnBasedStarted()
			ToggleTBSpeed(true)
		end

		function events.TurnBasedStopped()
			ToggleTBSpeed(false)
		end

		function events.LoadMapScripts()
			if not Game.TurnBased then
				for i = 0, 1 do
					Game.SpeedModifiers[i] = 1
				end
			end
		end
	end

	-- Prevent looting of items too far away from party.
	local function GetDist(x,y,z)
		local px, py, pz  = XYZ(Party)
		return math.sqrt((px-x)^2 + (py-y)^2 + (pz-z)^2)
	end

	mem.autohook2(0x468514, function(d)
		local obj = Mouse:GetTarget()
		if d.edx ~= obj.Index or (obj.Kind == 2 and GetDist(XYZ(Map.Objects[obj.Index])) > 500) then
			d:push(0x4686a5)
			return true
		end
	end)

	-- Remove artifacts found limit
	function events.LoadMap(WasInGame)
		if not WasInGame then
			for i,v in Party.ArtifactsFound do
				Party.ArtifactsFound[i] = false
				break
			end
		end
	end
	mem.nop(0x44dd82, 7)
	mem.nop(0x4541b4, 7)

	-- Fix GM staff usage with Unarmed skill (Damage bonus).
	local UNARMED = const.Skills.Unarmed
	function events.CalcStatBonusBySkills(t)
		if (t.Stat ~= const.Stats.MeleeDamageBase
			and t.Stat ~= const.Stats.MeleeDamageMin
			and t.Stat ~= const.Stats.MeleeDamageMax
			or t.Player.ItemMainHand == 0
			or t.Player.Skills[UNARMED] == 0)
		then
			return
		end

		local Item = t.Player.Items[t.Player.ItemMainHand]
		local ItemSkill = Game.ItemsTxt[Item.Number].Skill
		if Item.Broken or ItemSkill ~= 0 then return end

		local US, UM = SplitSkill(t.Player:GetSkill(UNARMED))
		local SS, SM = SplitSkill(t.Player:GetSkill(const.Skills.Staff))
		if UM < 2 or SM < 3 then return end

		local u_bonus = US
		if UM > 2 then
			u_bonus = US * 2
		end
		if u_bonus > SS then
			t.Result = t.Result + u_bonus - SS
		end
	end

	-- Repair unarmed skill dodge chance
	function events.GetArmorClass(t)
		local Skill, Mas = SplitSkill(t.Player:GetSkill(UNARMED))
		if Mas == 4 and math.random(1,100) < Skill then
			t.AC = 10000
		end
	end

	-- Fix Dragon's AC and Dmg bonuses by skill
	mem.IgnoreProtection(true)
	mem.u1[0x48cc04 + 1] = const.Class.Dragon
	mem.u1[0x48cc09 + 1] = const.Class.GreatWyrm

	mem.u1[0x48cca1 + 1] = const.Class.Dragon
	mem.u1[0x48cca6 + 1] = const.Class.GreatWyrm

	mem.u1[0x48e2e5 + 1] = const.Class.Dragon
	mem.u1[0x48e2e9 + 1] = const.Class.GreatWyrm
	mem.IgnoreProtection(false)

	function events.CalcStatBonusBySkills(t)
		if t.Stat == const.Stats.MeleeAttack
			or t.Stat == const.Stats.MeleeDamageBase then

			local mas, skill = SplitSkill(t.Player:GetSkill(const.Skills.DragonAbility))
			t.Result = t.Result + skill*mas
		end
	end

	-- Make zombie/lich dragon breath white projectile
	function events.DragonBreathProjectile(t)
		local PL = Party.PlayersArray[t.PlayerIndex]
		if PL.Face == 68 then
			t.ObjId = 8000
		end
	end

	-- Make regeneration skill and spell mm7-alike
	function events.RegenTick(Player)
		local Cond = Player:GetMainCondition()
		if Cond == 18 or Cond < 14 then
			local RegS, RegM = SplitSkill(Player:GetSkill(const.Skills.Regeneration))
			local RegP = RegS > 0 and 0.5 or 0
			RegP = RegP + RegS/10*RegM

			local Buff = Player.SpellBuffs[const.PlayerBuff.Regeneration]
			if Buff.ExpireTime > Game.Time then
				RegS, RegM = SplitSkill(Buff.Skill)
				RegP = RegP + RegS/10*RegM + 0.5
			end

			if RegP > 0 then
				local FHP = Player:GetFullHP()
				Player.HP = math.min(Player.HP + math.ceil(FHP*RegP/100), FHP)
			end
		end
	end

	-- Add a bit of sp regeneration by meditation skill
	function events.RegenTick(Player)
		local Cond = Player:GetMainCondition()
		if Cond == 18 or Cond == 17 or Cond < 14 then
			local RegS, RegM = SplitSkill(Player:GetSkill(const.Skills.Meditation))
			if RegM > 0 then
				local FSP	= Player:GetFullSP()
				if RegM==4 then
					RegM=5
				end
				local Add = FSP^0.5*RegS^0.7*((RegM+5)/50)
				Player.SP = math.min(FSP, Player.SP + Add)
			end
		end
	end

	-- Correct resistances by Class/Race
	function events.CalcStatBonusByItems(t)

		local Res = t.Stat
		if not (Res >= 10 and Res <= 15) then
			return
		end

		local Race = GetRace(t.Player, t.PlayerIndex)

		if Race == 6 and (Res == 15 or Res == 14) then -- Lich's immunities
			t.Result = 65000
			t.Player.Resistances[6].Base = 65000
			t.Player.Resistances[7].Base = 65000

		elseif Race == 1 and Res == 14 then -- Vampire's mind immunity
			t.Result = 65000
			t.Player.Resistances[7].Base = 65000

		elseif Race == 4 and (Res == 13 or Res == 15) then -- Troll's Earth and Body resistance.
			t.Result = t.Result + 5

		elseif Race == 9 and (Res == 12 or Res == 13) then -- Dwarf's water and earth resistance.
			t.Result = t.Result + 5

		elseif Race == 5 then -- Dragon's bonuses
			t.Result = t.Result + 5

		end

	end

	local function PartyCanLearn(skill)
		for _,pl in Party do
			if pl.Skills[skill] == 0 and GetMaxAvailableSkill(pl, skill) > 0 then
				return true
			end
		end
		return false
	end

	local function PlayerCanLearn(skill)
		local pl = Party[math.max(Game.CurrentPlayer,0)]
		return pl.Skills[skill] == 0 and GetMaxAvailableSkill(pl, skill) > 0
	end

	-- Correct learn skills in single-school guilds.
	function events.DrawLearnTopics(t)
		if (t.HouseType >= 5 and t.HouseType <= 8) then
			t.Handled = true
			t.NewTopics[1] = 0x2b + t.HouseType
			t.NewTopics[2] = const.LearnTopics.Learning
		elseif (t.HouseType >= 9 and t.HouseType <= 11) then
			t.Handled = true
			t.NewTopics[1] = 0x2b + t.HouseType
			t.NewTopics[2] = const.LearnTopics.Meditation
		end
	end

	-- For characters without SP factor, but with Meditation skill - add linear amount of SP
	local gameSPStats = Game.Classes.SPStats
	local statSP = const.Stats.SP
	function events.CalcStatBonusBySkills(t)
		if t.Stat == statSP and gameSPStats[t.Player.Class] == 0 then
			local Skill, Mas = SplitSkill(t.Player.Skills[const.Skills.Meditation])
			t.Result = Skill * Mas
		end
	end

	mem.IgnoreProtection(true)
	mem.u4[0x48da9d] = 0x48da87
	mem.IgnoreProtection(false)

	-- Correct learn skills in temples
	function events.DrawLearnTopics(t)
		if t.HouseType == const.HouseType.Temple then
			t.Handled = true
			t.NewTopics[1] = const.LearnTopics.Unarmed
			t.NewTopics[2] = const.LearnTopics.Dodging
			t.NewTopics[3] = const.LearnTopics.Regeneration
			t.NewTopics[4] = const.LearnTopics.Merchant
		end
	end

	-- Clean out map of removed corpses and summons by shrinking Map.Monsters table.
	--function events.LoadMap(WasInGame)
	--	local lim = Map.Monsters.limit
	--	if WasInGame and Map.Monsters.count >= lim then
	--		local MonsToKeep = {}
	--		local size = Map.Monsters[0]["?size"]
	--
	--		for i,v in Map.Monsters do
	--			if v.AIState ~= const.AIState.Removed and not (v.Summoner ~= 0 and v.HP <= 0) then
	--				table.insert(MonsToKeep, i)
	--			end
	--		end
	--
	--		for i,v in ipairs(MonsToKeep) do
	--			if i ~= v + 1 then
	--				mem.copy(Map.Monsters[i-1]["?ptr"], Map.Monsters[v]["?ptr"], size)
	--			end
	--		end
	--
	--		Map.Monsters.count = math.min(#MonsToKeep, lim)
	--	end
	--end

	-- Make mixing catalyst potions add up result catalyst power
	mem.autohook(0x415b25, function(d)
		local Target = structs.Item:new(d.ecx)
		Target.Bonus = Target.Bonus + Mouse.Item.Bonus
	end)
