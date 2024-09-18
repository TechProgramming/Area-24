local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")


-- Constant Objects
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local ScriptModules = script

-- Weapons Objects
local GameData = ReplicatedStorage:WaitForChild("GameData")
local GunData = GameData:WaitForChild("WeaponsData")
local FPSAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("FPS")
local FXModules = ReplicatedStorage:WaitForChild("EffectsModules")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")

-- Weapons Modules
local GunFrameworkData = require(GunData:WaitForChild("FrameworkData"))
local GunHandler = require(WeaponModules:WaitForChild("ClientWeaponHandler"))
local DisplayDamage = require(FXModules:WaitForChild("DisplayDamage"))

local AIMING_OFFSET = Instance.new("NumberValue", script)
AIMING_OFFSET.Name = "Aiming Offset"
AIMING_OFFSET.Value = -20

local FIRING_COOLDOWN = Instance.new("NumberValue", script)
FIRING_COOLDOWN.Name = "Firing Cooldown"
FIRING_COOLDOWN.Value = 0.4

local MAX_FIRING_OFFSET = Instance.new("NumberValue", script)
MAX_FIRING_OFFSET.Name = "Max Firing Offset"
MAX_FIRING_OFFSET.Value = 15

local WALKING_OFFSET = Instance.new("NumberValue", script)
WALKING_OFFSET.Name = "Walking Offset"
WALKING_OFFSET.Value = 10

local SPRINTING_OFFSET = Instance.new("NumberValue", script)
SPRINTING_OFFSET.Name = "Sprinting Offset"
SPRINTING_OFFSET.Value = 10

-- crosshair
local crosshairStack = {}

local crosshairGUI
local crosshairEnabled = false
local crosshairScale = 1
local crosshairTarDistance = 0
local crosshairBaseDistance = 0

local curInaccuracy = 0
local baseOffset = Instance.new("NumberValue", script)
baseOffset.Name = "BaseOffset"

-- Knit
local Knit = require(SharedModules:WaitForChild("Knit"))

local FPSController
local CameraController
local MovementController

local CrosshairController = Knit.CreateController({
	Name = "CrosshairController";
})

local weaponSettings

local function incrementTween(inst, info, goal)
	local start, conn = tick()
	conn = RunService.Heartbeat:Connect(function(dt)
		local alpha = math.clamp((tick() - start)/info.Time,0,1)
		local delta = TweenService:GetValue(alpha, info.EasingStyle, info.EasingDirection)
		if alpha == 1 then conn:Disconnect() end
		
		for i,v in pairs(goal) do
			inst[i] = inst[i] + v*delta
		end
	end)
end

local tweenProperty = {}
do
	tweenProperty.__index = tweenProperty
	function tweenProperty.new()
		local self = setmetatable({}, tweenProperty)
		
		self.alpha = Instance.new("NumberValue")
		self.tween = nil
		self.info = nil
		self.goal = nil
		
		return self
	end
	
	function tweenProperty:start(info, goal)
		if goal ~= self.goal then
			if self.tween then self.tween:Cancel() self.tween = nil end
			if info == nil then info = self.info end
			
			self.goal = goal
			self.tween = TweenService:Create(self.alpha, info, {Value = goal})
			self.tween:Play()
		end
	end
end

-- CROSSHAIR
function CrosshairController.ChangeCrosshairScale(scale)
	assert(typeof(scale) == "number", "Expected 'size' to be a number but got " .. typeof(scale))
	crosshairScale = scale

	crosshairGUI.UIScale.Scale = scale

	return true
end

function CrosshairController.AddCrosshairDistance(distance, time)
	assert(typeof(distance) == "number", "Expected 'distance' to be a number got " .. typeof(distance))
	if equippedHandler == nil then return false end

	local weaponName = equippedHandler.name

	Thread.SpawnNow(function()
		local passed = 0
		local doneFirstHalf = false

		local function update(dt)
			passed += dt
			local alpha = passed/time

			local newValue = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection[not doneFirstHalf and "Out" or "In"])
			crosshairTarDistance += (not doneFirstHalf and newValue or -newValue)

			if alpha >= 1 then
				if doneFirstHalf then
					return false
				else
					passed = 0
					doneFirstHalf = true
				end
			end

			return true
		end

		table.insert(crosshairStack, update)
	end)

	return true
end

