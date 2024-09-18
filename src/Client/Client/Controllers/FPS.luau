local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")


-- Constant Objects
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local WeaponsGui

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local ScriptModules = script

-- Weapons Objects
local GameData = ReplicatedStorage:WaitForChild("GameData")
local GunData = GameData:WaitForChild("WeaponsData")
local FPSAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("FPS")
local FXModules = ReplicatedStorage:WaitForChild("EffectsModules")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")
local WeaponUtils = require(WeaponModules:WaitForChild("WeaponUtils"))

-- Weapons Modules
local GunFrameworkData = require(GunData:WaitForChild("FrameworkData"))
local GunHandler = require(WeaponModules:WaitForChild("ClientWeaponHandler"))
local DisplayDamage = require(FXModules:WaitForChild("DisplayDamage"))

-- helping modules
local PartCache = require(SharedModules:WaitForChild("PartCache"))
local Queue = require(SharedModules:WaitForChild("Queue"))
local TimeSync = require(SharedModules:WaitForChild("TimeSync"))
local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))

--local WeaponsModels = workspace:WaitForChild("Scripted"):WaitForChild("Weapons") --FPSAssets:WaitForChild("Weapons")

local playersGunsData = {}
local npcGunsData = {}

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = {}


-- Knit
local Knit = require(SharedModules:WaitForChild("Knit"))
local Maid = require(Knit.Util:WaitForChild("Maid"))
local Signal = require(Knit.Util:WaitForChild("Signal"))
local Thread = require(Knit.Util:WaitForChild("Thread"))
local EffectsManager = require(Knit.Util:WaitForChild("EffectsManager"))

local ItemService = Knit.GetService("ItemService")
local FPSService = Knit.GetService("FPSService")

local MovementController
local InputController
local CameraController
local CharacterController
local ToolController
local SFXController
local TeamRulesController

local wait = Thread.Wait

local BulletPierceTransparencyThreshold = FPSService.BulletPierceTransparencyThreshold:Get()
local GlobalFastCastIgnoreTag = FPSService.GlobalFastCastIgnoreTag:Get()
local TrackedCharacterParts = FPSService.TrackedCharacterParts:Get()

-- Other
local ignoreList = {}

local handlers = {}
local equippedHandler, lastEquippedHandler
local lastAimValue = false

local noGunsInitiated = 0

local CurrentShotNumber = 0

local EquipingDisablers = EffectsManager.new({
	Climbing = false;
	Swimming = false;
})

local numToTxt = {
	"Zero";
	"One";
	"Two";
	"Three";
	"Four";
	"Five";
	"Six";
	"Seven";
	"Eight";
	"Nine";
}

local FPSController = Knit.CreateController({
	Name = "FPSController";
	handler = nil;

	areControlsBinded = false;

	isEquipped = false;
	isAiming = false;
	isAtEase = true;

	weaponConnections = {
		jumpSignal = nil;
		deathSignal = nil;
	};
	
	OnInstanceAddedToIgnoreList = Signal.new();

	OnHitSignal = Signal.new();
	OnEquippedToggledSignal = Signal.new();
	OnAtEaseToggledSignal = Signal.new();
	OnAimToggledSignal = Signal.new();
	OnFireToggledSignal = Signal.new();
	OnFiredSignal = Signal.new();

	GlobalFastCastIgnoreTag = GlobalFastCastIgnoreTag;
	BulletPierceTransparencyThreshold = BulletPierceTransparencyThreshold;
})

local getCharHumanoid = WeaponUtils.getCharHumanoid

local function waitForChildWhichIsA(parent, name, class)
	local function is(v) return v.Name == name and v:IsA(class) end
	for _, v in pairs(parent:GetChildren()) do
		if is(v) then return v end
	end
	local c = parent.ChildAdded:Wait()
	while not is(c) do
		c = parent.ChildAdded:Wait()
	end
	return c
end

local function findFirstChildWhichIsA(inst, name, classname, recur)
	for _, v in ipairs(recur and inst:GetDescendants() or inst:GetChildren()) do
		if v.Name == name and v:IsA(classname) then return v end
	end
end

