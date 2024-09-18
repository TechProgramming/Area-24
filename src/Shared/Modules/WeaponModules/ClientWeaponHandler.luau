local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local FIRST_PERSON_ENABLED = true
local THIRD_PERSON_ENABLED = true

local FIRE_DIRECTION_TRIES = 50
local WALL_SHOOTING_TRIES = 5

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")
local FXModules = ReplicatedStorage:WaitForChild("EffectsModules")
local WeaponsGUI = PlayerGui:WaitForChild("Weapons")
local ReloadFrame = WeaponsGUI:WaitForChild("Container")

local DisplayDamage = require(FXModules:WaitForChild("DisplayDamage"))

local FirstPersonWeapon = require(script.Parent:WaitForChild("FirstPersonWeapon"))
local ThirdPersonWeapon = require(script.Parent:WaitForChild("ThirdPersonWeapon"))

local Knit = require(SharedModules:WaitForChild("Knit"))
local CameraController
local TeamRulesService

local Signal = require(SharedModules.Knit.Util.Signal)
local Thread = require(SharedModules.Knit.Util.Thread)
local Maid = require(Knit.Util.Maid)

local PartCache = require(SharedModules:WaitForChild("PartCache"))
local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))

local Camera = workspace.CurrentCamera

local GuiInset = GuiService:GetGuiInset()


local ClientWeapon = {}
ClientWeapon.__index = ClientWeapon

local function getCharHumanoid(model)
	local curParent = model
	local hum = curParent:FindFirstChildOfClass("Humanoid")
	while curParent ~= workspace and hum == nil do
		curParent = curParent.Parent
		hum = curParent:FindFirstChildOfClass("Humanoid")
	end
	return hum and hum.Parent:IsA("Model") and hum or nil
end

