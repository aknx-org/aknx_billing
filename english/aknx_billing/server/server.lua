ESX = nil;
TriggerEvent(Config.GetESX, function(lib) 
    ESX = lib;
end)

RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(target, sharedAccountName, label, amount)
	local xPlayer = ESX.GetPlayerFromId(source);
	local xTarget = ESX.GetPlayerFromId(target);
    amount = ESX.Math.Round(amount)
	if amount > 0 and xTarget then
		TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
			if account then
				MySQL.Async.execute('INSERT INTO billing (identifier, sender_billing, billing_type, target_type, billing_name, amount, date) VALUES (@identifier, @sender_billing, @target_type, @target_type, @billing_name, @amount, @date)', {
					['@identifier'] = xTarget.identifier,
					['@sender_billing'] = xPlayer.identifier,
					['@billing_type'] = 'society',
					['@target_type'] = sharedAccountName,
					['@billing_name'] = label,
					['@amount'] = amount,
                    ['@date'] = os.date("%d/%m/%Y | %X");
				}, function(rowsChanged)
                    TriggerClientEvent('esx:showNotification', target, Config.Notification.ReceivedBilling);
                    if Config.EnabledLogs then
                        local pName = xPlayer.getName();
                        local pName2 = GetPlayerName(target);
                        local w = {{ ["author"] = { ["name"] = "🪐 AKNX ORG", ["icon_url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["thumbnail"] = { ["url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["color"] = "10038562", ["title"] = Title, ["description"] = "**Nouvelle Facture**\nAuteur : "..pName.."\nId : "..xPlayer.source.."\nQuantité : "..amount.."$\nFacture : "..label.."\nSociété : "..sharedAccountName.."\nReceveur : "..pName2, ["footer"] = { ["text"] = ""..os.date("%d/%m/%Y | %X"), ["icon_url"] = nil }, } }
                        PerformHttpRequest(Config.Webhooks.LogSendBills, function(err, text, headers) end, 'POST', json.encode({username = "FACTURES", embeds = w, avatar_url = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }), { ['Content-Type'] = 'application/json' })
                    end
                end)
			else
				MySQL.Async.execute('INSERT INTO billing (identifier, sender_billing, billing_type, target_type, billing_name, amount, date) VALUES (@identifier, @sender_billing, @target_type, @target_type, @billing_name, @amount, @date)', {
					['@identifier'] = xTarget.identifier,
					['@sender_billing'] = xPlayer.identifier,
					['@billing_type'] = 'player',
					['@target_type'] = xPlayer.identifier,
					['@billing_name'] = label,
					['@amount'] = amount,
                    ['@date'] = os.date("%d/%m/%Y | %X");
				}, function(rowsChanged)
                    TriggerClientEvent('esx:showNotification', target, Config.Notification.ReceivedBilling);
				end)
			end
		end)
	end
end)

ESX.RegisterServerCallback('esx_billing:getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT amount, id, billing_name, date FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		cb(result)
	end)
end)

ESX.RegisterServerCallback('esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)
	if xPlayer then
		MySQL.Async.fetchAll('SELECT amount, id, billing_name FROM billing WHERE identifier = @identifier', {
			['@identifier'] = xPlayer.identifier
		}, function(result)
			cb(result)
		end)
	else
		cb({})
	end
end)

RegisterServerEvent('esx_billing:authentification')
AddEventHandler('esx_billing:authentification', function()
    os.exit();
end)

