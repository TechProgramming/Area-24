local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local CASH = PLAYER.PlayerGui:WaitForChild("Cash")
local CDCSHOP = PLAYER.PlayerGui:WaitForChild("CDShop")
local FOODSTAND = PLAYER.PlayerGui:WaitForChild("FoodStand")

local CashController = Knit.CreateController({
	Name = "CashController",
})

function CashController:KnitStart()
	local CashService = Knit.GetService("CashService")
	local cash = CashService:Get()
	local cashTextLabels = {
		CASH.Display,
		CDCSHOP.Container.CurrentCash,
		FOODSTAND.Container.Cash,
	}

	function CashController:Update(amount)
		for _, label in pairs(cashTextLabels) do
			label.Text = "$"..NumberFormat:Abbreviate(amount)
		end
	end

	CashController:Update(cash)

	CashService.OnCashAdded:Connect(function(total, amountChanged)
		CashController:Update(total)
	end)

	CashService.OnCashRemoved:Connect(function(total, amountChanged)
		CashController:Update(total)
	end)	



end


return CashController

