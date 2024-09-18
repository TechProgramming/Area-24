local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local SpawnItems = CollectionService:GetTagged("SpawnItems")

local ProximityPromptTemplate = script.ProximityPromptTemplate:Clone()

local ItemSpawnService = Knit.CreateService({ 
	Name = "ItemSpawnService", 
	Client = {}
})

local Min = 60

function ItemSpawnService:KnitStart()

	local ProfileService = Knit.Services.ProfileService
	local NotificationService = Knit.Services.NotificationService
	local TransactionService = Knit.Services.TransactionService
	
	for _, item in pairs(game.Workspace.Scripted.ItemSpawns:GetChildren()) do
		spawn(function()
			item.Parent = nil
			local proximityPrompt = ProximityPromptTemplate:Clone()
			local handle = item:FindFirstChild("Handle")
			if handle then
				proximityPrompt.Parent = handle
			end
			proximityPrompt.ObjectText = item.Name
			
			proximityPrompt.Triggered:Connect(function(player)
				item.Parent = nil
				TransactionService:Award(player, item.Name)
				wait(math.random(Min * 5, Min * 5))
				item.Parent = workspace
			end)
			wait(math.random(30,120))
			item.Parent = workspace
		end)
	end
	
	
	
end


return ItemSpawnService
