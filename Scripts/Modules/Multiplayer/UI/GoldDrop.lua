local events = Multiplayer.events

Multiplayer.debug.GoldDropVelocity = 128

local function DropGold()
	local answer = Question("What amount of gold do you want to drop?")
	local success, result = pcall(tonumber, answer)
	if not success or not result then
		return
	end

	local amount = math.min(Party.Gold, result:floor())
	if not (amount > 0) then -- not (n > 0) excludes NaN
		return
	end

	local item_id = 189
	if amount < 100 then
		item_id = 187
	elseif amount < 1000 then
		item_id = 188
	end

	local obj = SummonItem(item_id, Party.X, Party.Y, Party.Z + 128, 0)
	obj.Item.Bonus2 = amount
	obj.Owner = Multiplayer.utils.ref_num(4, Multiplayer.utils.CurrentPlayer())

	local v = Multiplayer.utils.step_from_point(Party, Multiplayer.debug.GoldDropVelocity, Party.Direction)
	obj.VelocityX = v.X - Party.X
	obj.VelocityY = v.Y - Party.Y

	Party.Gold = Party.Gold - amount
end

local button = CustomUI.CreateButton{
	Active = false,
	IconUp = "cminup",
	IconDown = "cmindn",
	IconMouseOver = "cminht",
	Layer = 0,
	Screen = 0,
	X = 158,
	Y = 3,
	Action = function()
		Multiplayer.utils.delayed_call(DropGold, 4)
	end,
	MouseOverAction = function()
		Game.ShowStatusText("Drop gold")
	end
}

function events.MultiplayerStarted()
	button.X = Game.PatchOptions.UILayoutActive() and 283 or 158
	button.Active = true
end

function events.MultiplayerStopped()
	button.Active = false
end
