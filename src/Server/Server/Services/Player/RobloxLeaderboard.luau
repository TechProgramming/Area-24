local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local MarketPlaceService	= game:GetService("MarketplaceService");
local CollectionService		= game:GetService("CollectionService");
local TeamsService			= game:GetService("Teams");

local RobloxLeaderboardService = Knit.CreateService({ 
	Name = "RobloxLeaderboardService", 
})


function RobloxLeaderboardService:KnitStart()
	
	local ProfileService	= Knit.Services.ProfileService;

	function RobloxLeaderboardService:GetPlayerLeaderboard(player)
		return player:WaitForChild("leaderstats", 2)
	end
	
	function RobloxLeaderboardService:CreateStat(player, class, name, value)
		local newValue = Instance.new(class)
		newValue.Name = name
		newValue.Value = value
		newValue.Parent = RobloxLeaderboardService:GetPlayerLeaderboard(player)
	end
	
	function RobloxLeaderboardService:UpdateStat(player, name, value)
		local board = RobloxLeaderboardService:GetPlayerLeaderboard(player)
		if board then
			local stat = board:WaitForChild(name, 2)
			if stat then
				stat.Value = value
			end
		end
	end
	
	local function UpdateLeaderboard(player, profile)
		local NametagService = Knit.Services.NametagService
		local currentFolder = player:FindFirstChild("leaderstats")
		if currentFolder then
			currentFolder:Destroy()
		end

		if not player.Team then
			return
		end

		local teamName = player.Team.Name

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		RobloxLeaderboardService:CreateStat(player, "StringValue", "Title", "")
		RobloxLeaderboardService:UpdateStat(player, "Title", NametagService:GetPlayerRankInTeam(player, teamName))
		RobloxLeaderboardService:CreateStat(player, "IntValue", "Level", "")
		RobloxLeaderboardService:UpdateStat(player, "Level", profile.Progress[teamName].Level)
	end
	
	ProfileService.PlayerAdded:Connect(function(player, profile)
		UpdateLeaderboard(player, profile)
		player:GetPropertyChangedSignal("Team"):Connect(function()
			UpdateLeaderboard(player, profile)
		end)
	end)
	
end

return RobloxLeaderboardService;