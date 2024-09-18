local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local Scripted = workspace:WaitForChild("Scripted")

local FoodStandService = Knit.CreateService({ 
	Name = "FoodStandService", 
	Client = {
		OnFoodStandOpen = RemoteSignal.new();
	},
})

function FoodStandService.Client:Purchase(player, foodItem)
	return FoodStandService:Purchase(player, foodItem)
end

function FoodStandService:KnitStart()
	local TransactionService = Knit.Services.TransactionService

	function FoodStandService:Purchase(player, foodItem)
		TransactionService:Purchase(player, foodItem)
	end

	for _, shopButton in pairs(Scripted.FoodStands:GetChildren()) do
		shopButton.ProximityPrompt.Triggered:Connect(function(player)
			FoodStandService.Client.OnFoodStandOpen:Fire(player, shopButton.Name)
		end)
	end
end


return FoodStandService