local function copyArray(t)
	local n = table.create(#t, t[1])
	for i,v in ipairs(t) do
		if typeof(v) == "table" then
			n[i] = copyArray(v)
		else
			n[i] = v
		end
	end
	return n
end

local function drawray(ray, parent)
	local part = Instance.new("Part", parent or game.Workspace.CurrentCamera);
	part.FormFactor = Enum.FormFactor.Custom;
	part.Material = Enum.Material.Neon;
	part.Size = Vector3.new(.2, ray.Direction.magnitude, .2);
	part.CFrame = CFrame.new(ray.Origin + ray.Direction/2, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2,0,0);
	part.Anchored = true;
	part.CanCollide = false;
	part.BrickColor = BrickColor.new("Bright red");
	part.Transparency = 0.85
	return part;
end;
local function makeDbgPart(pos, color)
	local part = Instance.new("Part")
	part.Name = "dbgPart"
	part.Position = pos
	part.Size = Vector3.new(0.5,0.5,0.5)
	part.Color = color or Color3.new(0,0,0)
	part.CanCollide = false
	part.Anchored = true
	part.CastShadow = false
	part.Transparency = 0.5
	part.Parent = workspace.CurrentCamera
	return part
end

function ClientWeapon:GetCombinedSignal(signalName)
	local newSignal = Signal.new()
	self.onDestroyedMaid:GiveTask(newSignal)
	for _, v in pairs({FIRST_PERSON_ENABLED and self.firstPersonHandler[signalName], THIRD_PERSON_ENABLED and self.thirdPersonHandler[signalName]}) do
		if v == nil then continue end
		v:Connect(function(...)
			newSignal:Fire(...)
		end)
	end
	return newSignal
end

function ClientWeapon:PlaySound(name, index, copy, extraData)
	local sounds = self.weaponSettings.sounds[name]
	if not sounds then return false end
	if #sounds == 0 then return false end

	if index == nil then
		index = math.random(1, #sounds)
	end

	local sound = sounds[index]
	--local pitchEffect = sound:FindFirstChildWhichIsA("PitchShiftSoundEffect")
	--if pitchEffect == nil then
	--	pitchEffect = Instance.new("PitchShiftSoundEffect", sound)
	--	pitchEffect.Octave = 1
	--end
	if copy then
		sound = sound:Clone()
		--pitchEffect = sound[pitchEffect.Name]
		sound.Parent = script
		Thread.Spawn(function()
			if sound.IsPlaying == false then
				sound:Destroy()
				return
			end
			sound.Stopped:Connect(function()
				sound:Destroy()
			end)
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end)
	end
	--pitchEffect.Octave = math.random()*0.05 + pitchEffect.Octave
	--sound.Volume = math.random()*0.1 + sound.Volume

	self.playingSoundIndex[name] = index
	self.playingSoundInstance[name] = sound
	sound:Play()


	return sound
end

function ClientWeapon:StopSound(name)
	local sound = self.playingSoundInstance[name]
	if sound and sound.IsPlaying then
		sound:Stop()
	end
	return true
end

function ClientWeapon.new(tool, weaponSettings, metaSettings, firstPersonSettings, thirdPersonSettings, character)
	CameraController = Knit.Controllers["CameraController"]
	TeamRulesService = Knit.Controllers["TeamRulesService"]

	local self = setmetatable({}, ClientWeapon) --[[ setmetatable({}, {
		__index = function(table, key)
			if ClientWeapon[key] ~= nil then return ClientWeapon[key] end
			local pointsAt = rawget(table,"firstPersonHandler")[key]
			if typeof(pointsAt) == "function" then
				return function(...)
					local args = {...}
					local success, err = pcall(function()
						rawget(table,"thirdPersonHandler")[key](unpack(args))
					end)
					if not success then
						warn("THERE'S PROBABLY NO ", key, " IN ThirdPersonWeapon\n ERR:", err)
					end
					return pointsAt(unpack(args))
				end
			end
			return pointsAt
			--if rawget(table,"activeHandler") ~= nil then return rawget(table,"activeHandler")[key] end
			--return rawget(table,"firstPersonHandler")
		end
	})--]]
	local clientHandler = self

	self.isLineOfSightBlocked = false
	self.isAtEase = true
	self.isDestroyed = false

	self.onDestroyedMaid = Maid.new()
	self.playingSoundIndex = {}
	self.playingSoundInstance = {}

	self.tool = tool
	self.character = character
	self.metaSettings = metaSettings
	self.weaponSettings = weaponSettings

	self.serverAPI = metaSettings.serverAPI
	self.clientAPI = metaSettings.clientAPI
	self.movementAPI = metaSettings.movementAPI

	self.name = self.weaponSettings.name
	self.weapon = thirdPersonSettings.weapon

	if FIRST_PERSON_ENABLED then
		self.firstPersonHandler = FirstPersonWeapon.new(weaponSettings, firstPersonSettings, character, firstPersonSettings.weapon)
	end
	if THIRD_PERSON_ENABLED then
		self.thirdPersonHandler = ThirdPersonWeapon.new(weaponSettings, thirdPersonSettings, character, thirdPersonSettings.weapon)
	end

	local statesHandler = self[FIRST_PERSON_ENABLED and "firstPersonHandler" or "thirdPersonHandler"]
	self.statesHandler = statesHandler

	-- TODO: maybe change all signals to use GetCombinedSignal
	self.equippedSignal = self.statesHandler.equippedSignal
	self.unequippedSignal = self.statesHandler.unequippedSignal
	self.pumpedSignal = self.statesHandler.pumpedSignal
	self.reloadedSignal = self.statesHandler.reloadedSignal
	self.aimedSignal = self.statesHandler.aimedSignal
	self.unaimedSignal = self.statesHandler.unaimedSignal
	self.toggledFiringSignal = self:GetCombinedSignal("toggledFiringSignal")
	self.firedSignal = self.statesHandler.firedSignal

	self.activeHandler = nil

	local function overwrite(name, func)
		if FIRST_PERSON_ENABLED then
			local oldfunc1 = self.firstPersonHandler[name]
			if oldfunc1 == nil then warn("COULDNOT FIND FUNCTION IN FIRST WITH NAME", name) end
			self.firstPersonHandler[name] = function(...)
				local args = {...}
				table.insert(args, oldfunc1)
				return func(unpack(args))
			end
		end

		if THIRD_PERSON_ENABLED then
			local oldfunc2 = self.thirdPersonHandler[name]
			if oldfunc2 == nil then warn("COULDNOT FIND FUNCTION IN THIRD WITH NAME", name) end
			self.thirdPersonHandler[name] = function(...)
				local args = {...}
				table.insert(args, oldfunc2)
				return func(unpack(args))
			end
		end

		--print("overwritting ", name, oldfunc1, oldfunc2)
	end

	do
		local function StartPump(self, overwrittenFunction)
			if clientHandler.activeHandler ~= self then
				--print("called Fire from the other handler")
				return overwrittenFunction(self)
			else
				--print("called Fire correctly")
				local valid = overwrittenFunction(self)
				if not valid then return false end
			end
			
			
		end
		overwrite("StartPump", StartPump)

		local function Fire(self, origin, allDirections, overwrittenFunction)
			--if clientHandler.movementAPI:GetIsSprinting() then
			--	clientHandler.movementAPI:ToggleSprint(true, false)
			--end
			if clientHandler.isLineOfSightBlocked then
				return false
			end
			if clientHandler.activeHandler ~= self then
				--print("called Fire from the other handler")
				return overwrittenFunction(self, origin, allDirections)
			else
				--print("called Fire correctly")
				local valid = overwrittenFunction(self, origin, allDirections)
				if not valid then return false end
			end

			clientHandler.clientAPI:ClientFire(origin, allDirections, self.weaponSettings)

			clientHandler:PlaySound("fire", nil, true)
			if self.weaponSettings.weaponType == "shotgun" then
			else
				clientHandler:PlaySound("tail", nil, true)
			end

			--clientHandler.clientAPI.AddTempCrosshairDistance(self.weaponSettings.crosshair.fireDistance, self.weaponSettings.recoilWaitTime)
			--print(debug.traceback())
			return true
		end
		overwrite("Fire", Fire)

		local function SetFiring(self, state, overwrittenFunction)
			if clientHandler.isLineOfSightBlocked then
				return false
			end
			if clientHandler.activeHandler ~= self then
				--print("called ToggleAim from the other handler")
				return overwrittenFunction(self, state)
			else
				--print("called ToggleAim correctly")
				local valid = overwrittenFunction(self, state)
				if not valid then return false end
			end

			if not state then
				local sinceLastShot = tick() - self.lastShotTime
				if sinceLastShot <= 0.1 then
					--clientHandler:PlaySound("tail", nil, true)
				end
			end

			return true
		end
		overwrite("SetFiring", SetFiring)

		local function Equip(self, shouldShow, overwrittenFunction)
			if clientHandler.activeHandler ~= self then
				--print("called Equip from the other handler")
				return overwrittenFunction(self, shouldShow)
			else
				--print("called Equip correctly")
				local valid = overwrittenFunction(self, shouldShow)
				if not valid then return false end
			end

			--clientHandler.clientAPI:ChangeCrosshairDistance(self.weaponSettings.crosshair.idleDistance)
			--clientHandler.clientAPI:EnableCrosshair()

			coroutine.wrap(function()
				local pass = clientHandler.serverAPI:Equip(self.weaponSettings.name)
				if not pass then warn("server asked client to unequip")
					if self.tool then
						self.tool.Parent = LocalPlayer.Backpack
					end
					self:Unequip()
				end
			end)()

			return true
		end
		overwrite("Equip", Equip)

		local function Unequip(self, overwrittenFunction)
			if clientHandler.activeHandler ~= self then
				--print("called Unequip from the other handler")
				return overwrittenFunction(self)
			else
				--print("called Unequip correctly")
				local valid = overwrittenFunction(self)
				if not valid then return false end
			end

			--clientHandler.clientAPI:DisableCrosshair()

			coroutine.wrap(function()
				local pass = clientHandler.serverAPI:Unequip(self.weaponSettings.name)
				if not pass then warn("server asked client to equip") self.tool.Parent = LocalPlayer.Character self:Equip() end
			end)()

			return true
		end
		overwrite("Unequip", Unequip)

		local function ToggleAim(self, force, state, overwrittenFunction)
			if self.isLineOfSightBlocked then
				return false
			end
			if clientHandler.activeHandler ~= self then
				--print("called ToggleAim from the other handler")
				return overwrittenFunction(self, force, state)
			else
				--print("called ToggleAim correctly")
				local valid = overwrittenFunction(self, force, state)
				if not valid then return false end
			end

			local isAiming = self.isAiming
			clientHandler.serverAPI.AimEvent:Fire(isAiming)

			return true
		end
		overwrite("ToggleAim", ToggleAim)

		local function StartReloading(self, overwrittenFunction)
			if clientHandler.activeHandler ~= self then
				--print("called StartReloading from the other handler")
				return overwrittenFunction(self)
			else
				--print("called StartReloading correctly")
				local valid = overwrittenFunction(self)
				if not valid then return false end
			end

			local reloadingSound = self.weaponSettings.sounds.reload
			if reloadingSound and #reloadingSound > 0 then
				reloadingSound[math.random(1,#reloadingSound)]:Play()
			end

			clientHandler.serverAPI.ReloadEvent:Fire(true)

			return true
		end
		overwrite("StartReloading", StartReloading)

		local function StopReloading(self, finishedCorrectly, overwrittenFunction)
			if clientHandler.activeHandler ~= self then
				--print("called StopReloading from the other handler")
				return overwrittenFunction(self, finishedCorrectly)
			else
				--print("called StopReloading correctly")
				local valid = overwrittenFunction(self, finishedCorrectly)
				if not valid then return false end
			end

			clientHandler.serverAPI.ReloadEvent:Fire(false)
			--self:StopSound("reload")

			return true
		end
		overwrite("StopReloading", StopReloading)

		local function GetFirstPersonFiringDirection(base)
			return Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 1).Direction
			--return Camera:ScreenPointToRay((Camera.ViewportSize.X)/2 - GuiInset.X/2, (Camera.ViewportSize.Y)/2 - GuiInset.Y/2, 0).Direction --Camera.CFrame.LookVector
		end

		local function GetThirdPersonFiringDirection(base)
			local pos
			if not self:GetIsAtEase() then
				pos = Camera.ViewportSize/2 -- GuiInset/2
			else
				-- currently cant even shoot when not at ease but keeping it just in case
				pos = UserInputService:GetMouseLocation()
			end
			local cameraRay = Camera:ViewportPointToRay((pos.X), (pos.Y), 1)

			local rayOrigin = Camera.CFrame.Position
			local rayDirection = Camera.CFrame.LookVector * base.weaponSettings.range --Camera.CFrame.LookVector * base.weaponSettings.range

			local oldFilter = clientHandler.rayParams.FilterDescendantsInstances
			local newFilter = table.create(#oldFilter, nil)
			for _, v in ipairs(oldFilter) do
				newFilter[#newFilter+1] = v
			end
			if Players.LocalPlayer.Character then
				newFilter[#newFilter+1] = Players.LocalPlayer.Character
			end
			clientHandler.rayParams.FilterDescendantsInstances = newFilter

			local tries, hitPosition, hitInstance = 0, nil
			while tries <= FIRE_DIRECTION_TRIES do
				tries += 1

				local raycastResult = workspace:Raycast(rayOrigin, rayDirection, clientHandler.rayParams)
				hitPosition = raycastResult and raycastResult.Position or rayOrigin + rayDirection
				hitInstance = raycastResult and raycastResult.Instance

				if hitInstance and
					--not hitInstance.CanCollide and
					hitInstance.Transparency >= self.clientAPI.BulletPierceTransparencyThreshold
				then
					newFilter[#newFilter+1] = hitInstance
					clientHandler.rayParams.FilterDescendantsInstances = newFilter
				else
					break
				end
			end
			clientHandler.rayParams.FilterDescendantsInstances = oldFilter

			return (hitPosition - base.barrelAttachment.WorldPosition).Unit
		end
		if FIRST_PERSON_ENABLED then
			self.firstPersonHandler.GetFiringDirection = GetFirstPersonFiringDirection
		end
		if THIRD_PERSON_ENABLED then
			self.thirdPersonHandler.GetFiringDirection = GetThirdPersonFiringDirection
		end
	end

	--[
	do
		-- Fastcasting
		self.rayParams = RaycastParams.new()
		self.rayParams.IgnoreWater = true
		self.rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		self.rayParams.FilterDescendantsInstances = self.clientAPI:GetIgnoreList()
		-- TODO: Add local player's character here

	end

	self.connections = {}
	self.connections.onCameraChanged = CameraController.OnFirstPersonUpdated:Connect(function(isInFirstPerson)
		if self.activeHandler and self.activeHandler.isEquipped then
			if isInFirstPerson then
				self:EquipFirstPerson()
			else
				self:EquipThirdPerson()
			end
		end
	end)

	local function addAnimationEventsSupport(handler)
		for name, animations in pairs(handler.loadedAnimations) do
			for _, animation in pairs(animations) do
				if self.weaponSettings.animationEventsSounds then
					local animationEvents = self.weaponSettings.animationEventsSounds[name]
					if animationEvents then
						for eventName, sounds in pairs(animationEvents) do
							if #sounds == 0 then continue end
							animation:GetMarkerReachedSignal(eventName):Connect(function(param)
								if self.activeHandler == handler then
									local soundIndex = math.random(1,#sounds)
									local sound = sounds[soundIndex]
									sound:Play()

									self.serverAPI.PlaySoundEvent:Fire(eventName)
								end
							end)
						end
					end
				end
			end
		end
	end
	if FIRST_PERSON_ENABLED then
		addAnimationEventsSupport(self.firstPersonHandler)
	end
	if THIRD_PERSON_ENABLED then
		addAnimationEventsSupport(self.thirdPersonHandler)
	end

	local function updateMovementState()
		if not self:GetIsEquipped() then return end

		local isMoving = self.movementAPI:GetIsMoving()
		local isSprinting = isMoving and self.movementAPI:GetIsSprinting()

		if self:GetIsAiming() and isSprinting then
			self:ToggleAim(true, false)
		end
		if THIRD_PERSON_ENABLED then
			if not isMoving then
				self.thirdPersonHandler:StopAnimation("walk")
				self.thirdPersonHandler:StopAnimation("sprint")
			else
				if isSprinting then
					if not self.thirdPersonHandler:GetIsAnimationPlaying("sprint") then
						--self.thirdPersonHandler:StopAnimation("walk")
						self.thirdPersonHandler:RunAnimation("sprint")
					end
				elseif not self.thirdPersonHandler:GetIsAnimationPlaying("walk") then
					--self.thirdPersonHandler:StopAnimation("sprint")
					self.thirdPersonHandler:RunAnimation("walk")
				end
			end
		end
	end

	self.movementAPI.OnSprintChanged:Connect(updateMovementState)
	self.movementAPI.OnMovementChanged:Connect(updateMovementState)
	--[[]
	self.movementAPI.OnMovementChanged:Connect(function(isMoving)
		if not self:GetIsEquipped() then return end
		--print("OnMovementChanged fire with", isMoving)
		local isSprinting = self.movementAPI:GetIsSprinting()
		
		local animName = isSprinting and "sprint" or "walk"
		if THIRD_PERSON_ENABLED then
			if isMoving then
				self.thirdPersonHandler:RunAnimation(animName)
			else
				self.thirdPersonHandler:StopAnimation("walk")
				self.thirdPersonHandler:StopAnimation("sprint")
			end
		end
	end)
	--]]
	self.statesHandler.firedSignal:Connect(function() self:UpdateReloadFrame() end)
	self.statesHandler.reloadedSignal:Connect(function(finishedCorrectly) self:UpdateReloadFrame() end)

	UserInputService.WindowFocusReleased:Connect(function()
		--if self.statesHandler.isFiring then
		if FIRST_PERSON_ENABLED then
			self.firstPersonHandler:SetFiring(false)
		end
		if THIRD_PERSON_ENABLED then
			self.thirdPersonHandler:SetFiring(false)
		end
		--end
		if self.statesHandler.isAiming then
			if FIRST_PERSON_ENABLED then
				self.firstPersonHandler:ToggleAim(true, false)
			end
			if THIRD_PERSON_ENABLED then
				self.thirdPersonHandler:ToggleAim(true, false)
			end
		end
	end)

	self.toggledFiringSignal:Connect(function(...)
		self.clientAPI.OnFireToggledSignal:Fire(...)
	end)

	self.firedSignal:Connect(function(...)
		self.clientAPI.OnFiredSignal:Fire(...)
	end)

	return self
end

function ClientWeapon:Destroy()
	if self.isDestroyed then return true end

	self.isDestroyed = true
	if FIRST_PERSON_ENABLED then
		self.firstPersonHandler:Destroy()
	end
	if THIRD_PERSON_ENABLED then
		self.thirdPersonHandler:Destroy()
	end

	for _, v in pairs(self.connections) do
		v:Disconnect()
	end

	self.onDestroyedMaid:Destroy()

	return true
end

function ClientWeapon:GetIsDestroyed()
	return self.statesHandler.isDestroyed
end

function ClientWeapon:GetIsAiming()
	return self.statesHandler.isAiming
end

function ClientWeapon:GetIsFiring()
	return self.statesHandler.isFiring
end

function ClientWeapon:SetEquippingBlocked(state)
	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:SetEquippingBlocked(state)
	return FIRST_PERSON_ENABLED and self.firstPersonHandler:SetEquippingBlocked(state) or ret
end

function ClientWeapon:SetUnequippingBlocked(state)
	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:SetUnequippingBlocked(state)
	return FIRST_PERSON_ENABLED and self.firstPersonHandler:SetUnequippingBlocked(state) or ret
end

function ClientWeapon:GetIsAtEase()
	return self.statesHandler.isAtEase
end

function ClientWeapon:ToggleAtEase(force, state)
	if force then if self.isAtEase == state then return true end end
	local isAtEase = not self.isAtEase

	--if isAtEase then
	--	self.clientAPI.DisableCrosshair()
	--else
	--	self.clientAPI.EnableCrosshair()
	--end

	if THIRD_PERSON_ENABLED then
		self.thirdPersonHandler:ToggleAtEase(true, isAtEase)
	end
	if FIRST_PERSON_ENABLED then
		self.firstPersonHandler:ToggleAtEase(true, isAtEase)
	end

	self.isAtEase = self.statesHandler.isAtEase

	return true
end

function ClientWeapon:ToggleAim(force, state)
	--	if force then if self.statesHandler.isAiming == state then return true end end

	local isAiming = not self.statesHandler.isAiming

	--print("ClientWeapon:ToggleAim calling third person", state)
	if THIRD_PERSON_ENABLED then self.thirdPersonHandler:ToggleAim(force, state) end

	--print("ClientWeapon:ToggleAim calling first person", state)
	if FIRST_PERSON_ENABLED then self.firstPersonHandler:ToggleAim(force, state) end

	--CameraController:EnableAiming(self.statesHandler.isAiming)

	return true
end

function ClientWeapon:SetFiring(state)
	--if state then
	--	if self.movementAPI and self.movementAPI:GetIsSprinting() then
	--		self.movementAPI:SetDisableSprinting("aiming", true)
	--	end
	--end
	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:SetFiring(state)
	return FIRST_PERSON_ENABLED and self.firstPersonHandler:SetFiring(state) or ret
end

function ClientWeapon:SetReloading(...)
	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:SetReloading(...)
	return FIRST_PERSON_ENABLED and self.firstPersonHandler:SetReloading(...) or ret
end

function ClientWeapon:ToggleSprint(...)
	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:ToggleSprint(...)
	return FIRST_PERSON_ENABLED and self.firstPersonHandler:ToggleSprint(...) or ret
end

function ClientWeapon:GetIsEquipped()
	return self.activeHandler and self.activeHandler.isEquipped or false-- self.firstPersonHandler.isEquipped or self.thirdPersonHandler.isEquipped
end

function ClientWeapon:GetIsReloading()
	return self.activeHandler and self.activeHandler.isReloading
end

function ClientWeapon:EquipFirstPerson()
	--if self.firstPersonHandler.isEquipped and not self.firstPersonHandler.isHidden then return true end
	if not FIRST_PERSON_ENABLED then return self:EquipThirdPerson() end
	self.activeHandler = self.firstPersonHandler

	local isEquipped = self.statesHandler.isEquipped

	if isEquipped then
		if THIRD_PERSON_ENABLED then
			self.thirdPersonHandler:Hide()
		end
		return self.firstPersonHandler:Unhide()
	else
		if THIRD_PERSON_ENABLED then
			self.thirdPersonHandler:Equip(false)
		end
		return self.firstPersonHandler:Equip(true)
	end

end

function ClientWeapon:EquipThirdPerson()
	--if self.thirdPersonHandler.isEquipped and not self.thirdPersonHandler.isHidden then return true end
	if not THIRD_PERSON_ENABLED then return self:EquipFirstPerson() end
	self.activeHandler = self.thirdPersonHandler

	local isEquipped = self.statesHandler.isEquipped
	if isEquipped then
		if FIRST_PERSON_ENABLED then
			self.firstPersonHandler:Hide()
		end
		return self.thirdPersonHandler:Unhide()
	else
		if FIRST_PERSON_ENABLED then
			self.firstPersonHandler:Equip(false)
		end
		local ret = self.thirdPersonHandler:Equip(true)

		if self.movementAPI:GetIsMoving() then
			local isSprinting = self.movementAPI:GetIsSprinting()

			local animName = isSprinting and "sprint" or "walk"
			self.thirdPersonHandler:RunAnimation(animName)
		end

		return ret
	end
end

function ClientWeapon:Equip(firstPerson)
	--if not self:GetIsAtEase() then
	--	self.clientAPI.EnableCrosshair()
	--end
	--self.clientAPI.UpdateCurrentCrosshairDistance(self.weaponSettings.crosshair.idleDistance, true)

	self.isAtEase = self.statesHandler.isAtEase

	local ret
	if firstPerson then
		ret = self:EquipFirstPerson()
	else
		ret = self:EquipThirdPerson()
	end

	self:UpdateReloadFrame()

	--CameraController:EnableEquip(self.statesHandler.isEquipped)

	return ret
end

function ClientWeapon:Unequip()
	--self.clientAPI.DisableCrosshair()

	local fired = false
	local conn
	conn = self.statesHandler.unequippedSignal:Connect(function()
		fired = true
		conn:Disconnect()
	end)

	local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:Unequip()
	local ret2 = FIRST_PERSON_ENABLED and self.firstPersonHandler:Unequip() or not FIRST_PERSON_ENABLED and ret

	if not fired then
		self.statesHandler.unequippedSignal:Connect(function()
			if ret2 == true then
				self.activeHandler = nil
			end
		end)
	else
		if ret2 == true then
			self.activeHandler = nil
		end
	end

	--CameraController:EnableEquip(self.statesHandler.isEquipped)

	self:UpdateReloadFrame()

	return ret2
end

function ClientWeapon:UpdateReloadFrame()
	if self:GetIsEquipped() then
		WeaponsGUI = PlayerGui:WaitForChild("Weapons")
		ReloadFrame = WeaponsGUI:WaitForChild("Container")

		ReloadFrame.Visible = true
		ReloadFrame.Clip.Text = tostring(self.statesHandler.ammo)
	else
		ReloadFrame.Visible = false
	end

	return true
end

local dbgWallShootingRay
local dbgWallShootingTarget
local dbgWallShootingTarget2
function ClientWeapon:Update(...)
	if self.activeHandler == nil and self.statesHandler:IsValid() then return false end
--[[
	local theta = self.character.HumanoidRootPart.CFrame.LookVector:Dot(Camera.CFrame.LookVector)
	--print("ANGLE IS", theta)
	
	if theta >= 0.85 then
		if FIRST_PERSON_ENABLED then
			self.firstPersonHandler:SetIsLineOfSightBlocked(false)
		end
		if THIRD_PERSON_ENABLED then
			self.thirdPersonHandler:SetIsLineOfSightBlocked(false)
		end
		self.isLineOfSightBlocked = false
	end
	--]]
	--[
	if self.activeHandler
		and not self.isAtEase
		and workspace:IsAncestorOf(self.character)
		and self.character:FindFirstChildWhichIsA("Humanoid")
		and self.character:FindFirstChildWhichIsA("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead
		and self.character:FindFirstChild("Head")
		--and not (theta >= 0.85)
	then
		local blacklist = copyArray(self.clientAPI:GetIgnoreList())
		blacklist[#blacklist+1] = self.character
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = blacklist
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.IgnoreWater = true
		local function raycastFromHandler(handler)
			--if not handler.barrelPositionAfterGunUpFromHRP then
			--	return
			--end
			
			local isActiveHandler = handler == self.activeHandler
			local isFirstPerson = handler == self.firstPersonHandler
			
			local target
			local origin
			if isFirstPerson then
				if not handler.barrelPositionAfterGunUp then
					handler:SetIsLineOfSightBlocked(false)
					return
				end
				target = handler.barrelPositionAfterGunUp
				origin = Camera.CFrame.Position
			else
				if not handler.barrelCFrameAfterGunUpFromUT then
					handler:SetIsLineOfSightBlocked(false)
					return
				end
				local UTCFrame = self.character.UpperTorso.CFrame
				target = (UTCFrame * handler.barrelCFrameAfterGunUpFromUT).Position
				origin = self.character.RightUpperArm.Position
			end
			local dir = target - origin
			origin += dir.Unit*-1*0.5
			target += dir.Unit*0.5
			dir += dir.Unit
			local targetDistance = dir.Magnitude
			local result = workspace:Raycast(origin, dir, params)
			local distanceCovered = result and (result.Position - origin).Magnitude
			local currentTries = 1
			while result
				and result.Instance.Transparency >= self.clientAPI.BulletPierceTransparencyThreshold
				and distanceCovered < targetDistance
				and currentTries <= WALL_SHOOTING_TRIES
			do
				blacklist[#blacklist+1] = result.Instance
				params.FilterDescendantsInstances = blacklist
				result = workspace:Raycast(result.Position, (target - result.Position), params)
				if result then
					distanceCovered = distanceCovered + (result.Position - origin).Magnitude
				end
				currentTries += 1
			end
			local targetVal = result and result.Instance.Anchored and true or false
			
			--if result then
				--print(currentTries, distanceCovered, targetDistance, result and result.Instance.Transparency, result and result.Instance)
			--end
			
			handler:SetIsLineOfSightBlocked(targetVal)
			if isActiveHandler then
				self.isLineOfSightBlocked = targetVal
			end
			--[[
			if isActiveHandler then
				if dbgWallShootingRay then
					dbgWallShootingRay:Destroy()
				end
				if dbgWallShootingTarget then
					dbgWallShootingTarget:Destroy()
				end
				if dbgWallShootingTarget2 then
					dbgWallShootingTarget2:Destroy()
				end
				dbgWallShootingRay = drawray(Ray.new(origin+dir.Unit, dir))
				dbgWallShootingTarget = makeDbgPart(target, Color3.new())
				dbgWallShootingTarget2 = makeDbgPart(origin, Color3.new(0,0,1))
			end
			--]]
		end
		if self.activeHandler == self.firstPersonHandler then
			raycastFromHandler(self.firstPersonHandler)
		elseif self.activeHandler == self.thirdPersonHandler then
			raycastFromHandler(self.thirdPersonHandler)
		end
	end
	--]]
	if self.activeHandler == self.firstPersonHandler then
		local ret = THIRD_PERSON_ENABLED and self.thirdPersonHandler:Update(...)
		return FIRST_PERSON_ENABLED and self.firstPersonHandler:Update(...) or ret
	else
		local ret = FIRST_PERSON_ENABLED and self.firstPersonHandler:Update(...)
		return THIRD_PERSON_ENABLED and self.thirdPersonHandler:Update(...) or ret
	end
end

return ClientWeapon