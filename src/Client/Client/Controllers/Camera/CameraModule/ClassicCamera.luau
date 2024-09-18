--[[
	ClassicCamera - Classic Roblox camera control module
	2018 Camera Update - AllYourBlox

	Note: This module also handles camera control types Follow and Track, the
	latter of which is currently not distinguished from Classic
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Knit"))
local Thread = require(Knit.Util:WaitForChild("Thread"))
local FPSController = Knit.Controllers["FPSController"]
local CameraController = Knit.Controllers["CameraController"]
local FrameworkData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))
local SpringService = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SpringService"))
local Spring = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Spring"))

local Player = game:GetService("Players").LocalPlayer
local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- Local private variables and constants
local ZERO_VECTOR2 = Vector2.new(0,0)

local tweenAcceleration = math.rad(220) -- Radians/Second^2
local tweenSpeed = math.rad(0)          -- Radians/Second
local tweenMaxSpeed = math.rad(250)     -- Radians/Second
local TIME_BEFORE_AUTO_ROTATE = 2       -- Seconds, used when auto-aligning camera with vehicles

local DEFAULT_DISTANCE = 12.5
local INITIAL_CAMERA_ANGLE = CFrame.fromOrientation(math.rad(-15), 0, 0)
local ZOOM_SENSITIVITY_CURVATURE = 0.5

local FFlagUserCameraToggle do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserCameraToggle")
	end)
	FFlagUserCameraToggle = success and result
end

local FFlagUserCameraInputRefactor do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserCameraInputRefactor2")
	end)
	FFlagUserCameraInputRefactor = success and result
end

--[[ Services ]]--
local PlayersService = game:GetService("Players")
local VRService = game:GetService("VRService")

local CameraInput = require(script.Parent:WaitForChild("CameraInput"))
local Util = require(script.Parent:WaitForChild("CameraUtils"))

--[[ The Module ]]--
local BaseCamera = require(script.Parent:WaitForChild("BaseCamera"))
local ClassicCamera = setmetatable({}, BaseCamera)
ClassicCamera.__index = ClassicCamera

function ClassicCamera.new()
	local self = setmetatable(BaseCamera.new(), ClassicCamera)

	self.isFollowCamera = false
	self.isCameraToggle = false
	self.lastUpdate = tick()
	self.cameraToggleSpring = Util.Spring.new(5, 0)

	self.isFirstPersonForced = false
	
	self.firstPersonToggled = Instance.new("BindableEvent")

	self.isEquipped = false
	self.isAiming = false
	self.isAtEase = true
	Thread.Spawn(function()
		repeat CameraController = CameraController or Knit.OnControllerAdded:Wait() until CameraController.Name == "CameraController"

		if not Player.Character then Player.CharacterAdded:Wait() end
		Player.Character:WaitForChild("Humanoid")

		repeat FPSController = FPSController or Knit.OnControllerAdded.Event:Wait()
		until FPSController.Name == "FPSController"

		local function updateCameraOffset()
			self:UpdateCameraOffset()
		end

		FPSController.OnEquippedToggledSignal:Connect(function(state) self.isEquipped = state updateCameraOffset() end)
		FPSController.OnAtEaseToggledSignal:Connect(function(state) self.isAtEase = state updateCameraOffset() end)

		FPSController.OnAimToggledSignal:Connect(function(isAiming)
			self:EnableIsAiming(isAiming)
		end)

		self:UpdateMouseBehavior()
	end)

	self.currentFOV = Instance.new("NumberValue")
	self.currentFOV.Value = workspace.CurrentCamera.FieldOfView

	self.aimingOffsetDelta = Instance.new("NumberValue")
	self.aimingTween = nil

	self.FOVSpring = Spring.new(FrameworkData.defaultFOV)
	
	self.cameraOffsetTween = nil
	self.cameraOffsetValue = Instance.new("Vector3Value")
	self.targetCameraOffset = Vector3.new(0,0,0)
	
	--self.desiredCameraOffset = Vector3.new(0,0,0)
	--self.cameraOffsetSpring = Spring.new(Vector3.new(0,0,0))
	
	--[[
	local chardamper = Instance.new("NumberValue", script)
	chardamper.Name = "chardamper"
	chardamper.Value = 0.8

	local charspeed = Instance.new("NumberValue", script)
	charspeed.Name = "charspeed"
	charspeed.Value = 2
	
	self.characterYSpring = Spring.new()
	self.characterYSpring.Position = 0
	self.characterYSpring.Target = 0
	self.characterYSpring.Damper = chardamper.Value
	chardamper.Changed:Connect(function()
		self.characterYSpring.Damper = chardamper.Value
	end)
	self.characterYSpring.Speed = charspeed.Value
	charspeed.Changed:Connect(function()
		self.characterYSpring.Speed = charspeed.Value
	end)
	--]]

	return self
