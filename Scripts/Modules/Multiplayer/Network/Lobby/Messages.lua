
local LOBBY_COOKIE = 0x10bb40ff
local DEFAULT_LAN_PORT = 4445
local LAN_LOBBY_PORT, LAN_LOBBY, T = DEFAULT_LAN_PORT, "", nil

local function SetPort(port)
	LAN_LOBBY_PORT = port
	LAN_LOBBY = "255.255.255.255:" .. tostring(LAN_LOBBY_PORT)
	
	T.LAN_LOBBY_PORT = LAN_LOBBY_PORT
	T.LAN_LOBBY = LAN_LOBBY
end

local MSG_TYPES = {
	MsgHostInfo           = 1,
	MsgHostsListRequest   = 2,
	MsgHostsListResponse  = 3,
	MsgJoinLobby          = 4,
	MsgHostJoinResponse   = 5,
	MsgErrorResponse      = 6,
}

------------------------------------
-- Utils

local function ReadString(bin_string)
	local ptr = mem.topointer(bin_string)
	local len = mem.u2[ptr]
	if len > #bin_string then
		return nil
	end
	return mem.string(ptr + 2, len, true)
end

local function ReadStrings(bin_string, t, fields)
	local shift = 1
	for i, field in ipairs(fields) do
		local str = ReadString(bin_string:sub(shift))
		if str == nil then
			return false, "Could not read strings, stopped on " .. field
		end
		shift = shift + 2 + #str
		t[field] = str
	end
	return true
end

local function WriteString(ptr, str)
	mem.u2[ptr] = #str
	mem.copy(ptr+2, str)
	return #str + 2
end

local function WriteStrings(ptr, t, fields)
	local shift = 0
	for i, field in ipairs(fields) do
		shift = shift + WriteString(ptr + shift, t[field])
	end
	return shift
end

local function ErrSizeLess(got, expect)
	return ("Size of binary data is less than minimal necessary: %d / %d"):format(got, expect)
end

------------------------------------
-- Header

local function Header(msg_type)
	local ptr = Multiplayer.utils.sendbuff
	mem.u4[ptr] = LOBBY_COOKIE
	mem.u1[ptr+4] = msg_type
	return mem.string(ptr, 5, true)
end

------------------------------------
-- HostInfo

-- returns empty structure with predefined fields
local function NewHostInfo()
	local info = {
		Players = 0,
		MaxPlayers = 0,
		PasswordUsed = false,
		Active = false,
		Name = "",
		Version = Multiplayer.VERSION,
		Description = "",
		SessionCode = "",
		LAN = false,
	}
	return info
end

