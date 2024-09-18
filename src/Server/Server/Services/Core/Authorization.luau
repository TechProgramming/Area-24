local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local Queue = require(Knit.Util.Queue)

local TELEPORTS = game:GetService("Workspace"):WaitForChild("Scripted").Teleports

local AuthorizationService = Knit.CreateService({ 
	Name = "AuthorizationService", 
	Players = {},
	PlayersWithAuthed = {},
	LogHistory = {},
	Prompts = {},
	Client = {
		OnUpdateAuthorization = RemoteSignal.new(),
		OnLogUpdated = RemoteSignal.new(),
		OnToggleManager = RemoteSignal.new(),
		OnTogglePrompts = RemoteSignal.new(),
	}
})

local AllowedToAuthorize = {
	["Class - D"] = false,
	["Engineering and Technical"] = false,
	["Scientific Department"] = true,	
	["Security Department"] = false,
	["Chaos Insurgency"] = false,
	["Global Occult Coalition"] = false,
	["Site Director"] = true,
	["O5 Council"] = true,
	
}

function AuthorizationService.Client:GetLogHistory(player)
	return AuthorizationService:GetLogHistory(player)
end

function AuthorizationService:KnitStart()

	local NotificationService	= Knit.Services.NotificationService;
	local ProfileService		= Knit.Services.ProfileService;
	local ToolService			= Knit.Services.ProfileService;
	local TransactionService	= Knit.Services.TransactionService;
	local NametagService	= Knit.Services.NametagService;
	local TerminationService	= Knit.Services.TerminationService;
	local JobService = Knit.Services.JobService
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		local hum = character:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			AuthorizationService.Players[player] = false
		end)
		
		
		local team = player.Team
		if AllowedToAuthorize[team.Name] then
			AuthorizationService.Players[player] = true
		else
			AuthorizationService.Players[player] = false
			
			for key, plr in pairs(AuthorizationService.PlayersWithAuthed) do
				if plr == player then
					AuthorizationService.PlayersWithAuthed[key] = nil
					break
				end
			end
			
		end
		
		if team.Name == "Class - D" then
			local prompt = game.ReplicatedStorage.CharacterSelection.ProximityPrompt:Clone()
			prompt.Parent = character:WaitForChild("HumanoidRootPart")
			
			prompt.Triggered:Connect(function(triggerPlayer)
				local triggerTeam = triggerPlayer.Team
				local authorized = AllowedToAuthorize[triggerTeam.Name] 
				local adminLevel = ProfileService:GetProfile(triggerPlayer).AdminLevel or 0
				
				if not authorized and adminLevel <= 0 then
					NotificationService:ShowNotification(triggerPlayer, 3, "YOU ARE NOT AUTHORIZED!", Color3.fromRGB(255, 19, 19))
				else
					if AuthorizationService.PlayersWithAuthed[triggerPlayer] ~= player and AuthorizationService.PlayersWithAuthed[triggerPlayer] ~= nil then
						NotificationService:ShowNotification(triggerPlayer, 3, "You can only authorize 1 person at a time!", Color3.fromRGB(255, 19, 19))
						return
					end
					
					AuthorizationService.Client.OnToggleManager:Fire(triggerPlayer, true, player)
				end
				
			end)
			AuthorizationService.Prompts[player] = prompt
		end
	end)

	function self:GetLogHistory(player)
		return self.LogHistory
	end
	
	function self:AddToLogHistory(player, targetPlayer, reason)
		print(player, targetPlayer, reason)
		local log = {PlayerName = player.Name, PlayerTeam = player.Team.Name, TargetName = targetPlayer.Name, Reason = reason}
		table.remove(self.LogHistory, 15)
		table.insert(self.LogHistory, 1, log)
		self.Client.OnLogUpdated:FireAll(log)
	end
	
	function self:IsAuthorized(player)
		return AuthorizationService.Players[player]
	end
	
	local AuthorizationsOptions = {
		["Testing"] = {
			auth = true,
			text = "AUTHORIZED [TEST]",
			color = Color3.fromRGB(183, 0, 255),
		},
		["Deauthorize"] = {
			auth = false,
			text = "",
			color = Color3.fromRGB(0, 0, 0),
		},
	}
	
	AuthorizationService.Client.OnUpdateAuthorization:Connect(function(player, target, reason)
		if target ~= nil then
			local authData = AuthorizationsOptions[reason]
			if authData ~= nil then
				
				if authData.auth then
					self.PlayersWithAuthed[player] = target
				else
					self.PlayersWithAuthed[player] = nil
					
					--Teleport target back to CDC if not in it
					--local CDCRegionService = Knit.Services.CDCRegionService
					--if not CDCRegionService:IsPlayerInCDC(target) then
					--	target.Character.HumanoidRootPart.CFrame = TELEPORTS.CDCAuth.CFrame
					--	NotificationService:ShowNotification(target, 3, "You have been moved back to the CDC due to unauthorization.", Color3.fromRGB(53, 151, 255))
					--end
				end
				
				AuthorizationService.Players[target] = authData.auth
				JobService:Award(player)
				NametagService:UpdateStatus(target, authData.text, authData.color)
				--self:AddToLogHistory(player, target, reason)
			end
		end
	end)
	--function self:UpdateAuthorization

	--function self:Set(player, level)

	--	self.Players[player] = level;
	--	self.Client.OnUpdate:Fire(player, level);
	--	NotificationService:ShowNotification(player, 3, "You have Access Level: "..level, Color3.fromRGB(53, 151, 255))
	--end

	ProfileService.PlayerAdded:Connect(function(player)
		AuthorizationService.Players[player] = true
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		AuthorizationService.Players[player] = nil
		AuthorizationService.Prompts[player] = nil
		
		--Remove players own authed people
		AuthorizationService.PlayersWithAuthed[player] = nil
		
		--Remove player as authed from other people
		for key, plr in pairs(AuthorizationService.PlayersWithAuthed) do
			if plr == player then
				AuthorizationService.PlayersWithAuthed[key] = nil
				break
			end
		end
		
	end)

end

return AuthorizationService