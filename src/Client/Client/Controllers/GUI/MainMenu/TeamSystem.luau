local Knit = require(game:GetService("ReplicatedStorage").Knit)

local TeamsService = game:GetService("Teams") 

local PLAYER = game:GetService("Players").LocalPlayer
local MAIN_MENU = PLAYER.PlayerGui:WaitForChild("MainMenu")
local TEMPLATE = MAIN_MENU.Container.Teams.Template
local ProfileService = Knit.GetService("ProfileService")
local XPCalculator = require(game.ReplicatedStorage.XPCalculator)

local TeamSystem = {
	debounce = false
}


--Create team frames and register click events 
function TeamSystem:Init(profile)
	local profile = ProfileService:GetProfile()
	for _,team in pairs(TeamsService:GetChildren()) do
		if not team:IsA("Team") then
			continue
		end
		
		--Create team button
		local teamButton = TEMPLATE:Clone()
		teamButton.Parent = MAIN_MENU.Container.Teams
		teamButton.Name = team.Name
		teamButton.TeamName.Text = team.Name
		teamButton.TeamName.TextColor3 = team.TeamColor.Color
		teamButton.LayoutOrder = team.TeamMenuConfig.LayoutOrder.Value
		teamButton.Icon.Image = team.TeamMenuConfig.Icon.Value
		teamButton.Visible = true
		
		local currentLevel = XPCalculator.getLevel(profile.Progress[team.Name].XP)

		teamButton.Level.Text = "Lv. "..currentLevel
		local requiresGamepass = team:GetAttribute("RequiresGamepass")
		
		if requiresGamepass then
			teamButton.Gamepass.Visible = true
		end
		
		local avatarModel = game.ReplicatedStorage.TeamMenuAvatars:WaitForChild(team.Name):Clone()
		avatarModel.Parent = teamButton.ViewportFrame
		--Register click for it
		teamButton.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not TeamSystem.debounce then
				TeamSystem.debounce = true
				print(team)
				TeamSystem:AskToJoinTeam(team)
				wait(2)
				TeamSystem.debounce = false
			end
		end)
		
		--Register Hover Affects
		teamButton.MouseEnter:Connect(function()
			TeamSystem:AddHoverEffects(teamButton)
		end)
		
		teamButton.MouseLeave:Connect(function()
			TeamSystem:RemoveHoverEffects(teamButton)
		end)
	end
end


--Add hover styling for the team button
function TeamSystem:AddHoverEffects(teamButton)
	--teamButton.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
end 


--Remove hover styling for the team button
function TeamSystem:RemoveHoverEffects(teamButton)
	--teamButton.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
end


--Asks the server to join a team
function TeamSystem:AskToJoinTeam(team)
	local TeamingService = Knit.GetService("TeamingService")
	local MainMenuController = Knit.GetController("MainMenuController")
	
	--Ask to join team
	local result = TeamingService:AskToJoinTeam(team.Name)
	if result then
		MainMenuController:HideMenu()
		local FactionController = Knit.GetController("FactionController")
		FactionController:Show()
	end
end


return TeamSystem