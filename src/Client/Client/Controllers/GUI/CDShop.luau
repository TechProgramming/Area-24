local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local PLAYER	= game:GetService("Players").LocalPlayer
local SOUNDS	= game:GetService("SoundService"):WaitForChild("MainMenu")
local SHOP_UI	= PLAYER.PlayerGui:WaitForChild("CDShop")

local CDShopController = Knit.CreateController({
	Name = "CDShopController",
	VisibilityChanged = KnitSignal.new()
})

function CDShopController:KnitStart()
	
	local TransactionService	= Knit.GetService("TransactionService");
	local ProfileService		= Knit.GetService("ProfileService");
	local TeamingService		= Knit.GetService("TeamingService");
	local CDShopService			= Knit.GetService("CDShopService");
	local ItemService			= Knit.GetService("ItemService");
	local SFXController 		= Knit.GetController("SFXController")
	
	local closeButton = SHOP_UI.Container.Close.CloseButton;
	local purchaseButton = SHOP_UI.Container.Purchase.PurchaseButton;
	
	local selectedItem = nil;
	
	function CDShopController:HighlightReason(obj, set)
		if set then
			obj.BackgroundColor3 = Color3.fromRGB(193, 166, 15)
		else
			obj.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
		end
	end
	
	
	--Register cash changed
	ProfileService.OnCashChanged:Connect(function(newCash, _action)
		SHOP_UI.Container.CurrentCash.Text = "$"..newCash
	end)
	--Register open prompt
	CDShopService.OnPromptTriggered:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		SHOP_UI.Enabled = true
		CDShopController.VisibilityChanged:Fire(true)
	end)
	--Register click buttons
	closeButton.MouseButton1Click:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		CDShopController.VisibilityChanged:Fire(false)
		SHOP_UI.Enabled = false
	end)
	
	closeButton.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	--Register buy button
	purchaseButton.MouseButton1Click:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		TransactionService:Purchase(selectedItem.Name);
	end);
	
	purchaseButton.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	--Update Shop
	function self:Update()
		local playerTeam = game.Players.LocalPlayer.Team
		for _, shopObject in pairs(SHOP_UI.Container.Items:GetChildren()) do
			
			if shopObject:IsA("TextButton") then
				shopObject:Destroy();
			end;
		end;
		local items = ItemService:GetItems();
		for itemId, item in pairs(items) do
			local whitelisted = true
			if item.TeamWhitelist ~= nil then
				whitelisted = item.TeamWhitelist[playerTeam.Name] or false
			end
			
			if item.CDCShop and whitelisted then
				local buttonTemplate = script.ItemTemplate:Clone();
				if item.ImageId then
					buttonTemplate.Icon.Image = string.format("rbxassetid://%s", item.ImageId);
				else
					--warn(string.format("An item: %s do not have Image ID", itemId));
				end;
				if item.DisplayName then
					buttonTemplate.ItemName.Text = item.DisplayName;
				else
					--warn(string.format("An item: %s do not have Display Name", itemId));
				end;
				if item.Price then
					buttonTemplate.Price.Text = string.format("%s Coins", item.Price);
				end;
				buttonTemplate.Name = itemId;
				if itemId == "Screwdriver" then
					selectedItem = buttonTemplate
					CDShopController:HighlightReason(selectedItem, true)
				end
				
				buttonTemplate.MouseButton1Click:Connect(function()
					SFXController:PlayPrefab("ButtonClick")
					CDShopController:HighlightReason(selectedItem, false)
					selectedItem = buttonTemplate
					CDShopController:HighlightReason(buttonTemplate, true)
					--print("Selected " .. itemId);
				end);
				
				buttonTemplate.MouseEnter:Connect(function()
					SFXController:PlayPrefab("ButtonHover")
				end)
				
				buttonTemplate.Parent = SHOP_UI.Container.Items;
			end;
		end;
	end;
	
	self:Update();
	
	TeamingService.PlayersTeamChanged:Connect(function(team)
		self:Update();
	end)
end;

return CDShopController