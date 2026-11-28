if jit and jit.off then
    jit.off(true, true)
end

local ffi = require("ffi")
local u4, i4, r4, call = mem.u4, mem.i4, mem.r4, mem.call

local M = {}

local DirectDrawField = 0x20
local DeviceField = 0x38
local IID_IDirect3DTexture2 = 0x4EB9C0
local RenderRectFallback = 0xFFDE9C

local COM_QueryInterface, COM_Release = 0x00, 0x08
local DD_CreateSurface = 0x18
local Surface_Lock, Surface_Unlock = 0x64, 0x80
local Dev_GetRenderState, Dev_SetRenderState = 0x54, 0x58
local Dev_DrawPrimitive = 0x70
local Dev_GetTexture, Dev_SetTexture = 0x94, 0x98
local Dev_GetStageState, Dev_SetStageState = 0x9C, 0xA0

local DescSize = 0x7C
local Desc_Flags, Desc_Height, Desc_Width, Desc_Pitch, Desc_Surface = 0x04, 0x08, 0x0C, 0x10, 0x24
local Desc_PixelFormat, Desc_Caps, Desc_Caps2 = 0x48, 0x68, 0x6C
local PF_Size, PF_Flags, PF_BitCount = 0x00, 0x04, 0x0C
local PF_RMask, PF_GMask, PF_BMask, PF_AMask = 0x10, 0x14, 0x18, 0x1C
local DDSD_CAPS, DDSD_HEIGHT, DDSD_WIDTH, DDSD_PIXELFORMAT = 0x1, 0x2, 0x4, 0x1000
local DDPF_ALPHAPIXELS, DDPF_RGB = 0x1, 0x40
local DDSCAPS_TEXTURE, DDSCAPS2_TEXTUREMANAGE = 0x1000, 0x10
local DDLOCK_WAIT = 0x1

local D3DPT_TRIANGLEFAN, D3DFVF_TLVERTEX = 6, 0x1C4
local D3DDP_DONOTUPDATEEXTENTS, D3DDP_DONOTLIGHT = 8, 16
local VertexSize = 32

local RS_ZWRITEENABLE, RS_ALPHATESTENABLE, RS_SRCBLEND, RS_DESTBLEND = 14, 15, 19, 20
local RS_CULLMODE, RS_ZFUNC, RS_ALPHABLENDENABLE, RS_FOGENABLE = 22, 23, 27, 28
local RS_STENCILENABLE, RS_WRAP0 = 52, 128
local BLEND_ONE, BLEND_INVSRCALPHA, CULL_NONE, CMP_ALWAYS = 2, 6, 1, 8
local TSS_COLOROP, TSS_COLORARG1, TSS_COLORARG2 = 1, 2, 3
local TSS_ALPHAOP, TSS_ALPHAARG1, TSS_ALPHAARG2 = 4, 5, 6
local TSS_ADDRESSU, TSS_ADDRESSV, TSS_MAGFILTER, TSS_MINFILTER, TSS_MIPFILTER = 13, 14, 16, 17, 18
local TOP_DISABLE, TOP_MODULATE, TA_DIFFUSE, TA_TEXTURE = 1, 4, 0, 2
local TADDRESS_CLAMP, TFG_LINEAR, TFN_LINEAR, TFP_NONE = 3, 2, 2, 1

local MaxTileWidth, MinTileWidth, MinTileHeight, TileAspect = 2048, 256, 64, 4

local renderStates = {
    {RS_ZWRITEENABLE, 0}, {RS_ALPHATESTENABLE, 0}, {RS_ALPHABLENDENABLE, 1},
    {RS_SRCBLEND, BLEND_ONE}, {RS_DESTBLEND, BLEND_INVSRCALPHA}, {RS_CULLMODE, CULL_NONE},
    {RS_ZFUNC, CMP_ALWAYS}, {RS_FOGENABLE, 0}, {RS_STENCILENABLE, 0}, {RS_WRAP0, 0},
}

