local u4, mstr, toptr = mem.u4, mem.string, mem.topointer

local compress_buff = 0
local compress_buff_size = 0
local compress_max_size = mem.StaticAlloc(4)

local function resize_compress_buff(new_size)
	if compress_buff_size < new_size then
		mem.free(compress_buff)
		compress_buff = mem.malloc(new_size + 5)
		compress_buff_size = new_size
	end
end

local function compress(str)
	u4[compress_max_size] = #str
	resize_compress_buff(#str)

	local result = Game.Compress(compress_buff + 4, compress_max_size, toptr(str), #str)
	if result == 0 then
		u4[compress_buff] = #str
		return mstr(compress_buff, u4[compress_max_size] + 4, true)
	else
		return Multiplayer.utils.num_to_hexstr(0, 4) .. str
	end
end

local function decompress(str)
	if #str < 4 then
		return str
	end

	local ptr = toptr(str)
	local unc_size = u4[ptr]

	if unc_size == 0 then
		return string.sub(str, 5)
	else
		u4[compress_max_size] = unc_size
		resize_compress_buff(unc_size)

		Game.Uncompress(compress_buff, compress_max_size, ptr + 4, #str - 4)
		return mstr(compress_buff, unc_size, true)
	end
end

return {
	compress = compress,
	decompress = decompress
}

--~ test = Multiplayer.utils.mmt_dump(Map.Monsters[0])
--~ print(#test)
--~ tdump = Multiplayer.compress(test)
--~ print(#tdump)
--~ tdec = Multiplayer.decompress(tdump)
--~ print(#tdec)
