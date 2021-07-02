self = {
    billing_table = {}
}

openMenu = false;
RMenu.Add('billing_menu', 'main_menu', RageUI.CreateMenu(Traduction.BillingMenuTitle, Traduction.BillingMenuDescription));
RMenu:Get('billing_menu', 'main_menu').Closed = function()
	openMenu = false;
end

function openBillingMenu()
    if openMenu then
        openMenu = false;
    else
        openMenu = true;
        RageUI.Visible(RMenu:Get('billing_menu', 'main_menu'), true);
        Citizen.CreateThread(function()
            while openMenu do
                Citizen.Wait(1);
                RageUI.IsVisible(RMenu:Get('billing_menu', 'main_menu'), true, true, true, function()
                    RageUI.ButtonWithStyle(Traduction.RefreshBillingButtonTitle, nil, {RightLabel = "→→"}, true, function(_,_,s)
                        if s then
                            ESX.TriggerServerCallback('esx_billing:getBills', function(bills)
                                self.billing_table = bills;
                            end)
                        end
                    end)
                    if #self.billing_table == 0 then
                        RageUI.Separator(""); RageUI.Separator(Traduction.PlayerDontHaveBillingSeparatorTitle); RageUI.Separator("");
                    end
                    if #self.billing_table > 0 then
                        RageUI.Separator(Traduction.PlayerBillingAvailable);
                    end
                    for i = 1, #self.billing_table, 1 do
                        RageUI.ButtonWithStyle(self.billing_table[i].billing_name, Traduction.DateDescriptionBillingTitle..""..self.billing_table[i].date, {RightLabel = '['..Traduction.ColorMoney..self.billing_table[i].amount.."$~s~] →"}, true, function(_,_,s)
                            if s then
                                ESX.TriggerServerCallback('esx_billing:payBill', function()
                                    ESX.TriggerServerCallback('esx_billing:getBills', function(bills) self.billing_table = bills end)
                                end, self.billing_table[i].id);
                            end
                        end)
                    end
                end)
            end
        end)
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(1000);
    Config.MenuBannerColor [1] = GetResourceKvpInt("menuR");
    Config.MenuBannerColor [2] = GetResourceKvpInt("menuG");
    Config.MenuBannerColor [3] = GetResourceKvpInt("menuB");
    AddBannerColor();
end)

local AllMenuToChange = nil;
function AddBannerColor()
    Citizen.CreateThread(function()
        if AllMenuToChange == nil then
            AllMenuToChange = {};
            for Name,Menu in pairs(RMenu['billing_menu']) do
                if Menu.Menu.Sprite.Dictionary == "commonmenu" then
                    table.insert(AllMenuToChange, Name);
                end
            end
        end
        for k,v in pairs(AllMenuToChange) do
            RMenu:Get('billing_menu', v):SetRectangleBanner(Config.MenuBannerColor.r, Config.MenuBannerColor.g, Config.MenuBannerColor.b, Config.MenuBannerColor.opacity);
        end
    end)
end