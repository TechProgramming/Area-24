

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local MainMenuService = Knit.GetService("MainMenuService")

local CameraSystem = require(script.CameraSystem)
local TeamSystem = require(script.TeamSystem)

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local PLAYER = game:GetService("Players").LocalPlayer
local MAIN_MENU = PLAYER.PlayerGui:WaitForChild("MainMenu")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local MainMenuController = Knit.CreateController({ 
	Name = "MainMenuController",
	VisibilityChanged = KnitSignal.new(),
})


--Starts the main menu and registers mouse click events.
function MainMenuController:KnitStart()
	StarterGui:SetCore("ChatWindowPosition", UDim2.new(0,0,0,6))
	local ProfileService = Knit.GetService("ProfileService")
	local TransactionService = Knit.GetService("TransactionService")
	local ItemService = Knit.GetService("ItemService")
	local ItemService = Knit.GetService("ItemService")

	-- CONTROLLERS
	local SideBarController = Knit.GetController("SideBarController")
	SideBarController.VisibilityChanged:Fire(false)
	
	local TabsSystem = require(script.TabsSystem)
	local profile = ProfileService:GetProfile()

	--Setup team buttons
	coroutine.wrap(function()
		TeamSystem.Init()
	end)()
	
	--Register all button click events
	local MenuButtons = MAIN_MENU.Container.MenuButtons
	for _, v in pairs(MenuButtons:GetChildren()) do
		if v:IsA("TextButton") then
			v.MouseButton1Down:Connect(function()
				SOUNDS.Click:Play()
				TabsSystem:SwitchTab(v.Name)
			end)
		end
	end
	
	--Initalizes everything in order to properly show the main menu
	function MainMenuController:ShowMenu()
		coroutine.wrap(function()
			MainMenuService:RequestStreamingAtCameraTransition()
		end)()
		
		StarterGui:SetCore("TopbarEnabled", false)
		SOUNDS.MenuMusic:Play()
		CameraSystem:StartTransition()
		MAIN_MENU.Enabled = true
		self.VisibilityChanged:Fire(true)
	end


	--Uninitalizes everything used in order to properly show the main menu
	function MainMenuController:HideMenu()
		MAIN_MENU.Enabled = false
		SOUNDS.MenuMusic:Stop()
		CameraSystem:ResetCamera()
		StarterGui:SetCore("TopbarEnabled", true)
		self.VisibilityChanged:Fire(false)
	end
	
	--Display the menu
	--if not RunService:IsStudio() then
		MainMenuController:ShowMenu()
	--end
end


return MainMenuController

--[[



]]