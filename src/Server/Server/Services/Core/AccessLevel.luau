local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal	= require(Knit.Util.Remote.RemoteSignal);

local PlayerService = game:GetService("Players");

local AccessLevelService = Knit.CreateService({ 
	Name = "AccessLevelService", 
	Players = {},
	Client = {
		OnUpdate = RemoteSignal.new(),
	}
})

local TeamDefaultAccessLevels = {
	["Class - D"] = 0,
	["Engineering and Technical"] = 2,
	["Scientific Department"] = 3,	
	["Security Department"] = 2,
	["Chaos Insurgency"] = 4,
	["Mobile Task Force"] = 4,
	["Site Director"] = 5,
	["Global Occult Coalition"] = 2,
	["O5 Council"] = 5,	
}

function AccessLevelService.Client:Get(player)
	return AccessLevelService:Get(player)
end

function AccessLevelService:KnitStart()
	
	local NotificationService	= Knit.GetService("NotificationService");
	local ProfileService		= Knit.GetService("ProfileService");
	local LevelService			= Knit.GetService("LevelService");

	function self:Get(player)
		return self.Players[player];
	end
	
	function self:Set(player, level)
		
		self.Players[player] = level;
		self.Client.OnUpdate:Fire(player, level);
		NotificationService:ShowNotification(player, 3, string.format("You have Access Level: %s", level), Color3.fromRGB(55, 155, 255))
	end
	
	ProfileService.PlayerAdded:Connect(function(player)
		self:Set(player, 0);
	end)
	
	function self:RunUpdateCheck(player, level, force)
		local team = player.Team
		local defaultTeamLevel = TeamDefaultAccessLevels[team.Name]
		
		local accesslevel = defaultTeamLevel
		if level >= 30 then
			accesslevel = accesslevel + 1
		end
		accesslevel = math.clamp(accesslevel, 0, 5)
		
		local playerLevel = self:Get(player) or 0
		
		if accesslevel ~= playerLevel and accesslevel > playerLevel then
			self:Set(player, accesslevel);			
		end
	end
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		self:Set(player, 0)
		local team = player.Team
		local level = LevelService:GetLevel(player, team.Name)
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		self.Players[player] = nil
	end)
	
	
end;

return AccessLevelService;