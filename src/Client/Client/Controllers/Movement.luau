local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Constant Values
local DEFAULT_WALKSPEED = 16
local SPRINT_WALKSPEED = 25

-- Constant Objects
local Player = Players.LocalPlayer

local SharedModules = ReplicatedStorage:WaitForChild("Modules")

local Knit = require(SharedModules:WaitForChild("Knit"))
local Signal = require(Knit.Util:WaitForChild("Signal"))
--local EffectsManager = require(Knit.Util:WaitForChild("EffectsManager"))

local groudDetectionRayParams = RaycastParams.new({IgnoreWater = true, FilterDescendantsInstances = {}})

local CharacterController
local FPSController

local MovementController = Knit.CreateController({
	Name = "MovementController";
	
	IsSprinting = false;
	IsOnGround = false;
	IsMoving = false;
	
	_shiftInput = false;
	
	OnMovementChanged = Signal.new();
	OnSprintChanged = Signal.new();
	OnJumpSignal = Signal.new();
	
	IsAiming = false;
	IsFiring = false;
	
--	_sprintingDisabledEM = EffectsManager.new({
--		aiming = false;
--	});
})

function MovementController:GetIsSprinting()
	return self.IsSprinting
end

function MovementController:GetIsOnGround()
	return self.IsOnGround
end

function MovementController:GetIsMoving()
	return self.IsMoving
end

local lastMoveVector = Vector3.new(0,0,0)
function MovementController:_updateMoveVector(moveVector)
	if lastMoveVector == moveVector then return end
	--print("current move vector", moveVector)
	local isMoving = moveVector.Magnitude > 0
	self.IsMoving = isMoving
	if isMoving ~= (lastMoveVector.Magnitude > 0) then
		self.OnMovementChanged:Fire(isMoving)
	end
	
	lastMoveVector = moveVector
end
 
function MovementController:_updateSprintInput(state)
	self._shiftInput = state
	self:UpdateSprinting()
end

local forceSprint = Instance.new("BoolValue", script)
forceSprint.Name = "ForceSprint"
forceSprint.Changed:Connect(function() MovementController:UpdateSprinting() end)

function MovementController:UpdateSprinting(newState)
	local JobController = Knit.GetController("JobController")
	if JobController:IsInJob() then
		return
	end
	
	local isSprinting = newState or forceSprint.Value or (self._shiftInput and not self.IsAiming and not self.IsFiring)
	
	local character = Player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	if humanoid then
		humanoid.WalkSpeed = isSprinting and SPRINT_WALKSPEED or DEFAULT_WALKSPEED
	end
	
	self.IsSprinting = isSprinting

	self.OnSprintChanged:Fire(isSprinting)
end

function MovementController:ToggleSprint(force, state)
	if (force and self.IsSprinting == state) then
		return true
	end
	
	local isSprinting = not self.IsSprinting
	
	self:UpdateSprinting(isSprinting)
	
	return true
end

function MovementController:SetDisableSprinting(reason, state)
	assert(typeof(reason)=="string", "Expected reason to be string instead got " .. typeof(reason))
	assert(typeof(state)=="boolean", "Expected reason to be string instead got " .. typeof(state))

	--self._sprintingDisabledEM:Set(reason, state)
	self:UpdateSprinting()
end

function MovementController:Update(dt)
	local character = Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and root then
		local iterations = 5
		local feetContactPosition = root.Position + Vector3.new(0.5, -2.7 + 0.1, 0)
		local minPosition = feetContactPosition - Vector3.new(0, root.Size.X/2, 0)
		local maxPosition = feetContactPosition + Vector3.new(0, root.Size.X/2, 0)
		local diff = (maxPosition - minPosition)/iterations
		
		-- TODO: Add more raycasts on the edges of the character's feet to handle more cases
		local isOnGround = false
		for i = 0, iterations do
			local newPosition = (minPosition + diff*i)
			
			local result = workspace:Raycast(newPosition, Vector3.new(0,-.4,0), groudDetectionRayParams)
			
			if result then
				isOnGround = true
				break
			end
		end
		
		--print("IS ON GROUND: " .. tostring(isOnGround))
		
		self.IsOnGround = isOnGround
	end
end

function MovementController:KnitInit()
	CharacterController = Knit.Controllers["CharacterController"]
	FPSController = Knit.Controllers["FPSController"]
	
	FPSController.OnAimToggledSignal:Connect(function(state)
		--self:SetDisableSprinting("aiming", state)
		self.IsAiming = state
		self:UpdateSprinting()
	end)
	
	FPSController.OnFireToggledSignal:Connect(function(state)
		self.IsFiring = state
		self:UpdateSprinting()
	end)
	
	CharacterController.SpawnSignal:Connect(function(character)
		table.insert(groudDetectionRayParams.FilterDescendantsInstances, character)
	end)
end

function MovementController:KnitStart()
	RunService:BindToRenderStep(MovementController.Name, Enum.RenderPriority.Character.Value, function() self:Update() end)
end

return MovementController