local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local FACTION_UI = PLAYER.PlayerGui:WaitForChild("Factions")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local FactionController = Knit.CreateController({
	Name = "FactionController",
	VisibilityChanged = KnitSignal.new(),
})


function FactionController:KnitStart()
	--local HelpMenuService = Knit.GetService("HelpMenuService")
	local FactionService = Knit.GetService("FactionService")

	-------------------------

	function FactionController:Show()
		local team = PLAYER.Team
		local teamFrame = FACTION_UI.Container.Teams:FindFirstChild(team.Name)
		if teamFrame then
			FACTION_UI.Enabled = true
			teamFrame.Visible = true
			self.VisibilityChanged:Fire(true)
		end
	end

	function FactionController:Hide()
		FACTION_UI.Enabled = false
		for _, team in pairs(FACTION_UI.Container.Teams:GetChildren()) do
			team.Visible = false
		end
		self.VisibilityChanged:Fire(false)
	end

	for _, team in pairs(FACTION_UI.Container.Teams:GetChildren()) do
		for _, faction in pairs(team:GetChildren()) do
			if faction:IsA("TextButton") then
				faction.CloseButton.MouseButton1Down:Connect(function()
					FactionService.OnFactionChanged:Fire(faction.Name)
					FactionController:Hide()
				end)
			end
		end
	end
	--LoginAwardController.InitialStateChanged:Connect(function(state)
	--	if state == false then
	--		if Profile.HelpMenuDisplayed[PLAYER.Team.Name] == false then
	--			HelpMenuController:Show()
	--		end
	--	end
	--end)

	--[[coroutine.wrap(function()
		repeat wait(1) until LoginAwardController.HasClosedInitialLogin == true
		
	end)()]]
end


return FactionController