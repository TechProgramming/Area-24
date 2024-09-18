--[[
	CameraModule - This ModuleScript implements a singleton class to manage the
	selection, activation, and deactivation of the current camera controller,
	character occlusion controller, and transparency controller. This script binds to
	RenderStepped at Camera priority and calls the Update() methods on the active
	controller instances.

	The camera controller ModuleScripts implement classes which are instantiated and
	activated as-needed, they are no longer all instantiated up front as they were in
	the previous generation of PlayerScripts.

	2018 PlayerScripts Update - AllYourBlox
--]]

local CameraModule = {}
CameraModule.__index = CameraModule

local FFlagUserCameraToggle do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserCameraToggle")
	end)
	FFlagUserCameraToggle = success and result
end

local FFlagUserRemoveTheCameraApi do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserRemoveTheCameraApi")
	end)
	FFlagUserRemoveTheCameraApi = success and result
end

local FFlagUserCameraInputRefactor do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserCameraInputRefactor2")
	end)
	FFlagUserCameraInputRefactor = success and result
end

-- NOTICE: Player property names do not all match their StarterPlayer equivalents,
-- with the differences noted in the comments on the right
local PLAYER_CAMERA_PROPERTIES =
{
	"CameraMinZoomDistance",
	"CameraMaxZoomDistance",
	"CameraMode",
	"DevCameraOcclusionMode",
	"DevComputerCameraMode",			-- Corresponds to StarterPlayer.DevComputerCameraMovementMode
	"DevTouchCameraMode",				-- Corresponds to StarterPlayer.DevTouchCameraMovementMode

	-- Character movement mode
	"DevComputerMovementMode",
	"DevTouchMovementMode",
	"DevEnableMouseLock",				-- Corresponds to StarterPlayer.EnableMouseLockOption
}

local USER_GAME_SETTINGS_PROPERTIES =
{
	"ComputerCameraMovementMode",
	"ComputerMovementMode",
	"ControlMode",
	"GamepadCameraSensitivity",
	"MouseSensitivity",
	"RotationType",
	"TouchCameraMovementMode",
	"TouchMovementMode",
}

--[[ Roblox Services ]]--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- Static camera utils
local CameraUtils = require(script:WaitForChild("CameraUtils"))
local CameraInput = require(script:WaitForChild("CameraInput"))

-- Load Roblox Camera Controller Modules
local ClassicCamera = require(script:WaitForChild("ClassicCamera"))
local OrbitalCamera = require(script:WaitForChild("OrbitalCamera"))
local LegacyCamera = require(script:WaitForChild("LegacyCamera"))

-- Load Roblox Occlusion Modules
local Invisicam = require(script:WaitForChild("Invisicam"))
local Poppercam = require(script:WaitForChild("Poppercam"))

-- Load the near-field character transparency controller and the mouse lock "shift lock" controller
local TransparencyController = require(script:WaitForChild("TransparencyController"))
local MouseLockController = require(script:WaitForChild("MouseLockController"))

-- Table of camera controllers that have been instantiated. They are instantiated as they are used.
local instantiatedCameraControllers = {}
local instantiatedOcclusionModules = {}

-- Management of which options appear on the Roblox User Settings screen
do
	local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")

	PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Default)
	PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Follow)
	PlayerScripts:RegisterTouchCameraMovementMode(Enum.TouchCameraMovementMode.Classic)

	PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Default)
	PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Follow)
	PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.Classic)
	if FFlagUserCameraToggle then
		PlayerScripts:RegisterComputerCameraMovementMode(Enum.ComputerCameraMovementMode.CameraToggle)
	end
end

local FPSController
local CameraController
local CDShopController
local MainMenuController
local SideBarController
local CharacterEditorController
local GUIExposerController

local IsUIShown = false

