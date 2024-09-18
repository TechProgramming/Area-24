local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

--[[ Constants ]]--
local OnImageButtonBackgroundTransparency = 0.25
local OffImageButtonBackgroundTransparency = 0.7

local OnContainerBackgroundTransparency = 0.25
local OffContainerBackgroundTransparency = 0.8

local OnIconImageTransparency = 0
local OffIconImageTransparency = 0.7

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Knit = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Knit"))
local Thread = require(Knit.Util:WaitForChild("Thread"))

local FPSController
local MovementController
local CameraController

--[[ The Module ]]--
local BaseCharacterController = require(script.Parent:WaitForChild("BaseCharacterController"))
local TouchGunFramework = setmetatable({}, BaseCharacterController)
TouchGunFramework.__index = TouchGunFramework

function TouchGunFramework.new()
	local self = setmetatable(BaseCharacterController.new(), TouchGunFramework)
	
	self.isGunEquipped = false
	self.characterAddedConn = nil
	self.humanoidStateEnabledChangedConn = nil
	self.humanoidJumpPowerConn = nil
	self.humanoidParentConn = nil
	self.externallyEnabled = false
	self.jumpPower = 0
	self.jumpStateEnabled = true
	self.isJumping = false
	self.humanoid = nil -- saved reference because property change connections are made using it
	
	self.ui = PlayerGui:WaitForChild("MobileControls")
	self.aimButton = self.ui:WaitForChild("Aim")
	self.fireButton = self.ui:WaitForChild("Fire")
	self.reloadButton = self.ui:WaitForChild("Reload")
	self.changeCameraButton = self.ui:WaitForChild("ChangeCamera")
	self.changeModeButton = self.ui:WaitForChild("Mode")

	self.canChangeCamera = false
	self.canChangeMode = false

	self.canAim = false
	self.canFire = false
	self.canReload = false
	
	Thread.Spawn(function()
		
		FPSController = Knit.Controllers["FPSController"] or Knit.GetControllerInitSignal("FPSController").Event:Wait()
		MovementController = Knit.Controllers["MovementController"] or Knit.GetControllerInitSignal("MovementController").Event:Wait()
		CameraController = Knit.Controllers["CameraController"] or Knit.GetControllerInitSignal("CameraController").Event:Wait()
		
		FPSController.OnEquippedToggledSignal:Connect(function(isEquipped)
			self.isEquipped = isEquipped
			self:UpdateVisibility()
			--self:Enable(isEquipped, true)
		end)

		FPSController.OnAtEaseToggledSignal:Connect(function(isAtEase)
			self.isAtEase = isAtEase
			self:UpdateVisibility()
			--self:Enable(true, true)
		end)
		
		self.aimButton.InputBegan:Connect(function()
			self:aim()
		end)
		
		self.fireButton.InputBegan:Connect(function(input)
			self:fire(input)
		end)
		self.fireButton.InputEnded:Connect(function(input)
			self:fire(input)
		end)
		
		self.reloadButton.InputBegan:Connect(function()
			self:reload()
		end)
		
		self.changeCameraButton.InputBegan:Connect(function()
			self:toggleCamera()
		end)
		
		self.changeModeButton.InputBegan:Connect(function()
			self:toggleMode()
		end)

		self.isEquipped = FPSController:GetIsEquipped()
		self.isAtEase = FPSController:GetIsAtEase()
		
		self:Enable(UserInputService.TouchEnabled)
	end)

	return self
end

function TouchGunFramework:UpdateVisibility()
	local shouldAnyShow = self.enabled
	local shouldActionShow = shouldAnyShow and self.isEquipped and not self.isAtEase
	
	print("TouchGunFramework:UpdateVisibility", shouldAnyShow, shouldActionShow)

	self.canChangeCamera = shouldAnyShow
	self.canChangeMode = shouldAnyShow
	
	self.canAim = shouldActionShow
	self.canFire = shouldActionShow
	self.canReload = shouldActionShow
	
	
	self.changeCameraButton.Visible = shouldAnyShow
	self.changeModeButton.Visible = shouldAnyShow
	
	if shouldAnyShow and not shouldActionShow then
		self.aimButton.Visible = true
		self.fireButton.Visible = true
		self.reloadButton.Visible = true
	else
		self.aimButton.Visible = shouldActionShow
		self.fireButton.Visible = shouldActionShow
		self.reloadButton.Visible = shouldActionShow
	end
	
	local isOn = not (shouldAnyShow and not shouldActionShow)
	for _, imageButton in pairs({self.aimButton, self.fireButton, self.reloadButton}) do
		local container = imageButton.Container
		local icon = container.Icon
		
		imageButton.BackgroundTransparency = isOn and OnImageButtonBackgroundTransparency or OffImageButtonBackgroundTransparency
		container.BackgroundTransparency = isOn and OnContainerBackgroundTransparency or OffContainerBackgroundTransparency
		icon.ImageTransparency = isOn and OnIconImageTransparency or OffIconImageTransparency
	end
end

function TouchGunFramework:Enable(enable, skipCheck)
	self.enabled = enable
	print("TouchGunFramework::Enable", enable)
	--[[
	if skipCheck == true or enable == false or (FPSController and FPSController:GetIsEquipped() == enable) then

		self.aimButton.Visible = enable
		self.fireButton.Visible = enable
		self.reloadButton.Visible = enable
		self.changeCameraButton.Visible = enable
		self.changeModeButton.Visible = enable
	end
	--]]
	self:UpdateVisibility()
end

local function inputValid(inputObject)
	if inputObject.UserInputState ~= Enum.UserInputState.Begin or
		inputObject.UserInputType ~= Enum.UserInputType.Touch then
		return false
	end
	return true
end

function TouchGunFramework:reload(input)
	if not self.canReload then return false end
	print("started reloading on mobile")
	--if not inputValid(inputObject) then return end
	FPSController:Reload()
end

function TouchGunFramework:aim(enable)
	if not self.canAim then return false end
	print("started aiming on mobile")
	--if not inputValid(inputObject) then return end
	FPSController:ToggleAim()
end

function TouchGunFramework:fire(input)
	if not self.canFire then return false end
	if input.UserInputState == Enum.UserInputState.Change then return true end
	
	local enable = false
	if input.UserInputType == Enum.UserInputType.Touch then
		if input.UserInputState == Enum.UserInputState.Begin then
			enable = true
		end
	end
	print("setting firing on mobile to", enable)
	
	FPSController:SetFiring(enable)
end

function TouchGunFramework:toggleCamera()
	if not self.canChangeCamera then return false end
	--print("changed camera on mobile")
	
	CameraController:ToggleFirstPersonCamera()
end

function TouchGunFramework:toggleMode()
	if not self.canChangeMode then warn("TouchGunFramework::toggleMode failed, enabled == false") return false end
	print("TouchGunFramework::toggleMode changed mode")

	FPSController:ToggleAtEase()
end


return TouchGunFramework