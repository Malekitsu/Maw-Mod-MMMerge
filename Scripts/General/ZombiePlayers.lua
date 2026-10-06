
local max, min = math.max, math.min

function events.GameInitialized2()

	---- Reorganize priority of main conditions.
	local MainCondOrder = {
		const.Condition.Eradicated,
		const.Condition.Dead,
		const.Condition.Stoned,
		const.Condition.Unconscious,
		const.Condition.Asleep,
		const.Condition.Paralyzed,

		const.Condition.Disease3,
		const.Condition.Poison3,
		const.Condition.Disease2,
		const.Condition.Poison2,
		const.Condition.Disease1,
		const.Condition.Poison1,

		const.Condition.Zombie,
		const.Condition.Insane,
		const.Condition.Drunk,
		const.Condition.Afraid,
		const.Condition.Weak,
		const.Condition.Cursed
	}

	for i,v in ipairs(MainCondOrder) do
		mem.u4[0x4fdfa4 + i*4] = v
	end

	---- Make Zombies immune to some diseases and mental conditions.
	local ZombieImmunities = {
		const.Condition.Asleep,
		const.Condition.Disease3,
		const.Condition.Disease2,
		const.Condition.Disease1,
		const.Condition.Insane,
		const.Condition.Drunk,
		const.Condition.Afraid,
		const.Condition.Weak
	}

	function events.DoBadThingToPlayer(t)
		if t.Player.Conditions[17] > 0 and table.find(ZombieImmunities, t.Thing) then
			t.Allow = false
		end
	end

	---- Portrait switches.

	-- Keep drawing face animations if character is in zombie condition
	-- and switch portrait according to condition.
	NewCode = mem.asmpatch(0x48fb90, [[
	mov ecx, eax

	; Get face
	movzx eax, byte [ds:esi+0x353]

	; Get race
	imul eax, eax, ]] .. Game.CharacterPortraits[0]["?size"] ..[[;
	add eax, ]] .. Game.CharacterPortraits["?ptr"] .. [[;
	add eax, 0x3f; race value offset
	movzx eax, byte [ds:eax]

	cmp eax, ]] .. const.Race.Zombie .. [[;
	mov eax, dword [ds:esi+0x88]
	je @Zom

	test eax, eax
	jnz @SetFace
	jmp @std

	@Zom:
	test eax, eax
	jnz @std

	@SetFace:
	nop
	nop
	nop
	nop
	nop

	@std:
	mov eax, ecx
	mov ecx, esi
	cmp eax, 0x12
	je absolute 0x48fcb4
	cmp eax, 0x11
	je absolute 0x48fcb4]])

	local ZombieFaces = {
		[const.Race.Human 	] = {[0] = 59, [1] = 60},
		[const.Race.Vampire	] = {[0] = 59, [1] = 60},
		[const.Race.DarkElf	] = {[0] = 59, [1] = 60},
		[const.Race.Minotaur] = {[0] = 70, [1] = 70},
		[const.Race.Troll	] = {[0] = 76, [1] = 76},
		[const.Race.Dragon	] = {[0] = 68, [1] = 68},
		[const.Race.Undead	] = {},
		[const.Race.Elf		] = {[0] = 59, [1] = 60},
		[const.Race.Goblin	] = {[0] = 59, [1] = 60},
		[const.Race.Dwarf	] = {[0] = 72, [1] = 73},
		[const.Race.Zombie	] = {[0] = 59, [1] = 60},
	}

	-- Conditional portraits keep their creature race (dragon, minotaur, troll).
	-- Identify them by portrait ID too, rather than only by the Zombie race.
	local ConditionalZombieFaces = {}
	for _, faces in pairs(ZombieFaces) do
		for _, face in pairs(faces) do
			ConditionalZombieFaces[face] = true
		end
	end
	local function IsZombieFace(Face)
		return ConditionalZombieFaces[Face]
			or Game.CharacterPortraits[Face].Race == const.Race.Zombie
	end

	local WasZombie = {}

	local function SetFace(PlayerId)
		local Player = Party.PlayersArray[PlayerId]
		local CurrentPlayer = 0

		for k,v in Party.PlayersIndexes do
			if v == PlayerId then
				CurrentPlayer = k
			end
		end

		vars.PlayerFaces = vars.PlayerFaces or {}

		if Player.Conditions[const.Condition.Zombie] > 0 then
			WasZombie[PlayerId] = true
			if not IsZombieFace(Player.Face) then
				vars.PlayerFaces[PlayerId] = {Face = Player.Face, Voice = Player.Voice}
			end

			local OrigPortrait = Game.CharacterPortraits[vars.PlayerFaces[PlayerId].Face]
			local NewFace = ZombieFaces[OrigPortrait.Race][OrigPortrait.DefSex]

			if NewFace then
				Player.Face = NewFace
				SetCharFace(CurrentPlayer, NewFace)
				Player.Voice = Game.CharacterPortraits[NewFace].DefVoice
			else
				Player.Conditions[const.Condition.Zombie] = 0
				Player.Conditions[const.Condition.Dead] = Game.Time
			end
		else
			local NewFace = vars.PlayerFaces[PlayerId]
			if NewFace then
				Player.Face = NewFace.Face
				SetCharFace(CurrentPlayer, NewFace.Face)
				Player.Voice = NewFace.Voice
				-- A conditional portrait can leave a permanent hurt expression behind.
				-- Let the normal condition/animation logic choose the restored face.
				Player.Expression = 1
				Player.ExpressionTimePassed = 0
				Player.ExpressionLength = 0
			end
			WasZombie[PlayerId] = nil
		end
	end

	-- The original assembly gate only notices Race.Zombie when healing.
	-- Restore creature portraits before that gate when their condition is cleared.
	mem.hook(NewCode, function(d)
		local PlayerId = (d.esi - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
		local Player = Party.PlayersArray[PlayerId]
		local Original = vars.PlayerFaces and vars.PlayerFaces[PlayerId]
		if Player.Conditions[const.Condition.Zombie] == 0 and IsZombieFace(Player.Face)
				and (WasZombie[PlayerId] or Original and
					(Player.Face ~= Original.Face or Player.Voice ~= Original.Voice)) then
			SetFace(PlayerId)
		end
	end)

	mem.hook(NewCode+44, function(d)
		local PlayerId	= (d.esi - Party.PlayersArray["?ptr"])/Party.PlayersArray[0]["?size"]
		SetFace(PlayerId)
	end)

	-- Make direct heals harm zombie.
	mem.asmpatch(0x48d048, [[
	cmp dword [ds:esi+0x88], 0x0
	je @std
	sub dword [ds:esi+0x1bf8], ecx
	jmp @end

	@std:
	add dword [ds:esi+0x1bf8], ecx
	@end:
	]])

	-- Make Divine Intervention cure zombie condition aswell.
	mem.asmpatch(0x42be4a, [[
	push 0x20
	pop ecx
	mov esi, eax
	mov dword [ds:eax+0x88], 0
	]])

	-- Make cure of zombie condition same expensive as eradication.
	local IsDarkTemplePtr = mem.StaticAlloc(1)
	mem.asmpatch(0x4b661b, [[
	; don't increase cost in dark temples
	cmp byte [ds:]] .. IsDarkTemplePtr .. [[], 1
	je @std

	cmp eax, 0x11
	je absolute 0x4b662a

	@std:
	cmp eax, 0xe
	jl absolute 0x4b6648]])

	-- Dark temples will reanimate players instead of reviving.
	local IsDarkTemple = false
	function events.EnterHouse(i)
		local House = Game.Houses[i]
		IsDarkTemple = House.Type == const.HouseType.Temple and (House.C == 2 or House.C == 3)
		mem.u1[IsDarkTemplePtr] = IsDarkTemple and 1 or 0
	end

	local function NeedHealDark(Player)
		local Conditions = Player.Conditions
		local Race = Game.CharacterPortraits[Player.Face].Race

		if (Conditions[const.Condition.Dead] > 0 or Conditions[const.Condition.Eradicated] > 0)
				and Race ~= const.Race.Undead and not ZombieFaces[Race][Player:GetSex()] then
			return false
		end

		local NeedHeal = false
		for i = 0, 16 do
			if Conditions[i] > 0 then
				NeedHeal = true
				break
			end
		end

		local NeedHeal = NeedHeal or (Player.HP < Player:GetFullHP()) or (Player.SP < Player:GetFullSP())
		return NeedHeal
	end

	function events.ClickShopTopic(t)

		if IsDarkTemple and t.Topic == const.ShopTopics.Heal then

			local PlayerId = max(Game.CurrentPlayer, 0)
			local cPlayer  = Party[PlayerId]

			if not NeedHealDark(cPlayer) then
				t.Handled = true
				return
			end

			local Cost
			local HouseId = GetCurrentHouse()
			local Conditions = cPlayer.Conditions

			if Conditions[const.Condition.Dead] > 0 then
				Cost = Game.Houses[HouseId].Val*5
			elseif Conditions[const.Condition.Eradicated] > 0 then
				Cost = Game.Houses[HouseId].Val*10
			elseif Conditions[const.Condition.Zombie] > 0 then
				Cost = Game.Houses[HouseId].Val
			end

			if Cost and evt.Subtract{"Gold", Cost} then
				t.Handled = true
				-- Capture the original before transformation, including chosen zombie skins.
				if Conditions[const.Condition.Zombie] == 0 then
					vars.PlayerFaces = vars.PlayerFaces or {}
					vars.PlayerFaces[Party.PlayersIndexes[PlayerId]] = {Face = cPlayer.Face, Voice = cPlayer.Voice}
				end
				cPlayer.HP = cPlayer:GetFullHP()
				cPlayer.SP = cPlayer:GetFullSP()
				evt.ForPlayer(PlayerId).Set{"MainCondition", 1}
				if Game.CharacterPortraits[cPlayer.Face].Race ~= const.Race.Undead then
					Conditions[const.Condition.Zombie] = Game.Time
					SetFace(Party.PlayersIndexes[PlayerId])
				end
			end
		end
	end

	function events.CanShowHealTopic(t)
		if not IsDarkTemple then
			return
		end

		t.CanShow = NeedHealDark(Party[max(Game.CurrentPlayer, 0)])
	end

	local function TransformToZombie(Target, Skill, Mastery, Force)
		local Race = Game.CharacterPortraits[Target.Face].Race

		local valid = Force or Target.Conditions[const.Condition.Dead] > 0
			and Target.Conditions[const.Condition.Eradicated] == 0
			and (Race == const.Race.Undead or ZombieFaces[Race][Target:GetSex()])

		if valid then

			local resultHP = Skill*(10+10*Mastery)

			if Force or resultHP + Target.HP > 0 and resultHP > Target:GetFullHP()/2 then -- Success

				Game.PlaySound(18000)
				Target.HP = min(Target:GetFullHP(), resultHP + Target.HP)
				Target.HP = max(Target.HP, 1)

				for k,v in pairs(ZombieImmunities) do
					Target.Conditions[v] = 0
				end

				Target.Conditions[const.Condition.Unconscious] = 0
				Target.Conditions[const.Condition.Paralyzed] = 0
				Target.Conditions[const.Condition.Dead] = 0

				if Race ~= const.Race.Undead then
					if Target.Conditions[const.Condition.Zombie] == 0 then
						vars.PlayerFaces = vars.PlayerFaces or {}
						vars.PlayerFaces[Target:GetIndex()] = {Face = Target.Face, Voice = Target.Voice}
					end
					Target.Conditions[const.Condition.Zombie] = Game.Time
					SetFace(Target:GetIndex())
				end

				return 1

			else -- Not enough skill
				Game.PlaySound(136)
				return 2

			end

		else -- Not enough SP or wrong target

			return 0
		end

	end
	Game.TransformToZombie = TransformToZombie

	-- "Reanimate" spell will raise dead players as zombies
	local u2 = mem.u2
	function events.Action(t)
		if Game.CurrentScreen == 20 and t.Action == 110 then
			local Spell = u2[0x51d820]
			if Spell == 0x59 then -- reanimate
				local Target = Party[t.Param-1]
				local Caster = Party.PlayersArray[u2[0x51d822]]
				local Skill, Mas = SplitSkill(Caster:GetSkill(const.Skills.Dark))

				local Result = Caster.SP >= 10 and TransformToZombie(Target, Skill, Mas) or 0
				if Result == 1 then
					Caster:ShowFaceAnimation(const.FaceAnimation.CastSpell)
				elseif Result == 2 then
					Caster:ShowFaceAnimation(const.FaceAnimation.SpellFailed)
					Game.ShowStatusText(Game.GlobalTxt[750])
				else
					Game.ShowStatusText(Game.GlobalTxt[586])
					Caster:ShowFaceAnimation(const.FaceAnimation.SpellFailed)
					Game.NeedRedraw = true
				end

				u2[0x51d820] = 0
				ExitCurrentScreen(nil, nil, true)
			end
		end
	end

	-- Use race of original portrait to calculate bonuses for zombie
	function events.GetMaxSkillLevel(t)
		if t.Player.Conditions[17] > 0 then
			local R = vars.PlayerFaces[t.PlayerIndex]
			if R then
				R = Game.CharacterPortraits[R.Face].Race
				t.Result, t.Bonus = GetMaxSkillLevel(R, t.Player.Class, t.Skill)
			end
		end
	end

	local StdGetRace = GetRace
	function GetRace(Player, PlayerIndex)
		PlayerIndex = PlayerIndex or (Player["?ptr"]-Party.PlayersArray[0]["?ptr"])/Player["?size"]
		if Player.Conditions[17] > 0 then
			local R = vars.PlayerFaces[PlayerIndex]
			if R then
				return Game.CharacterPortraits[R.Face].Race
			else
				return StdGetRace(Player, PlayerIndex)
			end
		else
			return StdGetRace(Player, PlayerIndex)
		end
	end

end

-- Multiplayer compatibility

function events.MultiplayerInitialized()

	function events.GatherPartySaveData(t)
		t.ZombiePlayersData = vars.PlayerFaces
	end

	function events.ProcessPartySaveData(t)
		if t.ZombiePlayersData then
			vars.PlayerFaces = t.ZombiePlayersData
		end
	end

	function events.LoadMapScripts(WasInGame)
		if WasInGame then
			return
		end

		vars.PlayerFaces = vars.PlayerFaces or {}
		for i, v in Party.PlayersArray do
			if not vars.PlayerFaces[i] then
				if Game.CharacterPortraits[v.Face].Race == const.Race.Zombie then
					vars.PlayerFaces[i] = {Face = 1, Voice = 1}
				else
					vars.PlayerFaces[i] = {Face = v.Face, Voice = v.Voice}
				end
			end
		end
	end

end