local function updateCurrentCrosshairDistance(distance, perm)
	assert(typeof(distance) == "number", "Expected 'distance' to be a number got " .. typeof(distance))

	if perm then
		crosshairBaseDistance = distance
	end

	local gui = crosshairGUI
	local f1 = gui.F1
	local f2 = gui.F2
	local f3 = gui.F3
	local f4 = gui.F4

	f1.Position = UDim2.new(UDim.new(f1.Position.X.Scale, -distance), f1.Position.Y)
	f2.Position = UDim2.new(UDim.new(f2.Position.X.Scale,  distance), f2.Position.Y)

	f3.Position = UDim2.new(f3.Position.X, UDim.new(f3.Position.Y.Scale, -distance))
	f4.Position = UDim2.new(f4.Position.X, UDim.new(f4.Position.Y.Scale,  distance))

	return true
end

local function applyProperties(props)
	local f1 = crosshairGUI.F1
	local f2 = crosshairGUI.F2
	local f3 = crosshairGUI.F3
	local f4 = crosshairGUI.F4
	local dot = crosshairGUI.MiddleDot
	for i,v in pairs(props) do
		f1[i] = v
		f2[i] = v
		f3[i] = v
		f4[i] = v
		dot[i] = v
	end
end

function CrosshairController.EnableCrosshair()
	if crosshairEnabled then return true end
	crosshairEnabled = true
	crosshairGUI.Enabled = true
	
	crosshairBaseDistance = weaponSettings.crosshair.idleOffset
	updateCurrentCrosshairDistance(crosshairBaseDistance)

	return true
end

function CrosshairController.DisableCrosshair()
	if not crosshairEnabled then return true end
	crosshairEnabled = false
	crosshairGUI.Enabled = false

	return true
end

local aimingAlpha, aimingTween, lastAimingValue, aimingGoal = Instance.new("NumberValue"), nil, 0, nil
local lastFirstPerson = false
local lastShotFired, firingDelta, firingTween = tick(), Instance.new("NumberValue")
--local walkingAlpha, walkingGoal, sprintingAlpha, sprintingGoal = Instance.new("NumberValue"), 0, Instance.new("NumberValue"), 0
local walkingTween, sprintingTween = tweenProperty.new(), tweenProperty.new()