function CameraModule.new()
	local self = setmetatable({},CameraModule)

	-- Current active controller instances
	self.activeCameraController = nil
	self.activeOcclusionModule = nil
	self.activeTransparencyController = nil
	self.activeMouseLockController = nil

	self.currentComputerCameraMovementMode = nil

	-- Connections to events
	self.cameraSubjectChangedConn = nil
	self.cameraTypeChangedConn = nil

	-- Adds CharacterAdded and CharacterRemoving event handlers for all current players
	for _,player in pairs(Players:GetPlayers()) do
		self:OnPlayerAdded(player)
	end

	-- Adds CharacterAdded and CharacterRemoving event handlers for all players who join in the future
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)

	self.activeTransparencyController = TransparencyController.new()
	self.activeTransparencyController:Enable(true)

	--if not UserInputService.TouchEnabled then
		self.activeMouseLockController = MouseLockController.new()
		local toggleEvent = self.activeMouseLockController:GetBindableToggleEvent()
		if toggleEvent then
			toggleEvent:Connect(function()
				self:OnMouseLockToggled()
			end)
		end
	--end

	self:ActivateCameraController(self:GetCameraControlChoice())
	self:ActivateOcclusionModule(Players.LocalPlayer.DevCameraOcclusionMode)
	self:OnCurrentCameraChanged() -- Does initializations and makes first camera controller
	
	local value = Instance.new("IntValue", script)
	value.Name = "Render"
	value.Value = Enum.RenderPriority.Camera.Value
	RunService:BindToRenderStep("cameraRenderUpdate", value.Value, function(dt) self:Update(dt) end)
	value.Changed:Connect(function(v)
		RunService:UnbindFromRenderStep("cameraRenderUpdate")
		RunService:BindToRenderStep("cameraRenderUpdate", value.Value, function(dt) self:Update(dt) end)
	end)

	-- Connect listeners to camera-related properties
	for _, propertyName in pairs(PLAYER_CAMERA_PROPERTIES) do
		Players.LocalPlayer:GetPropertyChangedSignal(propertyName):Connect(function()
			self:OnLocalPlayerCameraPropertyChanged(propertyName)
		end)
	end

	for _, propertyName in pairs(USER_GAME_SETTINGS_PROPERTIES) do
		UserGameSettings:GetPropertyChangedSignal(propertyName):Connect(function()
			self:OnUserGameSettingsPropertyChanged(propertyName)
		end)
	end
	game.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:OnCurrentCameraChanged()
	end)

	self.lastInputType = UserInputService:GetLastInputType()
	UserInputService.LastInputTypeChanged:Connect(function(newLastInputType)
		self.lastInputType = newLastInputType
	end)

	coroutine.wrap(function()
		local FrameworkData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameData"):WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))
		warn("waiting for fpscontroller")
		local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Knit"))
		FPSController = Knit.Controllers["FPSController"] or Knit.GetControllerInitSignal("FPSController").Event:Wait()
		
		--CDShopController = Knit.Controllers["CDShopController"]
		--MainMenuController = Knit.Controllers["MainMenuController"]
		--SideBarController = Knit.Controllers["SideBarController"]
		--CharacterEditorController = Knit.Controllers["CharacterEditorController"]
		CameraController = Knit.Controllers["CameraController"]
		GUIExposerController = Knit.Controllers["GUIExposerController"]
		
		FPSController.OnEquippedToggledSignal:Connect(function(isEquipped)
			self:EnableEquip(isEquipped)
		end)
		
		FPSController.OnAtEaseToggledSignal:Connect(function(isAtEase)
			--print("CameraModule::OnAtEaseToggledSignal", isAtEase)
			self:EnableAtEase(isAtEase)
		end)


		local wasMouseEnabledDueToUI = false
		local function onUIStateUpdated(state)
			IsUIShown = GUIExposerController:GetIsAnyEnabled()
			--print("CURRENT GUI STATES", IsUIShown, GUIExposerController.CurrentStates)
			self:UpdateMouseLock()
			--[[
			if not state then
				if wasMouseEnabledDueToUI then
					wasMouseEnabledDueToUI = false
					if not FPSController:GetIsAtEase() or CameraController:GetIsFirstPerson() then
						UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
						repeat UserInputService.MouseIconEnabled = false wait() until UserInputService.MouseIconEnabled == false
					end
				end
			else
				if not FPSController:GetIsAtEase() or CameraController:GetIsFirstPerson() then
					wasMouseEnabledDueToUI = true
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					repeat UserInputService.MouseIconEnabled = true wait() until UserInputService.MouseIconEnabled == true
				end
			end--]]
		end
		--[[
		if CDShopController then
			CDShopController.VisibilityChanged:Connect(onUIStateUpdated)
		end
		if MainMenuController then
			MainMenuController.VisibilityChanged:Connect(onUIStateUpdated)
		end
		if SideBarController then
			SideBarController.VisibilityChanged:Connect(onUIStateUpdated)
		end
		if CharacterEditorController then
			CharacterEditorController.VisibilityChanged:Connect(onUIStateUpdated)
		end--]]
		GUIExposerController.VisibilityChanged:Connect(onUIStateUpdated)
	end)()
	
	self.isEquipped = false
	self.isAtEase = true
	
	self.activeCameraController.firstPersonToggled.Event:Connect(function(state)
		self:UpdateMouseLock()
	end)
	
	return self
