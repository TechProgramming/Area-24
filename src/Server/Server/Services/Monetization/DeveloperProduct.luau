local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local DeveloperProductService = Knit.CreateService({
	Name = "DeveloperProductService",
	Ready = false,
	BindsByProductId = {},
	Client = {
		OnUpdate = RemoteSignal.new(),
		OnRequestItems = RemoteSignal.new(),
	}
})


function DeveloperProductService.Client:GetProductByRobloxId(player, productId)
	return DeveloperProductService:GetProductByRobloxId(productId)
end

function DeveloperProductService.Client:GetProduct(player, productId)
	return DeveloperProductService:GetDevProduct(productId)
end

function DeveloperProductService.Client:GetProducts(player)
	return DeveloperProductService:GetProducts()
end

function DeveloperProductService.Client:Prompt(player, gamepassName)
	return DeveloperProductService:Prompt(player, gamepassName)
end

function DeveloperProductService:KnitStart()
	local ProfileService = Knit.Services.ProfileService
	local CharacterEditorService = Knit.Services.CharacterEditorService
	-----------------------------------------------------
	DeveloperProductService.ProductsById = {}
	DeveloperProductService.Products = {
		["+1 Avatar Slot"] = {
			Id = 1191282181,
			Process = function(player)
				local profile = ProfileService:GetProfile(player)
				profile.PurchasedCharacterSlots = profile.PurchasedCharacterSlots + 1
				CharacterEditorService.PurchasedSlot:Fire(player, profile.PurchasedCharacterSlots)
			end,
		}
		
	}
	
	function DeveloperProductService:UpdateDevProducts()
		for itemName, itemData in pairs(DeveloperProductService.Products) do
			local productData = MarketplaceService:GetProductInfo(itemData.Id, Enum.InfoType.Product)
			for key, value in pairs(productData) do
				itemData[key] = value
				DeveloperProductService.ProductsById[itemData.Id] = itemName
			end
		end
		DeveloperProductService.Ready = true
		DeveloperProductService.Client.OnUpdate:FireAll(DeveloperProductService.Products)
	end
	
	function DeveloperProductService:GetProduct(productId)
		return DeveloperProductService.Products[productId]
	end
	
	function DeveloperProductService:GetProducts()
		return DeveloperProductService.Products
	end
	
	function DeveloperProductService:GetProductByRobloxId(productId)
		return DeveloperProductService.BindsByProductId[productId]
	end
	
	DeveloperProductService.Client.OnRequestItems:Connect(function(player)
		repeat wait() until DeveloperProductService.Ready == true
		DeveloperProductService.Client.OnUpdate:Fire(player, DeveloperProductService.Products)
	end)
	
	function DeveloperProductService:Prompt(player, gamepassName)
		MarketplaceService:PromptProductPurchase(player, DeveloperProductService.Products[gamepassName].Id)
	end
	
	MarketplaceService.ProcessReceipt = function(receiptInfo)

		print("Work")
		local player = PlayersService:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		--local productNameId = ItemService:GetDevProductByRobloxId(receiptInfo.ProductId)
		local itemName = DeveloperProductService.ProductsById[receiptInfo.ProductId]
		local profile = ProfileService:GetProfile(player)
		profile.DevProducts[itemName] = true
		print("PURCHASED", itemName)
		DeveloperProductService.Products[itemName].Process(player)
		--TransactionService.ProcessPurchase[productNameId](player, profile)
		--self.Client.OnDevProductPurchased:Fire(player, productNameId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	DeveloperProductService:UpdateDevProducts()
	------------------------------------------------------
	
	for productId, productData in pairs(DeveloperProductService.Products) do
		DeveloperProductService.BindsByProductId[productData.Id] = productId
	end	

end


return DeveloperProductService