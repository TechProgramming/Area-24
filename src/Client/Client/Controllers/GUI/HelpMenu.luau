local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local HELP_UI = PLAYER.PlayerGui:WaitForChild("HelpMenu")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local HelpMenuController = Knit.CreateController({
	Name = "HelpMenuController",
	VisibilityChanged = KnitSignal.new(),
})


function HelpMenuController:KnitStart()
	--local HelpMenuService = Knit.GetService("HelpMenuService")
	local ProfileService = Knit.GetService("ProfileService")
	local LoginAwardController = Knit.GetController("LoginAwardController")
	local Profile = ProfileService.GetProfile()
	-------------------------
	
	function HelpMenuController:Show()
		HELP_UI.Enabled = true
		self.VisibilityChanged:Fire(true)
	end
	
	function HelpMenuController:Hide()
		HELP_UI.Enabled = false
		self.VisibilityChanged:Fire(false)
	end
	
	HELP_UI.Container.Close.CloseButton.MouseButton1Down:Connect(function()
		HelpMenuController:Hide()
	end)
	
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


return HelpMenuController