end

function CameraModule:GetCameraMovementModeFromSettings()
	local cameraMode = Players.LocalPlayer.CameraMode

	-- Lock First Person trumps all other settings and forces ClassicCamera
	if cameraMode == Enum.CameraMode.LockFirstPerson then
		return CameraUtils.ConvertCameraModeEnumToStandard(Enum.ComputerCameraMovementMode.Classic)
	end

	local devMode, userMode
	if UserInputService.TouchEnabled then
		devMode = CameraUtils.ConvertCameraModeEnumToStandard(Players.LocalPlayer.DevTouchCameraMode)
		userMode = CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.TouchCameraMovementMode)
	else
		devMode = CameraUtils.ConvertCameraModeEnumToStandard(Players.LocalPlayer.DevComputerCameraMode)
		userMode = CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.ComputerCameraMovementMode)
	end

	if devMode == Enum.DevComputerCameraMovementMode.UserChoice then
		-- Developer is allowing user choice, so user setting is respected
		return userMode
	end

	return devMode
end

function CameraModule:ActivateOcclusionModule( occlusionMode )
	local newModuleCreator
	if occlusionMode == Enum.DevCameraOcclusionMode.Zoom then
		newModuleCreator = Poppercam
	elseif occlusionMode == Enum.DevCameraOcclusionMode.Invisicam then
		newModuleCreator = Invisicam
	else
		warn("CameraScript ActivateOcclusionModule called with unsupported mode")
		return
	end

	-- First check to see if there is actually a change. If the module being requested is already
	-- the currently-active solution then just make sure it's enabled and exit early
	if self.activeOcclusionModule and self.activeOcclusionModule:GetOcclusionMode() == occlusionMode then
		if not self.activeOcclusionModule:GetEnabled() then
			self.activeOcclusionModule:Enable(true)
		end
		return
	end

	-- Save a reference to the current active module (may be nil) so that we can disable it if
	-- we are successful in activating its replacement
	local prevOcclusionModule = self.activeOcclusionModule

	-- If there is no active module, see if the one we need has already been instantiated
	self.activeOcclusionModule = instantiatedOcclusionModules[newModuleCreator]

	-- If the module was not already instantiated and selected above, instantiate it
	if not self.activeOcclusionModule then
		self.activeOcclusionModule = newModuleCreator.new()
		if self.activeOcclusionModule then
			instantiatedOcclusionModules[newModuleCreator] = self.activeOcclusionModule
		end
	end

	-- If we were successful in either selecting or instantiating the module,
	-- enable it if it's not already the currently-active enabled module
	if self.activeOcclusionModule then
		local newModuleOcclusionMode = self.activeOcclusionModule:GetOcclusionMode()
		-- Sanity check that the module we selected or instantiated actually supports the desired occlusionMode
		if newModuleOcclusionMode ~= occlusionMode then
			warn("CameraScript ActivateOcclusionModule mismatch: ",self.activeOcclusionModule:GetOcclusionMode(),"~=",occlusionMode)
		end

		-- Deactivate current module if there is one
		if prevOcclusionModule then
			-- Sanity check that current module is not being replaced by itself (that should have been handled above)
			if prevOcclusionModule ~= self.activeOcclusionModule then
				prevOcclusionModule:Enable(false)
			else
				warn("CameraScript ActivateOcclusionModule failure to detect already running correct module")
			end
		end

		-- Occlusion modules need to be initialized with information about characters and cameraSubject
		-- Invisicam needs the LocalPlayer's character
		-- Poppercam needs all player characters and the camera subject
		if occlusionMode == Enum.DevCameraOcclusionMode.Invisicam then
			-- Optimization to only send Invisicam what we know it needs
			if Players.LocalPlayer.Character then
				self.activeOcclusionModule:CharacterAdded(Players.LocalPlayer.Character, Players.LocalPlayer )
			end
		else
			-- When Poppercam is enabled, we send it all existing player characters for its raycast ignore list
			for _, player in pairs(Players:GetPlayers()) do
				if player and player.Character then
					self.activeOcclusionModule:CharacterAdded(player.Character, player)
				end
			end
			self.activeOcclusionModule:OnCameraSubjectChanged(game.Workspace.CurrentCamera.CameraSubject)
		end

		-- Activate new choice
		self.activeOcclusionModule:Enable(true)
	end
