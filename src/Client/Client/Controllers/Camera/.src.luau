local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


-- Constant Objects
local Player = Players.LocalPlayer

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local ScriptModules = script--.Parent:WaitForChild("CameraControllerModules")

local GameData = ReplicatedStorage:WaitForChild("GameData")
local FrameworkData = require(GameData:WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))

-- Requires
local Knit = require(SharedModules:WaitForChild("Knit"))
local Signal = require(Knit.Util.Signal)
local Cameras = {}

-- Other
local MovementController
local FPSController

local canEquip = true

local weaponsData = {}

local CameraController = Knit.CreateController({
	Name = "CameraController";

	IsInFirstPerson = false;

	OnFirstPersonUpdated = Signal.new();
})

setmetatable(CameraController, {
	__index = function(t, i)
		if rawget(CameraController,i) ~= nil then return rawget(CameraController,i) end
		if Cameras[i] ~= nil then return Cameras[i] end
		return nil
	end
})

function CameraController:GetIsFirstPerson()
	return Cameras.inFirstPerson
end

function CameraController:ChangeIsInFirstPerson(state)
	local old = self.IsInFirstPerson

	self.IsInFirstPerson = state

	if state ~= old then
		self.OnFirstPersonUpdated:Fire(state)
	end
end

function CameraController:ForceFirstPerson(state)
	if state then
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		Player.CameraMode = Enum.CameraMode.Classic
	end

	self.IsInFirstPerson = state
end

function CameraController:GetIsInFirstPerson()
	return self.IsInFirstPerson
end

function CameraController:EnableFirstPerson(enable)
	print("CameraController::EnableFirstPerson", enable)
	if enable then
		Cameras:EnableFirstPerson(true)
	else
		Cameras:EnableFirstPerson(false)
	end
end

function CameraController:ToggleFirstPersonCamera(force, state)
	local isFirstPerson = Player.CameraMode == Enum.CameraMode.LockFirstPerson
	if force then
		if state == isFirstPerson then
			return true
		end
	end
	
	local state = not isFirstPerson
	--print("CameraController::ToggleFirstPersonCamera", state)
	self:EnableFirstPerson(state)
	
	return true
end

local function onUpdate(dt)
	
end

function CameraController:KnitInit()
	Cameras = require(ScriptModules:WaitForChild("CameraModule"))
	self.Cameras = Cameras
	
	MovementController = Knit.Controllers["MovementController"]
	FPSController = Knit.Controllers["FPSController"]
end

function CameraController:KnitStart()
	
end

return CameraController