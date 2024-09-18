local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)
local CollectionService = game:GetService("CollectionService")
--local CharacterCollections = script.Characters
local KnitSignal	= require(Knit.Util.Signal)

local PlayerCollectorService = Knit.CreateService({ 
	Name = "PlayerCollectorService", 
	Players = {},
	Characters = {},
	Touched = KnitSignal.new(),
	TouchEnded = KnitSignal.new(),
	CharacterAddedToCollection = KnitSignal.new()
})




function PlayerCollectorService:KnitStart()

	local ProfileService = Knit.Services.ProfileService
	local NotificationService = Knit.Services.NotificationService
	local NametagService = Knit.Services.NametagService
	local AreaService = Knit.Services.AreaService
	local AuthorizationService = Knit.Services.AuthorizationService
	
	function PlayerCollectorService:GetCharacterCollection(id)
		if PlayerCollectorService.Characters[id] == nil then
			PlayerCollectorService.Characters[id] = {}
		end
		return PlayerCollectorService.Characters[id] 
	end
	

	ProfileService.PlayerAdded:Connect(function(player)
		
	end)
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		character.HumanoidRootPart.Touched:Connect(function(part)
			if CollectionService:HasTag(part, "CollectPlayerCharacter") then
				local collectorId = part:GetAttribute("CollectorId") 
				local collection = PlayerCollectorService:GetCharacterCollection(collectorId)
				table.insert(collection, character)
				self.CharacterAddedToCollection:Fire(collectorId, collection, character)
			end
			if CollectionService:HasTag(part, "CollectTouchSignal") then
				PlayerCollectorService.Touched:Fire(part, player, character)
			end
		end)
		
		character.HumanoidRootPart.TouchEnded:Connect(function(part)
			if CollectionService:HasTag(part, "CollectPlayerCharacter") then
				local collectorId = part:GetAttribute("CollectorId") 
				local collection = PlayerCollectorService:GetCharacterCollection(collectorId)
				for num, char in pairs(collection) do
					if char == character then
						table.remove(collection, num)
					end
				end
			end
			if CollectionService:HasTag(part, "CollectTouchSignal") then
				PlayerCollectorService.TouchEnded:Fire(part, player, character)
			end
		end)
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		
	end)
	
end


return PlayerCollectorService