local function copy(a)
	local t = table.create(#a, a[1])
	for i,v in ipairs(a) do
		t[i] = v
	end
	return t
end

local function makePart(pos, size, color)
	local p = Instance.new("Part")
	p.Size = size --Vector3.new(2,2,2)
	p.Color = color --Color3.fromRGB(0,255,0)
	p.Anchored = true
	p.CanCollide = false
	p.Position = pos
	p.Transparency = 0.8
	p.Parent = workspace.fastCast
	Debris:AddItem(p, 1)
	return p
end
--[[
do
	local listsNumber = 15
	local expansionNumber = 5
	local ignoreLists = {}
	local ignoreListsData = {}
	function getIgnoreList()
		local idx = #ignoreList
		local list = ignoreLists[idx]
		ignoreListsData[tostring(list)] = {#list}
		ignoreLists[idx] = nil
		return list
	end
	function returnIgnoreList(list)
		
	end
	
	function registerIgnoreList()
		local new = copy(ignoreList)
		
		return new
	end
end
--]]
function FPSController:Reload(force, state)
	if equippedHandler == nil then return false end
	--if force and equippedHandler:GetIsReloading() == state then return true end

	--local state = not equippedHandler:GetIsReloading()

	--if not equippedHandler:GetIsReloading() then
	equippedHandler:SetReloading(true)
	--end

	return true
end

function FPSController:GetIsAtEase()
	return equippedHandler == nil or self.isAtEase -- not equippedHandler:GetIsEquipped() or equippedHandler:GetIsAtEase()
end

function FPSController:GetIsEquipped()
	return equippedHandler and equippedHandler:GetIsEquipped()
end

function FPSController:GetEquippedHandler()
	return equippedHandler
end


function FPSController:GetIsAiming()
	return equippedHandler and equippedHandler:GetIsAiming()
end

function FPSController:ToggleAim(force, state)
	if equippedHandler == nil then return end
	local isAiming = equippedHandler:GetIsAiming()

	if not force then
		force = true
		state = not isAiming
	end

	return equippedHandler:ToggleAim(force, state)
end

function FPSController:ToggleAtEase(force, state)
	--print("FPSController:ToggleAtEase")
	if equippedHandler == nil then return false end
	if force and state == self.isAtEase then
		if equippedHandler:GetIsAtEase() ~= state then
			return equippedHandler:ToggleAtEase(true, state)
		else
			return true
		end
	end
	self.isAtEase = not self.isAtEase
	--print("FPSController:ToggleAtEase setting to", self.isAtEase)

	self.OnAtEaseToggledSignal:Fire(self.isAtEase)
	--CameraController:EnableAtEase(self.isAtEase)

	return equippedHandler:ToggleAtEase(true, self.isAtEase)
end

function FPSController:SetFiring(enable)
	if equippedHandler == nil then return false end
	if equippedHandler:GetIsFiring() == enable then return true end

	local ret = equippedHandler:SetFiring(enable)

	--self.OnFireToggledSignal:Fire(enable)

	return ret
end

local equipCallQueue = Queue.new()
local isProcessingToggleEquip, onToggleEquipFinished = false, Instance.new("BindableEvent")
local isEquippedHandlerQueued = false

local function updateEquippedHandlers()
	if isEquippedHandlerQueued then return end
	if isProcessingToggleEquip then
		isEquippedHandlerQueued = true
		onToggleEquipFinished.Event:Wait()
		isEquippedHandlerQueued = false
	end

	local toEquipHandler
	local weaponEquippedWithoutTool = false
	for _, v in pairs(handlers) do
		if v:GetIsDestroyed() then continue end
		local isToolEquipped = ToolController:GetIsToolEquipped(v.tool)
		--print("tool", v.tool:GetFullName(), "'s equipped state:", isToolEquipped, "and weapon:", v:GetIsEquipped())
		if not v:GetIsEquipped() and isToolEquipped then
			toEquipHandler = v
			break
		elseif v:GetIsEquipped() and not isToolEquipped then
			weaponEquippedWithoutTool = true
		end
	end
	if toEquipHandler then
		FPSController:ToggleEquip(true, true, toEquipHandler)
	elseif weaponEquippedWithoutTool then
		FPSController:ToggleEquip(true, false)
	end
end

function FPSController:ToggleEquip(force, state, newhandler)
	equipCallQueue:push({force, state, newhandler})
	while isProcessingToggleEquip do
		onToggleEquipFinished.Event:Wait()
	end
	if equipCallQueue:isEmpty() then return end
	local force, state, newhandler = unpack(equipCallQueue:pop())

	if LocalPlayer.Character == nil then return false end

	if force then
		local curState = self:GetIsEquipped()
		if newhandler ~= nil and newhandler ~= equippedHandler then
			if state == true then
				-- another weapon is equipped so must go on
				--elseif equippedHandler == newhandler and state == false then
				-- weapon is equipped so must go on
			elseif curState == state then
				return true
			end
		else
			if state == curState then return true end
		end
		--if (state == false or equippedHandler == nil or equippedHandler == newhandler) and state == self:GetIsEquipped() then
		--	return false
		--end
	end

	local isEquipped
	if force then
		isEquipped = state
	else
		isEquipped = not self:GetIsEquipped()
	end

	if isEquipped then
		if not EquipingDisablers:GetIsAllOff() then
			return false
		end
	end

	if newhandler == nil then
		if isEquipped then
			if lastEquippedHandler == nil then
				warn("FPSController::ToggleEquip called without a handler and lastEquippedHandler is nil")
				return false
			else
				newhandler = lastEquippedHandler
			end
		else
			if equippedHandler == nil then
				-- asked to unequip when equippedHandler is nil
				return true
			else
				newhandler = equippedHandler
			end
		end
	end

	if newhandler:GetIsDestroyed() then
		warn("Tried equipping/unequipping a destroyed", newhandler.name)
		return false
	end

	print("FPSController::ToggleEquip changing equip to ", isEquipped)

	isProcessingToggleEquip = true
	local correctlyProcessedFunction = false
	local result = false
	
	local success = false
	Thread.SpawnNow(function()
		--if isEquipped ~= FPSController.isEquipped then
		--end
		if not isEquipped then
			if newhandler.tool and (newhandler.tool.Parent == LocalPlayer.Backpack or newhandler.tool.Parent == LocalPlayer.Character) then
				newhandler.tool.Parent = LocalPlayer.Backpack
			end
		end

		newhandler:SetUnequippingBlocked(true)
		for _,v in pairs(handlers) do
			if v ~= newhandler and v:GetIsEquipped() then
				v:SetEquippingBlocked(true)
				local conn = nil
				local fired = false
				conn = v.unequippedSignal:Connect(function()
					conn:Disconnect()
					fired = true
				end)
				v:Unequip()
				if not fired then
					v.unequippedSignal:Wait()
				end
				v:SetEquippingBlocked(false)
			end
		end
		newhandler:SetUnequippingBlocked(false)

		local conn, fired = nil, false
		conn = (isEquipped and newhandler.equippedSignal or newhandler.unequippedSignal):Connect(function()
			fired = true
			conn:Disconnect()
		end)

		local actionId

		if isEquipped then
			result = newhandler:Equip(CameraController:GetIsInFirstPerson()) --newhandler:SetEquip(not newhandler:GetIsEquipped())
			actionId = newhandler.statesHandler.equipId
		else
			result = newhandler:Unequip()
			actionId = newhandler.statesHandler.unequipId
		end

		if not result then
			--warn("TOGGLING EQUIP FAILED")
			warn("Failed to unequip/equip gun")
		else
			if isEquipped then
				lastEquippedHandler = equippedHandler
				equippedHandler = newhandler
			else
				equippedHandler = nil
				if lastAimValue then
					lastAimValue = false
					self.OnAimToggledSignal:Fire(false)
				end
			end

			WeaponsGui.AtEaseToggle.Visible = isEquipped
		end

		FPSController.isEquipped = isEquipped
		FPSController.OnEquippedToggledSignal:Fire(isEquipped, newhandler)

		newhandler:ToggleAtEase(true, self.isAtEase)

		correctlyProcessedFunction = true

		Thread.Delay(newhandler.statesHandler.actionsDuration.equip, function()
			local newActionId
			if isEquipped then
				newActionId = newhandler.statesHandler.equipId
			else
				newActionId = newhandler.statesHandler.unequipId
			end
			if newActionId ~= actionId then warn("ActionId doesn't equal NewActionId so ignoring") return end
			--if not fired then
			--	warn("Equip/Unequip signal hasn't fired so waiting for it")
			--	local signal = isEquipped and newhandler.equippedSignal or newhandler.unequippedSignal
			--	signal:Wait()
			--end
			--warn("Finished waiting for Equip/Unequip signal")
			isProcessingToggleEquip = false
			onToggleEquipFinished:Fire()
		end)
		
		success = true
	end)

	if not correctlyProcessedFunction then
		if isProcessingToggleEquip then
			isProcessingToggleEquip = false
			onToggleEquipFinished:Fire()
		end
	end

	--if not success then
	--	Thread.SpawnNow(function()
	--		error("Failed to equip " .. tostring(newhandler.weaponSettings.name) .. "\n" .. errmsg)
	--	end)
	--end

	return result
end

function FPSController:DestroyAllHandlers()
	--print("FPSController.DestroyAllHandlers")

	for _, v in pairs(handlers) do
		v:Destroy()
	end
	table.clear(handlers)
	noGunsInitiated = 0
	if equippedHandler then
		equippedHandler = nil
		self.isEquipped = false
		if lastAimValue then
			self.OnAimToggledSignal:Fire(false)
		end
		self.OnEquippedToggledSignal:Fire(false)
		self.OnFireToggledSignal:Fire(false)
	end

	equipCallQueue:emptyAll()
	if isProcessingToggleEquip then
		isProcessingToggleEquip = false
		onToggleEquipFinished:Fire()
	end


	WeaponsGui.Container.Visible = false
	WeaponsGui.AtEaseToggle.Visible = false
	--self.DisableCrosshair()
end

function FPSController:Update(dt)
	--[[
	crosshairTarDistance = 0
	
	if crosshairEnabled then
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

		self.UpdateCurrentCrosshairDistance(crosshairTarDistance + crosshairBaseDistance, false)
	end
	--]]
	for _, handler in pairs(handlers) do
		handler:Update(dt)
	end
	--	if equippedHandler then
	--	end
end

-- Called on ray hit
local function onRayHit(cast, raycastResult, segmentVelocity, bullet)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local hitMaterial = raycastResult.Material
	local normal = raycastResult.Normal
	
	local userData = cast.UserData

	local firedByClient = cast.UserData.firedByClient
	if not firedByClient then return end

	local weaponSettings = cast.UserData.weaponSettings

	local serverTick = TimeSync:GetTime()

	local hum, limb = getCharHumanoid(hitPart)

	local canHarm, isHeadshot, damage = false, false, nil

	if hum then
		local targetPlayer = Players:GetPlayerFromCharacter(hum.Parent)
		if targetPlayer then
			canHarm = TeamRulesController:CanKillPlayer(LocalPlayer, targetPlayer)
		else
			canHarm = TeamRulesController:CanKillEntity(LocalPlayer, hum.Parent)
		end

		if canHarm then
			isHeadshot = limb.Name == "Head"
			damage = isHeadshot and weaponSettings.headshot or weaponSettings.damage

			DisplayDamage.Display(LocalPlayer.Character, hum.Parent, damage, isHeadshot and 3 or 1)

			local shotId = userData.shotId

			if targetPlayer then
				FPSService.PlayerHitEvent:Fire(targetPlayer, shotId, serverTick, hitPoint, hitPart, hitPart.Position)
			else
				FPSService.NPCHitEvent:Fire(shotId, serverTick, hitPoint, hitPart)
			end
		end
	end

	FPSController.OnHitSignal:Fire(hum, hitPoint, canHarm, isHeadshot, damage)

	DisplayDamage.BulletContact(hitPoint, hitPart, hitMaterial, hum)

	if hitMaterial then
		SFXController:Play("impact", {material = hitMaterial, position = hitPoint})
	end

	--print("FPSCONTROLLER: RAY HIT ", hitPart:GetFullName())
end

local function onRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, bullet)
	--print("bullet travelling at ", segmentDirection, " from ", segmentOrigin)
	local BulletLength = bullet.Size.Z / 2
	bullet.CFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection) * CFrame.new(0, 0, -(length - BulletLength))
