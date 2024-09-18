local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)
local CollectionService = game:GetService("CollectionService")

local Players = {}

local TerminationService = Knit.CreateService({ 
	Name = "TerminationService", 
	Players = Players,
	Client = {
		OnUpdate = RemoteSignal.new(),
	}
})

function TerminationService.Client:Get(player)
	local plr = PlayerService:GetPlayerByUserId(player.UserId)
	return TerminationService:Get(plr)
end

function TerminationService.Client:GetByUserId(_, userId)
	local target = PlayerService:GetPlayerByUserId(userId)
	return TerminationService:Get(target)
end

function TerminationService:KnitStart()

	local ProfileService = Knit.Services.ProfileService
	local NotificationService = Knit.Services.NotificationService
	local NametagService = Knit.Services.NametagService
	local AreaService = Knit.Services.AreaService
	local AuthorizationService = Knit.Services.AuthorizationService
	
	function TerminationService:Get(player)
		return TerminationService.Players[player]
	end
	
	function TerminationService:Set(player, status)	
		TerminationService.Players[player] = status
		TerminationService.Client.OnUpdate:FireAll(player, status)
		if status == true then
			NametagService:UpdateStatus(player, "TERMINATE", Color3.fromRGB(255, 0, 0))
			NotificationService:ShowNotification(player, 3, "You are marked for TERMINATION!", Color3.fromRGB(53, 151, 255))
		end
	end
	
	AreaService.OnAreaEntered:Connect(function(player, name, part)
		local markForTermination = part:GetAttribute("MarkForTermination")
		local overrideAuthorization = part:GetAttribute("OverrideAuthorization")
		if markForTermination and player.Team.Name == "Class - D" then
			local isAuthorized = AuthorizationService:IsAuthorized(player)
			if isAuthorized == false or overrideAuthorization then
				TerminationService:Set(player, true)
			end
		end
	end)

	ProfileService.PlayerAdded:Connect(function(player)
		TerminationService:Set(player, false)
	end)
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		TerminationService:Set(player, false)
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		TerminationService.Players[player] = nil
	end)
	
end


return TerminationService
