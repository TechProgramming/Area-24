

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local MarketPlaceService	= game:GetService("MarketplaceService");
local CollectionService		= game:GetService("CollectionService");
local TeamsService			= game:GetService("Teams");

local TeamingService = Knit.CreateService({ 
	Name = "TeamingService", 
	Client = {
		PlayersTeamChanged = RemoteSignal.new()
	} ,
	PlayersTeamChanged = KnitSignal.new(),
})


function TeamingService:KnitStart()
	
	local NotificationService	= Knit.Services.NotificationService;
	local AnalyticsService		= Knit.Services.AnalyticsService;
	local BundleService 		= Knit.GetService("BundleService")
	local ProfileService 		= Knit.GetService("ProfileService")
	--Teams the player with the specifed team
	function TeamingService:TeamPlayer(player, team)
		local currentTeam = player.Team
		if currentTeam == team then
			return false
		end
		player.Team = team
		
		AnalyticsService:Log("joined-team", player, {
			Team = team.Name
		})
		self.PlayersTeamChanged:Fire(player, team, currentTeam);
		self.Client.PlayersTeamChanged:Fire(player, team, currentTeam)
		return true
	end
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		character:WaitForChild("HumanoidRootPart").Touched:Connect(function(part)
			if part.Name == "JOIN_CHAOS" then
				if player.Team.Name == "Class - D" then
					local JobService = Knit.Services.JobService
					JobService:Award(player)
					local newTeam = TeamingService:TeamPlayer(player, TeamsService["Chaos Insurgency"]);
					if newTeam then
						player:LoadCharacter();
						--BundleService:Prompt(player, "Chaos Insurgency")
					end;
				else
					NotificationService:ShowNotification(player, 2, "Only Class - D can join Insurgency.", Color3.fromRGB(255, 55, 55))
				end;
			end
		end)
	end)
	
	for _, holder in pairs(CollectionService:GetTagged("Team Changer")) do

		if holder:FindFirstChild("ProximityPrompt") then

			holder.ProximityPrompt.Triggered:Connect(function(player)
				
				if player.Team.Name == "Class - D" then
					local JobService = Knit.Services.JobService
					JobService:Award(player)
					local newTeam = TeamingService:TeamPlayer(player, TeamsService["Chaos Insurgency"]);
					if newTeam then
						player:LoadCharacter();
						--BundleService:Prompt(player, "Chaos Insurgency")
					end;
				else
					NotificationService:ShowNotification(player, 2, "Only Class - D can join Insurgency.", Color3.fromRGB(255, 55, 55))
				end;
			end);
		end;
	end;
end;

--Allows clients to ask to join a team
function TeamingService.Client:AskToJoinTeam(player, teamName)
	--Get and check if team exists
	local team = TeamsService[teamName]
	if not team then
		player:Kick("Exploiting Team Service")
		return false
	end
	
	--Check if player owns team gamepass if team requires it. If a user's rank id is 9 or above, allow to team anyways.
	
	local gamepasses = team.TeamMenuConfig:FindFirstChild("Gamepasses")
	if gamepasses then
		local ownsAnyRequiredGamepass = false
		for _,gamepass in pairs(gamepasses:GetChildren()) do
			local id = gamepass.Value
			local ownsGamepass = MarketPlaceService:UserOwnsGamePassAsync(player.UserId, id)
			if ownsGamepass then
				ownsAnyRequiredGamepass = true
				break
			end
		end
		
		if not ownsAnyRequiredGamepass and not game:GetService("RunService"):IsStudio() then
			local groupRank = player:GetRankInGroup(4889827)
			if groupRank < 9 then
				MarketPlaceService:PromptGamePassPurchase(player, team:GetAttribute("NewGamepass"))
				return false
			end
		end
	end
	
	--Respawn player and team them
	local newTeam = TeamingService:TeamPlayer(player, team)
	if newTeam then
		player:LoadCharacter()
	end
	return true
end;

return TeamingService;