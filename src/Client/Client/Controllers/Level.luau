local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)
local TitlesService = Knit.GetService("TitlesService")
local LevelService = Knit.GetService("LevelService")
local XPCalculator = require(ReplicatedStorage.XPCalculator)

local PLAYER = game:GetService("Players").LocalPlayer
local LEVEL_GUI = PLAYER.PlayerGui:WaitForChild("Level")
local MAINMENU = PLAYER.PlayerGui:WaitForChild("MainMenu")

local LevelController = Knit.CreateController({
	Name = "LevelController",
	CachedLevel = 0,
	Titles = {},
})

function LevelController:KnitStart() 
	--Setup main menu event
	local MainMenuController = Knit.GetController("MainMenuController")

	--Handle the main menu opening and closing
	MainMenuController.VisibilityChanged:Connect(function(visible)
		LEVEL_GUI.Enabled = not visible
	end)
	
	--Setup team changed event
	PLAYER:GetPropertyChangedSignal("Team"):Connect(function()
		self:GetNewLevelInfo()
	end)
	
	--Setup XP changed
	LevelService.XPChanged:Connect(function(teamName, totalXP, _changedBy)
		if PLAYER.Team.Name == teamName then
			self:SetNewLevelInfo(totalXP)
		end
	end)
	
	--Setup titles changed
	TitlesService.OnTitlesChanged:Connect(function(newTitles)
		self.Titles = newTitles
		self:GetNewLevelInfo()
	end)
	
	--Initial setup
	self.Titles = TitlesService:GetTitles()
	self:GetNewLevelInfo()
end


function LevelController:GetNewLevelInfo()
	LEVEL_GUI.Bar.Foreground.BackgroundColor3 = PLAYER.Team.TeamColor.Color
	
	local xp = LevelService:GetExperience(PLAYER.Team.Name)
	self:SetNewLevelInfo(xp)
end


function LevelController:SetNewLevelInfo(totalXP)
	--Get current level info
	local currentLevel = XPCalculator.getLevel(totalXP)
	local currentLevelXP = XPCalculator.getExperienceRequiredForLevel(currentLevel)
	local nextLevelXP = XPCalculator.getExperienceRequiredForLevel(currentLevel+1)-currentLevelXP
	
	--Get next rank name if exists
	local nextRank = ""
	local titles = self.Titles[PLAYER.Team.Name]
	if titles then
		for _,title in pairs(titles) do
			if title.requiredLevel == currentLevel+1 then
				nextRank = title.title
				break
			end
		end
	end
	
	--Set XP text and progress bar
	LEVEL_GUI.Bar.XP.Text = totalXP-currentLevelXP.."/"..nextLevelXP
	LEVEL_GUI.Bar.Foreground:TweenSize(UDim2.new((totalXP-currentLevelXP) / nextLevelXP,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint,.6,true)
	LEVEL_GUI.Bar.Title.Text = nextRank
	LEVEL_GUI.Bar.Level.Text = "Lv. "..currentLevel
	LevelController.CachedLevel = currentLevel
	MAINMENU.Container.Teams:WaitForChild(PLAYER.Team.Name).Level.Text = "Lv. "..currentLevel
end


return LevelController
