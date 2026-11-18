Multiplayer.SESSION_ID_SIZE = 24
Multiplayer.EMPTY_ADDR =  '0.0.0.0'
Multiplayer.EMPTY_ADDRPORT =  '0.0.0.0:0'

Multiplayer.session_code = function(priv, pub)
	priv = priv or Multiplayer.my_private_addr()
	pub = pub or Multiplayer.my_public_addr()
	local result = {}

	for _, line in pairs({priv, pub}) do
		local addr, port = line:match("(%A*):(%d*)")
		local a,b,c,d = addr:match("(%d*).(%d*).(%d*).(%d*)")
		for i, v in ipairs({a,b,c,d}) do
			table.insert(result, bit.tohex(tonumber(v), 2))
		end
		table.insert(result, bit.tohex(tonumber(port or 0), 4))
	end
	return table.concat(result, '')
end

Multiplayer.my_session_code = function()
	return Multiplayer.session_code(Multiplayer.my_private_addr(), Multiplayer.my_public_addr())
end

Multiplayer.addr_from_session_code = function(session_code)
	local function numhex(str)
		return tonumber('0x' .. str)
	end

	local function toaddr(hexstr)
		local parts = {numhex(hexstr:sub(1,2)), numhex(hexstr:sub(3,4)), numhex(hexstr:sub(5,6)), numhex(hexstr:sub(7,8))}
		return string.format("%s:%s", table.concat(parts, '.'), numhex(hexstr:sub(9)))
	end

	local priv, pub = session_code:sub(1, 12), session_code:sub(13)
	return toaddr(priv), toaddr(pub)
end