local stageStates = {
    {0, TSS_COLOROP, TOP_MODULATE}, {0, TSS_COLORARG1, TA_TEXTURE}, {0, TSS_COLORARG2, TA_DIFFUSE},
    {0, TSS_ALPHAOP, TOP_MODULATE}, {0, TSS_ALPHAARG1, TA_TEXTURE}, {0, TSS_ALPHAARG2, TA_DIFFUSE},
    {0, TSS_ADDRESSU, TADDRESS_CLAMP}, {0, TSS_ADDRESSV, TADDRESS_CLAMP},
    {0, TSS_MAGFILTER, TFG_LINEAR}, {0, TSS_MINFILTER, TFN_LINEAR}, {0, TSS_MIPFILTER, TFP_NONE},
    {1, TSS_COLOROP, TOP_DISABLE}, {1, TSS_ALPHAOP, TOP_DISABLE},
}

local desc = mem.StaticAlloc(DescSize)
local outPtr = mem.StaticAlloc(4)
local quad = mem.StaticAlloc(4 * VertexSize)
local savedRender, savedStage = {}, {}
local renderRectPtr

local function method(obj, offset)
    return u4[u4[obj] + offset]
end

local function release(obj)
    if obj ~= 0 then
        call(method(obj, COM_Release), 0, obj)
    end
end

local function hex(hr)
    return string.format("%08X", hr % 0x100000000)
end

local function renderRect()
    if not renderRectPtr then
        local po = Game.PatchOptions
        renderRectPtr = po.Present("RenderRectLeft") and po["?ptr"] + structs.o.PatchOptions.RenderRectLeft or RenderRectFallback
    end
    return renderRectPtr
end

local function nextPow2(n)
    local p = 1
    while p < n do
        p = p * 2
    end
    return p
end

local function lock(surface)
    mem.fill(desc, DescSize, 0)
    u4[desc] = DescSize
    local hr = call(method(surface, Surface_Lock), 0, surface, 0, desc, DDLOCK_WAIT, 0)
    if hr ~= 0 then
        return nil, hr
    end
    return u4[desc + Desc_Surface], i4[desc + Desc_Pitch]
end

local function unlock(surface)
    call(method(surface, Surface_Unlock), 0, surface, 0)
end

local function createTexture(dd, w, h)
    mem.fill(desc, DescSize, 0)
    u4[desc] = DescSize
    u4[desc + Desc_Flags] = DDSD_CAPS + DDSD_HEIGHT + DDSD_WIDTH + DDSD_PIXELFORMAT
    u4[desc + Desc_Height] = h
    u4[desc + Desc_Width] = w
    local pf = desc + Desc_PixelFormat
    u4[pf + PF_Size] = 32
    u4[pf + PF_Flags] = DDPF_RGB + DDPF_ALPHAPIXELS
    u4[pf + PF_BitCount] = 32
    u4[pf + PF_RMask] = 0x00FF0000
    u4[pf + PF_GMask] = 0x0000FF00
    u4[pf + PF_BMask] = 0x000000FF
    u4[pf + PF_AMask] = 0xFF000000
    u4[desc + Desc_Caps] = DDSCAPS_TEXTURE
    u4[desc + Desc_Caps2] = DDSCAPS2_TEXTUREMANAGE
    u4[outPtr] = 0
    local hr = call(method(dd, DD_CreateSurface), 0, dd, desc, outPtr, 0)
    if hr ~= 0 then
        return nil, "CreateSurface " .. w .. "x" .. h .. " failed: " .. hex(hr)
    end
    local surface = u4[outPtr]
    u4[outPtr] = 0
    hr = call(method(surface, COM_QueryInterface), 0, surface, IID_IDirect3DTexture2, outPtr)
    if hr ~= 0 then
        release(surface)
        return nil, "QueryInterface(IDirect3DTexture2) failed: " .. hex(hr)
    end
    local texture = u4[outPtr]
    local bits, pitch = lock(surface)
    if not bits then
        release(texture)
        release(surface)
        return nil, "Lock failed: " .. hex(pitch)
    end
    mem.fill(bits, pitch * h, 0)
    unlock(surface)
    return {surface = surface, texture = texture}