end

-- When supplied, legacyCameraType is used and cameraMovementMode is ignored (should be nil anyways)
-- Next, if userCameraCreator is passed in, that is used as the cameraCreator
function CameraModule:ActivateCameraController(cameraMovementMode, legacyCameraType)
	local newCameraCreator = nil

	if legacyCameraType~=nil then
		--[[
			This function has been passed a CameraType enum value. Some of these map to the use of
			the LegacyCamera module, the value "Custom" will be translated to a movementMode enum
			value based on Dev and User settings, and "Scriptable" will disable the camera controller.
		--]]

		if legacyCameraType == Enum.CameraType.Scriptable then
			if self.activeCameraController then
				self.activeCameraController:Enable(false)
				self.activeCameraController = nil
				return
			end
		elseif legacyCameraType == Enum.CameraType.Custom then
			cameraMovementMode = self:GetCameraMovementModeFromSettings()

		elseif legacyCameraType == Enum.CameraType.Track then
			-- Note: The TrackCamera module was basically an older, less fully-featured
			-- version of ClassicCamera, no longer actively maintained, but it is re-implemented in
			-- case a game was dependent on its lack of ClassicCamera's extra functionality.
			cameraMovementMode = Enum.ComputerCameraMovementMode.Classic

		elseif legacyCameraType == Enum.CameraType.Follow then
			cameraMovementMode = Enum.ComputerCameraMovementMode.Follow

		elseif legacyCameraType == Enum.CameraType.Orbital then
			cameraMovementMode = Enum.ComputerCameraMovementMode.Orbital

		elseif legacyCameraType == Enum.CameraType.Attach or
			   legacyCameraType == Enum.CameraType.Watch or
			   legacyCameraType == Enum.CameraType.Fixed then
			newCameraCreator = LegacyCamera
		else
			warn("CameraScript encountered an unhandled Camera.CameraType value: ",legacyCameraType)
		end
	end

	if not newCameraCreator then
		if cameraMovementMode == Enum.ComputerCameraMovementMode.Classic or
			cameraMovementMode == Enum.ComputerCameraMovementMode.Follow or
			cameraMovementMode == Enum.ComputerCameraMovementMode.Default or
			(FFlagUserCameraToggle and cameraMovementMode == Enum.ComputerCameraMovementMode.CameraToggle) or
			cameraMovementMode == Enum.ComputerCameraMovementMode.Orbital then
			newCameraCreator = ClassicCamera
		-- EDIT: Make sure orbital cant be activated since we only want ClassicCamera
		--elseif cameraMovementMode == Enum.ComputerCameraMovementMode.Orbital then
		--	newCameraCreator = OrbitalCamera
		else
			warn("ActivateCameraController did not select a module.")
			return
		end
	end

	-- Create the camera control module we need if it does not already exist in instantiatedCameraControllers
	local newCameraController
	if not instantiatedCameraControllers[newCameraCreator] then
		newCameraController = newCameraCreator.new()
		instantiatedCameraControllers[newCameraCreator] = newCameraController
	else
		newCameraController = instantiatedCameraControllers[newCameraCreator]
	end

	-- If there is a controller active and it's not the one we need, disable it,
	-- if it is the one we need, make sure it's enabled
	if self.activeCameraController then
		if self.activeCameraController ~= newCameraController then
			self.activeCameraController:Enable(false)
			self.activeCameraController = newCameraController
			self.activeCameraController:Enable(true)
		elseif not self.activeCameraController:GetEnabled() then
			self.activeCameraController:Enable(true)
		end
	elseif newCameraController ~= nil then
		self.activeCameraController = newCameraController
		self.activeCameraController:Enable(true)
	end

	if self.activeCameraController then
		if cameraMovementMode~=nil then
			self.activeCameraController:SetCameraMovementMode(cameraMovementMode)
		elseif legacyCameraType~=nil then
			-- Note that this is only called when legacyCameraType is not a type that
			-- was convertible to a ComputerCameraMovementMode value, i.e. really only applies to LegacyCamera
			self.activeCameraController:SetCameraType(legacyCameraType)
		end
	end
	
	if self.activeCameraController and self.activeMouseLockController then
		self.activeCameraController:SetIsMouseLocked(self.activeMouseLockController:GetIsMouseLocked())
	end