end

local function onRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	local self = cast.UserData.fastcastData
	local castBehavior = self.castBehavior

	--print("RAY TERMINATED ", cosmeticBullet:GetFullName())
	if cosmeticBullet ~= nil then
		-- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example gun works out of the box.
		-- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.
		castBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
		--cosmeticBullet:Destroy()
	end
end

local function canPierceFunction(cast, result, segmentVelocity)
	local instance = result.Instance
	if not result.Instance:IsA("Terrain")
		and (result.Instance.Transparency >= BulletPierceTransparencyThreshold and result.Instance.Name ~= "HumanoidRootPart")--or result.Instance.CanCollide == false)
	then
		--warn("passed through", result.Instance:GetFullName())
		return true
	else
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			local char = plr.Character
			if char then
				if instance.Parent == char then
					for _, v in ipairs(TrackedCharacterParts) do
						if instance.Name == v then
							return false
						end
					end
					return true
				elseif instance.Parent.Parent == char then
					return true
				end
			end
		end
		--warn("failed to pass through", result.Instance:GetFullName())
		return false
	end
end

FPSController.OnRayHit = onRayHit
FPSController.OnRayUpdated = onRayUpdated
FPSController.CanPierceFunction = canPierceFunction

local function baseFire(character, isPlayer, cache, index, origin, allDirections, weaponNameOrSettings, firedByClient)
	--print("BULLET FIRED")

	local weaponName, weaponSettings
	if typeof(weaponNameOrSettings) == "string" then
		weaponName = weaponNameOrSettings
		weaponSettings = GunFrameworkData.weaponsSettings[weaponName]
	elseif typeof(weaponNameOrSettings) == "table" then
		weaponSettings = weaponNameOrSettings
		weaponName = weaponSettings.name
	else
		error("::baseFire weaponNameOrSettings is neither a string or a table, instead is", typeof(weaponNameOrSettings))
	end

	local range = weaponSettings.range
	local speed = weaponSettings.speed

	local cacheData = cache[index]

	if cacheData == nil then
		local newIgnoreList = copy(ignoreList)
		if character then
			newIgnoreList[#newIgnoreList+1] = character
		end
		
		local onDestroyedMaid = Maid.new()
		onDestroyedMaid:GiveTask(FPSController.OnInstanceAddedToIgnoreList:Connect(function(inst)
			newIgnoreList[#newIgnoreList+1] = inst
		end))
		
		cacheData = {
			newIgnoreList = newIgnoreList;
			ignoredCharacter = character;
			onDestroyedMaid = onDestroyedMaid;
		}
		cache[index] = cacheData
	end

	if cacheData[weaponName] == nil then
		local caster = FastCast.new()

		local rayParams = RaycastParams.new()
		rayParams.IgnoreWater = true
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.FilterDescendantsInstances = cacheData.newIgnoreList

		local castBehavior = FastCast.newBehavior()
		castBehavior.RaycastParams = rayParams
		castBehavior.MaxDistance = range
		castBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

		local cosmeticPartProvider = PartCache.new(weaponSettings.bullet, weaponSettings.poolNumber[isPlayer and "player" or "npc"], workspace.fastCast)

		castBehavior.CosmeticBulletProvider = cosmeticPartProvider
		castBehavior.CosmeticBulletContainer = workspace.fastCast
		castBehavior.Acceleration = Vector3.new(0, 0, 0)--weaponSettings.bulletGravity
		castBehavior.AutoIgnoreContainer = false
		castBehavior.CanPierceFunction = canPierceFunction

		caster.RayHit:Connect(onRayHit)
		caster.LengthChanged:Connect(onRayUpdated)
		caster.CastTerminating:Connect(onRayTerminated)

		cacheData[weaponName] = {
			caster = caster;
			rayParams = rayParams;
			castBehavior = castBehavior;
			characterIgnored = character;
		}
	end

	local caster = cacheData[weaponName].caster
	local rayParams = cacheData[weaponName].rayParams
	local castBehavior = cacheData[weaponName].castBehavior
	
	local newIgnoreList = cacheData.newIgnoreList
	if cacheData.ignoredCharacter ~= character then
		cacheData.ignoredCharacter = character
		newIgnoreList[#newIgnoreList+1] = character
		
		rayParams.FilterDescendantsInstances = newIgnoreList
	end

	--makePart(origin, Vector3.new(1.5,1.5,1.5), Color3.fromRGB(0,0,0))

	--print("SHOOTING FROM ", origin)
	for i, dir in ipairs(allDirections) do
		local bullet = castBehavior.CosmeticBulletProvider:GetPart()
		onRayUpdated(nil, origin, dir, 0, Vector3.new(), bullet)
		RunService.RenderStepped:Wait()

		local activeCast = caster:Fire(
			origin,
			dir,
			speed,
			castBehavior,
			bullet
		)

		activeCast.UserData.character = character
		activeCast.UserData.weaponSettings = weaponSettings
		activeCast.UserData.shooterData = cacheData
		activeCast.UserData.fastcastData = cacheData[weaponName]
		activeCast.UserData.firedByClient = firedByClient
		activeCast.UserData.playedFlyby = false
		activeCast.UserData.shotId = CurrentShotNumber+i
		activeCast.UserData.origin = origin
		activeCast.UserData.direction = dir
	end

	if not firedByClient then
		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
		if head then
			local mindist = 999
			local minpoint = Vector3.new()
			for i, dir in ipairs(allDirections) do
				-- https://monkeyproofsolutions.nl/wordpress/how-to-calculate-the-shortest-distance-between-a-point-and-a-line/
				local m = (origin + dir*range) - origin
				local t0 = m:Dot(head.Position - origin)/m:Dot(m)
				local intersectionPoint = origin + t0 * m;

				local dist = (head.Position - intersectionPoint).Magnitude
				if dist < mindist then
					mindist = dist
					minpoint = intersectionPoint
				end
			end
			if mindist <= SFXController.FlybyMaxDist.Value then
				local timeToReach = (minpoint - origin).Magnitude/speed
				Thread.Delay(timeToReach, function()
					SFXController:Play("flyby", {position = minpoint, distance = mindist})
				end)
			end
		end
	end
	
	if firedByClient then
		local serverTick = TimeSync:GetTime()
		local serverDirections = {}
		for i, v in ipairs(allDirections) do
			serverDirections[i] = {v, CurrentShotNumber+i}
		end
		FPSService.FireEvent:Fire(serverTick, origin, serverDirections)
	end
	
	CurrentShotNumber += #allDirections-1
	--print("fastcast data ", cacheData[weaponName])
end

local function onBulletFired(shooter, origin, allDirections, weaponName)
	baseFire(
		shooter.Character,
		true,
		playersGunsData,
		tostring(shooter.UserId),
		origin,
		allDirections,
		weaponName,
		false
	)
end

local function onNPCFired(npc, weaponName, origin, allDirections)
	baseFire(
		npc,
		false,
		npcGunsData,
		npc,
		origin,
		allDirections,
		weaponName,
		false
	)
end

function FPSController:ClientFire(origin, allDirections, weaponSettings)
	
	baseFire(
		LocalPlayer.Character,
		true,
		playersGunsData,
		tostring(LocalPlayer.UserId),
		origin,
		allDirections,
		weaponSettings,
		true
	)
end

local function onInstanceAddedToIgnore(inst)
	ignoreList[#ignoreList+1] = inst
	rayParams.FilterDescendantsInstances = ignoreList
end

local function onPlayerRemoving(player)
	if playersGunsData[player.UserId] then
		playersGunsData[player.UserId].onDestroyedMaid:Destroy()
		playersGunsData[player.UserId] = nil
	end
end

local function onPlayerAdded(player)
	if player ~= LocalPlayer then
		local function onCharacterAdded()
			local character = player.Character
			
			local function onChildAdded(inst)
				for _, partName in pairs(TrackedCharacterParts) do
					if inst.Name == partName and inst:IsA("BasePart") then
						return
					end
				end

				ignoreList[#ignoreList+1] = inst
				
				--print("FPSController Ignoring", player.Name, "'s", inst.Name, "which is", inst.ClassName)
			end
			
			character.ChildAdded:Connect(onChildAdded)
			for _, v in ipairs(character:GetChildren()) do
				onChildAdded(v)
			end
		end
		player.CharacterAdded:Connect(onCharacterAdded)
		if player.Character then onCharacterAdded(player.Character) end
	end
end

function FPSController:makeHandler(tool, weaponSettings, clientHandlerSettings, firstPersonSettings, thirdPersonSettings, ...)
	local settings = table.pack(...)
	--[[
    print("adding ", weaponNumber, "----------------")
    for i, v in pairs({...}) do
        print(i,v)
    end
    print("finished adding ", weaponNumber, "----------------")
	--]]

	local weaponNumber = noGunsInitiated
	noGunsInitiated += 1

	local loadingLabelState = false

	local labelEquipConn = tool.Equipped:Connect(function(equipped)
		print("equipped tool")
		loadingLabelState = true
		WeaponsGui.LoadingLabel.Visible = true
	end)
	local labelUnequipConn = tool.Unequipped:Connect(function(equipped)
		print("unequipped tool")
		loadingLabelState = false
		WeaponsGui.LoadingLabel.Visible = false
	end)

	local newhandler = GunHandler.new(tool, weaponSettings, clientHandlerSettings, firstPersonSettings, thirdPersonSettings, ...)
	local pos = #handlers + 1
	table.insert(handlers, newhandler)

	labelEquipConn:Disconnect()
	labelUnequipConn:Disconnect()
	if loadingLabelState then
		WeaponsGui.LoadingLabel.Visible = false
	end

	local equipContextName = "EquipGun" .. tostring(weaponNumber)
	local aimContextName = "AimGun" .. tostring(weaponNumber)
	local shootContextName = "ShootGun" .. tostring(weaponNumber)
	local reloadContextName = "ReloadGun" .. tostring(weaponNumber)
	local atEaseContextName = "AtEaseGun" .. tostring(weaponNumber)

	newhandler.aimedSignal:Connect(function()
		if lastAimValue ~= true then
			lastAimValue = true
			self.OnAimToggledSignal:Fire(lastAimValue)
		end
	end)
	newhandler.unaimedSignal:Connect(function()
		if lastAimValue ~= false then
			lastAimValue = false
			self.OnAimToggledSignal:Fire(lastAimValue)
		end
	end)

	local function onEquippedOrUnequipped(equip)
		print("setting equip to", equip, "for", newhandler.name)
		updateEquippedHandlers()
		--self:ToggleEquip(true, equip, newhandler)
	end

	newhandler.onDestroyedMaid:GiveTask(ToolController.OnEquipped:Connect(function(equipped)
		if equipped == tool then
			if EquipingDisablers:GetIsAllOff() and (tool.Parent == LocalPlayer.Backpack or tool.Parent == LocalPlayer.Character) then
				--print("tool equipped")
				onEquippedOrUnequipped(true)
			else
				print("EquipingDisablers returned true", "\n", EquipingDisablers)
				tool.Parent = LocalPlayer.Backpack
			end
		end
	end))
	if ToolController:GetIsToolEquipped(tool) then
		onEquippedOrUnequipped(true)
	end

	newhandler.onDestroyedMaid:GiveTask(ToolController.OnUnequipped:Connect(function(equipped)
		if equipped == tool then
			--print("tool unequipped")
			onEquippedOrUnequipped(false)
		end
	end))

	newhandler.onDestroyedMaid:GiveTask(ToolController.OnDestroyed:Connect(function(destroyed)
		if destroyed == tool then
			if equippedHandler == newhandler then
				equippedHandler = nil
				self.OnEquippedToggledSignal:Fire(false)
			end
			newhandler:Destroy()
			noGunsInitiated -= 1

			table.remove(handlers, pos)
		end
	end))
	
	newhandler.onDestroyedMaid:GiveTask(FPSService.OrderWeaponSkinChange:Connect(function(weaponName, skinData)
		if weaponName ~= newhandler.name then return end
		for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
			for partName, partData in pairs(skinData) do
				local part = findFirstChildWhichIsA(weaponModel, partName, "BasePart", true)
				assert(part, "Failed to find " .. tostring(partName))
				for property, value in pairs(partData) do
					part[property] = value
				end
			end
		end
	end))

	newhandler.onDestroyedMaid:GiveTask(FPSService.OrderWeaponStickerChange:Connect(function(weaponName, state, stickerDataOrName)
		if weaponName ~= newhandler.name then return end
		if state then
			local stickerData = stickerDataOrName
			for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
				local stickerPart = stickerData.Part:Clone()
				stickerPart.Motor6D.Part0 = findFirstChildWhichIsA(weaponModel, stickerData.Part0Name, "BasePart", true)
				stickerPart.Parent = weaponModel
			end
		else
			local stickerName = stickerDataOrName
			for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
				if weaponModel:FindFirstChild(stickerName) then
					weaponModel:FindFirstChild(stickerName):Destroy()
				end
			end
		end
	end))

	newhandler.onDestroyedMaid:GiveTask(FPSService.OrderWeaponCharmChange:Connect(function(weaponName, state, charmDataOrName)
		if weaponName ~= newhandler.name then return end
		for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
			for _, v in ipairs(weaponModel:GetChildren()) do
				if v:GetAttribute("IsCharm") then
					v:Destroy()
				end
			end
		end
		if state then
			local charmData = charmDataOrName
			for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
				local charmPart = charmData.Part:Clone()
				
				local charmHolder = weaponModel.CharmHolder
				charmHolder.RopeConstraint.Attachment1 = charmPart.Attachment1
				charmPart.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(-1.5,0,0)
				charmPart.Parent = weaponModel
				if weaponModel == firstPersonSettings.viewmodel then
					newhandler.firstPersonHandler.charm = charmPart
				else
					newhandler.thirdPersonHandler.charm = charmPart
				end
			end
		end
	end))

	newhandler.onDestroyedMaid:GiveTask(FPSService.OrderAllWeaponStickerRemove:Connect(function(weaponName)
		for _, weaponModel in ipairs({firstPersonSettings.viewmodel, thirdPersonSettings.weapon}) do
			for _, v in ipairs(weaponModel:GetChildren()) do
				if v:GetAttribute("IsSticker") then v:Destroy() end
			end
		end
	end))

	ContextActionService:BindAction(aimContextName, function(name, state, obj)
		if newhandler:GetIsEquipped() and not newhandler:GetIsAtEase() then

			--warn("taken aim input")
			newhandler:ToggleAim(true, state == Enum.UserInputState.Begin)

			return Enum.ContextActionResult.Sink -- stop execution stack
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.UserInputType.MouseButton2)

	ContextActionService:BindAction(shootContextName, function(name, state, obj)
		if newhandler:GetIsEquipped() and not newhandler:GetIsAtEase() then
			--print("taken shoot input")

			self:SetFiring(state == Enum.UserInputState.Begin)

			return Enum.ContextActionResult.Sink -- stop execution stack
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.UserInputType.MouseButton1)

	ContextActionService:BindAction(reloadContextName, function(name, state, obj)
		if newhandler:GetIsEquipped() and not newhandler:GetIsAtEase() then
			print("taken reload input")

			if state == Enum.UserInputState.Begin then
				--warn("reloading input ", Handler)
				if not newhandler:GetIsReloading() then
					newhandler:SetReloading(true)
				end
			end

			return Enum.ContextActionResult.Sink -- stop execution stack
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.KeyCode.R)

	ContextActionService:BindAction(atEaseContextName, function(name, state, obj)
		if newhandler:GetIsEquipped() and state == Enum.UserInputState.Begin then

			self:ToggleAtEase()

			return Enum.ContextActionResult.Sink -- stop execution stack
		else
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.KeyCode.F)

	newhandler.onDestroyedMaid:GiveTask(function()
		ContextActionService:UnbindAction(equipContextName)
		ContextActionService:UnbindAction(aimContextName)
		ContextActionService:UnbindAction(shootContextName)
		ContextActionService:UnbindAction(reloadContextName)
		ContextActionService:UnbindAction(atEaseContextName)
	end)

	--print("Finished setting up", weaponSettings.name)
end

function FPSController:GetIgnoreList()
	return ignoreList
end

function FPSController:AddToIgnoreList(inst)
	table.insert(ignoreList, inst)
	rayParams.FilterDescendantsInstances = ignoreList
	self.OnInstanceAddedToIgnoreList:Fire(inst)
end

function FPSController:KnitInit()

end

function FPSController:KnitStart()
	local Self = self

	MovementController = Knit.Controllers["MovementController"]
	InputController = Knit.Controllers["InputController"]
	CameraController = Knit.Controllers["CameraController"]
	CharacterController = Knit.Controllers["CharacterController"]
	ToolController = Knit.Controllers["ToolController"]
	SFXController = Knit.Controllers["SFXController"]
	TeamRulesController = Knit.Controllers["TeamRulesController"]
	
	TimeSync:Initialize()

	Players.PlayerRemoving:Connect(onPlayerRemoving)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, plr in ipairs(Players:GetPlayers()) do
		Thread.Spawn(function()
			onPlayerAdded(plr)
		end)
	end

	ignoreList = FPSService:GetIgnoreList()
	rayParams.FilterDescendantsInstances = ignoreList

	for _, v in ipairs(CollectionService:GetTagged(GlobalFastCastIgnoreTag)) do
		if v:IsA("BasePart") then
			ignoreList[#ignoreList+1] = v
		end
	end
	CollectionService:GetInstanceAddedSignal(GlobalFastCastIgnoreTag):Connect(function(v)
		if v:IsA("BasePart") then
			ignoreList[#ignoreList+1] = v
		end
	end)

	FPSController:AddToIgnoreList(workspace.CurrentCamera)

	FPSService.OnInstanceAddedToIgnore:Connect(onInstanceAddedToIgnore)
	FPSService.OnFiredEvent:Connect(onBulletFired)
	FPSService.OnNPCFired:Connect(onNPCFired)

	self.weaponConnections.jumpSignal = MovementController.OnJumpSignal:Connect(function()
		if equippedHandler then
			equippedHandler:SetJump(true)
			wait(0.1)
			equippedHandler:SetJump(false)
		end
	end)

	local isProcessingDeath, processedDeathSignal = false, Signal.new() -- in case handler::Destroy yields
	--[[ not needed since tools are destroyed when character dies already and that is handled
	self.weaponConnections.deathSignal = CharacterController.DeathSignal:Connect(function()
		isProcessingDeath = true
		
		for _, handler in ipairs(handlers) do
			handler:Destroy()
		end
		handlers = {}
		
		noGunsInitiated = 0
		
		isProcessingDeath = false
		processedDeathSignal:Fire()
	end)
	--]]

	CharacterController.DeathSignal:Connect(function(char)
		self:DestroyAllHandlers()
	end)

	CharacterController.SpawnSignal:Connect(function(char)
		FPSController:AddToIgnoreList(char)

		local humanoid = char:WaitForChild("Humanoid")

		--self:DestroyAllHandlers()

		--humanoid.StateChanged:Connect(function(oldstate, newstate)
		--	if newstate == Enum.HumanoidStateType.Dead then
		--		self:DestroyAllHandlers()
		--	end
		--end)

		local wasEquipped = false
		local function unequip(name, state)
			EquipingDisablers:Set(name, state)
			if state then
				if self:GetIsEquipped() then
					wasEquipped = true
					self:ToggleEquip(true, false)
				end
			else
				if wasEquipped then
					wasEquipped = false
					self:ToggleEquip(true, true)
				end
			end
		end

		--humanoid.Climbing:connect(function(state) unequip("Climbing", state) end)
		--humanoid.Swimming:connect(function(state) unequip("Swimming", state) end)
	end)

	FPSService.OrderClientSetup:Connect(function(weaponName, tool, weaponModel)
		if isProcessingDeath then processedDeathSignal:Wait() end

		local character = LocalPlayer.Character
		if character == nil then character = LocalPlayer.CharacterAdded:Wait() end
		--print("asked to setup", weaponName)

		local handler

		local weaponSettings = GunFrameworkData.weaponsSettings[weaponName]
		local clientHandlerSettings = {
			serverAPI = FPSService;
			clientAPI = FPSController;
			movementAPI = MovementController;
		}

		--local model = ItemService:GetItem(weaponName).Model

		handler = self:makeHandler(
			tool,
			weaponSettings,
			clientHandlerSettings,
			{ --firstperson metadata
				isPlayer = true;
				viewmodel = FPSAssets:WaitForChild("viewmodel"):Clone();

				shouldPlayAnimations = true;
				aimingSensMult = 0.1;
				aimingSwayMult = 0.1;
				weapon = weaponModel:Clone();

				clientAPI = FPSController;
				serverAPI = FPSService;
				movementAPI = MovementController;
				inputAPI = InputController;
			},
			{ -- thirdperson metadata
				isPlayer = true;
				weapon = weaponModel:Clone();
				shouldPlayAnimations = true;

				clientAPI = FPSController;
				serverAPI = FPSService;
				movementAPI = MovementController;
			},
			character
		)
	end)

	RunService:BindToRenderStep("FPSController", Enum.RenderPriority.Character.Value, function(dt)
		Self:Update(dt)
	end)

	FPSService.OrderWeaponRigToggle:Connect(function(player, weaponModel, weaponName, state)
		local character = player.Character
		if not character then return end
		character:WaitForChild("RightUpperArm")
		character:WaitForChild("UpperTorso")
		weaponModel = weaponModel or waitForChildWhichIsA(character, weaponName, "Model")
		weaponModel:WaitForChild("receiver")
		weaponModel.receiver:WaitForChild("backweld")
		weaponModel.receiver:WaitForChild("weaponHold")
		print("FPSCONTROLLER::OrderWeaponRigToggle", player, weaponModel, weaponName, state)
		
		if not workspace:IsAncestorOf(character) then return end

		local weaponSettings = GunFrameworkData.weaponsSettings[weaponName]

		local offsets = weaponSettings.offsets.weaponFrame

		local backweld = weaponModel.receiver.backweld
		local weaponHold = weaponModel.receiver.weaponHold

		if state then
			weaponModel.Parent = character

			weaponHold.C0 = offsets.weaponHold.C0
			weaponHold.C1 = offsets.weaponHold.C1

			weaponHold.Part0 = character.RightUpperArm
		else
			if not weaponSettings.hidesOnUnequip then
				backweld.C0 = offsets.backweld.C0
				backweld.C1 = offsets.backweld.C1

				backweld.Part0 = character.UpperTorso
			else
				weaponModel.Parent = FPSService.UnequippedWeaponsFolder:Get()
			end
		end
		--[[ 
		for _, v in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
			local anim = v.Animation
			local isWeaponAnim, weaponName, animType = GunFrameworkData.isIdWeaponAnimationId(anim.AnimationId)
			if isWeaponAnim then -- and animType=="equip"
				print(anim.Parent, "restarting", anim.AnimationId)
				local weight, speed, pos, looped = v.WeightCurrent, v.Speed, v.TimePosition, v.Looped
				v:Stop()
				v:Play(nil, weight, speed)
				v.Looped = looped
				v.TimePosition = pos
			else
				print(anim:GetFullName(), "isnt in GunData but is playing", animType, anim.AnimationId)
			end
		end
		--]]
	end)

	FPSService.PlaySoundEvent:Connect(function(requester, sound, weaponModel)
		if not weaponModel or not weaponModel.PrimaryPart then return end
		local newSound = sound:Clone()
		newSound.Volume = sound.Volume * 0.7
		newSound.Parent = weaponModel.PrimaryPart
		newSound.PlayOnRemove = true
		newSound:Destroy()
	end)

	WeaponsGui = PlayerGui:WaitForChild("Weapons")
	PlayerGui.ChildAdded:Connect(function(child)
		if child.Name == "Weapons" and child:IsA("ScreenGui")  then
			WeaponsGui = child
		end
	end)

	local forceAim = Instance.new("BoolValue", script)
	forceAim.Name = "ForceAim"
	forceAim.Changed:Connect(function()
		if equippedHandler then
			equippedHandler:ToggleAim(true, forceAim.Value)
		end
	end)
end

return FPSController