end

local function releaseList(tiles)
    for _, t in ipairs(tiles) do
        release(t.texture)
        release(t.surface)
    end
end

local function vertex(p, x, y, u, v)
    r4[p], r4[p + 4], r4[p + 8], r4[p + 12] = x, y, 0, 1
    u4[p + 16], u4[p + 20] = 0xFFFFFFFF, 0
    r4[p + 24], r4[p + 28] = u, v
end

local Target = {}
Target.__index = Target

function M.create(width, height, gdi)
    if not (Game and Game.IsD3D and Game.RendererD3D ~= 0) then
        return nil
    end
    local self = setmetatable({
        width = math.max(1, math.floor(width)),
        height = math.max(1, math.floor(height)),
        visible = true,
        in_game = true,
        gdi = gdi,
        uploaded = false,
        failed = false,
    }, Target)
    self.surface = gdi.create_dib_surface(self.width, self.height)
    self.render = function()
        self:draw()
    end
    events.PostRender = self.render
    return self
end

function Target:fail(err)
    if self.failed then
        return
    end
    self.failed = true
    print("[overlay-d3d] " .. tostring(err))
    Game.ShowStatusText("MAW overlay: in-game drawing failed, see MMExtensionLog.txt")
end

function Target:currentDirectDraw()
    local renderer = Game.RendererD3D
    return renderer ~= 0 and u4[renderer + DirectDrawField] or 0
end

function Target:releaseTiles()
    if self.tiles and self.dd == self:currentDirectDraw() then
        releaseList(self.tiles)
    end
    self.tiles, self.uploaded = nil, false
end

