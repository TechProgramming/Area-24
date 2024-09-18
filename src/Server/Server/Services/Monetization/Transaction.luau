local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService		= game:GetService("Players")
local MarketplaceService	= game:GetService("MarketplaceService")
local RemoteSignal			= require(Knit.Util.Remote.RemoteSignal)

local TransactionService = Knit.CreateService({
	Name = "TransactionService",
	Client = {
		OnGamepassPurchased		= RemoteSignal.new(),
		OnDevProductPurchased	= RemoteSignal.new(),
		OnGameItemPurchased		= RemoteSignal.new(),
		OnGameItemAwarded		= RemoteSignal.new(),
	}
})

function TransactionService:KnitStart()
	
	local AccessLevelService	= Knit.GetService("AccessLevelService");
	local GamepassService		= Knit.GetService("GamepassService");
	local ProfileService		= Knit.GetService("ProfileService");
	local EventService			= Knit.GetService("EventService");
	local CashService			= Knit.GetService("CashService");
	local ItemService			= Knit.GetService("ItemService");
	local ToolService			= Knit.GetService("ToolService");
	local NotificationService	= Knit.GetService("NotificationService");
	local FPSService			= Knit.GetService("FPSService");
	
	TransactionService.ProcessPurchase = {
		-- GAME ITEMS
		["Level 4 Access Card"] = function(player, itemData)
			AccessLevelService:Set(player, 4);
			return true;
		end,
		["25 Cash Award"] = function(player, itemData)
			CashService:Add(player, 25)
			return true
		end,
		["50 Cash Award"] = function(player, itemData) 
			CashService:Add(player, 50)
			return true
		end,	
		["75 Cash Award"] = function(player, itemData)
			CashService:Add(player, 75)
			return true
		end,			
		["100 Cash Award"] = function(player, itemData)
			CashService:Add(player, 100)
			return true
		end,		
		["120 Cash Award"] = function(player, itemData)
			CashService:Add(player, 120)
			return true
		end,	
	
		
		-- PROCESS BY TYPE
		["Tool"] = function(player, itemData, ...)
			local tool = itemData.Tool:Clone()
			--print("BUILDING TOOL", itemData, tool)
			if tool:GetAttribute("ToolType") == "Weapon" then -- DESTROY WEAPON
				
				--Prevent duplicate weapons
				local hasGun = false
				
				if player.Backpack:FindFirstChild(tool.Name) then
					hasGun = true
				end
				
				if player.Character and player.Character:FindFirstChild(tool.Name) then
					hasGun = true
				end
				
				if hasGun then
					tool:Destroy()
					warn("Tried adding", tool.Name, "while weapon already exists")
					return false
				end
				
				for _, v in pairs(tool:GetDescendants()) do
					if v:IsA("BasePart") then
						v:Destroy()
					end
				end
			end
			--print(tool)
			ToolService:Add(player, tool, player.Backpack, ...)
			return true
		end,
		
		["WeaponSkin"] = function(player, itemData)
			--FPSService:ChangeWeaponSkin(player, itemData.WeaponName, itemData.ItemId, true)
			if itemData.Gamepass then
				return false, true
			else
				local profile = ProfileService:GetProfile(player)
				local purchasedItems = profile.PurchasedItems
				local alreadyBought = table.find(purchasedItems, itemData.ItemId)
				if alreadyBought then
					return false
				else
					purchasedItems[#purchasedItems+1] = itemData.ItemId
					return true
				end
			end
		end,
		["WeaponSticker"] = function(player, itemData)
			if itemData.Gamepass then
				return false, true
			else
				local profile = ProfileService:GetProfile(player)
				local purchasedItems = profile.PurchasedItems
				local alreadyBought = table.find(purchasedItems, itemData.ItemId)
				if alreadyBought then
					return false
				else
					purchasedItems[#purchasedItems+1] = itemData.ItemId
					return true
				end
			end
			--FPSService:AddWeaponSticker(player, itemData.WeaponName, itemData.ItemId, true)
		end,
		["WeaponCharm"] = function(player, itemData)
			if itemData.Gamepass then
				return false, true
			else
				local profile = ProfileService:GetProfile(player)
				local purchasedItems = profile.PurchasedItems
				local alreadyBought = table.find(purchasedItems, itemData.ItemId)
				if alreadyBought then
					return false
				else
					purchasedItems[#purchasedItems+1] = itemData.ItemId
					return true
				end
			end
		end,
		
		-- EVENT
		
		["Riot"] = function(player, itemData)
			EventService:StartEvent("Riot");
			return true
		end,
		
		-- DEV PRODUCTS
		["50 Cash"] = function(player, itemData)
			CashService:Add(player, 50)
			return true
		end,
		["100 Cash"] = function(player, itemData)
			CashService:Add(player, 50)
			return true
		end,
		
		-- GAMEPASSES
		["Gamepass"] = function(player, itemData) -- CurrencyPack1
			--GamepassService:Process("LegacyEngineer")
			return true
		end	
	}
	
	function self:IsPremium(player)
		return MarketplaceService:IsPlayerSubscribed(player)
	end
	
	function self:HasGamepass(player, itemId)
		
		local itemData = ItemService:GetGamepass(itemId)
		return MarketplaceService:UserOwnsGamePassAsync(player, itemData.Id)
	end
	
	function self:GetProductInfo(player, itemId)
		
		local itemData = ItemService:GetGamepass(itemId)
		return MarketplaceService:UserOwnsGamePassAsync(player, itemData.Id)
	end
	
	function self:Award(player, itemId, ...)
		-- GAME ITEM
		local itemData = ItemService:GetItem(itemId)
		if itemData then
			
			local process = TransactionService.ProcessPurchase[itemId] or TransactionService.ProcessPurchase[itemData.ProcessType]
			if process then
				
				local profile = ProfileService:GetProfile(player)
				process(player, itemData, ...)
				self.Client.OnGameItemAwarded:Fire(player, itemId)
				return true;
			end;
		else
			return false;
		end;
	end;
	
	function self:Purchase(player, itemId)
		-- GAME ITEM
		local itemData = ItemService:GetItem(itemId);
		if itemData then
			
			local whitelist = itemData.TeamWhitelist;
			if not whitelist or whitelist[player.Team.Name] then
				
				local offCooldown = true;
				local eventCooldown = itemData.EventCooldown;
				if eventCooldown then
					for _, cooldown in pairs(eventCooldown) do
						if (EventService.Cooldown[cooldown] or tick() - 1) > tick() then
							offCooldown = false;
						end;
					end;
				end;
				if offCooldown then
					
					local process = TransactionService.ProcessPurchase[itemId] or TransactionService.ProcessPurchase[itemData.ProcessType]
					if process then
						
						local profile = ProfileService:GetProfile(player)
						local cash = profile.Cash
						local itemPrice = itemData.Price or 0;
						if self:CanAfford(cash, itemPrice) then
							
							local success, dontErr = process(player, itemData)
							if not success then
								if not dontErr then
									NotificationService:ShowNotification(player, 2, "You already own this item.", Color3.fromRGB(255, 55, 55))
								end
								return false
							end
							
							CashService:Remove(player, itemPrice)
							self.Client.OnGameItemPurchased:Fire(player, itemId)
							return true;
						else
							NotificationService:ShowNotification(player, 2, "Insufficient funds.", Color3.fromRGB(255, 55, 55))
							return false
						end;
					end;
				end;
			end;
		end;
	end;
	
	function self:Prompt(player, itemId)
		
		local itemData = ItemService:GetDevProduct(itemId)
		if itemData ~= nil and TransactionService.ProcessPurchase[itemId] ~= nil then
			
			MarketplaceService:PromptProductPurchase(player, itemData.Id)
			return true
		end
		local itemData = ItemService:GetGamepass(itemId)
		if itemData ~= nil and TransactionService.ProcessPurchase[itemId] ~= nil then
			
			MarketplaceService:PromptGamePassPurchase(player, itemData.Id)
			return true
		end
		return false
	end
	
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if gamePassId == nil or not purchased then return end
		local productNameId = GamepassService:GetGamepassByRobloxId(gamePassId)
		local profile = ProfileService:GetProfile(player)
		--TransactionService.ProcessPurchase[productNameId](player, profile)
		GamepassService:Process(player, productNameId)
		self.Client.OnGamepassPurchased:Fire(player, productNameId)
	end)

	
	--ItemService:UpdateGamepasses()
	--ItemService:UpdateDevProducts()
	
end

function TransactionService.Client:IsPremium(player)
	return TransactionService:IsPremium(player)
end

function TransactionService.Client:HasGamepass(player)
	return TransactionService:HasGamepass(player)
end

function TransactionService.Client:Purchase(player, itemId)
	return TransactionService:Purchase(player, itemId)
end	

function TransactionService.Client:Prompt(player, itemId)
	return TransactionService:Prompt(player, itemId)
end	

function TransactionService:CanAfford(amount, price)
	return amount >= price
end

return TransactionService