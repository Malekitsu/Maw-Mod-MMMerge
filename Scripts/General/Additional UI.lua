
------------------------------------------
-- Fixes

-- unify basebar ptr
mem.asmpatch(0x4c7662, "push 0x4f4388")
mem.asmpatch(0x4c7edc, "push 0x4f4388")

local UISetsParams = mem.StaticAlloc(18)
-- 1 - show blank stat icon
-- 2 - selring on top
-- 3-6 - stat icon Y
-- 7-10 - X offset
-- 11-14 - selring Y
-- 15-18 - X offset

-- Hostile indicator position

mem.asmpatch(0x4c8046, [[
call absolute 0x491514
test eax, eax
jnz @end

cmp byte [ds:]] .. UISetsParams .. [[], 1
je @equ
jmp @end

@equ:
mov eax, dword [ds:0x519118]
jmp absolute 0x4c807a

@end:
]])

mem.asmpatch(0x4c804f, [[
mov eax, dword [ds:0x519118]
cmp word [ds:edi+0x1bf2], 0
je absolute 0x4c8059

cmp byte [ds:]] .. UISetsParams .. [[], 1
je absolute 0x4c807a
jmp absolute 0x4c80ab
]])

mem.nop(0x4c8057, 2)

mem.asmpatch(0x4c8098, [[
push dword [ds:]] .. UISetsParams + 2 ..[[]
add eax, dword[ds:]] .. UISetsParams + 6 ..[[];]])

mem.asmpatch(0x4c80ea, [[
push dword [ds:]] .. UISetsParams + 2 ..[[]
add eax, dword[ds:]] .. UISetsParams + 6 ..[[];]])

mem.u2[UISetsParams + 2] = 0x1ca

-- Keep showing status icon, despite current phase in turn-based mode.
mem.asmpatch(0x4c7fcd, [[

; If status indicator behaivor overriden:
	mov eax, dword [ds:0x509C9C]
	cmp byte [ds:]] .. UISetsParams .. [[], 1
	jne @default

	; fetch blank status icon pointer.
	mov eax, dword [ds:0x519118]
	mov edx, eax
	inc edx
	neg edx
	sbb edx, edx
	lea eax, dword [ds:eax+eax*8]
	lea eax, dword [ds:0x70D624+eax*8]
	and edx, eax
	push edx

	; setup counter
	xor ecx, ecx
	push ecx

@loop:
	movsx eax, word [ds:ecx*2+0x4FD9D0]
	add eax, dword[ds:]] .. UISetsParams + 6 ..[[]
	sub eax, 8

	; show status icon for each character
	push 0
	push edx
	push dword [ds:]] .. UISetsParams + 2 ..[[]
	push eax
	mov ecx, 0xec1980
	call absolute 0x4A419B

	pop ecx
	pop edx
	inc ecx
	push edx
	push ecx
	cmp ecx, dword [ds:0xB7CA60]
	jl @loop

	pop eax
	pop eax

@default:
	cmp dword [ds:0x509C9C], 0x1
	je absolute 0x4c7fd3

@end:
]])

-- selring position

mem.asmpatch(0x4c7a28, [[
cmp byte [ds:]] .. UISetsParams + 1 .. [[], 0;
je @end
call absolute 0x4c7fbb
@end:
mov ecx, dword [ds:0x519350]
]])

mem.asmpatch(0x4c7ac1, [[
cmp byte [ds:]] .. UISetsParams + 1 .. [[], 0;
jnz @end
call absolute 0x4c7fbb
@end:
]])

mem.asmpatch(0x4c7ab0, [[
push dword [ds:]] .. UISetsParams + 10 .. [[]
mov ebx, dword [ds:]] .. UISetsParams + 14 .. [[]
add dword [ss:ebp-4], ebx
mov ebx, 0]])

mem.u4[UISetsParams + 10] = 0x185

------------------------------------------
-- UI sets table

local function ProcessUITable()

	local TxtTable = io.open("Data/Tables/Additional UI.txt", "r")
	if not TxtTable then
		Game.UISets = {}
		return
	end

	local LineIt = TxtTable:lines()
	LineIt() -- skip header

	local Words
	local UISets = {}

	for line in LineIt do
		Words = string.split(line, "\9")

		UISets[#UISets+1] = {
			LodName 			= Words[2] or "default",
			DLodName			= Words[3] or "",
			ShowBlankIndicator 	= string.lower(Words[4]) == "x",
			IndicatorY 			= tonumber(Words[5]) or 458,
			IndicatorXOffset	= tonumber(Words[6]) or 0,
			SelringOnTop		= string.lower(Words[7]) == "x",
			SelringY			= tonumber(Words[8]) or 389,
			SelringXOffset		= tonumber(Words[9]) or 0,
			}
	end

	io.close(TxtTable)

	Game.UISets = UISets

end

------------------------------------------
-- Base functions

