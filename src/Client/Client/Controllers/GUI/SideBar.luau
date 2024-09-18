

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local MainMenuService = Knit.GetService("MainMenuService")

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local IS_STUDIO = RunService:IsStudio()

local PLAYER = game:GetService("Players").LocalPlayer
local RIGHT_BAR = PLAYER.PlayerGui:WaitForChild("RightBar")
local LEFT_BAR = PLAYER.PlayerGui:WaitForChild("LeftBar")
local TIME = PLAYER.PlayerGui:WaitForChild("Time")
local LEVEL = PLAYER.PlayerGui:WaitForChild("Level")
local CASH = PLAYER.PlayerGui:WaitForChild("Cash")
local SCHEDULE = PLAYER.PlayerGui:WaitForChild("Schedule")
local ACCESSLEVEL = PLAYER.PlayerGui:WaitForChild("AccessLevel")
local ACTION = PLAYER.PlayerGui:WaitForChild("Action")
local JOB = PLAYER.PlayerGui:WaitForChild("Job")
local TEAMHELP = PLAYER.PlayerGui:WaitForChild("TeamHelp")

local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

	
local SideBarController = Knit.CreateController({ 
	Name = "SideBarController",
	VisibilityChanged = KnitSignal.new(),
	SelectionChanged = KnitSignal.new(),
})


--Starts the main menu and registers mouse click events.
function SideBarController:KnitStart()
	local ProfileService = Knit.GetService("ProfileService")
	local TransactionService = Knit.GetService("TransactionService")
	local ItemService = Knit.GetService("ItemService")
	local GamepassService = Knit.GetService("GamepassService")
	
	
	local MainMenuController = Knit.GetController("MainMenuController")
	local CharacterEditorController = Knit.GetController("CharacterEditorController")
	local LoginAwardController = Knit.GetController("LoginAwardController")
	local ObjectivesController = Knit.GetController("ObjectivesController")
	local SecurityCameraController = Knit.GetController("SecurityCameraController")
	local FoodStandController = Knit.GetController("FoodStandController")
	local ActionController = Knit.GetController("ActionController")
	local JobController = Knit.GetController("JobController")
	local CDShopController = Knit.GetController("CDShopController")
	local TeamHelpController = Knit.GetController("TeamHelpController")
	local BundleController = Knit.GetController("BundleController")
	local RadioController = Knit.GetController("RadioController")
	local NightVisionController = Knit.GetController("NightVisionController")
	
	self.VisibilityChanged:Connect(function(status)
		RIGHT_BAR.Enabled = status
		LEFT_BAR.Enabled = status
		TIME.Enabled = status
		LEVEL.Enabled = status
		CASH.Enabled = status
		SCHEDULE.Enabled = status
		ACCESSLEVEL.Enabled = status
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, status)	
	end)
	
	JobController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
		if status then wait()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end)
	
	ActionController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
		if status then wait()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end)

	MainMenuController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	TeamHelpController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	FoodStandController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	CharacterEditorController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)

	LoginAwardController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	ObjectivesController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	SecurityCameraController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	CDShopController.VisibilityChanged:Connect(function(status)
		self.VisibilityChanged:Fire(not status)
	end)
	
	local MenuButtons = RIGHT_BAR.Frame
	for _, option in pairs(MenuButtons:GetChildren()) do
		if option:IsA("ImageButton") then
			
			SideBarController.SelectionChanged:Connect(function(open)
				--if option == open then
				--	self:ShowDisplayName(option)
				--else
				--	self:HideDisplayName(option)
				--end
			end)
			
			
			option.InputBegan:Connect(function()
				SideBarController.SelectionChanged:Fire(option)
			end)
			
			option.InputEnded:Connect(function()
				SideBarController.SelectionChanged:Fire()
			end)
			
			option.MouseButton1Down:Connect(function()
				self:HideDisplayName(option)
				option.Selected = false
				if option.Name == "CharacterEditor" then
					CharacterEditorController:Show()
				elseif option.Name == "MainMenu" then
					MainMenuController:ShowMenu()
				elseif option.Name == "LoginAward" then
					LoginAwardController:Show()
				elseif option.Name == "Objectives" then
					ObjectivesController:Show()
				elseif option.Name == "NightVision" then
					--check for gamepass
					local ownsGamepass = GamepassService:HasGamepass("Night Vision")
					--if not ownsGamepass and not IS_STUDIO then
					if not ownsGamepass then
						local rank = PLAYER:GetRankInGroup(4889827)
						if rank < 9 then
							BundleController:Show("Night Vision")
							return
						end
					end
					
					NightVisionController:Toggle()
				end
			end)
		end
	end
	
	local MenuButtons = LEFT_BAR.Container
	for _, option in pairs(MenuButtons:GetChildren()) do
		if option:IsA("ImageButton") then

			--SideBarController.SelectionChanged:Connect(function(open)
			--	--if option == open then
			--	--	self:ShowDisplayName(option)
			--	--else
			--	--	self:HideDisplayName(option)
			--	--end
			--end)


			--option.InputBegan:Connect(function()
			--	SideBarController.SelectionChanged:Fire(option)
			--end)

			--option.InputEnded:Connect(function()
			--	SideBarController.SelectionChanged:Fire()
			--end)

			option.MouseButton1Down:Connect(function()
				--self:HideDisplayName(option)
				option.Selected = false
				if option.Name == "TeamHelp" then
					TeamHelpController:Show()
				end
				
				if option.Name == "Bundles" then
					BundleController:Show()
				end
				
				if option.Name == "Radio" then
					local ownsGamepass = GamepassService:HasGamepass("Radio")
					if not ownsGamepass and not IS_STUDIO then
						
						local rank = PLAYER:GetRankInGroup(4889827)
						if rank < 9 then
							BundleController:Show("Radio")
							return
						end
					end
					
					--Show
					RadioController:Show()
				end
			end)
		end
	end
	
	function SideBarController:ShowDisplayName(option)
		SOUNDS.Click:Play()
		option.DisplayName.Visible = true
	end

	function SideBarController:HideDisplayName(option)
		--SOUNDS.Click:Play()
		option.DisplayName.Visible = false
	end

end


--Initalizes everything in order to properly show the main menu
--function SideBarController:ShowMenu()
--	coroutine.wrap(function()
--		MainMenuService:RequestStreamingAtCameraTransition()
--	end)()
--	StarterGui:SetCore("TopbarEnabled", false)
--	--SOUNDS.MenuMusic:Play()
--	MAIN_MENU.Enabled = true
--	self.VisibilityChanged:Fire(true)
--end


--Uninitalizes everything used in order to properly show the main menu
--function SideBarController:HideMenu()
--	MAIN_MENU.Enabled = false
--	--SOUNDS.MenuMusic:Stop()
--	CameraSystem:ResetCamera()
--	StarterGui:SetCore("TopbarEnabled", true)
--	self.VisibilityChanged:Fire(false)
--end


return SideBarController