end

-- Note: The active transparency controller could be made to listen for this event itself.
function CameraModule:OnCameraSubjectChanged()
	if self.activeTransparencyController then
		self.activeTransparencyController:SetSubject(game.Workspace.CurrentCamera.CameraSubject)
	end

	if self.activeOcclusionModule then
		self.activeOcclusionModule:OnCameraSubjectChanged(game.Workspace.CurrentCamera.CameraSubject)
	end
end

function CameraModule:OnCameraTypeChanged(newCameraType)
	if newCameraType == Enum.CameraType.Scriptable then
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	-- Forward the change to ActivateCameraController to handle
	self:ActivateCameraController(nil, newCameraType)
end

-- Note: Called whenever workspace.CurrentCamera changes, but also on initialization of this script
function CameraModule:OnCurrentCameraChanged()
	local currentCamera = game.Workspace.CurrentCamera
	if not currentCamera then return end

	if self.cameraSubjectChangedConn then
		self.cameraSubjectChangedConn:Disconnect()
	end

	if self.cameraTypeChangedConn then
		self.cameraTypeChangedConn:Disconnect()
	end

	self.cameraSubjectChangedConn = currentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
		self:OnCameraSubjectChanged(currentCamera.CameraSubject)
	end)

	self.cameraTypeChangedConn = currentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
		self:OnCameraTypeChanged(currentCamera.CameraType)
	end)

	self:OnCameraSubjectChanged(currentCamera.CameraSubject)
	self:OnCameraTypeChanged(currentCamera.CameraType)
end

