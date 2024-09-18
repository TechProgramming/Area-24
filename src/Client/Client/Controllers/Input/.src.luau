-- Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constant Values
local BTN_SPRINT = Enum.KeyCode.LeftShift

-- Constant Objects
local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local ScriptModules = script--.Parent:WaitForChild("InputControllerModules")

local ControlModule = require(ScriptModules:WaitForChild("ControlModule"))

local Player = Players.LocalPlayer

local isMovementEnabled = true

-- Requires
local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Knit"))
local Thread = require(Knit.Util.Thread)

local MovementController
local CharacterController
local FPSController

local controls -- This is forked from Roblox's default control system
local currentMoveVector = Vector3.new()

local InputController = Knit.CreateController({
	Name = "InputController";
	
	IsMovementEnabled = isMovementEnabled;
	
	controls = nil;
})


local function toggleSprint(state)
	MovementController:_updateSprintInput(state)
end

local function handleSprint(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		toggleSprint(true)
	elseif inputState == Enum.UserInputState.End then
		toggleSprint(false)
	end
end

local function onUpdate(dt)
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		--print("is beyond frame: ", InputController.controls:GetIsBeyondFrame())
		if InputController.controls:GetIsBeyondFrame() then
			toggleSprint(true)
		else
			toggleSprint(false)
		end
	end
end


function InputController.Bind(name, func, ...)
	ContextActionService:UnbindAction(name)
	
	ContextActionService:BindAction(name, func, false, ...)
end

-- The dots are used in case we want to pass any variables
function InputController.DisableMovement(...)
	isMovementEnabled = false
end

function InputController.EnableMovement(...)
	isMovementEnabled = true
end

function InputController.GetMovementEnabled(...)
	return isMovementEnabled
end

-- Honestly, I have no idea what that boolean value means, it's sent to LocalPlayer.Move function by ControlModule
--[[ Only used with custom movement
function moveFunction(character, moveDirection, boolean)
	if not MovementController.SetDirectionalMovement then return end
	MovementController.SetDirectionalMovement(isMovementEnabled and MovementController:GetIsAnyMovementEnabled() and moveDirection or Vector3.new(0,0,0))
end


function jumpFunction()
	--MovementController.ToggleJump(true, true)
	InputHandler.handleJump()
end
--]]

local function aimFunction(...)
	FPSController:ToggleAim(...)
end

local function moveFunction(player, moveVector,...)
	currentMoveVector = moveVector
	Player.Move(player, moveVector, ...)
	if not MovementController then return end
	--if player and player.Character and player.Character:GetAttribute("Controlled") then return end
	MovementController:_updateMoveVector(moveVector)
end

function InputController:GetMoveVector()
	return currentMoveVector
end

function InputController:KnitStart()
	controls = ControlModule.new(moveFunction, jumpFunction, aimFunction)
	self.controls = controls
	
	local BINDS = {
		SPRINT = {handleSprint, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift};
	}

	for i,v in pairs(BINDS) do
		InputController.Bind(i, unpack(v))
	end

	MovementController = Knit.Controllers["MovementController"]
	CharacterController = Knit.Controllers["CharacterController"]
	FPSController = Knit.Controllers["FPSController"]

	RunService:BindToRenderStep("InputController", Enum.RenderPriority.Input.Value, onUpdate)
end

return InputController