local InterfaceIcons = {
"ARMORY","asiL00","asiL01","asiL02","asiL03","asiL04","asiL05","asiL06","asiL07","asiL08","asiL09","asiL10","asiR00","asiR05","asiR06","backhand","bardata","Basebar","but20D","but20H","but20U","but21D","but21H","but21U","but22D",
"but22H","but22U","but23D","but23H","but23U","but24D","but24H","but24U","but25D","but25H","but25U","but26D","but26H","but26U","butn1d","butn1u","butn2d","butn2u","butn3d","butn3u","butn4d","butn4u","cornr_LL",
"cornr_LR","cornr_UL","cornr_UR","c_close_DN","c_close_ht","c_close_up","c_ok_dn","c_ok_ht","c_ok_up","DIVBAR","edge_btm","edge_lf","edge_rt","edge_top","endcap","evt","evtnpc","FACEMASK","fr_award","fr_inven",
"fr_skill","fr_stats","GENSHELF","ia02-001","ia02-002","ia02-003","ia02-004","ia02-005","ia02-006","ia02-007","ia02-008","ia02-009","ia02-010","IB-8pxbar","Ib-Mb-A","IBshield01","IBshield02","IBshield03","IBshield04",
"IB_spelico","IRB-1","IRB-2","IRB-3","IRB-4","IRBgrnd","IRT01b","IRT01r","IRT02b","IRT02r","IRT03b","IRT03r","IRT04b","IRT04r","IRT05b","IRT05r","IRT06b","IRT06r","IRT07b","IRT07r","IRT08b","IRT08r","IRT09b","IRT09r",
"IRT10b","IRT10r","leather","MAGSHELF","manaB","manaFRM","ManaG","manar","manaY","map+dn","map+ht","map+up","map-dn","map-ht","map-up","mapframe","parchment","QUIKREF","R1hD","R1hH","R1hU","R5mD","R5mH","R5mU","R8hD",
"R8hH","R8hU","RdawnD","RdawnH","RdawnU","restmain","RexitD","RexitH","RexitU","rost_bg","scoreBG","selring","sp21a10","sp21a20","sp21a30","sp21a40","sp21a50","sp21a60","sp21a70","sp21a80","statG","statR","statY", "statbl",
"topbar","topbar2", "UIExample"}

local LoadCustomLod = Game.CustomLods.Load
local FreeCustomLod = Game.CustomLods.Free
local FilesPath = "Data/Additional UI/"
local TmpLods = {}
local ReplaceIcon = CustomUI.ReplaceIcon
local CurrentUI = 1
local DLODPTR = 0x6f330c

local function LoadLod(p, s)
	local res = LoadCustomLod(p, s)
	TmpLods[res] = true
	Log(Merge.Log.Info, "LoadLod: %s, 0x%X", s, res)
	if (Game.PatchOptions.UILayout or "") == "" then
		return
	end
	s = path.setext(s, "."..Game.PatchOptions.UILayout..".lod")
	for s in path.find(s) do
		res = LoadCustomLod(p, s)
		TmpLods[res] = true
		Log(Merge.Log.Info, "LoadLod: %s, 0x%X", s, res)
	end
end

local function ReloadLayout()
	Game.Dll.UILayoutSetVarInt('Merge.UI', CurrentUI)
end

local function LoadUI(i)
	local Old, New, ref

	New = Game.UISets[i]
	if not New then
		return
	end

	for k in pairs(TmpLods) do
		if k ~= 0 then
			FreeCustomLod(k)
		end
	end
	TmpLods = {}

	if New.LodName ~= "default" then
		LoadLod(Game.IconsLod["?ptr"], FilesPath .. New.LodName)
	end
	if New.DLodName ~= "" then
		LoadLod(DLODPTR, FilesPath .. New.DLodName)
	end

	mem.u1[UISetsParams] 	= New.ShowBlankIndicator and 1 or 0
	mem.u1[UISetsParams+1] 	= New.SelringOnTop and 1 or 0
	mem.u4[UISetsParams+2] 	= New.IndicatorY
	mem.u4[UISetsParams+6] 	= New.IndicatorXOffset
	mem.u4[UISetsParams+10]	= New.SelringY
	mem.u4[UISetsParams+14]	= New.SelringXOffset

	for k,v in pairs(InterfaceIcons) do
		ReplaceIcon(v,v)
	end

	CurrentUI = i

	if (Game.PatchOptions.UILayout or "") ~= "" then
		Game.Dll.UILayoutClearCache()
		ReloadLayout()
	end
end
Game.LoadUI = LoadUI

function GetCurrentUI()
	return CurrentUI
end

------------------------------------------
-- Events

function events.GameInitialized1()
	ProcessUITable()
end

function events.LeaveGame()
	Game.LoadUI(1)
end

if (Game.PatchOptions.UILayout or "") ~= "" then
	local cast = require('ffi').cast
	Game.Dll.UILayoutOnLoad(tonumber(cast('int', cast('void (*)()', ReloadLayout))))
end
