
local function InitShrinkedPotionsUI()

	local LoadedSprites = 0
	local LoadedIcons = 0
	local NewSpritesLodPath = "Data/Additional UI/alchemy.sprites.lod"
	local NewIconsLodPath = "Data/Additional UI/alchemy.icons.lod"

	if not (Game.IsD3D and path.FindFirst(NewSpritesLodPath) and path.FindFirst(NewIconsLodPath)) then
		return
	end

	local function memswap(p1, p2)
		local SwapBuff = mem.string(p1, 0x28, true)
		mem.copy(p1, p2, 0x28)
		mem.copy(p2, SwapBuff, 0x28)
	end

	local function ChangeBottles()
		local function Reload()
			CustomUI.ReplaceIcon("item186", "item186", true)
			CustomUI.ReplaceIcon("item198", "item198", true)

			local Lod = Game.SpritesLod
			local was_zero = Lod.SpritesD3D.count == 0

			for i = 160, 181 do
				local current_id = Lod:LoadSprite("obj" .. tostring(i), 7)
				local sprite_id = Lod:LoadSprite("sobj" .. tostring(i), 7)

				Lod.SpritesD3D.count = Lod.SpritesSW.count

				memswap(Lod.SpritesSW[sprite_id]["?ptr"], Lod.SpritesSW[current_id]["?ptr"])
				memswap(Lod.SpritesD3D[sprite_id]["?ptr"], Lod.SpritesD3D[current_id]["?ptr"])
			end

			if was_zero then
				Lod.SpritesD3D.count = 0
			end
		end

		if Game.SmallerPotionBottles then
			if LoadedSprites == 0 and path.FindFirst(NewSpritesLodPath) then
				LoadedSprites = Game.CustomLods.Load(Game.SpritesLod["?ptr"], NewSpritesLodPath)
			end
			if LoadedIcons == 0 and path.FindFirst(NewIconsLodPath) then
				LoadedIcons = Game.CustomLods.Load(Game.IconsLod["?ptr"], NewIconsLodPath)
				Reload()
			end
		else
			if LoadedSprites > 0 then
				Game.CustomLods.Free(LoadedSprites)
				LoadedSprites = 0
			end
			if LoadedIcons > 0 then
				Game.CustomLods.Free(LoadedIcons)
				LoadedIcons = 0
				Reload()
			end
		end
	end

	local shift = 40

	-- frame
	CustomUI.CreateIcon{
		Icon = "none",
		Masked = true,
		Layer	= 0,
		Screen	= const.Screens.MergeInterfaceSettings,
		Condition = function(t)
			-- Cannot regulate tooltip height other than adding lines at the moment
			local n = Game.SmallerPotionBottles and " \n \n " or " \n \n \n \n "
			CustomUI.ShowTooltip(n, t.X - 20, t.Y - 17, 110)
			return true
		end,
		X = 414, Y = 244
	}

	CustomUI.CreateIcon{
		Icon = "item186",
		Masked = true,
		Layer	= 0,
		Screen	= const.Screens.MergeInterfaceSettings,
		X = 414 + shift, Y = 244
	}

	CustomUI.CreateIcon{
		Icon = "item198",
		Masked = true,
		Layer	= 0,
		Screen	= const.Screens.MergeInterfaceSettings,
		X = 414, Y = 244
	}

	local toggle_text = CustomUI.CreateText{
		Text = "Smaller potion bottles",
		ColorMouseOver = RGB(255,255,150),
		Action = function(t)
			Game.PlaySound(23)
			Game.SmallerPotionBottles = not Game.SmallerPotionBottles
			t.CStd = Game.SmallerPotionBottles and 58980 or 65535
			ChangeBottles()
		end,
		Layer 	= 0,
		Screen 	= const.Screens.MergeInterfaceSettings,
		X = 349, Y = 204}

	function events.LoadMapScripts(WasInGame)
		Game.SmallerPotionBottles = vars.SmallerPotionBottles or false
		if not WasInGame then
			ChangeBottles()
		end
	end

	function events.BeforeSaveGame()
		vars.SmallerPotionBottles = Game.SmallerPotionBottles
	end

	function events.OpenExtraSettingsMenu()
		toggle_text.CStd = Game.SmallerPotionBottles and 58980 or 65535
	end