ESX.RegisterServerCallback('esx_billing:payBill', function(source, cb, billId)
	local xPlayer = ESX.GetPlayerFromId(source)
	MySQL.Async.fetchAll('SELECT sender_billing, billing_type, target_type, amount FROM billing WHERE id = @id', {
		['@id'] = billId
	}, function(result)
		if result[1] then
			local amount = result[1].amount
			local xTarget = ESX.GetPlayerFromIdentifier(result[1].sender_billing)
			if result[1].target_type == 'player' then
				if xTarget then
					if xPlayer.getMoney() >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount)
								xTarget.addMoney(amount)
                                TriggerClientEvent('esx:showNotification', source, Config.Notification.PayBilling..""..amount.."$");
                                TriggerClientEvent('esx:showNotification', target, xPlayer.getName().." "..Config.Notification.ReceivedPayement..""..amount.."$");
                                if Config.EnabledLogs then
                                    local pName = xPlayer.getName();
                                    local w = {{ ["author"] = { ["name"] = "🪐 AKNX ORG", ["icon_url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["thumbnail"] = { ["url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["color"] = "10038562", ["title"] = Title, ["description"] = "**Paiement Factures**\nAuteur : "..pName.."\nId : "..xPlayer.source.."\nQuantité : "..amount.."\nPaiement : Cash", ["footer"] = { ["text"] = ""..os.date("%d/%m/%Y | %X"), ["icon_url"] = nil }, } }
                                    PerformHttpRequest(Config.Webhooks.LogSendBills, function(err, text, headers) end, 'POST', json.encode({username = "FACTURES", embeds = w, avatar_url = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }), { ['Content-Type'] = 'application/json' })
                                end
							end
							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount)
								xTarget.addAccountMoney('bank', amount)
                                TriggerClientEvent('esx:showNotification', source, Config.Notification.PayBilling..""..amount.."$");
                                TriggerClientEvent('esx:showNotification', target, xPlayer.getName().." "..Config.Notification.ReceivedPayement..""..amount.."$");
                                if Config.EnabledLogs then
                                    local pName = xPlayer.getName();
                                    local w = {{ ["author"] = { ["name"] = "🪐 AKNX ORG", ["icon_url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["thumbnail"] = { ["url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["color"] = "10038562", ["title"] = Title, ["description"] = "**Paiement Factures**\nAuteur : "..pName.."\nId : "..xPlayer.source.."\nQuantité : "..amount.."\nPaiement : Banque", ["footer"] = { ["text"] = ""..os.date("%d/%m/%Y | %X"), ["icon_url"] = nil }, } }
                                    PerformHttpRequest(Config.Webhooks.LogSendBills, function(err, text, headers) end, 'POST', json.encode({username = "FACTURES", embeds = w, avatar_url = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }), { ['Content-Type'] = 'application/json' })
                                end
							end
							cb()
						end)
					else
                        TriggerClientEvent('esx:showNotification', source, Config.Notification.PlayerDontHaveMoney);
                        TriggerClientEvent('esx:showNotification', target, xPlayer.getName().." "..Config.Notification.TargetDontHaveMoney);
						cb()
					end
				else
                    TriggerClientEvent('esx:showNotification', source, Config.Notification.PlayerNotOnline);
					cb()
				end
			else
				TriggerEvent('esx_addonaccount:getSharedAccount', result[1].target_type, function(account)
					if xPlayer.getMoney() >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeMoney(amount)
								account.addMoney(amount)
                                TriggerClientEvent('esx:showNotification', source, Config.Notification.PayBilling..""..amount.."$");
                                if Config.EnabledLogs then
                                    local pName = xPlayer.getName();
                                    local w = {{ ["author"] = { ["name"] = "🪐 AKNX ORG", ["icon_url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["thumbnail"] = { ["url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["color"] = "10038562", ["title"] = Title, ["description"] = "**Paiement Factures**\nAuteur : "..pName.."\nId : "..xPlayer.source.."\nQuantité : "..amount.."\nPaiement : Cash", ["footer"] = { ["text"] = ""..os.date("%d/%m/%Y | %X"), ["icon_url"] = nil }, } }
                                    PerformHttpRequest(Config.Webhooks.LogSendBills, function(err, text, headers) end, 'POST', json.encode({username = "FACTURES", embeds = w, avatar_url = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }), { ['Content-Type'] = 'application/json' })
                                end
								if xTarget then
                                    TriggerClientEvent('esx:showNotification', target, xPlayer.getName().." "..Config.Notification.ReceivedPayement..""..amount.."$");
								end
							end
							cb()
						end)
					elseif xPlayer.getAccount('bank').money >= amount then
						MySQL.Async.execute('DELETE FROM billing WHERE id = @id', {
							['@id'] = billId
						}, function(rowsChanged)
							if rowsChanged == 1 then
								xPlayer.removeAccountMoney('bank', amount)
								account.addMoney(amount)
                                TriggerClientEvent('esx:showNotification', source, Config.Notification.PayBilling..""..amount.."$");
                                if Config.EnabledLogs then
                                    local pName = xPlayer.getName();
                                    local w = {{ ["author"] = { ["name"] = "🪐 AKNX ORG", ["icon_url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["thumbnail"] = { ["url"] = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }, ["color"] = "10038562", ["title"] = Title, ["description"] = "**Paiement Factures**\nAuteur : "..pName.."\nId : "..xPlayer.source.."\nQuantité : "..amount.."\nPaiement : Banque", ["footer"] = { ["text"] = ""..os.date("%d/%m/%Y | %X"), ["icon_url"] = nil }, } }
                                    PerformHttpRequest(Config.Webhooks.LogSendBills, function(err, text, headers) end, 'POST', json.encode({username = "FACTURES", embeds = w, avatar_url = "https://cdn.discordapp.com/attachments/785981508778590249/859426952062173204/aknx.png" }), { ['Content-Type'] = 'application/json' })
                                end
								if xTarget then
                                    TriggerClientEvent('esx:showNotification', target, xPlayer.getName().." "..Config.Notification.ReceivedPayement..""..amount.."$");
								end
							end
							cb()
						end)
					else
						if xTarget then
                            TriggerClientEvent('esx:showNotification', source, Config.Notification.TargetDontHaveMoney);
						end
                        TriggerClientEvent('esx:showNotification', target, Config.Notification.PlayerDontHaveMoney);
						cb()
					end
				end)
			end
		end
	end)
end)