function CameraModule:OnLocalPlayerCameraPropertyChanged(propertyName)
	if propertyName == "CameraMode" then
		-- CameraMode is only used to turn on/off forcing the player into first person view. The
		-- Note: The case "Classic" is used for all other views and does not correspond only to the ClassicCamera module
		if Players.LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
			-- Locked in first person, use ClassicCamera which supports this
			if not self.activeCameraController or self.activeCameraController:GetModuleName() ~= "ClassicCamera" then
				self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(Enum.DevComputerCameraMovementMode.Classic))
			end

			if self.activeCameraController then
				self.activeCameraController:UpdateForDistancePropertyChange()
			end
		elseif Players.LocalPlayer.CameraMode == Enum.CameraMode.Classic then
			-- Not locked in first person view
			local cameraMovementMode =self: GetCameraMovementModeFromSettings()
			self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(cameraMovementMode))
		else
			warn("Unhandled value for property player.CameraMode: ",Players.LocalPlayer.CameraMode)
		end

	elseif propertyName == "DevComputerCameraMode" or 
		   propertyName == "DevTouchCameraMode" then
		local cameraMovementMode = self:GetCameraMovementModeFromSettings()
		self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(cameraMovementMode))

	elseif propertyName == "DevCameraOcclusionMode" then
		self:ActivateOcclusionModule(Players.LocalPlayer.DevCameraOcclusionMode)

	elseif propertyName == "CameraMinZoomDistance" or propertyName == "CameraMaxZoomDistance" then
		if self.activeCameraController then
			self.activeCameraController:UpdateForDistancePropertyChange()
		end
	elseif propertyName == "DevTouchMovementMode" then
	elseif propertyName == "DevComputerMovementMode" then
	elseif propertyName == "DevEnableMouseLock" then
		-- This is the enabling/disabling of "Shift Lock" mode, not LockFirstPerson (which is a CameraMode)
		-- Note: Enabling and disabling of MouseLock mode is normally only a publish-time choice made via
		-- the corresponding EnableMouseLockOption checkbox of StarterPlayer, and this script does not have
		-- support for changing the availability of MouseLock at runtime (this would require listening to
		-- Player.DevEnableMouseLock changes)
	end
end

function CameraModule:OnUserGameSettingsPropertyChanged(propertyName)
	if propertyName == 	"ComputerCameraMovementMode" then
		local cameraMovementMode = self:GetCameraMovementModeFromSettings()
		self:ActivateCameraController(CameraUtils.ConvertCameraModeEnumToStandard(cameraMovementMode))
	end
end

--[[
	Main RenderStep Update. The camera controller and occlusion module both have opportunities
	to set and modify (respectively) the CFrame and Focus before it is set once on CurrentCamera.
	The camera and occlusion modules should only return CFrames, not set the CFrame property of
	CurrentCamera directly.
--]]
function CameraModule:Update(dt)
	debug.profilebegin("CameraModule")
	if self.activeCameraController then
		if FFlagUserCameraToggle then
			--self.activeCameraController:UpdateMouseBehavior()
		end

		local newCameraCFrame, newCameraFocus = self.activeCameraController:Update(dt)
		self.activeCameraController:ApplyVRTransform()
		if self.activeOcclusionModule then
			newCameraCFrame, newCameraFocus = self.activeOcclusionModule:Update(dt, newCameraCFrame, newCameraFocus)
		end

		-- Here is where the new CFrame and Focus are set for this render frame
		game.Workspace.CurrentCamera.CFrame = newCameraCFrame
		game.Workspace.CurrentCamera.Focus = newCameraFocus

		-- Update to character local transparency as needed based on camera-to-subject distance
		if self.activeTransparencyController then
			self.activeTransparencyController:Update()
		end

		if FFlagUserCameraInputRefactor and CameraInput.getInputEnabled() then
			CameraInput.resetInputForFrameEnd()
		end
	end
	debug.profileend()
end

-- Formerly getCurrentCameraMode, this function resolves developer and user camera control settings to
-- decide which camera control module should be instantiated. The old method of converting redundant enum types
function CameraModule:GetCameraControlChoice()
	
	return CameraUtils.ConvertCameraModeEnumToStandard(Enum.DevComputerCameraMovementMode.Classic)
	--return Enum.DevTouchCameraMovementMode.Classic
	--[[
	local player = Players.LocalPlayer

	if player then
		if self.lastInputType == Enum.UserInputType.Touch or UserInputService.TouchEnabled then
			-- Touch
			if player.DevTouchCameraMode == Enum.DevTouchCameraMovementMode.UserChoice then
				return CameraUtils.ConvertCameraModeEnumToStandard( UserGameSettings.TouchCameraMovementMode )
			else
				return CameraUtils.ConvertCameraModeEnumToStandard( player.DevTouchCameraMode )
			end
		else
			-- Computer
			if player.DevComputerCameraMode == Enum.DevComputerCameraMovementMode.UserChoice then
				local computerMovementMode = CameraUtils.ConvertCameraModeEnumToStandard(UserGameSettings.ComputerCameraMovementMode)
				return CameraUtils.ConvertCameraModeEnumToStandard(computerMovementMode)
			else
				return CameraUtils.ConvertCameraModeEnumToStandard(player.DevComputerCameraMode)
			end
		end
	end--]]