end

function events.GameInitialized2()
	CustomUI.NewSettingsPage("MergeInterfaceSettings", " Interface settings", "ExSetScr2")
	InitShrinkedPotionsUI()

	local UI = {}

	---- Save/load values

	local function FitUIToContinent()
		local NewUI = Game.CustomInterface

		if Game.UIDependsOnContinent then
			NewUI = TownPortalControls.MapOfContinent(Map.MapStatsIndex)
			if not Game.UISets[NewUI] then
				NewUI = 1
			end
		end

		if NewUI ~= GetCurrentUI() then
			Game.LoadUI(NewUI)
		end
	end

	function events.LoadMapScripts(WasInGame)

		if not WasInGame then

			-- Custom Interface
			Game.UIDependsOnContinent = vars.UIDependsOnContinent or false
			Game.CustomInterface = vars.CustomInterface or 1

			UI.CustomUIText.Text = tostring(Game.CustomInterface)

			if Game.CustomInterface ~= GetCurrentUI() then
				Game.LoadUI(Game.CustomInterface)
			end

			if Game.UIDependsOnContinent then
				UI.SwapUIText.CStd = 58980
			else
				UI.SwapUIText.CStd = 65535
			end

		end

		FitUIToContinent()

	end

	function events.BeforeSaveGame()
		vars.InfinityView = Game.InfinityView
		vars.CustomInterface = Game.CustomInterface
		vars.UIDependsOnContinent = Game.UIDependsOnContinent
	end

	---- Interface elements

	-- Choose UI
	CustomUI.CreateIcon{
		Icon = "UIExample",
		Layer	= 0,
		Screen	= const.Screens.MergeInterfaceSettings,
		Condition = function(t)
			if t.Wt then -- t.Wt is nil, if icon is not loaded
				-- Cannot regulate tooltip height other than adding lines at the moment
				CustomUI.ShowTooltip(" \n \n \n \n \n \n \n \n \n \n",
					t.X - 20, t.Y - 17, t.Wt + 40)
			end
			return true
		end,
		X = 118, Y = 244
	}

	UI.CustomUIText = CustomUI.CreateText{
		Text = "",
		Layer = 0,
		Screen = const.Screens.MergeInterfaceSettings,
		Width = 20, Height = 12,
		X = 224, Y = 180}

	CustomUI.CreateText{
		Text = "< ",
		Action = function(t)
			Game.PlaySound(24)
			Game.CustomInterface = math.max(Game.CustomInterface - 1, 1)
			UI.CustomUIText.Text = tostring(Game.CustomInterface)
			if not Game.UIDependsOnContinent then
				Game.LoadUI(Game.CustomInterface)
			end
		end,
		Layer 	= 0,
		Screen 	= const.Screens.MergeInterfaceSettings,
		X = 200, Y = 180}

	CustomUI.CreateText{
		Text = " >",
		Action = function(t)
			Game.PlaySound(23)
			Game.CustomInterface = math.min(Game.CustomInterface + 1, #Game.UISets)
			UI.CustomUIText.Text = tostring(Game.CustomInterface)
			if not Game.UIDependsOnContinent then
				Game.LoadUI(Game.CustomInterface)
			end
		end,
		Layer 	= 0,
		Screen 	= const.Screens.MergeInterfaceSettings,
		X = 240, Y = 180}

	CustomUI.CreateText{
		Text = "Interface:",
		Layer 	= 0,
		Screen 	= const.Screens.MergeInterfaceSettings,
		X = 100, Y = 180}

	UI.SwapUIText = CustomUI.CreateText{
		Text = "UI depends on continent",
		ColorMouseOver = RGB(255,255,150),
		Action = function(t)
			Game.PlaySound(23)
			Game.UIDependsOnContinent = not Game.UIDependsOnContinent
			t.CStd = Game.UIDependsOnContinent and 58980 or 65535
			FitUIToContinent()
		end,
		Layer 	= 0,
		Screen 	= const.Screens.MergeInterfaceSettings,
		X = 99, Y = 204}

	function events.OpenExtraSettingsMenu()
		UI.SwapUIText.CStd = Game.UIDependsOnContinent and 58980 or 65535
		UI.CustomUIText.Text = tostring(Game.CustomInterface)
	end
end

