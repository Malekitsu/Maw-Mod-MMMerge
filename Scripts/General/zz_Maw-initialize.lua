--MAW SETTING HERE
autoTargetHeals=true
ColouredStats=true
chargeKey=69
healthPotionKey=71
manaPotionKey=86
Game.PatchOptions.FixMonstersBlockingShots=true
buffRework=true
restoreMM6Glory=true
disableDamageOnFriendlyUnits=true
disableHomingProjectiles=false
austerity=false

--sorting buttons
currentBagSortKey=82
partyBagSortKey=84
multiBagSortKey=67
partyMultyBagSortKey=71
AlchemyBagKey=69

function events.GameInitialized2()
	if Game.ItemsTxt[1466].Name=="Emerald Island" then
		isRedone=true
	end
	for i=0,11 do
		Skillz.setDesc(i,1,Skillz.getDesc(i,1) .. "\n")
	end
end

--custom rounding function, as math.round is capped to 2^32
function round(x)
	if x%1>=0.5 then
		x=x-x%1+1
	else
		x=x-x%1
	end
	return x
end

function shortenNumber(number, significantDigits, color)
    if significantDigits < 1 then
        error("Number of digits needs to be at least 1")
    end

    local suffix = ""
    local divisor = 1

    if math.abs(number) >= 10^(9+math.max(0,significantDigits-3)) then
        suffix = "B"
        divisor = 1e9
    elseif math.abs(number) >= 10^(6+math.max(0,significantDigits-3)) then
        suffix = "M"
        divisor = 1e6
    elseif math.abs(number) >= 10^(3+math.max(0,significantDigits-3)) then
        suffix = "K"
        divisor = 1e3
    end

    local shortened = math.round(number / divisor)

	if color then
		if suffix == "K" then
			local txt=StrColor(255,255,30,tostring(shortened) .. suffix)
			return txt
		end
		if suffix == "M" then
			local txt=StrColor(255,165,0,tostring(shortened) .. suffix)
			return txt
		end
		if suffix == "B" then
			local txt=StrColor(255,0,0,tostring(shortened) .. suffix)
			return txt
		end
	end
	
    return tostring(shortened) .. suffix
end



---------------------------------
--HERE IS THE KEYBIND LIST--
---------------------------------
--[[
LBUTTON= 1	
RBUTTON= 2	
CANCEL= 3	
MBUTTON= 4	NOT contiguous with L & RBUTTON
XBUTTON1= 5	
XBUTTON2= 6	
BACK= 8	
BACKSPACE= 8	
TAB= 9	
CLEAR= 12	
ENTER= 13	
RETURN= 13	
SHIFT= 16	
CONTROL= 17	
CTRL= 17	
ALT= 18	
MENU= 18	
PAUSE= 19	
CAPITAL= 20	
CAPSLOCK= 20	
HANGUL= 21	
KANA= 21	
JUNJA= 23	
FINAL= 24	
HANJA= 25	
KANJI= 25	
ESCAPE= 27	
CONVERT= 28	
NONCONVERT= 29	
ACCEPT= 30	
MODECHANGE= 31	
SPACE= 32	
PGUP= 33	
PRIOR= 33	
NEXT= 34	
PGDN= 34	
END= 35	
HOME= 36	
LEFT= 37	
UP= 38	
RIGHT= 39	
DOWN= 40	
SELECT= 41	
PRINT= 42	
EXECUTE= 43	
SNAPSHOT= 44	
INSERT= 45	
DELETE= 46	
HELP= 47	
0= 48	
1= 49	
2= 50	
3= 51	
4= 52	
5= 53	
6= 54	
7= 55	
8= 56	
9= 57	
A= 65	
B= 66	
C= 67	
D= 68	
E= 69	
F= 70	
G= 71	
H= 72	
I= 73	
J= 74	
K= 75	
L= 76	
M= 77	
N= 78	
O= 79	
P= 80	
Q= 81	
R= 82	
S= 83	
T= 84	
U= 85	
V= 86	
W= 87	
X= 88	
Y= 89	
Z= 90	
LWIN= 91	
RWIN= 92	
APPS= 93	
SLEEP= 95	
NUMPAD0= 96	
NUMPAD1= 97	
NUMPAD2= 98	
NUMPAD3= 99	
NUMPAD4= 100	
NUMPAD5= 101	
NUMPAD6= 102	
NUMPAD7= 103	
NUMPAD8= 104	
NUMPAD9= 105	
MULTIPLY= 106	
ADD= 107	
SEPARATOR= 108	
SUBTRACT= 109	
DECIMAL= 110	
DIVIDE= 111	
F1= 112	
F2= 113	
F3= 114	
F4= 115	
F5= 116	
F6= 117	
F7= 118	
F8= 119	
F9= 120	
F10= 121	
F11= 122	
F12= 123	
F13= 124	
F14= 125	
F15= 126	
F16= 127	
F17= 128	
F18= 129	
F19= 130	
F20= 131	
F21= 132	
F22= 133	
F23= 134	
F24= 135	
NUMLOCK= 144	
SCROLL= 145	
SCROLLLOCK= 145	
LSHIFT= 160	
RSHIFT= 161	
LCONTROL= 162	
RCONTROL= 163	
LMENU= 164	
RMENU= 165	
BROWSER_BACK= 166	
BROWSER_FORWARD= 167	
BROWSER_REFRESH= 168	
BROWSER_STOP= 169	
BROWSER_SEARCH= 170	
BROWSER_FAVORITES= 171	
BROWSER_HOME= 172	
VOLUME_MUTE= 173	
VOLUME_DOWN= 174	
VOLUME_UP= 175	
MEDIA_NEXT_TRACK= 176	
MEDIA_PREV_TRACK= 177	
MEDIA_STOP= 178	
MEDIA_PLAY_PAUSE= 179	
LAUNCH_MAIL= 180	
LAUNCH_MEDIA_SELECT= 181	
LAUNCH_APP1= 182	
LAUNCH_APP2= 183	
OEM_1= 186	
OEM_PLUS= 187	
OEM_COMMA= 188	
OEM_MINUS= 189	
OEM_PERIOD= 190	
OEM_2= 191	
OEM_3= 192	
OEM_4= 219	
OEM_5= 220	
OEM_6= 221	
OEM_7= 222	
OEM_8= 223	
OEM_102= 226	
PROCESSKEY= 229	
PACKET= 231	
ATTN= 246	
CRSEL= 247	
EXSEL= 248	
EREOF= 249	
PLAY= 250	
ZOOM= 251	
NONAME= 252	
PA1= 253	
OEM_CLEAR= 254
]]
