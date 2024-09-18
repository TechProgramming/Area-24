local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer

local TEAMHELP_UI = PLAYER.PlayerGui:WaitForChild("TeamHelp")
local TEAMSCONTAINER = TEAMHELP_UI:WaitForChild("Container")
local TEAMSFOLDER = TEAMSCONTAINER:WaitForChild("Teams")

local MAINMENU_UI = PLAYER.PlayerGui:WaitForChild("MainMenu")
local AWARD_UI = PLAYER.PlayerGui:WaitForChild("LoginAward")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local TeamHelpController = Knit.CreateController({
	Name = "TeamHelpController",
	VisibilityChanged = KnitSignal.new(),
	LastTeam = nil, 
	InitialVisibilityChanged = {
		["Chaos Insurgency"] = false,
		["Class - D"] = false,
		["Engineering and Technical"] = false,
		["Mobile Task Force"] = false,
		["Scientific Department"] = false,
		["Security Department"] = false,
	},
})




function TeamHelpController:KnitStart()
	
	repeat wait() until PLAYER.Team ~= nil
	local team = PLAYER.Team
	TeamHelpController.LastTeam = team
	local UI = TEAMSFOLDER:WaitForChild(team.Name)
	UI.Visible = true
	
	function TeamHelpController:Show()
		TEAMHELP_UI.Enabled = true
		
		local lastTeamUI = TEAMSFOLDER:WaitForChild(TeamHelpController.LastTeam.Name)
		lastTeamUI.Visible = false
		
		local teamName = PLAYER.Team.Name
		local nextTeamUI = TEAMSFOLDER:WaitForChild(teamName)
		nextTeamUI.Visible = true
		TeamHelpController.LastTeam = PLAYER.Team
		
		TEAMSCONTAINER.Title.Text = "HOW TO PLAY - " .. string.upper(teamName)
		
		self.VisibilityChanged:Fire(true)
	end
	
	function TeamHelpController:Hide()
		TEAMHELP_UI.Enabled = false
		local teamName = PLAYER.Team.Name
		self.VisibilityChanged:Fire(false)
		TeamHelpController.InitialVisibilityChanged[teamName] = true 
	end
	
	TEAMHELP_UI.Container.Close.CloseButton.MouseButton1Down:Connect(function()
		TeamHelpController:Hide()
	end)
	
	--coroutine.wrap(function()
	--	repeat wait(1) until MAINMENU_UI.Enabled == false and AWARD_UI.Enabled == false and 
	--	TeamHelpController:Show()
	--end)()
	
	PLAYER:GetPropertyChangedSignal("Team"):Connect(function()
		local teamName = PLAYER.Team.Name
		if TeamHelpController.InitialVisibilityChanged[teamName] == false then
			TeamHelpController:Show()
		end
	end)
end


return TeamHelpController