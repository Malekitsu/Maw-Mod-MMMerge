
local mmver = offsets.MMVersion

local OldNPCCount, NewNPCCount			= 551, nil
local OldGreetsCount, NewGreetsCount 	= 205, nil
local OldGroupsCount, NewGroupsCount 	= 51, nil
local OldNewsCount, NewNewsCount 		= 51, nil

local NPCTablesLoaded = false

local OldTopicCount, NewTopicCount	= 748, nil
local OldTextCount, NewTextCount	= 1000, nil

local TextsTopicsLoaded = false

local OldGlobalEvtSize, NewGlobalEvtSize = 0xb400, nil
local OldGlEvtLinesCount, NewGlEvtLinesCount = 5000, nil

local function ChangeGameArray(name, p, count)
	structs.o.GameStructure[name] = p
	internal.SetArrayUpval(Game[name], "o", p)
	internal.SetArrayUpval(Game[name], "count", count)
end

if mmver == 8 then

	local TeacherTopics = {}

	local function RemoveNPCTablesLimits()

		local NewNPCDataSize = 19*4*NewNPCCount
		local NewGreetsSize = NewGreetsCount*4

		local DynamicNPCTableOffset 	= NewNPCDataSize + 0x4c
		local NPCNewsOffset 			= (NewNPCDataSize+0x4c)*2 + 0x10
		local NPCPtrTableOffset 		= NPCNewsOffset + NewNewsCount*4 + 0x10
		local NPCGreetsOffset 			= NPCPtrTableOffset + 0x10 + 4*NewNPCCount
		local NPCGroupOffset	 		= NPCGreetsOffset + 2*4*NewGreetsCount + 0x20
		local ControlStackOffset 		= NPCGroupOffset + NewGroupsCount*8 + 0x10

		local NewSpacePointer = mem.StaticAlloc(ControlStackOffset+NewGroupsCount*8+0x200)
		local DynamicNPCTablePtr = NewSpacePointer + DynamicNPCTableOffset - 0x4c
		local NPCGroupPtr = NewSpacePointer + NPCGroupOffset

		mem.IgnoreProtection(true)

		--Control stack.

		mem.u4[0x475fc3 + 2] = ControlStackOffset

		mem.u4[0x475bf1 + 2] = ControlStackOffset + 0x4
		mem.u4[0x475c11 + 2] = ControlStackOffset + 0x4
		mem.u4[0x475d7e + 2] = ControlStackOffset + 0x4

		mem.u4[0x475ed0 + 2] = ControlStackOffset + 0x20
		mem.u4[0x475fea + 2] = ControlStackOffset + 0x20

		mem.u4[0x475c3f + 2] = ControlStackOffset + 0x18
		mem.u4[0x476007 + 2] = ControlStackOffset + 0x18

		mem.u4[0x475b2d + 2] = ControlStackOffset + 0x24
		mem.u4[0x475b42 + 2] = ControlStackOffset + 0x24
		mem.u4[0x475b60 + 2] = ControlStackOffset + 0x24
		mem.u4[0x475fd2 + 2] = ControlStackOffset + 0x24

		mem.u4[0x475a69 + 2] = ControlStackOffset + 0x28
		mem.u4[0x475a7f + 2] = ControlStackOffset + 0x28
		mem.u4[0x475a9d + 2] = ControlStackOffset + 0x28
		mem.u4[0x475fe4 + 2] = ControlStackOffset + 0x28

		mem.u4[0x475d8f + 2] = ControlStackOffset + 0x2c
		mem.u4[0x476018 + 2] = ControlStackOffset + 0x2c

		mem.u4[0x45ea97 + 2] = NewSpacePointer + ControlStackOffset

		mem.u4[0x442f17 + 2] = NewSpacePointer + ControlStackOffset + 0x4
		mem.u4[0x442f6e + 2] = NewSpacePointer + ControlStackOffset + 0x4
		mem.u4[0x4432f3 + 2] = NewSpacePointer + ControlStackOffset + 0x4
		mem.u4[0x492378 + 2] = NewSpacePointer + ControlStackOffset + 0x4
		mem.u4[0x49238b + 2] = NewSpacePointer + ControlStackOffset + 0x4

		mem.u4[0x4936b9 + 2] = NewSpacePointer + ControlStackOffset + 0x10
		mem.u4[0x49370a + 2] = NewSpacePointer + ControlStackOffset + 0x10
		mem.u4[0x493734 + 2] = NewSpacePointer + ControlStackOffset + 0x10

		-- NPCData table itself (original start - 0x761998).

		mem.u4[0x45cb6c + 1] = NewSpacePointer
		mem.u4[0x4629dd + 1] = NewSpacePointer
		mem.u4[0x46426a + 1] = NewSpacePointer -- loading table
		mem.u4[0x490758 + 1] = NewSpacePointer

		-- Dynamic NPC table (stored in savegame, original start - 0x76bd2c)

		mem.u4[0x475bf9 + 2] = DynamicNPCTableOffset
		mem.u4[0x442c17 + 1] = DynamicNPCTablePtr
		mem.u4[0x443ea6 + 1] = DynamicNPCTablePtr
		mem.u4[0x45cb5f + 1] = DynamicNPCTablePtr
		mem.u4[0x45d2ef + 1] = DynamicNPCTablePtr
		mem.u4[0x49075d + 1] = DynamicNPCTablePtr
		mem.u4[0x43006d + 2] = DynamicNPCTablePtr + 0x8
		mem.u4[0x443e4f + 2] = DynamicNPCTablePtr + 0x8
		mem.u4[0x444108 + 2] = DynamicNPCTablePtr + 0x14
		mem.u4[0x443e56 + 2] = DynamicNPCTablePtr + 0x1c
		mem.u4[0x492380 + 1] = DynamicNPCTablePtr + 0x44
		mem.u4[0x442f22 + 1] = DynamicNPCTablePtr + 0x54
		mem.u4[0x443306 + 1] = DynamicNPCTablePtr + 0x74

			-- New amount to save in SaveGame:

		mem.u4[0x45cb5a + 1] = NewNPCDataSize -- to load
		mem.u4[0x45d2fa + 3] = NewNPCDataSize -- to save


		-- NPCNews table (original start - 0x778f50).

		mem.u4[0x475edc + 2] = NPCNewsOffset
		mem.u4[0x4216ee + 3] = NewSpacePointer + NPCNewsOffset
		mem.u4[0x4688f8 + 3] = NewSpacePointer + NPCNewsOffset

		-- Table of pointers to NPCdata lines (original start - 0x779020).

		mem.u4[0x475bff + 2] = NPCPtrTableOffset
		mem.u4[0x475c52 + 2] = NPCPtrTableOffset

		-- NPCGreets table (original start - 0x7798c0).

		mem.u4[0x475d9b + 2] = NPCGreetsOffset

		-- NPCGroup table (original start - 0x779f8e)

		mem.u4[0x475e37 + 2] = NPCGroupOffset + NewGroupsCount*4 + 0x96
		mem.u4[0x476027 + 2] = NPCGroupOffset + NewGroupsCount*4 + 0x96

		mem.u4[0x4216da + 4] = NPCGroupPtr + NewGroupsCount*2
		mem.u4[0x443fd8 + 4] = NPCGroupPtr + NewGroupsCount*2
		mem.u4[0x4688e4 + 4] = NPCGroupPtr + NewGroupsCount*2
		mem.u4[0x49076e + 1] = NPCGroupPtr + NewGroupsCount*2

		mem.u4[0x475e43 + 2] = NPCGroupOffset
		--mem.u4[0x490769 + 1] = NPCGroupPtr -- corrected in asmpatch below
		mem.nop(0x45cbc9, 2)
		mem.asmpatch(0x45cbcb, [[
		push ]] .. NewGroupsCount*2 .. [[;
		push ]] .. NPCGroupPtr + NewGroupsCount*2 .. [[;]])  -- to load

		mem.u4[0x45d35b + 1] = NPCGroupPtr + NewGroupsCount*2 -- to save
		mem.u4[0x45d366 + 3] = NewGroupsCount*2

			-- New counters.

		-- NPCdata
		mem.u4[0x490753 + 1] = NewNPCCount*76
		mem.u4[0x475c61 + 3] = NewNPCCount-1
		mem.u4[0x475d7e + 6] = NewNPCCount
		mem.u4[0x442be2 + 2] = NewNPCCount

		-- NPCGreet
		mem.u4[0x475da5 + 3] = NewGreetsCount

		-- NPCGroup
		mem.u4[0x475e4d + 3] = NewGroupsCount
		mem.nop(0x490767, 2)
		mem.asmpatch(0x490769, [[
		push ]] .. NewGroupsCount*2 .. [[;
		push ]] .. NPCGroupPtr .. [[;]])

		-- NPCNews
		mem.u4[0x475ee6 + 3] = NewNewsCount


		mem.IgnoreProtection(false)

		ChangeGameArray("NPCDataTxt", NewSpacePointer, NewNPCCount)
		ChangeGameArray("NPC", DynamicNPCTablePtr, NewNPCCount)
		ChangeGameArray("NPCGreet", NewSpacePointer + NPCGreetsOffset - 0x8, NewGreetsCount + 1)
		ChangeGameArray("NPCGroup", NPCGroupPtr + NewGroupsCount*2 + 2, NewGroupsCount)
		ChangeGameArray("NPCNews", NewSpacePointer + NPCNewsOffset, NewNewsCount)

		Game.NPC.count = NewNPCCount

		return NewSpacePointer

	end

	local function RemoveTextsAndTopicsLimits()

		local NewSpaceSize = math.max(NewTopicCount, NewTextCount)*8 + 0x30

		local NewTextTopicPtr = mem.StaticAlloc(NewSpaceSize)

		-- 0x75e448, 0x75e44c - ID = 0 pointers to topics and texts.
		-- 0x75e450, 0x75e454 - ID = 1 pointers for table filling.

		mem.IgnoreProtection(true)

		mem.u4[0x420726 + 3] = NewTextTopicPtr + 0x8 -- Topics preview in status window.
		mem.u4[0x4428e9 + 3] = NewTextTopicPtr + 0x8 -- Topics loading.
		mem.u4[0x44339f + 3] = NewTextTopicPtr + 0x8

		mem.u4[0x469168 + 3] = NewTextTopicPtr + 0x8

		mem.u4[0x4b159f + 3] = NewTextTopicPtr + 0x8 -- Topics loading 2
		mem.u4[0x4b15df + 3] = NewTextTopicPtr + 0x8

		mem.u4[0x444efb + 3] = NewTextTopicPtr + 0xC
		mem.u4[0x444f1a + 3] = NewTextTopicPtr + 0xC
		mem.u4[0x444f73 + 3] = NewTextTopicPtr + 0xC

		mem.u4[0x4456be + 3] = NewTextTopicPtr + 0xC

		-- mem.u4[0x4b2811 + 3] = NewTextTopicPtr + 0xC -- corrected inside new teacher's topics handler.

		mem.u4[0x475b6d + 3] = NewTextTopicPtr + 0x10

		mem.u4[0x475aaa + 3] = NewTextTopicPtr + 0x14

		-- Below are custom pointers to topics belonging to mainstory, hardcoded quests etc - main reason to just append new topics.

		local TmpAddrTable

		local function SimpleReplacePtr(t, CmdSize, OldOrigin, NewOrigin)
			local OldAddr
			for i, v in ipairs(t) do
				OldAddr = mem.u4[v + CmdSize]
				mem.u4[v + CmdSize] = NewOrigin + OldAddr - OldOrigin
			end
		end

			-- Shifts
		TmpAddrTable = {0x4b7136, 0x4b0f22, 0x4b11d8, 0x4b271b, 0x4b2b3a}
		SimpleReplacePtr(TmpAddrTable, 3, 0x75e440, NewTextTopicPtr)

		TmpAddrTable = {0x4b0968, 0x4b2924, 0x4ba7ca}
		SimpleReplacePtr(TmpAddrTable, 2, 0x75e440, NewTextTopicPtr)

			-- Constants
		TmpAddrTable = {0x42f962, 0x4939ba, 0x4b0722, 0x4b3513, 0x4b71fa}
		SimpleReplacePtr(TmpAddrTable, 2, 0x75e440, NewTextTopicPtr)

		TmpAddrTable = {0x4b069e, 0x4b0def, 0x4b0efb, 0x4b0f09, 0x4b1066, 0x4b11a0, 0x4b11bd, 0x4b11d1, 0x4b9db2, 0x4b9dc9, 0x4b9dd0, 0x4b9dd7, 0x4bae69, 0x4bae7d, 0x4bae84}
		SimpleReplacePtr(TmpAddrTable, 1, 0x75e440, NewTextTopicPtr)

		-- Borders:

		mem.u4[0x475b24 + 3] = NewTextTopicPtr + 0x14 + NewTextCount*8
		mem.u4[0x475be0 + 3] = NewTextTopicPtr + 0x10 + NewTopicCount*8

		mem.IgnoreProtection(false)

		ChangeGameArray("NPCTopic", NewTextTopicPtr + 0x10, NewTopicCount)
		ChangeGameArray("NPCText", NewTextTopicPtr + 0x14, NewTextCount)

	end



	local function ProcessTeachTopicsTable() -- New teacher's topics handler.

		local TxtTable = io.open("Data/Tables/Teacher topics.txt", "r")

		if not TxtTable then
			TxtTable = io.open("Data/Tables/Teacher topics.txt", "w")
			local DefBase = 300

			TxtTable:write("TopicId\9Notes\9SkillId\9Mastery\9TextId\9Req. gold\9Req. skill\n")
			for i = 300, 416 do
				TxtTable:write(i .. "\9" .. Game.NPCTopic[i] .. "\9" .. math.floor((i-300)/3) .. "\9" .. ((i-300)/3 - math.floor((i-300)/3))*3 + 1 .. "\9" .. i .. "\n")
			end
			io.close(TxtTable)

			TxtTable = io.open("Data/Tables/Teacher topics.txt", "r")
		end

		local LineIt = TxtTable:lines()
		LineIt()

		for line in LineIt do
			local Words = string.split(line, "\9")
			TeacherTopics[tonumber(Words[1])] = {SId = tonumber(Words[3]) or 0, Mas = tonumber(Words[4]) or 1, Text = tonumber(Words[5]) or 300, Gold = tonumber(Words[6]), Skill = tonumber(Words[7])}
		end

		local CurTopic
		local function IsTeachTopic(i)
			CurTopic = i
			return TeacherTopics[i] and 1 or 0
		end

		mem.hook(0x4b07b5, function(d)
			events.Call("ClickNPCTopic", d.ecx) -- happens before related evt.Global executed
			d.edx = IsTeachTopic(d.ecx)
		end)
		mem.asmpatch(0x4b07bb, "test edx, edx")
		mem.asmpatch(0x4b07bd, "je absolute 0x4b07cf")
		mem.asmpatch(0x4b07c3, "xor edx, edx")

		mem.hook(0x4b1528, function(d) d.ZF = IsTeachTopic(d.edx) == 0 end)
		mem.nop(0x4b152e, 2)
		mem.asmpatch(0x4b1530, "je absolute 0x4b154e")
		mem.nop(0x4b1536, 2)

		mem.hook(0x4ba842, function(d)
			events.Call("ClickNPCTopic", d.ecx) -- happens before related evt.Global executed
			d.eax = 0
		end) --IsTeachTopic(d.ecx) end) -- Teacher topics are super buggy when used outdoors, disabling them for now.
		mem.asmpatch(0x4ba848, "test eax, eax")
		mem.asmpatch(0x4ba84a, "je absolute 0x4ba85c")
		mem.nop(0x4ba850, 2)

		mem.hook(0x4b0de8, function(d)
				local Topic = TeacherTopics[d.ecx]
				if Topic then
					d.eax = Topic.SId
				else
					d.eax = 0
				end
			end)

		mem.hook(0x4b2811, function(d) d.eax = mem.u4[Game.NPCText["?ptr"] + TeacherTopics[d.ecx].Text*8 - 8] end)

		mem.nop(0x4b0dfd, 2)
		mem.hook(0x4b0e00, function(d)
				local Topic = TeacherTopics[d.esi]
				d.edx = (Topic and Topic.Mas or 1) - 1
				d.edi = 3
			end)

		-- Required gold
		local function GetReqGold(d)
			local Tt = TeacherTopics[CurTopic]
			if Tt and Tt.Gold then
				mem.u4[0xffd420] = Tt.Gold
				d.edx = Tt.Gold
			end
		end

		mem.autohook2(0x4b104c, GetReqGold)
		mem.autohook2(0x4b105a, GetReqGold)
		mem.hook(0x4b0fab, GetReqGold)

		-- Required skill
		local NewCode
		local DefReq = {4,7,10}
		local function GetReqSkill(d)
			local Tt = TeacherTopics[CurTopic]
			if Tt then
				if Tt.Skill then
					d.eax = Tt.Skill
				elseif Tt.Mas then
					d.eax = DefReq[Tt.Mas]
				end
			else
				d.eax = 4
			end
		end

		NewCode = mem.asmpatch(0x4b109f, [[
		nop
		nop
		nop
		nop
		nop
		cmp edi, eax
		jge absolute 0x4b10a9]])
		mem.hook(NewCode, GetReqSkill)

		NewCode = mem.asmpatch(0x4b100d, [[
		nop
		nop
		nop
		nop
		nop
		cmp edi, eax
		jl absolute 0x4b10a4]])
		mem.hook(NewCode, GetReqSkill)

		NewCode = mem.asmpatch(0x4b0f50, [[
		nop
		nop
		nop
		nop
		nop
		cmp edi, eax
		jl absolute 0x4b10a4]])
		mem.hook(NewCode, GetReqSkill)

	end


	local function RemoveGlobalEvtLimits()

			--Global events module:
		-- 0x5bb448 - original start.
		-- 0x587e8c
		-- 0x596908
		-- 0x5ac9e0

		local LinesInGlobalEvtNewSize = NewGlEvtLinesCount*12 + 0x10 + 0x100

		--local GlobalModuleNewSpace = mem.StaticAlloc(NewGlobalEvtSize + 0x10 + LinesInGlobalEvtNewSize*4)				--0x5bb440
		local GlobalModuleNewSpace = mem.StaticAlloc(NewGlobalEvtSize + 0x10 + LinesInGlobalEvtNewSize*2)				--0x5bb440
		local GlobalModuleOffsetsNewSpace1 = GlobalModuleNewSpace + NewGlobalEvtSize + 0x10								--mem.StaticAlloc(LinesInGlobalEvtNewSize)	--005ac9e0
		local GlobalModuleOffsetsNewSpace2 = GlobalModuleNewSpace + NewGlobalEvtSize + 0x10 + LinesInGlobalEvtNewSize	--mem.StaticAlloc(LinesInGlobalEvtNewSize) 	--0x587e6c
		--local GlobalModuleOffsetsNewSpace3 = GlobalModuleNewSpace + NewGlobalEvtSize + 0x10 + LinesInGlobalEvtNewSize*2	--mem.StaticAlloc(LinesInGlobalEvtNewSize) 	--0x596908
		--local GlobalModuleOffsetsNewSpace4 = GlobalModuleNewSpace + NewGlobalEvtSize + 0x10 + LinesInGlobalEvtNewSize*3	--mem.StaticAlloc(LinesInGlobalEvtNewSize) 	--0x5ccce8

		mem.IgnoreProtection(true)

		mem.u4[0x440bc9 + 1] = NewGlobalEvtSize + 0x10 -- New buffer size
		mem.u4[0x440be8 + 1] = LinesInGlobalEvtNewSize
		--mem.u4[0x440d3e + 1] = LinesInGlobalEvtNewSize -- Map events
		mem.u4[0x4435f2 + 1] = LinesInGlobalEvtNewSize
		mem.u4[0x4437cc + 1] = LinesInGlobalEvtNewSize

		--[[
		mem.u4[0x440d48 + 1] = GlobalModuleOffsetsNewSpace4		--0x5ccce8
		mem.u4[0x440d6d + 3] = GlobalModuleOffsetsNewSpace4+0x4
		mem.u4[0x440dc8 + 1] = GlobalModuleOffsetsNewSpace4+0x4
		mem.u4[0x440e1c + 1] = GlobalModuleOffsetsNewSpace4
		mem.u4[0x44163f + 1] = GlobalModuleOffsetsNewSpace4+0x8
		mem.u4[0x4416a8 + 3] = GlobalModuleOffsetsNewSpace4
		mem.u4[0x443813 + 1] = GlobalModuleOffsetsNewSpace4
		mem.u4[0x44974d + 1] = GlobalModuleOffsetsNewSpace4
		mem.u4[0x449768 + 2] = GlobalModuleOffsetsNewSpace4+0x14
		mem.u4[0x449777 + 2] = GlobalModuleOffsetsNewSpace4+0x8
		mem.u4[0x44979d + 1] = GlobalModuleOffsetsNewSpace4
		mem.u4[0x4497b8 + 2] = GlobalModuleOffsetsNewSpace4+0x14
		mem.u4[0x4497c7 + 2] = GlobalModuleOffsetsNewSpace4+0x8
		]]

		--[[
		mem.u4[0x443818 + 1] = GlobalModuleOffsetsNewSpace3	 	--0x596908
		mem.u4[0x44386a + 2] = GlobalModuleOffsetsNewSpace3
		mem.u4[0x44387a + 2] = GlobalModuleOffsetsNewSpace3+0x4
		mem.u4[0x443886 + 2] = GlobalModuleOffsetsNewSpace3+0x8
		]]

		--mem.u4[0x4435c7 + 1] = GlobalModuleOffsetsNewSpace2+0x8
		--mem.u4[0x445f60 + 2] = GlobalModuleOffsetsNewSpace2+0x4
		--mem.u4[0x445f7c + 2] = GlobalModuleOffsetsNewSpace2   	--0x587e6c
		--mem.u4[0x445fa2 + 2] = GlobalModuleOffsetsNewSpace2

		mem.u4[0x4435fc + 1] = GlobalModuleOffsetsNewSpace2+0 --(not 0x587e8c) 0x587EA0
		mem.u4[0x44363c + 2] = GlobalModuleOffsetsNewSpace2+0
		mem.u4[0x443648 + 2] = GlobalModuleOffsetsNewSpace2+4
		mem.u4[0x443654 + 2] = GlobalModuleOffsetsNewSpace2+8

		mem.u4[0x440bf2 + 1] = GlobalModuleOffsetsNewSpace1		--005ac9e0
		mem.u4[0x440c0e + 3] = GlobalModuleOffsetsNewSpace1+0x4
		mem.u4[0x4435f7 + 1] = GlobalModuleOffsetsNewSpace1
		mem.u4[0x4437fd + 1] = GlobalModuleOffsetsNewSpace1

		mem.u4[0x440be1 + 1] = GlobalModuleNewSpace+0x4
		mem.u4[0x440bf7 + 2] = GlobalModuleNewSpace   			--0x5bb440
		mem.u4[0x440c02 + 2] = GlobalModuleNewSpace
		mem.u4[0x440c47 + 2] = GlobalModuleNewSpace+0x4
		mem.u4[0x440c4f + 2] = GlobalModuleNewSpace
		mem.u4[0x4435e7 + 1] = GlobalModuleNewSpace
		mem.u4[0x4437ee + 1] = GlobalModuleNewSpace

		mem.u4[0x440bce + 1] = GlobalModuleNewSpace+0x8
		mem.u4[0x440c16 + 3] = GlobalModuleNewSpace+0x8+0x2
		mem.u4[0x440c1d + 3] = GlobalModuleNewSpace+0x8+0x1
		mem.u4[0x440c2c + 3] = GlobalModuleNewSpace+0x8+0x3
		mem.u4[0x440c35 + 3] = GlobalModuleNewSpace+0x8
		mem.u4[0x443601 + 6] = GlobalModuleNewSpace+0x8
		mem.u4[0x4437f3 + 6] = GlobalModuleNewSpace+0x8

		mem.IgnoreProtection(false)

		ChangeGameArray("GlobalEvtLines", GlobalModuleOffsetsNewSpace1, NewGlEvtLinesCount)
		internal.SetArrayUpval(Game.GlobalEvtLines, "lenP", GlobalModuleNewSpace)
		--ChangeGameArray("MapEvtLines", GlobalModuleOffsetsNewSpace4, NewGlEvtLinesCount)

		--offsets.CurrentEvtLines = GlobalModuleOffsetsNewSpace3

		mem.asmpatch(0x443804, [[
		pop eax
		push 0xEA60
		mov eax, dword ptr [0x5C7020]
		]])

		return GlobalModuleNewSpace + 0x8

	end


	local TablesPtrs = mem.StaticAlloc(0x18)

	local LoadNPCTables = mem.asmproc([[
	push 0
	mov esi, ecx
	push 0x4fb754
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCData.txt
	mov dword [ds:]] .. TablesPtrs .. [[], eax
	push 0
	push 0x4fb744
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCGreet.txt
	mov dword [ds:]] .. TablesPtrs + 0x4 .. [[], eax
	push 0
	push 0x4fb734
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCGroup.txt
	mov dword [ds:]] .. TablesPtrs + 0x8 .. [[], eax
	push 0
	push 0x4fb728
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCNews.txt
	mov dword [ds:]] .. TablesPtrs + 0xc .. [[], eax
	nop; memhook here
	nop
	nop
	nop
	nop
	mov eax, dword [ds:]] .. TablesPtrs .. [[];
	retn
	nop]])
	mem.nop2(0x475c25, 0x475c38)
	mem.asmpatch(0x475c33, "call absolute " .. LoadNPCTables)

	mem.hook(LoadNPCTables + 90, function(d)

		if not NPCTablesLoaded then

			NewNPCCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs], 6, 6) - 1
			NewGreetsCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs+0x4], 3, 5) - 1
			NewGroupsCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs+0x8], 1, 2) - 1
			NewNewsCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs+0xc], 1) - 1

			mem.nop2(0x475d72, 0x475d7e)
			mem.asmpatch(0x475d88, "mov eax, " .. mem.u4[TablesPtrs+0x4])

			mem.nop2(0x475e24, 0x475e35)
			mem.asmpatch(0x475e30, "mov eax, " .. mem.u4[TablesPtrs+0x8])

			mem.nop2(0x475ebd, 0x475ece)
			mem.asmpatch(0x475ec9, "mov eax, " .. mem.u4[TablesPtrs+0xc])

			if OldNPCCount < NewNPCCount or
				OldGreetsCount < NewGreetsCount or
				OldGroupsCount < NewGroupsCount or
				OldNewsCount < NewNewsCount then

				local NewPtr = RemoveNPCTablesLimits()

				mem.u4[d.esp+0xc] = NewPtr
				d.ecx = NewPtr
				d.esi = NewPtr

			else

				d.ecx = 0x761998
				d.esi = 0x761998

			end

			NPCTablesLoaded = true

		end

	end)

	local LoadTextsAndTopicsTxt = mem.asmproc([[
	push 0
	push 0x4fb71c
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCText.txt
	mov dword [ds:]] .. TablesPtrs + 0x10 .. [[], eax
	push 0
	push 0x4fb70c
	mov ecx, 0x6fb828
	call absolute 0x411c9b; load NPCTopic.txt
	mov dword [ds:]] .. TablesPtrs + 0x14 .. [[], eax
	nop; memhook here
	nop
	nop
	nop
	nop
	mov eax, dword [ds:]] .. TablesPtrs + 0x10 .. [[];
	retn
	]])
	mem.nop2(0x475a86, 0x475a97)
	mem.asmpatch(0x475a92, "call absolute " .. LoadTextsAndTopicsTxt)

	mem.hook(LoadTextsAndTopicsTxt + 44, function(d)

		if not TextsTopicsLoaded then

			NewTextCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs+0x10], 2) - 1
			NewTopicCount 	= DataTables.ComputeRowCountInPChar(mem.u4[TablesPtrs+0x14], 1) - 1

			mem.nop2(0x475b49, 0x475b5a)
			mem.asmpatch(0x475b55, "mov eax, " .. mem.u4[TablesPtrs+0x14])

			if OldTextCount < NewTextCount
				or OldTopicCount < NewTopicCount then

				RemoveTextsAndTopicsLimits()

			end

			ProcessTeachTopicsTable()
			Game.TeacherTopics = TeacherTopics
			TextsTopicsLoaded = true

		end

	end)

	local TmpVars = mem.StaticAlloc(4)
	local CountEvtLines = mem.asmproc([[
	push eax
	push ecx
	push esi
	xor ecx, ecx
	mov esi, eax
	@start:
	cmp byte [ds:esi], 0
	je @end
	movzx eax, byte [ds:esi]
	add esi, eax
	inc esi
	inc ecx
	jmp @start
	@end:
	mov dword [ds:0x5bb440], ecx
	pop esi
	pop ecx
	pop eax
	retn
	]])

	local LoadGlobalEvt = mem.asmproc([[
	push ebp
	mov ebp, esp
	sub esp, 0xe4
	push esi
	push edi
	mov edi, ecx
	push 0
	push edi
	mov ecx, 0x6fb828
	mov dword [ss:ebp-0x8], edx
	call absolute 0x411c9b;
	call absolute ]] .. CountEvtLines .. [[;
	nop; memhook here
	nop
	nop
	nop
	nop
	jmp absolute 0x440b24
	]])
	mem.asmpatch(0x440bd8, "call absolute " .. LoadGlobalEvt)

	mem.hook(LoadGlobalEvt + 0x1d + 5, function(d)

		NewGlobalEvtSize = mem.u4[d.esp-0x30]
		NewGlEvtLinesCount = mem.u4[0x5bb440]

		if OldGlobalEvtSize < NewGlobalEvtSize or OldGlEvtLinesCount < NewGlEvtLinesCount then

			local NewPtr = RemoveGlobalEvtLimits()

			mem.u4[d.ebp - 0x8] = NewPtr
			mem.u4[d.ebp + 0x8] = NewGlobalEvtSize + 0x10

			return true

		end

	end)

	local function InitNewsTopicsColumn()
		local function GetNewsTopic(i)
			local Base = mem.u4[Game.NPCNews["?ptr"] + i*4]
			local Topic = mem.string(Base + string.len(Game.NPCNews[i]) + 1)

			if Topic == nil then
				return ""
			end

			if string.len(Topic) < 2 then
				Topic = mem.string(Base  + string.len(Game.NPCNews[i]) + 2)
			end

			Topic = string.replace(Topic, "\9", "")
			return Topic
		end

		local ptr = mem.StaticAlloc(Game.NPCNews.count * 4)
		ChangeGameArray("NPCNewsTopics", ptr, Game.NPCNews.count)

		for i, v in Game.NPCNews do
			Game.NPCNewsTopics[i] = GetNewsTopic(i)
		end
	end
	events.GameInitialized2 = InitNewsTopicsColumn

end