end

function CameraModule:OnCharacterAdded(char, player)
	if self.activeOcclusionModule then
		self.activeOcclusionModule:CharacterAdded(char, player)
	end
end

function CameraModule:OnCharacterRemoving(char, player)
	if self.activeOcclusionModule then
		self.activeOcclusionModule:CharacterRemoving(char, player)
	end
end

function CameraModule:OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char, player)
	end)
	player.CharacterRemoving:Connect(function(char)
		self:OnCharacterRemoving(char, player)
	end)
end

function CameraModule:OnMouseLockToggled()
	if self.activeMouseLockController then
		local mouseLocked = self.activeMouseLockController:GetIsMouseLocked()
		local mouseLockOffset = self.activeMouseLockController:GetMouseLockOffset()
		if self.activeCameraController then
			--print("CameraModule::OnMouseLockToggled", mouseLocked)
			--print(debug.traceback())
			self.activeCameraController:SetIsMouseLocked(mouseLocked)
			self.activeCameraController:SetMouseLockOffset(mouseLockOffset)
		end
	end
end

function CameraModule:GetSubjectDistance()
	return self.activeCameraController.currentSubjectDistance
end

function CameraModule:GetIsInFirstPerson()
	return self.activeCameraController and self.activeCameraController:IsInFirstPerson()
end

function CameraModule:EnableFirstPerson(enable)
	if not UserInputService.TouchEnabled then
		if enable then
			--self.activeMouseLockController:EnableMouseLock(false)
		else
			--self.activeMouseLockController:EnableMouseLock(true)
		end
	end
	if self.activeCameraController then
		if enable then
			self.activeCameraController:EnterFirstPerson()
		else
			self.activeCameraController:LeaveFirstPerson()
		end
	end
end

function CameraModule:ForceFirstPerson(state)
	self.activeCameraController:ForceFirstPerson(state)
end

function CameraModule:UpdateMouseLock()
	--if UserInputService.TouchEnabled then return end
	local isLocked = self.activeMouseLockController:GetIsMouseLocked()
	local gunup = self.isEquipped and not self.isAtEase
	local isInFirstPerson = self:GetIsInFirstPerson()
	--print("CameraModule:UpdateMouseLock", self.isEquipped, self.isAtEase, isInFirstPerson, isLocked)
	
	local updated = false
	if (gunup or isInFirstPerson) and not IsUIShown and not isLocked then
		-- at Gun Up but not locking so lock
		updated = true
		self.activeMouseLockController:OnMouseLockToggled()
	elseif not gunup and isLocked then -- and not self.activeCameraController.inFirstPerson
		-- not at Gun Up but locking so unlock
		updated = true
		self.activeMouseLockController:OnMouseLockToggled()
	end
	if self.activeCameraController and updated then
		self.activeCameraController:UpdateMouseBehavior()
	end
	if IsUIShown or (not gunup and not isInFirstPerson)  then
		UserInputService.MouseIconEnabled = true
	else
		UserInputService.MouseIconEnabled = false
	end
end

function CameraModule:EnableAtEase(state)
	self.isAtEase = state
	self:UpdateMouseLock()
end

function CameraModule:EnableEquip(state)
	self.isEquipped = state
	self:UpdateMouseLock()
end

local cameraModuleObject = CameraModule.new()
local cameraApi = {}

--if FFlagUserRemoveTheCameraApi then
--	return cameraApi
--else
	return cameraModuleObject
--end
