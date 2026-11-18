
local CurScreen = 0x4f37d8
local InGame = 0x71ef8d	-- dword. 0x714b1d - byte. Don't know anything about these.
						-- Just using them as indicator of main menu
						-- (both of them are 0 when in main menu and 1 when in game).

function events.GameInitialized2()

	function IsInGameScreen()
		if mem.u4[InGame] == 0 then
			return false
		end

		local CurScr = Game.CurrentScreen

		if CurScr == 1
		or CurScr == 2
		or CurScr == 3
		or CurScr == 6
		-- or CurScr == 8
		or CurScr == 9
		or CurScr == 11
		or CurScr == 12
		or CurScr == 16
		or CurScr == 21
		-- or CurScr == 22
		or CurScr == 26
		or CurScr == 28
		or CurScr == 104 then
			return false
		else
			return true
		end
	end

	mem.hookalloc(0x400) -- New space for code.

	local SwitchTable = mem.StaticAlloc(0x18)
	local ParamStack = mem.StaticAlloc(0x10)

	local ExitInventory = mem.asmproc([[
	pushad
	pushfd

	mov ebp, 0x1006148
	mov esi, 0xfeb360
	mov edi, 1
	mov ecx, 0x71
	mov eax, 0x28
	xor ebx, ebx

	push edi
	push ebx
	mov ecx, ebp
	call absolute 0x4d1c62

	mov ecx, dword [ds:0x75d770]
	push 0x4f41cc
	call absolute 0x467c67

	popfd
	popad

	retn
	]])

	local ClearDialog = mem.asmproc([[
	mov eax, dword [ds:esi+0x4c]

	@Rep:
	mov edi, dword [ds:eax+0x34]
	push eax
	mov ecx, 0x73f910
	call absolute 0x424863		; Clear SpeakNPC buttons.
	cmp edi, 0
	mov eax, edi
	jnz @Rep

	mov dword [ds:esi+0x4c], 0
	mov dword [ds:esi+0x50], 0
	mov dword [ds:esi+0x20], 0
	mov dword [ds:esi+0x18], 0

	retn
	]])

	local HireNPC = mem.asmproc([[
	push 0x1; index from roster.txt
	mov ecx, 0xb20e90
	call absolute 0x48c09f
	retn
	]])

	local HireNPCSoundTrigger = mem.asmproc([[
	cmp byte [ds:]] .. ParamStack + 1 .. [[], 1
	mov byte [ds:]] .. ParamStack + 1 .. [[], 0
	je absolute 0x48c154
	push ebp
	push ebp
	push ebp
	push ebp
	push -1
	jmp absolute 0x48c143
	]])
	mem.asmpatch(0x48c13d, "jmp absolute " .. HireNPCSoundTrigger)

	local DismissNPC = mem.asmproc([[
	push 0x1; index of character in group (0 - main character, 1 - second, etc)
	mov ecx, 0xb20e90
	call absolute 0x48c019
	retn
	]])

	-- Dismiss char event.
	local NewCode = mem.asmproc([[
	nop
	nop
	nop
	nop
	nop
	cmp ebx, 0x5
	push esi
	mov esi, ecx
	jg absolute 0x48c099
	jmp absolute 0x48c028
	]])

	mem.hook(NewCode, function(d)
		local t = {Handled = false, PlayerId = d.ebx}
		if t.PlayerId >= 0 then
			events.call("DismissCharacter", t)
			d.ebx = t.PlayerId
			if t.Handled then
				d.ebx = -1
			end
		end
	end)

	mem.asmpatch(0x48c023, "jmp absolute " .. NewCode)

	local SpeakNPCInHouseScr = mem.asmproc([[
	push eax
	push ecx
	mov ecx, 0
	mov eax, dword [ds:0x518678]
	call absolute 0x4b2c36
	pop ecx
	pop eax
	retn
	]])

	local ExitCurScr = mem.asmproc([[
	nop
	nop
	nop
	nop
	nop
	retn
	]])

	local RefrHouseScreen = mem.asmproc([[
	push eax
	push ecx
	push edx
	push ebp

	mov eax, dword [ds:0x5186a8]
	test eax, eax
	je @Start

	push esi
	mov esi, 0x51865c
	call absolute ]] .. ClearDialog .. [[;
	pop esi

	@Start:
	mov edx, 0
	mov eax, dword [ds:0x519328]
	mov ecx, dword [ds:eax+0x1c]
	call absolute 0x442e8d		; Update NPC's stack and vizualization.

	cmp dword [ds:0x519324], 0
	je @Out

	mov eax, dword [ds:0x519324]
	mov dword [ds:eax+0x18], 0

	@Out:
	mov dword [ds:0x51867c], 0
	mov dword [ds:0x518674], 0
	mov dword [ds:0x5db8fc], 0
	mov dword [ds:0x519328], 0
	push dword [ds:0x518ce8]

	push 0
	push dword [ds:0x518678]
	push 0x19
	push 0x1e0
	push 0x280
	xor edx, edx
	xor ecx, ecx
	call absolute 0x41baf1		; Reload NPC's topics, appearance and buttons.
	mov dword [ds:0x519328], eax
	pop dword [ds:0x518ce8]

	mov eax, dword [ds:0x5a5714]; Number of NPCs in current house
	cmp eax, 1
	jl @Ncl
	je @npc
	mov dword [ds:0x51867c], eax
	jg @Ncl

	@npc:						; Enter dialog if only one npc left.
	cmp dword [ds:0x518ce8], 2
	je @Jup
	mov eax, dword [ds:0x519324]
	mov dword [ds:eax+0x18], 0
	mov ecx, 0
	mov eax, dword [ds:0x518678]
	call absolute 0x4b2c36		;SpeakNPC
	@Jup:
	mov dword [ds:0xffd408], -1
	xor eax, eax
	xor ecx, ecx
	call absolute 0x4b2c36		;Update topics.
	jmp @end


	@Ncl:
	cmp dword [ds:0x518ce8], 1
	jle @Ct
	call absolute ]] .. ExitCurScr .. [[;
	mov dword [ds:0x518ce8], 1
	mov dword [ds:0xffd408], 0
	@Ct:
	mov dword [ds:0x5186e8], 0
	mov dword [ds:0x5186d8], 0
	jmp @end

	@end:
	pop ebp
	pop edx
	pop ecx
	pop eax
	retn
	]])

	local CastSpellSelf = mem.asmproc([[
	pushfd
	pushad

	mov ebx, 0xfeb360
	mov esi, 0x5c3213
	mov eax, 0x0; 11
	mov ecx, 0x0; 16
	mov edx, 0x0; 21
	push 0x0; 26
	push 0x0; 28
	push 0x0; 30
	push 0x0; 32
	push 0x0; 34
	push 0x0; 36
	push 0x0; 38
	call absolute 0x44622c

	popad
	popfd
	retn]])

	local CastSpellScrollAs = mem.asmproc([[

	pushfd
	pushad

	xor eax, eax
	xor edi, edi
	xor ebx, ebx
	inc ebx
	mov esi, dword[ds:]] .. ParamStack + 4 .. [[]; Spell Number
	mov ecx, dword [ds:0x75d770]
	call absolute 0x467c0a

	mov eax, dword [ds:0x51e148]

	mov dword [ds:eax*4+0x51e14c],0x92
	mov eax, dword [ds:0x51e148]
	lea eax, dword [ds:eax+eax*2]
	mov dword [ds:eax*4+0x51e150],esi
	mov eax, dword [ds:0x51e148]
	lea eax, dword [ds:eax+eax*2+3]
	mov dword [ds:eax*4+0x51e148],0x5
	inc dword [ds:0x51e148]
	xor ebx,ebx

	popad
	popfd
	retn

	]])
	-- Refresh character face
	-- Refreshes character face, but not the paperdoll.

	local Char = mem.StaticAlloc(8)
	local Por = Char + 4
	local RefreshCharFaceAs = mem.asmproc([[
		mov ecx, dword[ds:]] .. Char .. [[];
		mov edx, dword[ds:]] .. Por .. [[];
		call absolute 0x4909b5
		retn]])

	function SetCharFace(CharId, PortraitId)
		mem.u4[Char] = CharId
		mem.u4[Por] = PortraitId
		return mem.call(RefreshCharFaceAs)
	end

	-- Clear palletes data.
	local UnloadPalettesAs = mem.asmproc([[
	mov ecx, 0x84afe0
	call absolute 0x489c19
	retn]])
	local function UnloadPalettes()
		mem.call(UnloadPalettesAs)
	end
	Game.UnloadPalettes = UnloadPalettes
	----

	-- Get list of monsters in party' sight
	local GetMonInSightAs = mem.asmproc([[

	pushad
	pushfd
	push dword [ds:0xfeb230]

	xor eax, eax
	mov ecx, 0x28

	@rep:
	sub ecx, 4
	mov dword [ds:0x51d688 + ecx], eax
	test ecx, ecx
	jnz @rep

	mov dword [ds:0xfeb230], 0x22; limit
	mov eax, 1
	mov ecx, dword [ds:0x75ce00]
	mov edx, 0
	mov ebx, 0x51d820
	mov esi, 0
	mov edi, 0xf

	push esi
	mov dword [ss:ebp-0x38], esi
	call absolute 0x42d74e
	mov ecx, eax
	call absolute 0x433d70
	call absolute 0x4d967c
	push eax
	push 0x64
	pop edx
	mov ecx, 0x51d688
	call absolute 0x468a6e

	pop dword [ds:0xfeb230]
	popfd
	popad

	retn
	]])

	local function GetMonstersInSight()
		local res = {}
		if mem.u4[InGame] == 1 then
			mem.call(GetMonInSightAs)

			local MonId = mem.u4[0x51d688]
			while MonId > 0 do
				table.insert(res, MonId)
				MonId = mem.u4[0x51d688 + #res*4]
			end
		end
		return res
	end
	Game.GetMonstersInSight = GetMonstersInSight
	----

	-- Play SpellBuff effect on monster
	local function ShowMonsterBuffAnim(MonId, Color24)
		if MonId < Map.Monsters.count and mem.u4[InGame] == 1 and Game.CurrentScreen == 0 then
			Map.Monsters[MonId]:ShowSpellEffect(Color24 or 0)
		end
	end
	Game.ShowMonsterBuffAnim = ShowMonsterBuffAnim

	----

	-- Refresh Adevnturer Inn's screen
	local RefreshAdvInnAs = mem.asmproc([[
	pushfd
	pushad

	mov esi, dword [ds:0x100614c]
	mov edi, -1
	push edi
	mov ecx, 0xb20e90
	call absolute 0x48c09f
	mov ecx, esi

	mov eax, 1
	mov edx, 0
	mov ebx, 0
	mov ebp, 0x1006148

	call absolute 0x4c8bff

	popad
	popfd
	retn]])

	-- make first character available for Inn.
	mem.nop(0x4c8186, 1)

	function RefreshAdevnturerInn()
		if Game.CurrentScreen == 29 then
			mem.call(RefreshAdvInnAs)
		end
	end
	----

--~ 	-- Alternative Question function
--~ 	local StdQuestion = Question
--~ 	local NeedAnswer = false
--~ 	local Answer

--~ 	mem.autohook(0x42fcb5, function()
--~ 		if NeedAnswer then
--~ 			Answer = Game.StatusMessage
--~ 			NeedAnswer = false
--~ 		end
--~ 	end)

--~ 	local function AltQuestion(Text)

--~ 		NeedAnswer = true

--~ 		local co = coroutine.create(function() StdQuestion(Text) end)
--~ 		coroutine.resume(co)

--~ 		while not Answer do
--~ 			Sleep(25, 25, {Game.CurrentScreen})
--~ 		end

--~ 		local result = Answer
--~ 		Answer = nil

--~ 		return result

--~ 	end

--~ 	-- temporary, while MMPatch 2.3 have this bug
--~ 	Question = AltQuestion

	----

	local CastQuickSpellAsm = mem.asmproc([[
	mov edx, dword [ss:esp+0x4]
	mov eax, dword [ss:esp+0x8]
	mov ecx, dword [ss:esp+0xC]
	pushad
	mov edi, 1
	xor ebx, ebx
	mov ebp, 0x1006148
	mov esi, 0xfeb360
	push edx
	dec edx
	push ebx
	push ebx
	call absolute 0x425b67
	popad
	retn]])

	-- check and update quick spell sound set each cast
	mem.asmpatch(0x43159a, [[
	cmp dword [ds:0x4f37d8], 0; current screen
	jne @std

	mov esi, dword [ss:esp+0x8]
	push esi
	push ecx
	imul esi, esi, 0xafd8
	add esi, 0xadef80
	xchg ecx, esi
	call absolute 0x492b52

	mov edx, dword [ss:esp+0x8]
	dec edx
	mov ecx, esi
	mov esi, 0xfeb360

	@std:
	jmp absolute 0x4320de]])

	function CastQuickSpell(PlayerId, SpellId)
		-- update sound set
		mem.call(0x492b52, 1, 0xadef80 + (PlayerId + 1)*0xafd8, SpellId, PlayerId + 1)
		mem.call(CastQuickSpellAsm, 0, PlayerId+1, Party[PlayerId]["?ptr"], SpellId)
	end

	local NeedExit, NeedRefresh, ExitDone

	function events.Action(t)
		if NeedExit then
			t.Action = NeedExit
			NeedExit = false
		end
	end

	function ExitCurrentScreen(Refresh, Now, CallNow)
		local ExitActions = {[1] = 123, [3] = 470, [5] = 167, [7] = 168, [10] = 11, [13] = 113, [19] = 491}
		if Game.CurrentScreen == 0 then
			return
		elseif Game.CurrentScreen == 7 then
			mem.call(ExitInventory)
		else
			mem.u4[0x51e330] = 1
			NeedExit = ExitActions[Game.CurrentScreen] or 113
			if CallNow then
				mem.call(0x42edd8)
			elseif Now or Refresh then
				Sleep(10,10)
			end
			if Refresh then
				RefreshHouseScreen()
			end
		end
	end
	mem.hook(ExitCurScr, function() ExitCurrentScreen() end)

	-- Some spells requie selection screen to be set beforehand
	-- and cannot be processed glitchless if it is not.
	-- These require inventory screen to be open and execute exit, when spell is done.
	-- Execution of exit without inventory screen open, breaks UI.
	local spells_with_inventory_screen = {
		[4] = 0,
		[28] = 0,
		[30] = 0,
		[91] = 0}

	function CastSpellDirect(SpellId, Skill, Mastery, Caster, Target, Flags, TargetKind)
		if spells_with_inventory_screen[SpellId] then
			return
		end

		Caster = Caster or 49
		if Caster == 49 then
			local pl = Party.PlayersArray[Caster]
			pl.SP = 1000
			pl.DevineInterventionCasts = 0
			pl.ArmageddonCasts = 0
			pl.AgeBonus = 0
		end

		mem.u2[0x51d820] = SpellId
		mem.u2[0x51d822] = Caster -- Caster - rosterId
		mem.u2[0x51d824] = Target or 49 -- Target - rosterId
		mem.u2[0x51d828] = Flags or 0x8020
		mem.u2[0x51d82a] = JoinSkill(Skill or 1, Mastery or 0)
		mem.u2[0x51d82c] = bit.lshift(Target or 0, 3) + (TargetKind or 4)
	end

	function CastSpellScroll(SpellId)
		mem.u4[ParamStack + 4] = SpellId
		mem.call(CastSpellScrollAs)
	end

	function CastSpellOnParty(Number, SkillLevel, Skill)

		if not IsInGameScreen() then
			return 0
		end

		mem.IgnoreProtection(true)

		mem.u4[CastSpellSelf + 11 + 7] = Skill
		mem.u1[CastSpellSelf + 38 + 7] = Skill

		mem.u4[CastSpellSelf + 16 + 7] = Number
		mem.u1[CastSpellSelf + 36 + 7] = Number

		mem.u4[CastSpellSelf + 21 + 7] = SkillLevel
		mem.u1[CastSpellSelf + 34 + 7] = SkillLevel

		mem.IgnoreProtection(false)

		mem.call(CastSpellSelf)

	end

	function HireCharacter(RosterID, NoSound)

		if not IsInGameScreen() then
			return 0
		end

		if NoSound then
			mem.u1[ParamStack + 1] = 1
		end

		mem.u1[HireNPC + 1] = RosterID

		return mem.call(HireNPC)

	end

	function DismissCharacter(PlayerID)

		if not IsInGameScreen() then
			return 0
		end

		mem.IgnoreProtection(true)
		mem.u1[DismissNPC + 1] = PlayerID
		mem.IgnoreProtection(false)

		mem.call(DismissNPC)

	end

	function RefreshHouseScreen()

		if Game.CurrentScreen ~= 13 then
			return
		end

		mem.call(RefrHouseScreen)

	end

	function SpeakNPCInHouse(NPCPosition)

		if GetCurrentNPC() then
			return
		end

		if Game.CurrentScreen ~= 13 then
			return
		end

		mem.u1[SpeakNPCInHouseScr + 3] = NPCPosition

		mem.call(SpeakNPCInHouseScr)

	end

	function DoGameAction(a, p1, p2, now)
		mem.u4[0x51e330] = 1

		local function act(t)
			t.Action = a  or 0
			t.Param  = p1 or 0
			t.Param2 = p2 or 0
			events.Remove("Action", act)
		end
		events.Action = act

		if now then
			mem.call(0x42edd8)
		end
	end

	function ForceStartNewGame(MapName, PartyPersist)

		local act1, act2, act3, TimeMark, PartyMembers

		act1 = function()

			if PartyPersist then
				PartyMembers = {}
				for i,v in Party do
					PartyMembers[Party.PlayersIndexes[i]] = mem.string(v["?ptr"], v["?size"], true)
				end
			end

			if MapName then
				Game.NewGameMap = MapName
			end

			mem.u4[0x6ceb28] = 4
			TimeMark = os.time() + 1
			events.FGInterfaceUpd = act2

		end

		act2 = function()
			CustomUI.ShowIcon("TPGlobal", 0, 0)
			if os.time() > TimeMark then

				mem.u4[0x6ceb24] = 1
				mem.u4[0x51e330] = 1
				events.Remove("FGInterfaceUpd", act2)
			end

		end

		act3 = function()

			if PartyPersist then
				local cnt = 0
				for k,v in pairs(PartyMembers) do
					local pl = Party.PlayersArray[k]
					Party.PlayersIndexes[cnt] = k
					mem.copy(pl["?ptr"], v)
					cnt = cnt + 1

					for k,v in pl.Awards do
						pl.Awards[k] = false
					end
				end
				Party.count = cnt
			end

			events.Remove("NewGameMap", act3)

		end

		events.NewGameMap = act3

		act1()

	end

end
