local events = Multiplayer.events
local u1, u2, u4, r4, i4, mstr, mcopy, toptr = mem.u1, mem.u2, mem.u4, mem.r4, mem.i4, mem.string, mem.copy, mem.topointer
local item_to_bin, bin_to_item = Multiplayer.utils.item_to_bin, Multiplayer.utils.bin_to_item

local packets = {
	bank_gold_change = {
		bulb = Multiplayer.utils.num_to_hexstr,
		handler = function(bin_string, metadata)
			local amount = i4[toptr(bin_string)]
			Party.BankGold = math.max(Party.BankGold + amount, 0)
		end,
		check_delivery = true
	}
}
Multiplayer.utils.init_packets(packets)

function events.GatherGameData(t)
	t.BankGold = Party.BankGold
end

function events.ProcessGameData(t)
	Party.BankGold = t.BankGold or 0
end

function events.DepositBankGold(amount)
	Multiplayer.broadcast(packets.bank_gold_change:prep(amount), nil)
end

function events.WithdrawBankGold(amount)
	Multiplayer.broadcast(packets.bank_gold_change:prep(-amount), nil)
end