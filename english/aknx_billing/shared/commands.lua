if Config.EnableBillingMenu then
    RegisterCommand("factures", function()
        if not playerIsDead then
            openBillingMenu()
        end
    end)
end