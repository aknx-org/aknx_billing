ESX = nil;
Citizen.CreateThread(function()
	while ESX == nil do
        TriggerEvent(Config.GetESX, function(lib) ESX = lib end)
		Citizen.Wait(10);
	end
end)

playerIsDead = false;

AddEventHandler('esx:onPlayerDeath', function()
    playerIsDead = true;
end)
AddEventHandler('playerSpawned', function()
    playerIsDead = false;
end)

TriggerServerEvent('testze')