function CrosshairController:Update(dt)
	crosshairTarDistance = 0
	
	--local fov = Camera.FieldOfView
	--local xOffset = (Camera.ViewportSize.X/2)/curInaccuracy + baseOffset.Value
	--local yOffset = (Camera.ViewportSize.Y/2)/curInaccuracy + baseOffset.Value
	

	crosshairGUI = PlayerGui:FindFirstChild("Crosshair")
	
	if crosshairEnabled and crosshairGUI then
		local isInFirstPerson = CameraController:GetIsInFirstPerson()

		local aimingOffset = isInFirstPerson and weaponSettings.crosshair.firstPersonAimingOffset or weaponSettings.crosshair.thirdPersonAimingOffset
		local firingCooldown = weaponSettings.crosshair.firingCooldown
		local maxFiringOffset = weaponSettings.crosshair.maxFiringOffset
		
		if isInFirstPerson then
			applyProperties({BackgroundTransparency = aimingAlpha.Value})
		elseif lastFirstPerson then
			applyProperties({BackgroundTransparency = 0})
		end
		if aimingAlpha.Value ~= lastAimingValue then
			lastAimingValue = aimingAlpha.Value
		end
		if tick() - lastShotFired >= firingCooldown then
			firingTween = TweenService:Create(firingDelta, TweenInfo.new(firingCooldown), {Value = 0})
			firingTween:Play()
		end
		local i = 1
		while (i < #crosshairStack) do
			local func = crosshairStack[i]
			local result = func(dt)

			if not result then
				table.remove(crosshairStack, i)
			else
				i += 1
			end
		end
		
		updateCurrentCrosshairDistance(
			crosshairTarDistance +
				crosshairBaseDistance +
				(aimingAlpha.Value*aimingOffset) +
				math.min(firingDelta.Value, MAX_FIRING_OFFSET.Value) +
				(sprintingTween.alpha.Value * SPRINTING_OFFSET.Value) +
				(walkingTween.alpha.Value * WALKING_OFFSET.Value)
			,false)
		
		lastFirstPerson = isInFirstPerson
	end
end

local function updateCrosshair()
	local isEquipped = FPSController:GetIsEquipped()
	local isAtEase = FPSController:GetIsAtEase()
	local isAiming = FPSController:GetIsAiming()

	if isEquipped then
		weaponSettings = FPSController:GetEquippedHandler().weaponSettings
		
		MAX_FIRING_OFFSET.Value = weaponSettings.crosshair.maxFiringOffset
		crosshairBaseDistance = weaponSettings.crosshair.idleOffset
	end
	
	if isEquipped and not isAtEase then
		CrosshairController.EnableCrosshair()
	else
		CrosshairController.DisableCrosshair()
	end
end

local hitMarkerTween
local function enableHitMarker(isCritical)
	if hitMarkerTween then hitMarkerTween:Cancel() hitMarkerTween = nil end

	local hitMarker = crosshairGUI.HitMarker.HitMarkerImage
	hitMarker.ImageTransparency = 0
	hitMarker.ImageColor3 = isCritical and Color3.fromRGB(255, 60, 46) or Color3.new(255,255,255)

	local info = TweenInfo.new(0.85)
	hitMarkerTween = TweenService:Create(hitMarker, info, {ImageTransparency = 1})
	hitMarkerTween:Play()
end

local function onHit(humanoid, hitPoint, canHarm, isHeadshot, damage)
	if humanoid then
		enableHitMarker(isHeadshot)
	end
end

local function updateMovement()
	local isMoving = MovementController:GetIsMoving()
	local isSprinting = MovementController:GetIsSprinting()

	sprintingTween:start(TweenInfo.new(0.5), isMoving and isSprinting and 1 or 0)
	walkingTween:start(TweenInfo.new(0.4), isMoving and 1 or 0)
end

function CrosshairController:KnitInit()
	FPSController = Knit.Controllers["FPSController"]
	CameraController = Knit.Controllers["CameraController"]
	MovementController = Knit.Controllers["MovementController"]

	crosshairGUI = PlayerGui:WaitForChild("Crosshair")
	--print("crosshair", crosshairGUI:GetFullName())
	crosshairGUI.Enabled = false

	FPSController.OnEquippedToggledSignal:Connect(updateCrosshair)
	FPSController.OnAtEaseToggledSignal:Connect(updateCrosshair)
	FPSController.OnAimToggledSignal:Connect(function(isAiming)
		if isAiming and aimingGoal ~= 1 then
			if aimingTween then aimingTween:Cancel() aimingTween = nil end

			aimingGoal = 1
			local info = TweenInfo.new(weaponSettings.aimTime)
			aimingTween = TweenService:Create(aimingAlpha, info, {Value = 1})
			aimingTween:Play()
		elseif not isAiming and aimingGoal ~= 0 then
			if aimingTween then aimingTween:Cancel() aimingTween = nil end

			aimingGoal = 0
			local info = TweenInfo.new(weaponSettings.aimTime)
			aimingTween = TweenService:Create(aimingAlpha, info, {Value = 0})
			aimingTween:Play()
		end
	end)
	FPSController.OnHitSignal:Connect(onHit)
	local offset = Instance.new("NumberValue", script)
	offset.Name = "Firing offset"
	offset.Value = 1
	local time = Instance.new("NumberValue", script)
	time.Name = "Firing time"
	time.Value = 0.2
	FPSController.OnFiredSignal:Connect(function()
		if firingTween then firingTween:Cancel() firingTween = nil end
		lastShotFired = tick()
		local fireOffset = weaponSettings.crosshair.fireOffset
		local fireOffsetTime = weaponSettings.crosshair.fireOffsetTime
		if firingDelta.Value >= MAX_FIRING_OFFSET.Value then
			local r = math.random(2, 5)
			MAX_FIRING_OFFSET.Value += r
			wait(0.05)
			MAX_FIRING_OFFSET.Value -= r
		else
			incrementTween(firingDelta, TweenInfo.new(fireOffsetTime), {Value = fireOffset + math.random()*fireOffset*0.3})
		end
	end)
	
	MovementController.OnMovementChanged:Connect(updateMovement)
	MovementController.OnSprintChanged:Connect(updateMovement)
	
	RunService:BindToRenderStep(self.Name, Enum.RenderPriority.Camera.Value, function(...) self.Update(self, ...) end)
end

function CrosshairController:KnitStart()

end

return CrosshairController