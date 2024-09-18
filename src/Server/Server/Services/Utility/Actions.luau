local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local EmoteService = false

local ActionService = Knit.CreateService({
	Name = "ActionService",
	Players = {},
	Container = {},
	Client = {
		OnStopAction = RemoteSignal.new(),
		OnActionStarted = RemoteSignal.new()
	},
})

--local Jobs = {
--	["Sleep"] = {
--		Work = function(jobData, player, jobObject)
--			EmoteService:Play(player, "Bodybuilder")
--		end,
--	}
--}

function ActionService:KnitStart()
	
	local ProfileService = Knit.Services.ProfileService
	local LevelService = Knit.Services.LevelService
	local NotificationService = Knit.Services.NotificationService
	EmoteService = Knit.Services.EmoteService
	
	ProfileService.PlayerAdded:Connect(function(player)
		ActionService.Players[player] = nil
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		local actionObject = ActionService.Players[player]
		if actionObject then
			actionObject.ProximityPrompt.Enabled = true
		end
		ActionService.Players[player] = nil
	end)
	
	ActionService.Client.OnStopAction:Connect(function(player)
		local actionObject = ActionService.Players[player]
		player.Character.HumanoidRootPart.Anchored = false
		actionObject.ProximityPrompt.Enabled = true
		EmoteService:Stop(player)
		ActionService.Players[player] = nil
	end)
	
	function ActionService:AddActionObject(object)
		local actionCharacter = object.Parent.Character
		for _, part in pairs(actionCharacter:GetChildren()) do
			part.Transparency = 1
			part.CanCollide = false
		end
		local face = actionCharacter.Head:FindFirstChild("face")
		if face then face:Destroy() end
		local actionName = object.Parent.Name
		object.Transparency = 1
		object.ProximityPrompt.Triggered:Connect(function(player)
			object.ProximityPrompt.Enabled = false
			--NotificationService:ShowNotification(player, 3, "Zzz.", Color3.fromRGB(255, 255, 255))
			player.Character.HumanoidRootPart.Anchored = true
			player.Character.HumanoidRootPart.CFrame = actionCharacter.HumanoidRootPart.CFrame
			EmoteService:Play(player, actionName)
			ActionService.Players[player] = object
			ActionService.Client.OnActionStarted:Fire(player)
			--object.ProximityPrompt.Enabled = true
		end)
	end

	local actionObjects = CollectionService:GetTagged("Action")
	for _, object in pairs(actionObjects) do
		ActionService:AddActionObject(object)
	end
end


return ActionService