end

local fovdamper = Instance.new("NumberValue", script)
fovdamper.Name = "fovdamper"
fovdamper.Value = 0.8

local fovspeed = Instance.new("NumberValue", script)
fovspeed.Name = "fovspeed"
fovspeed.Value = 18

function ClassicCamera:EnableIsAiming(isAiming)
	self.isAiming = isAiming

	--if self.aimingTween then
	--	self.aimingTween:Cancel()
	--end

	self.desiredFOV = isAiming and FrameworkData.aimingFOV or FrameworkData.defaultFOV

	self.FOVSpring.Position = workspace.CurrentCamera.FieldOfView
	self.FOVSpring.Target = self.desiredFOV
	self.FOVSpring.Speed = fovspeed.Value
	self.FOVSpring.Damper = fovdamper.Value

	--SpringService:Target(workspace.CurrentCamera, dampingRatio.Value, frequency.Value, {FieldOfView = self.desiredFOV})

	--local tweenObject

	if isAiming then
		--workspace.CurrentCamera.FieldOfView = 

		--local tweeningInformation = TweenInfo.new(0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
		--tweenObject = TweenService:Create(self.aimingOffsetDelta, tweeningInformation, { Value = 1 })
	else
		--workspace.CurrentCamera.FieldOfView = 

		--local tweeningInformation = TweenInfo.new(0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
		--tweenObject = TweenService:Create(self.aimingOffsetDelta, tweeningInformation, { Value = 0 })
	end

	--self.aimingTween = tweenObject
end

local cameraOffsetTime = Instance.new("NumberValue", script)
cameraOffsetTime.Name = "cameraOffsetTime"
cameraOffsetTime.Value = 0.25

--local offsetdamper = Instance.new("NumberValue", script)
--offsetdamper.Name = "offsetdamper"
--offsetdamper.Value = 1.4

--local offsetspeed = Instance.new("NumberValue", script)
--offsetspeed.Name = "offsetspeed"
--offsetspeed.Value = 22

function ClassicCamera:UpdateCameraOffset()
	if not FPSController then return true end

	local isEquipped = self.isEquipped
	local isAtEase = self.isAtEase
	local isFirstPerson = self.inFirstPerson

	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	
	if self.cameraOffsetTween then
		self.cameraOffsetTween:Cancel()
		self.cameraOffsetTween = nil
	end
	
	local targetOffset, isActive = Vector3.new(0,0,0), false

	if humanoid then
		if isFirstPerson then
			targetOffset = FrameworkData.firstPersonCameraOffset
		else
			if isEquipped then
				if isAtEase then
					targetOffset = FrameworkData.ateaseCameraOffset
				else
					targetOffset = FrameworkData.thirdPersonCameraOffset
					isActive = true
				end
			else
				targetOffset = FrameworkData.unequippedCameraOffset
			end
		end
	end
	
	self.desiredCameraOffset = targetOffset

	--self.cameraOffsetSpring.Position = humanoid.CameraOffset
	--self.cameraOffsetSpring.Target = self.desiredCameraOffset
	--self.cameraOffsetSpring.Speed = offsetspeed.Value
	--self.cameraOffsetSpring.Damper = offsetdamper.Value
	
	self.cameraOffsetTween = TweenService:Create(self.cameraOffsetValue, TweenInfo.new(cameraOffsetTime.Value, Enum.EasingStyle.Quart), {Value = targetOffset})
	self.cameraOffsetTween:Play()
end

function ClassicCamera:GetCameraToggleOffset(dt)
	assert(FFlagUserCameraToggle)

	if self.isCameraToggle then
		local zoom = self.currentSubjectDistance

		if CameraInput.getTogglePan() then
			self.cameraToggleSpring.goal = math.clamp(Util.map(zoom, 0.5, self.FIRST_PERSON_DISTANCE_THRESHOLD, 0, 1), 0, 1)
		else
			self.cameraToggleSpring.goal = 0
		end

		local distanceOffset = math.clamp(Util.map(zoom, 0.5, 64, 0, 1), 0, 1) + 1
		return Vector3.new(0, self.cameraToggleSpring:step(dt)*distanceOffset, 0)
	end

	return Vector3.new()
end

-- Movement mode standardized to Enum.ComputerCameraMovementMode values
function ClassicCamera:SetCameraMovementMode(cameraMovementMode)
	BaseCamera.SetCameraMovementMode(self, cameraMovementMode)

	self.isFollowCamera = cameraMovementMode == Enum.ComputerCameraMovementMode.Follow
	self.isCameraToggle = cameraMovementMode == Enum.ComputerCameraMovementMode.CameraToggle
end

function ClassicCamera:Update()
	local now = tick()
	local timeDelta = now - self.lastUpdate

	local camera = workspace.CurrentCamera
	local newCameraCFrame = camera.CFrame
	local newCameraFocus = camera.Focus

	local overrideCameraLookVector = nil
	if self.resetCameraAngle then
		local rootPart = self:GetHumanoidRootPart()
		if rootPart then
			overrideCameraLookVector = (rootPart.CFrame * INITIAL_CAMERA_ANGLE).lookVector
		else
			overrideCameraLookVector = INITIAL_CAMERA_ANGLE.lookVector
		end
		self.resetCameraAngle = false
	end

	local player = PlayersService.LocalPlayer
	local humanoid = self:GetHumanoid()
	local cameraSubject = camera.CameraSubject
	local isInVehicle = cameraSubject and cameraSubject:IsA("VehicleSeat")
	local isOnASkateboard = cameraSubject and cameraSubject:IsA("SkateboardPlatform")
	local isClimbing = humanoid and humanoid:GetState() == Enum.HumanoidStateType.Climbing

	if self.lastUpdate == nil or timeDelta > 1 then
		self.lastCameraTransform = nil
	end

	local rotateInput
	if FFlagUserCameraInputRefactor then
		rotateInput = CameraInput.getRotation()
	else
		rotateInput = self.rotateInput
	end

	--if FFlagUserCameraInputRefactor then
	do
		local zoom = self.currentSubjectDistance	
		local zoomDelta = CameraInput.getZoomDelta()

		--print("zoom booleans ", self.inFirstPerson, Player.CameraMode ~= Enum.CameraMode.LockFirstPerson, UserInputService.TouchEnabled)
		if self.inFirstPerson and Player.CameraMode ~= Enum.CameraMode.LockFirstPerson and UserInputService.TouchEnabled then
			self:LeaveFirstPerson()
			local newZoom = DEFAULT_DISTANCE

			self:SetCameraToSubjectDistance(newZoom)
		elseif math.abs(zoomDelta) > 0 and FFlagUserCameraInputRefactor then
			local newZoom

			print("zoom booleans ", self.inFirstPerson, Player.CameraMode ~= Enum.CameraMode.LockFirstPerson, UserInputService.TouchEnabled)
			if self.inFirstPerson and zoomDelta < 0 then
				newZoom = 0.5
			else
				if zoomDelta > 0 then
					newZoom = zoom + zoomDelta*(1 + zoom*ZOOM_SENSITIVITY_CURVATURE)
				else
					newZoom = (zoom + zoomDelta) / (1 - zoomDelta*ZOOM_SENSITIVITY_CURVATURE)
				end
			end

			self:SetCameraToSubjectDistance(newZoom)
		end
	end

	if self.lastUpdate and not FFlagUserCameraInputRefactor then
		local gamepadRotation = self:UpdateGamepad()

		if self:ShouldUseVRRotation() then
			self.rotateInput = self.rotateInput + self:GetVRRotationInput()
		else
			-- Cap out the delta to 0.1 so we don't get some crazy things when we re-resume from
			local delta = math.min(0.1, timeDelta)

			if gamepadRotation ~= ZERO_VECTOR2 then
				self.rotateInput = self.rotateInput + (gamepadRotation * delta)
			end

			local angle = 0
			if not (isInVehicle or isOnASkateboard) then
				angle = angle + (self.turningLeft and -120 or 0)
				angle = angle + (self.turningRight and 120 or 0)
			end

			if angle ~= 0 then
				self.rotateInput = self.rotateInput +  Vector2.new(math.rad(angle * delta), 0)
			end
		end
	end

	local cameraHeight = self:GetCameraHeight()

	-- Reset tween speed if user is panning
	if FFlagUserCameraInputRefactor then
		if CameraInput.getRotation() ~= Vector2.new() then
			tweenSpeed = 0
			self.lastUserPanCamera = tick()
		end
	else
		if self.userPanningTheCamera then
			tweenSpeed = 0
			self.lastUserPanCamera = tick()
		end
	end

	local userRecentlyPannedCamera = now - self.lastUserPanCamera < TIME_BEFORE_AUTO_ROTATE
	local subjectPosition = self:GetSubjectPosition()

	if subjectPosition and player and camera then
		local zoom = self:GetCameraToSubjectDistance()
		if zoom < 0.5 then
			zoom = 0.5
		end

		if self:GetIsMouseLocked() and not self:IsInFirstPerson() then
			-- We need to use the right vector of the camera after rotation, not before
			local newLookCFrame
			if FFlagUserCameraInputRefactor then 
				newLookCFrame = self:CalculateNewLookCFrameFromArg(overrideCameraLookVector, rotateInput)
			else
				newLookCFrame = self:CalculateNewLookCFrame(overrideCameraLookVector)
			end

			local offset = self:GetMouseLockOffset()
			local cameraRelativeOffset = offset.X * newLookCFrame.rightVector + offset.Y * newLookCFrame.upVector + offset.Z * newLookCFrame.lookVector

			--offset can be NAN, NAN, NAN if newLookVector has only y component
			if Util.IsFiniteVector3(cameraRelativeOffset) then
				subjectPosition = subjectPosition + cameraRelativeOffset
			end
		else
			local userPanningTheCamera
			if FFlagUserCameraInputRefactor then
				userPanningTheCamera = CameraInput.getRotation() ~= Vector2.new()
			else
				userPanningTheCamera = self.userPanningTheCamera == true
			end

			if not userPanningTheCamera and self.lastCameraTransform then

				local isInFirstPerson = self:IsInFirstPerson()

				if (isInVehicle or isOnASkateboard or (self.isFollowCamera and isClimbing)) and self.lastUpdate and humanoid and humanoid.Torso then
					if isInFirstPerson then
						if self.lastSubjectCFrame and (isInVehicle or isOnASkateboard) and cameraSubject:IsA("BasePart") then
							local y = -Util.GetAngleBetweenXZVectors(self.lastSubjectCFrame.lookVector, cameraSubject.CFrame.lookVector)
							if Util.IsFinite(y) then
								if FFlagUserCameraInputRefactor then
									rotateInput = rotateInput + Vector2.new(y, 0)
								else
									self.rotateInput = self.rotateInput + Vector2.new(y, 0)
								end
							end
							tweenSpeed = 0
						end
					elseif not userRecentlyPannedCamera then
						local forwardVector = humanoid.Torso.CFrame.lookVector
						if isOnASkateboard and not FFlagUserCameraInputRefactor then
							forwardVector = cameraSubject.CFrame.lookVector
						end

						tweenSpeed = math.clamp(tweenSpeed + tweenAcceleration * timeDelta, 0, tweenMaxSpeed)

						local percent = math.clamp(tweenSpeed * timeDelta, 0, 1)
						if self:IsInFirstPerson() and not (self.isFollowCamera and self.isClimbing) then
							percent = 1
						end

						local y = Util.GetAngleBetweenXZVectors(forwardVector, self:GetCameraLookVector())
						if Util.IsFinite(y) and math.abs(y) > 0.0001 then
							if FFlagUserCameraInputRefactor then
								rotateInput = rotateInput + Vector2.new(y * percent, 0)
							else
								self.rotateInput = self.rotateInput + Vector2.new(y * percent, 0)
							end
						end
					end

				elseif self.isFollowCamera and (not (isInFirstPerson or userRecentlyPannedCamera) and not VRService.VREnabled) then
					-- Logic that was unique to the old FollowCamera module
					local lastVec = -(self.lastCameraTransform.p - subjectPosition)

					local y = Util.GetAngleBetweenXZVectors(lastVec, self:GetCameraLookVector())

					-- This cutoff is to decide if the humanoid's angle of movement,
					-- relative to the camera's look vector, is enough that
					-- we want the camera to be following them. The point is to provide
					-- a sizable dead zone to allow more precise forward movements.
					local thetaCutoff = 0.4

					-- Check for NaNs
					if Util.IsFinite(y) and math.abs(y) > 0.0001 and math.abs(y) > thetaCutoff * timeDelta then
						rotateInput = rotateInput + Vector2.new(y, 0)
					end
				end
			end
		end

		if not self.isFollowCamera then
			local VREnabled = VRService.VREnabled

			if VREnabled then
				newCameraFocus = self:GetVRFocus(subjectPosition, timeDelta)
			else
				newCameraFocus = CFrame.new(subjectPosition)
			end

			local cameraFocusP = newCameraFocus.p
			if VREnabled and not self:IsInFirstPerson() then
				local vecToSubject = (subjectPosition - camera.CFrame.p)
				local distToSubject = vecToSubject.magnitude

				local flaggedRotateInput
				if FFlagUserCameraInputRefactor then
					flaggedRotateInput = rotateInput
				else
					flaggedRotateInput = self.rotateInput
				end

				-- Only move the camera if it exceeded a maximum distance to the subject in VR
				if distToSubject > zoom or flaggedRotateInput.x ~= 0 then
					local desiredDist = math.min(distToSubject, zoom)
					if FFlagUserCameraInputRefactor then
						vecToSubject = self:CalculateNewLookFromArg(nil, rotateInput) * desiredDist
					else
						vecToSubject = self:CalculateNewLookVector() * desiredDist
					end
					local newPos = cameraFocusP - vecToSubject
					local desiredLookDir = camera.CFrame.lookVector
					if flaggedRotateInput.x ~= 0 then
						desiredLookDir = vecToSubject
					end
					local lookAt = Vector3.new(newPos.x + desiredLookDir.x, newPos.y, newPos.z + desiredLookDir.z)
					if not FFlagUserCameraInputRefactor then
						self.rotateInput = ZERO_VECTOR2
					end

					newCameraCFrame = CFrame.new(newPos, lookAt) + Vector3.new(0, cameraHeight, 0)
				end
			else
				local newLookVector
				if FFlagUserCameraInputRefactor then
					newLookVector = self:CalculateNewLookVectorFromArg(overrideCameraLookVector, rotateInput)
				else
					newLookVector = self:CalculateNewLookVector(overrideCameraLookVector)
					self.rotateInput = ZERO_VECTOR2
				end
				newCameraCFrame = CFrame.new(cameraFocusP - (zoom * newLookVector), cameraFocusP)
			end
		else -- is FollowCamera
			local newLookVector
			if FFlagUserCameraInputRefactor then
				newLookVector = self:CalculateNewLookVectorFromArg(overrideCameraLookVector, rotateInput)
			else
				newLookVector = self:CalculateNewLookVector(overrideCameraLookVector)
				self.rotateInput = ZERO_VECTOR2
			end

			if VRService.VREnabled then
				newCameraFocus = self:GetVRFocus(subjectPosition, timeDelta)
			else
				newCameraFocus = CFrame.new(subjectPosition)
			end
			newCameraCFrame = CFrame.new(newCameraFocus.p - (zoom * newLookVector), newCameraFocus.p) + Vector3.new(0, cameraHeight, 0)
		end

		if FFlagUserCameraToggle then
			local toggleOffset = self:GetCameraToggleOffset(timeDelta)
			newCameraFocus = newCameraFocus + toggleOffset
			newCameraCFrame = newCameraCFrame + toggleOffset
		end

		self.lastCameraTransform = newCameraCFrame
		self.lastCameraFocus = newCameraFocus
		if (isInVehicle or isOnASkateboard) and cameraSubject:IsA("BasePart") then
			self.lastSubjectCFrame = cameraSubject.CFrame
		else
			self.lastSubjectCFrame = nil
		end
	end

	if self.characterRotateWithCamera then
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
			local xvec = rootPart.CFrame.RightVector
			local yvec = rootPart.CFrame.UpVector
			local zvec = -newCameraCFrame.LookVector

			local camx,camy,camz = newCameraCFrame:ToOrientation()
			--self.characterYSpring.Target = camy
			local charx,chary,charz = rootPart.CFrame:ToOrientation()
			local newCharacterCFrame = CFrame.new(rootPart.Position) * CFrame.fromOrientation(charx, camyInstance.Value and camy or chary, charz)
			--print(camy)
			--local newCharacterCFrame = CFrame.fromMatrix(rootPart.Position, xvec, yvec)
			character:SetPrimaryPartCFrame(newCharacterCFrame)
		end
	end
	--[[
	if self.aimingOffsetDelta.Value ~= 0 then
		local delta = self.aimingOffsetDelta.Value
		local offset = CFrame.new():Lerp(FrameworkData.aimingCameraOffset, delta)

		newCameraCFrame = newCameraCFrame * offset
	end
	--]]
	
	-- TODO: Add a check to save performence for when we can guess no change will be made
	workspace.CurrentCamera.FieldOfView = self.FOVSpring.Position
	if humanoid then
		humanoid.CameraOffset = self.cameraOffsetValue.Value
	end
	--humanoid.CameraOffset = self.cameraOffsetSpring.Position

	self.lastUpdate = now
	return newCameraCFrame, newCameraFocus
end

camyInstance = Instance.new("BoolValue", script)
camyInstance.Name = "camyInstance"

function ClassicCamera:EnterFirstPerson()
	self.inFirstPerson = true

	if UserInputService.TouchEnabled then
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end

	self:UpdateMouseBehavior()

	game:GetService("UserInputService").MouseIconEnabled = false

	CameraController:ChangeIsInFirstPerson(true)

	self:UpdateCameraOffset()

	self.firstPersonToggled:Fire(true)
end

function ClassicCamera:LeaveFirstPerson()
	self.inFirstPerson = false

	if Player.CameraMode == Enum.CameraMode.LockFirstPerson then
		repeat Player.CameraMode = Enum.CameraMode.Classic wait()
			--print("setting to Classic")
		until Player.CameraMode == Enum.CameraMode.Classic
		--print("ClassicCamera::LeaveFirstPerson Classic", Player.CameraMode == Enum.CameraMode.Classic)
	end

	if UserInputService.TouchEnabled then
		self:SetCameraToSubjectDistance(DEFAULT_DISTANCE)
	end

	self:UpdateMouseBehavior()

	CameraController:ChangeIsInFirstPerson(false)

	self:UpdateCameraOffset()
	
	self.firstPersonToggled:Fire(false)
end

return ClassicCamera
