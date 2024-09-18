local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local XPCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("XPCalculator"))

local LevelService = Knit.CreateService({
	Name = "LevelService", 
	Client = {
		XPChanged = RemoteSignal.new()
	}
})


--Gets the player's level for a specific team
function LevelService:GetLevel(player, teamName)
	local profileService = Knit.Services.ProfileService
	local RobloxLeaderboardService = Knit.Services.RobloxLeaderboardService
	local AccessLevelService = Knit.GetService("AccessLevelService");
	--Get profile
	local profile = profileService:GetProfile(player)
	
	--Get team progress
	local team = profile.Progress[teamName]
	if not team then
		return 0
	end
	
	--Get level from xp
	local level = XPCalculator.getLevel(team.XP)
	team.Level = level
	AccessLevelService:RunUpdateCheck(player, level)
	RobloxLeaderboardService:UpdateStat(player, "Level", level)
	return level
end


--Allows the client to retrieve their level
function LevelService.Client:GetLevel(player, teamName)
	return LevelService:GetLevel(player, teamName)
end


--Gets the player's XP for a specific team
function LevelService:GetExperience(player, teamName)
	local profileService = Knit.Services.ProfileService

	--Get profile
	local profile = profileService:GetProfile(player)
	
	--Get team progress
	local team = profile.Progress[teamName]
	if not team then
		return 0
	end
	
	return team.XP
end


--Allow the client to retrieve their XP
function LevelService.Client:GetExperience(player, teamName)
	return LevelService:GetExperience(player, teamName)
end


--Adds XP to the specified player.
function LevelService:AddXP(player, teamName, amount)
	local profileService = Knit.Services.ProfileService
	
	--Get profile
	local profile = profileService:GetProfile(player)
	
	--Get team progress
	local team = profile.Progress[teamName]
	if not team then
		return
	end
	
	team.XP = team.XP + amount
	self.Client.XPChanged:Fire(player, teamName, team.XP, amount)
	local level = LevelService:GetLevel(player, teamName)
end


--Wrapper for AddXP but for removing
function LevelService:RemoveXP(player, teamName, amount)
	return self:AddXP(player, teamName, -amount)
end


--Adds levels
function LevelService:AddLevel(player, teamName, amount)
	local profileService = Knit.Services.ProfileService
	
	--Get profile
	local profile = profileService:GetProfile(player)
	
	--Get team progress
	local team = profile.Progress[teamName]
	if not team then
		return
	end
	
	local currentLevel = self:GetLevel(player, teamName)
	local requiredXP = XPCalculator.getExperienceRequiredForLevel(currentLevel + amount)
	team.XP = requiredXP
	local AccessLevelService = Knit.GetService("AccessLevelService");
end


--Wrapper for AddLevel but for removing
function LevelService:RemoveLevel(player, teamName, amount)
	self:AddLevel(player, teamName, -amount)
end


return LevelService