function Target:buildTiles()
    local dd = self:currentDirectDraw()
    if dd == 0 then
        return false
    end
    if self.tiles and self.dd == dd then
        return true
    end
    self.tiles, self.uploaded = nil, false
    local err
    local tileW = math.min(MaxTileWidth, nextPow2(self.width))
    while tileW >= MinTileWidth do
        local tileH = math.max(MinTileHeight, math.min(tileW / TileAspect, nextPow2(self.height)))
        local tiles = {}
        err = nil
        for y = 0, self.height - 1, tileH do
            for x = 0, self.width - 1, tileW do
                local t
                t, err = createTexture(dd, tileW, tileH)
                if not t then
                    break
                end
                t.x, t.y = x, y
                t.w, t.h = math.min(tileW, self.width - x), math.min(tileH, self.height - y)
                tiles[#tiles + 1] = t
            end
            if err then
                break
            end
        end
        if not err then
            self.tiles, self.dd, self.tileW, self.tileH = tiles, dd, tileW, tileH
            local rect = renderRect()
            print(string.format("[overlay-d3d] %d textures %dx%d for %dx%d, view (%d,%d)-(%d,%d)", #tiles, tileW, tileH,
                self.width, self.height, i4[rect], i4[rect + 4], i4[rect + 8], i4[rect + 12]))
            return true
        end
        releaseList(tiles)
        print("[overlay-d3d] " .. err)
        tileW = tileW / 2
    end
    self:fail("no texture size could be created, in-game drawing disabled")
    return false
end

function Target:upload()
    if not self:buildTiles() then
        return
    end
    local src = tonumber(ffi.cast("uint32_t", self.surface.bits))
    local stride = self.width * 4
    for _, t in ipairs(self.tiles) do
        local bits, pitch = lock(t.surface)
        if bits then
            local from, bytes = src + t.y * stride + t.x * 4, t.w * 4
            for row = 0, t.h - 1 do
                mem.copy(bits + row * pitch, from + row * stride, bytes)
            end
            unlock(t.surface)
        end
    end
    self.uploaded = true
end

function Target:present()
    if not self.visible or self.failed or not self.surface then
        return
    end
    local ok, err = pcall(self.upload, self)
    if not ok then
        self:fail(err)
    end
end

function Target:drawTiles(dev)
    local rect = renderRect()
    local left, top = i4[rect], i4[rect + 4]
    local sx, sy = (i4[rect + 8] - left) / self.width, (i4[rect + 12] - top) / self.height
    local setTexture, drawPrimitive = method(dev, Dev_SetTexture), method(dev, Dev_DrawPrimitive)
    for _, t in ipairs(self.tiles) do
        local x1, y1 = left + t.x * sx - 0.5, top + t.y * sy - 0.5
        local x2, y2 = left + (t.x + t.w) * sx - 0.5, top + (t.y + t.h) * sy - 0.5
        local u2, v2 = t.w / self.tileW, t.h / self.tileH
        vertex(quad, x1, y1, 0, 0)
        vertex(quad + VertexSize, x2, y1, u2, 0)
        vertex(quad + 2 * VertexSize, x2, y2, u2, v2)
        vertex(quad + 3 * VertexSize, x1, y2, 0, v2)
        call(setTexture, 0, dev, 0, t.texture)
        call(drawPrimitive, 0, dev, D3DPT_TRIANGLEFAN, D3DFVF_TLVERTEX, quad, 4, D3DDP_DONOTUPDATEEXTENTS + D3DDP_DONOTLIGHT)
    end
end

function Target:draw()
    if not self.visible or not self.uploaded or self.failed then
        return
    end
    local renderer = Game.RendererD3D
    if renderer == 0 or u4[renderer + DirectDrawField] ~= self.dd then
        return
    end
    local dev = u4[renderer + DeviceField]
    if dev == 0 then
        return
    end
    local getRS, setRS = method(dev, Dev_GetRenderState), method(dev, Dev_SetRenderState)
    local getTS, setTS = method(dev, Dev_GetStageState), method(dev, Dev_SetStageState)
    for i, s in ipairs(renderStates) do
        savedRender[i] = call(getRS, 0, dev, s[1], outPtr) == 0 and u4[outPtr]
        if savedRender[i] then
            call(setRS, 0, dev, s[1], s[2])
        end
    end
    for i, s in ipairs(stageStates) do
        savedStage[i] = call(getTS, 0, dev, s[1], s[2], outPtr) == 0 and u4[outPtr]
        if savedStage[i] then
            call(setTS, 0, dev, s[1], s[2], s[3])
        end
    end
    u4[outPtr] = 0
    call(method(dev, Dev_GetTexture), 0, dev, 0, outPtr)
    local previous = u4[outPtr]

    local ok, err = pcall(self.drawTiles, self, dev)

    call(method(dev, Dev_SetTexture), 0, dev, 0, previous)
    release(previous)
    for i = #stageStates, 1, -1 do
        local s = stageStates[i]
        if savedStage[i] then
            call(setTS, 0, dev, s[1], s[2], savedStage[i])
        end
    end
    for i = #renderStates, 1, -1 do
        if savedRender[i] then
            call(setRS, 0, dev, renderStates[i][1], savedRender[i])
        end
    end
    if not ok then
        self:fail(err)
    end
end

function Target:set_visible(vis)
    self.visible = vis and true or false
end

function Target:pump_events()
end

function Target:resize(new_w, new_h)
    new_w = math.max(1, math.floor(new_w))
    new_h = math.max(1, math.floor(new_h))
    if new_w == self.width and new_h == self.height then
        return
    end
    self:releaseTiles()
    if self.surface then
        self.surface:dispose()
    end
    self.width, self.height = new_w, new_h
    self.surface = self.gdi.create_dib_surface(new_w, new_h)
end

function Target:destroy()
    events.remove("PostRender", self.render)
    self:releaseTiles()
    if self.surface then
        self.surface:dispose()
        self.surface = nil
    end
end

return M
