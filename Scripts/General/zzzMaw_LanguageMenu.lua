-- Settings page "Language / Sprache" in the game's extra settings (the pages one pages through with the arrows):
--   Language: German / English  (click; MAWSettings.lua is changed, the new language applies after a restart)
--   Items, tooltips: German / English and Shops, houses: German / English  (click, same way; they only matter with
--     language German and are English by default: many players know the English item names)
--   Voice output: on / off      (click; applies at once and is remembered in the registry)
-- The keys for "repeat voice" and "stop voice" are entries of the Keybinds page (zzzMaw_NPCVoices.lua).

local MF = Merge and Merge.Functions
local REG_VOICE = "maw_voice_enabled"

local TEXT = {
	de = {
		header = " Sprache / Language",
		language = "Sprache: %s",
		items = "Gegenst\228nde, Tooltips: %s",
		shops = "L\228den, H\228user: %s",
		voice = "Sprachausgabe: %s",
		on = "An", off = "Aus",
		names = {de = "Deutsch", en = "English"},
		restart = "Neustart n\246tig",
	},
	en = {
		header = " Sprache / Language",
		language = "Language: %s",
		items = "Items, tooltips: %s",
		shops = "Shops, houses: %s",
		voice = "Voice output: %s",
		on = "On", off = "Off",
		names = {de = "Deutsch", en = "English"},
		restart = "Restart required",
	},
}

-- Changes key = "..." in MAWSettings.lua (or adds the line); true when the file was written.
local function writeSetting(key, value)
	local path = (AppPath or "") .. "MAWSettings.lua"
	local f = io.open(path, "rb")
	if not f then
		return false
	end
	local text = f:read("*all")
	f:close()
	local line = key .. ' = "' .. value .. '",'
	local new, n = text:gsub(key .. '%s*=%s*"[^"]*",?', line, 1)
	if n == 0 then
		new, n = text:gsub("return%s*{", "return {\r\n    " .. line, 1)
	end
	if n == 0 then
		return false
	end
	f = io.open(path, "wb")
	if not f then
		return false
	end
	f:write(new)
	f:close()
	return true
end

local function voiceOn()
	return not MawVoices or MawVoices.Enabled ~= false
end

function events.GameInitialized2()
	if not CustomUI or not CustomUI.NewSettingsPage then
		return
	end
	-- the remembered voice setting
	if MawVoices and MF and MF.GetRegistryValue then
		local ok, v = pcall(MF.GetRegistryValue, REG_VOICE, 1)
		if ok and v == 0 then
			MawVoices.Enabled = false
		end
	end

	local lang = MawLanguage or {}
	local active = lang.Active == "de" and "de" or "en"
	local chosen = {language = active, items = lang.Items and "de" or "en", shops = lang.Shops and "de" or "en"}
	local started = {language = chosen.language, items = chosen.items, shops = chosen.shops}  -- what runs now
	local Screen = CustomUI.NewSettingsPage("MawLanguageSettings", TEXT[active].header, "ExSetScr2")

	local function strings()
		return TEXT[chosen.language]
	end

	local langLabel, itemsLabel, shopsLabel, voiceLabel, noteLabel
	local function refresh()
		local s = strings()
		-- a leading space: the first character of a text is not drawn (the headers of the pages start with one too)
		langLabel.Text = " " .. s.language:format(s.names[chosen.language])
		itemsLabel.Text = " " .. s.items:format(s.names[chosen.items])
		shopsLabel.Text = " " .. s.shops:format(s.names[chosen.shops])
		voiceLabel.Text = " " .. s.voice:format(voiceOn() and s.on or s.off)
		local changed = chosen.language ~= started.language or chosen.items ~= started.items or chosen.shops ~= started.shops
		noteLabel.Text = changed and s.restart or " "
	end

	local function toggle(key, setting)
		return function()
			local new = chosen[key] == "de" and "en" or "de"
			if writeSetting(setting, new) then
				chosen[key] = new
			end
			Game.PlaySound(25)
			refresh()
		end
	end

	local function make(y, action)
		return CustomUI.CreateText{
			Text = " ", X = 120, Y = y, AlignLeft = true, Layer = 0, Screen = Screen, Font = Game.Lucida_fnt, Width = 440, Height = 20,
			Action = action}
	end

	langLabel = make(160, toggle("language", "language"))
	itemsLabel = make(200, toggle("items", "languageItems"))
	shopsLabel = make(240, toggle("shops", "languageShops"))
	voiceLabel = make(280, function()
		if MawVoices then
			MawVoices.Enabled = not voiceOn()
			if not MawVoices.Enabled and MawVoices.Stop then
				pcall(MawVoices.Stop)
			end
			if MF and MF.SetRegistryValue then
				pcall(MF.SetRegistryValue, REG_VOICE, MawVoices.Enabled and 1 or 0)
			end
		end
		Game.PlaySound(25)
		refresh()
	end)
	noteLabel = make(330, nil)

	function events.OpenExtraSettingsMenu()
		refresh()
	end
	refresh()
end
