
local OldGame = structs.f.GameStructure
local OldParty = structs.f.GameParty
local OldMap = structs.f.GameMap

function structs.f.GameStructure(define)
	OldGame(define)
	define
	[0x6f3784].array(4).r4 'SpeedModifiers'
	[0x4e87b0].struct(structs.PartyLight) 'PartyLight'

	if not define.members.GlobalTxt then
		define
		[0x601448].array(750).EditPChar 'GlobalTxt'
	end

	if not define.members.TransTxt then
		define
		[0x4fade4].array(500).EditPChar 'TransTxt'
	end

	if not define.members.TurnBasedState then
		define
		[0x509C98].struct(structs.TurnBasedState) 'TurnBasedState'
	end

	if not define.members.TurnBasedQueue then
		define
		[0x509cb8].array{64, lenA = mem.i4, lenP = 0x509ca4}.struct(structs.TurnBasedQueueItem) 'TurnBasedQueue'
	end

	-- News topic column of NPCNews.txt, initialized in RemoveNPCTablesLimits.lua
	if not define.members.NPCNewsTopics then
		define
		[0x778F50].array(50).EditPChar 'NPCNewsTopics'
	end
end

function structs.f.GameMap(define)
	OldMap(define)
	if not define.members.BloodSplats then
		define
		[0x521f10].array{64, lenA = mem.i4, lenP = 0x52290C}.struct(structs.BloodSplat) 'BloodSplats'
		[0x52290C].u4 'BloodSplatsCount'
		[0x522910].u4 'BloodSplatsCreated'


		function CreateBloodSplat(X, Y, Z, R, G, B, radius, unk1, unk2, unk3)
			local buff = mem.topointer("\0\0\0\0")
			local function r4asint(n)
				mem.r4[buff] = n
				return mem.u4[buff]
			end

			return mem.call(0x498909, 1,
				unk1 or 0xbb5940,
				r4asint(X), r4asint(Y), r4asint(Z),
				r4asint(R or 1), r4asint(G or 0), r4asint(B or 0),
				r4asint(radius or 60), r4asint(unk2 or 0), r4asint(unk3 or 0))
		end
	end
end

function structs.f.GameParty(define)
	OldParty(define)
	define
	[0xb2160e].u1 'DaysWithoutRest'
end

local function EditPLight(o, obj, Name, val)
	local Adr = Name == "Radius" and 0x4e87b0 or 0x4e87b4
	if val == nil then
		return mem.r4[Adr]
	else
		mem.IgnoreProtection(true)
		mem.r4[Adr] = val
		mem.IgnoreProtection(false)
	end
end

function structs.f.PartyLight(define)
   define
   .CustomType('Radius', 0, EditPLight)
   .CustomType('Falloff', 0, EditPLight)
end

function structs.f.BloodSplat(define)
	define
	.r4 'X'
	.r4 'Y'
	.r4 'Z'
	.r4 'Radius'
	.r4 'unk5'
	.u1 'R'
	.u1 'G'
	.u1 'B'
	.u1 'unk6'
	.u4 'unk7'
	.u4 'unk8'
	.u4 'unk9'
	.u4 'unk10'
end

function structs.f.TurnBasedState(define)
	define
	.u4 'RoundNumber'
	.u4 'Phase'
	.u4 'RoundLength'
	.u4 'ParticipantsCount'
	.u4 'CombatTimeLeft'
	.u4 'PartyMoveTimeLeft'
	.u4 'unk5'
	.u4 'unk6'
end

function structs.f.TurnBasedQueueItem(define)
	define
	.u4 'EntityRef'
	.u4 'RecoveryDelay' -- subtracted from CombatTimeLeft of TurnBasedState
	.u4 'unk2' -- Changed after mon took damage. Always 0 for player. Animation frames for monster?
	.u4 'NextQueueItemId' -- Always 2 for party members - thus skips one item below current, if entity at id is monster during combat phase, queue goes below till player found
	.CustomType('Kind', 0, function(o, obj, Name, val)
		return bit.And(obj.EntityRef, 7)
	end)
	.CustomType('Index', 0, function(o, obj, Name, val)
		return bit.rshift(obj.EntityRef, 3)
	end)
end

--function dump_queue()
--	print("round:", Game.TurnBasedState.RoundNumber, Game.TurnBasedState.Phase, Game.TurnBasedState.RoundLength, Game.TurnBasedState.CombatTimeLeft)
--	for i, v in Game.TurnBasedQueue do
--		print(i, v.Kind, v.Index, v.RecoveryDelay, v.unk2, v.NextQueueItemId)
--	end
--end
