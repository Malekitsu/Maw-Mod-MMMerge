local events = Multiplayer.events

local SyncPlayers = Multiplayer.require("Synchronization/Players.lua")

local function ShowTextRight(Text, X, Y)
	local str = StrRight(640 - X) .. Text
	CustomUI.ShowText(str, Game.Smallnum_fnt, 0, 0, 3, 640, 480, 0, Y, 0xFFFF, 0, true, 640, 480)
end

local function npc_pic_name(id)
	local str = tostring(id)
	return 'npc' .. ('0000'):sub(#str + 1) .. str
end

local function show_clients_in_house(info)
	local baseX = 400
	local baseY = 288
	local lineHeight = 80
	
	local count = 0
	for _, v in pairs(info) do
		local h = baseY - count * lineHeight
		CustomUI.ShowIcon(npc_pic_name(v.pic_id or 670), baseX, h) -- NPC icon of client's character
		if v.talking_to then
			local msg = ("%s (speaking with %s)"):format(v.name or "Player", Game.NPC[v.talking_to].Name)
			ShowTextRight(msg, baseX, h)
		else
			ShowTextRight(v.name or "Player", baseX, h)
		end
		count = count + 1
	end
	
	if count > 0 then
		ShowTextRight("Other players in house:", baseX + 76, baseY - (count - 1) * lineHeight - 20)
	end
end
--[[
function events.BGInterfaceUpd()
	if Game.CurrentScreen ~= const.Screens.House then
		return
	end
	
	local house = GetCurrentHouse()
	local clients_in_houses = SyncPlayers.clients_in_houses()
	local blocked_npcs = Multiplayer.blocked_npcs()
	
	local info = {}
	for client_id, house_id in pairs(clients_in_houses) do
		if house_id == house then
			local client_info = SyncPlayers.client_info(client_id)
			local pic_id = client_info.face and Game.CharacterPortraits[client_info.face].NPCPic or 1516
			table.insert(info, {name = client_info.name or "", pic_id = pic_id, talking_to = blocked_npcs[client_id]})
		end
	end

	if #info > 0 then
		show_clients_in_house(info)
	end	
end
]]