-- reads from host infos struct from bin array
-- returns struct, amount of bytes read, error if any (nil - if no errors)
local function ReadHostInfo(bin_string)
	if #bin_string < 14 then
		return nil, 0, ErrSizeLess(#bin_string, 14)
	end

	local ptr = mem.topointer(bin_string)
	local t = {
		Players = mem.u2[ptr],
		MaxPlayers = mem.u2[ptr+2],
		PasswordUsed = mem.u1[ptr+4] > 0,
		Active = mem.u1[ptr+5] > 0,
		LAN = mem.u1[ptr+5] == 255,
		Name = "",
		Version = "",
		Description = "",
		SessionCode = "",
	}

	local success, err = ReadStrings(bin_string:sub(7), t, {"Name", "Version", "Description", "SessionCode"})
	if not success then
		return nil, 0, err
	end
	return t, 14 + #t.Name + #t.Version + #t.Description + #t.SessionCode, nil
end

-- serializes host info struct into bin string in a way, remote lobby server could accept it
local function HostInfoToBin(t)
	local ptr = Multiplayer.utils.sendbuff
	mem.u2[ptr] = t.Players
	mem.u2[ptr+2] = t.MaxPlayers
	mem.u1[ptr+4] = t.PasswordUsed and 1 or 0
	mem.u1[ptr+5] = t.Active and (t.LAN and 255 or 1) or 0

	local n = WriteStrings(ptr + 6, t, {"Name", "Version", "Description", "SessionCode"})
	return mem.string(ptr, n + 6, true)
end

------------------------------------
-- Lobby selection

local function NewHostSelection(SkipPassword, SkipFull, Offset, Limit, Version)
	local t = {
		SkipPassword = SkipPassword or false,
		SkipFull = SkipFull or false,
		Offset = Offset or 0,
		Limit = Limit or 0,
		Version = Version or Multiplayer.VERSION
	}
	return t
end

local function HostSelectionBin(t)
	local ptr = Multiplayer.utils.sendbuff
	mem.u1[ptr] = t.SkipPassword and 1 or 0
	mem.u1[ptr+1] = t.SkipFull and 1 or 0
	mem.u4[ptr+2] = t.Offset
	mem.u4[ptr+6] = t.Limit
	local n = WriteString(ptr+10, t.Version)
	return mem.string(ptr, n + 10, true)
end

local function ReadHostSelection(bin_string)
	if #bin_string < 12 then
		return nil, 0, ErrSizeLess(#bin_string, 12)
	end

	local ptr = mem.topointer(bin_string)
	local t = {
		SkipPassword = mem.u1[ptr] > 0,
		SkipFull = mem.u1[ptr+1] > 0,
		Offset = mem.u4[ptr+2],
		Limit = mem.u4[ptr+6],
		Version = ""
	}

	local success, err = ReadStrings(bin_string:sub(11), t, {"Version"})
	if not success then
		return nil, 0, err
	end
	return t, 12 + #t.Version, nil
end

------------------------------------
-- Join request

local function NewJoinRequest(HostSessionCode, SessionCode, Password)
	return {
		HostSessionCode = HostSessionCode or "",
		SessionCode = SessionCode or "",
		Password = Password or ""
	}
end

local function JoinLobbyRequestBin(t)
	local ptr = Multiplayer.utils.sendbuff
	local n = WriteStrings(ptr, t, {"HostSessionCode", "SessionCode", "Password"})
	return mem.string(ptr, n, true)
end

local function ReadJoinRequest(bin_string)
	if #bin_string < 6 then
		return nil, 0, ErrSizeLess(#bin_string, 6)
	end

	local t = NewJoinRequest()
	local success, err = ReadStrings(bin_string, t, {"HostSessionCode", "SessionCode", "Password"})
	if not success then
		return nil, 0, err
	end
	return t, 6 + #t.HostSessionCode + #t.SessionCode + #t.Password, nil
end

------------------------------------
-- Join response

local function NewJoinResponse(Result, SessionCode, Reason)
	return {
		Result = Result or false,
		SessionCode = SessionCode or "",
		Reason = Reason or ""
	}
end

local function JoinResponseBin(t)
	local ptr = Multiplayer.utils.sendbuff
	mem.u1[ptr] = t.Result and 1 or 0
	local n = WriteStrings(ptr+1, t, {"SessionCode", "Reason"})
	return mem.string(ptr, n + 1, true)
end

local function ReadJoinResponse(bin_string)
	if #bin_string < 5 then
		return nil, 0, ErrSizeLess(#bin_string, 5)
	end

	local t = NewJoinResponse(mem.u1[mem.topointer(bin_string)] > 0)
	local success, err = ReadStrings(bin_string:sub(2), t, {"SessionCode", "Reason"})
	if not success then
		return nil, 0, err
	end
	return t, 5 + #t.SessionCode + #t.Reason, nil
end

------------------------------------
-- Error response

local function ErrorResponseBin(err)
	local ptr = Multiplayer.utils.sendbuff
	return mem.string(ptr, WriteString(ptr, err), true)
end

local function ReadErrorResponse(bin_string)
	return ReadString(bin_string)
end

------------------------------------

T = {
	LAN_LOBBY_PORT = LAN_LOBBY_PORT,
	LAN_LOBBY = LAN_LOBBY,
	DEFAULT_LAN_PORT = DEFAULT_LAN_PORT,
	LOBBY_COOKIE = LOBBY_COOKIE,
	
	SetPort = SetPort,

	Types = MSG_TYPES,
	Header = Header,

	NewHostInfo = NewHostInfo,
	HostInfoToBin = HostInfoToBin,
	ReadHostInfo = ReadHostInfo,

	NewHostSelection = NewHostSelection,
	HostSelectionBin = HostSelectionBin,
	ReadHostSelection = ReadHostSelection,

	NewJoinRequest = NewJoinRequest,
	JoinLobbyRequestBin = JoinLobbyRequestBin,
	ReadJoinRequest = ReadJoinRequest,

	NewJoinResponse = NewJoinResponse,
	JoinResponseBin = JoinResponseBin,
	ReadJoinResponse = ReadJoinResponse,

	ErrorResponseBin = ErrorResponseBin,
	ReadErrorResponse = ReadErrorResponse,
}

SetPort(DEFAULT_LAN_PORT)

return T
