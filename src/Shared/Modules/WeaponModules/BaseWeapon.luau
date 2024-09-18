	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local Debris = game:GetService("Debris")

	-- CONSTANTS
	local IsServer = RunService:IsServer()
	local IsClient = not IsServer

	local SharedModules = ReplicatedStorage:WaitForChild("Modules")
	local WeaponModules = SharedModules:WaitForChild("WeaponModules")

	local Knit = require(SharedModules.Knit)
	local Signal = require(Knit.Util.Signal)
	local Thread = require(Knit.Util.Thread)
	local Maid = require(Knit.Util.Maid)

	local wait = Thread.Wait

	-- Requires
	--local FastcastHandler = require(WeaponModules:WaitForChild("FastCastHandler"))
	local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))
	local PartCache = require(SharedModules:WaitForChild("PartCache"))

	local BaseWeapon = {}
	BaseWeapon.__index = BaseWeapon

	local function createValue(className, defaultValue, parent)
	    local value = Instance.new(className)
	    value.Value = defaultValue
	    if parent then
	        value.Parent = parent
	    end
	    return value
	end

	local function findFirstChildOfClassAndName(inst, class, name, recursive)
		for _, v in ipairs(inst:GetChildren()) do
			if v.Name == name and v.ClassName == class then
				return v
			else
				if recursive then
					local found = findFirstChildOfClassAndName(v, class, name, recursive)
					if found then
						return found
					end
				end
			end
		end
	end

	function BaseWeapon.new(weaponSettings, metaSettings, character, weapon)
	    assert(typeof(weaponSettings) == "table", ("Expected weaponSettings table, got %s"):format(typeof(weaponSettings)))
	    assert(typeof(metaSettings) == "table", ("Expected metaSettings table, got %s"):format(typeof(metaSettings)))
	    assert(typeof(character) == "Instance", ("Expected character model, got %s"):format(typeof(character)))
	    assert(typeof(weapon) == "Instance", ("Expected weapon model, got %s"):format(typeof(weapon)))

	    local self = setmetatable({}, BaseWeapon)
		
	    self.weaponSettings = weaponSettings
	    self.metaSettings = metaSettings
	    self.character = character
		self.weapon = weapon
		
		self.name = weaponSettings.name

	    --[[
	    for _, v in ipairs(weapon:GetDescendants()) do
	        if v:IsA("BasePart") then
	            v.Massless = true
	            v.Anchored = false
	            v.CanCollide = false
	            v.CastShadow = false
	        end
	    end
	    --]]

	    self.randomGenerator = Random.new()

	    -- Meta
	    self.isPlayer = self.metaSettings.isPlayer
	    self.movementAPI = metaSettings.movementAPI
		self.shouldPlayAnimations = metaSettings.shouldPlayAnimations
		
		self.onDestroyedMaid = Maid.new()

	    -- Signals
	        -- On Action Done Signals
	        self.equippedSignal = Signal.new()
	        self.unequippedSignal = Signal.new()
	        self.pumpedSignal = Signal.new()
			self.reloadedSignal = Signal.new()
			self.firedSignal = Signal.new()
			self.toggledFiringSignal = Signal.new()
			self.aimedSignal = Signal.new()
			self.unaimedSignal = Signal.new()
			
			-- On Action Needed Signals
	        self.reloadNeededSignal = Signal.new()
	        self.pumpNeededSignal = Signal.new()

	    self.actionCancelled = {
	        aim = Signal.new();
	        equip = Signal.new();
	        unequip = Signal.new();

	    }

	    -- Weapon Settings
	    self.actionsDuration = weaponSettings.actionsDuration
	    self.ammo = weaponSettings.magCapacity

	    self.usesPump = weaponSettings.usesPump

	    -- States
	    self.isEnabled = true
		self.equippedIn = 0
		
		self.isAtEase = IsClient and true or false

	    self.currentFiringMode = weaponSettings.defaultFiringMode
	    self.canFire = true
		self.isFiring = false
		self.isLineOfSightBlocked = false
		self.lastShotTime = 0
		self.firingId = 0

	    self.isSprinting = false
	    self.isAiming = false
	    self.isEquipped = false

	    self.isReloading = false
	    self.reloadingSince = 0

	    self.isFillingBullets = false
	    self.hasPumpedBullet = true
	    self.cancelledPump = false
	    self.lastPumpTime = 0
	    self.isPumping = false

	    self.isEquipBlockedExt = false
		self.isUnequipBlockedExt = false
		
		self.isDestroyed = false

		self.playingAnimationIndex = {}

		self.frameNumber = 0
		
		if not IsServer then
			self.movementAPI.OnSprintChanged:Connect(function(state)
				self:ToggleSprint(true, state)
			end)
			self.movementAPI.OnMovementChanged:Connect(function()
				self:PlayIdleAnim()
			end)
		end
		
		self.receiver = self.weapon.receiver
		self.barrelAttachment = findFirstChildOfClassAndName(self.weapon, "Attachment", "barrel", true)
		
		if IsClient then
			-- muzzle flash is useless on server
			self.muzzleFlashShown = false
			self.muzzleFlashBeam = findFirstChildOfClassAndName(self.weapon, "Beam", "muzzleFlash", true)
			if self.muzzleFlashBeam then
				self.muzzleFlash0 = findFirstChildOfClassAndName(self.weapon, "Attachment", "muzzleFlash0", true)
				self.muzzleFlash1 = findFirstChildOfClassAndName(self.weapon, "Attachment", "muzzleFlash1", true)

				self.muzzleFlash0CFrame = self.muzzleFlash0.WorldCFrame
				self.muzzleFlash1CFrame = self.muzzleFlash1.WorldCFrame
			end
		end

	    return self
	end

	function BaseWeapon:Destroy()
		if self.isDestroyed then return true end
		self.isDestroyed = true
		
	    Debris:AddItem(self.weapon,0)

	    self.isEnabled = false
	    self.isFiring = false
	    self.canFire = false
	    self.isReloading = false
		self.isPumping = false
		self:StopAllAnimations()
		
		self.onDestroyedMaid:Destroy()

	    return true
	end

	function BaseWeapon:GetIsDestroyed()
		return self.isDestroyed
	end

	function BaseWeapon:IsValid()
	    return self.character and self.isEnabled and self.weapon and not self.isDestroyed-- and workspace:IsAncestorOf(self.weapon)
	end

	function BaseWeapon:SetEquippingBlocked(state)
	    self.isEquipBlockedExt = state
	end

	function BaseWeapon:SetUnequippingBlocked(state)
	    self.isUnequipBlockedExt = state
	end

	function BaseWeapon:StopAllAnimations()
	    local function stop(t)
	        for _,v in pairs(t) do
	            if typeof(v) == "table" then
	                stop(v)
	            else
	                v:Stop()
	            end
	        end
	    end
	    stop(self.loadedAnimations)
	    return true
	end

	function BaseWeapon:StopAnimation(name)
		local index = self.playingAnimationIndex[name]
		if self.loadedAnimations[name] and index then
			self.loadedAnimations[name][index]:Stop()
		else
			return false
		end
		return true
	end

	function BaseWeapon:GetIsAnimationPlaying(name)
		local index = self.playingAnimationIndex[name]
		if self.loadedAnimations[name] and index and self.loadedAnimations[name][index].IsPlaying then
			return true
		else
			return false
		end
	end

	function BaseWeapon:GetPlayingAnimation(name)
		local index = self.playingAnimationIndex[name]
		if self.loadedAnimations[name] and index and self.loadedAnimations[name][index].IsPlaying then
			return self.loadedAnimations[name][index]
		else
			return nil
		end
	end

	function BaseWeapon:PlayAnimation(name, index, loop, dur, speed, priority, timePosition)
	    if not self.shouldPlayAnimations then return false end
		if typeof(index) == "table" then
			local settings = index
			index = settings.index
			loop = settings.loop
			dur = settings.dur
			speed = settings.speed
			priority = settings.priority
			timePosition = settings.timePosition
		end
	    local allAnims = self.loadedAnimations[name]
	    if allAnims == nil then return false end

	    local index = index == nil and math.random(1, #allAnims) or index
	    local animObj = allAnims[index]
	    local speed = speed or self.animationsSpeeds[name][index]
		
		animObj.Looped = loop
		if priority then
			animObj.Priority = priority
		end
		
		--print("playing", name, "#", index, "for", dur, "with speed", speed, "is looped", animObj.Looped)
	    animObj:Play(nil, nil, (dur ~= nil and animObj.Length/dur) or (speed ~= nil and speed) or 1)

	    self.playingAnimationIndex[name] = index

	    return animObj
	end

	function BaseWeapon:PlayEquipAnim(index)
		local name = "equip"
		local animObj = self:PlayAnimation(name, {loop = false, priority = Enum.AnimationPriority.Action})
	    --local conn
		--conn = animObj.Stopped:Connect(function()
		local equipId = self.equippedIn
		Thread.SpawnNow(function()
	    --coroutine.wrap(function()
	        --conn:Disconnect()
	        wait(self.actionsDuration[name])
			if not self.isEquipped or self.equippedIn ~= equipId then
				--warn("Ignoring equipped finished bec equipId is different")
				return
			end
	        self.equippedSignal:Fire()
	        if animObj then
	            animObj:Stop()
			end
			if not self.isAtEase then
				self:RunAnimation("gunUp")
	        	--warn("playing gunUp animation")
			else
				self:RunAnimation("atease")
				--warn("playing atease animation")
			end
	    end)--()

	    return true
	end

	function BaseWeapon:PlayUnequipAnim()
		local name = "unequip"
		
		if self.shouldPlayAnimations then
			local index = self.playingAnimationIndex["equip"]
			local animObj = self.loadedAnimations["equip"][index]
			local hasFinishedPlaying = tick() - self.equippedIn >= self.actionsDuration["equip"]
			local beginAt = hasFinishedPlaying and animObj.Length or animObj.Length - animObj.TimePosition
			animObj.TimePosition = beginAt
			animObj:Play(nil, nil, -self.animationsSpeeds["equip"][index])
		end
		local unequipId = self.unequippedIn
		--local conn
		--conn = animObj.Stopped:Connect(function()
		Thread.SpawnNow(function()
			--coroutine.wrap(function()
			--conn:Disconnect()
			wait(self.actionsDuration[name])
			if self.unequippedIn ~= unequipId then return end
			--or (self.weaponSettings.unequipTime - (tick() - self.unequippedIn)) >= 0.09 
			if self.isEquipped then print("unequipped cancelled", tick() - self.unequippedIn, self.weaponSettings.unequipTime) return end

			self.unequippedSignal:Fire()

			self:StopAllAnimations()
			--animObj:Stop()
		end)--()
		
		return true
	end

	function BaseWeapon:PlayIdleAnim()
		if not self.isEquipped then return end
		
		local animSettings = {loop = true; priority = Enum.AnimationPriority.Idle}
		if self.isAtEase then
			self:StopAnimation("gunUp")
			self:PlayAnimation("atease", animSettings)
		else
			if self.isLineOfSightBlocked or self.isSprinting and self.movementAPI:GetIsMoving() then
				self:StopAnimation("gunUp")
				self:PlayAnimation("atease", animSettings)
			else
				self:StopAnimation("atease")
				self:PlayAnimation("gunUp", animSettings)
			end
		end
	end

	function BaseWeapon:RunAnimation(name)
	    local allAnims = self.loadedAnimations[name]
	    local index,animObj,speed;
	    if allAnims and #allAnims >= 1 then
	        index = math.random(1, #allAnims)
	        animObj = allAnims[index]
	        speed = self.animationsSpeeds[name][index]
	    end

		if name == "aimFire" or name == "fire" then
			animObj = self:PlayAnimation(name, {
				index = index,
				loop = false,
				speed = speed,
				priority = Enum.AnimationPriority.Action
			})

	        --local conn
			--conn = obj.Stopped:Connect(function()
			Thread.SpawnNow(function()
	        --coroutine.wrap(function()
	            --conn:Disconnect()
	            wait(self.actionsDuration[name])

	            if tick() - self.lastShotTime + self.deltaTime >= self.actionsDuration[name]
	                then
	                if self.usesPump then
	                    if self.isPlayer or self.isFiring then
	                        local fired = false
	                        local conn
	                        conn = self.pumpedSignal:Connect(function()
	                            conn:Disconnect()
	                            fired = true
	                        end)
	                    
	                        self:StartPump()

	                        if self.isPlayer then

	                        else
	                            self.pumpNeededSignal:Fire()
	                            if not fired then
	                                self.pumpedSignal:Wait()
	                            end
	                        end
	                    end
	                else --is not pump

	                end
	            else
	                --warn("FAILED TO START PUMP ", obj.Length/obj.Speed, tick() - self.lastShotTime, self.deltaTime)
	            end
			end)--()
		
	    elseif name == "equip" then
			self:PlayEquipAnim(index)
			
	    elseif name == "unequip" then
			self:PlayUnequipAnim(index)
			
	    elseif name == "firePump" or name == "aimFirePump" then
	        
			animObj = self:PlayAnimation(name, {loop = false, priority = Enum.AnimationPriority.Action})
	        --local conn
			--conn = obj.Stopped:Connect(function()
			Thread.SpawnNow(function()
	        --coroutine.wrap(function()
	            --conn:Disconnect()
	            wait(self.actionsDuration[name])

	            if self.isPumping then-- and tick() - self.lastPumpTime + self.deltaTime >= self.weaponSettings.pumpTime
	                print("finished pump", tick() - self.lastPumpTime)

	                self.hasPumpedBullet = true
	                self.pumpedSignal:Fire()
	            else
	                print("pump considered cancelled", tick() - self.lastPumpTime)
	            end

	            self:StopPump()
	        end)--()
		elseif name == "aim" then
			if self.isUnequipped then return end
			
			if index then
				local aimId = self.aimedIn
				self.playingAnimationIndex[name] = index
				if self.shouldPlayAnimations then
					animObj = self.loadedAnimations[name][index]
					animObj.Priority = Enum.AnimationPriority.Action
					animObj.TimePosition = 0
					animObj:Play(nil, nil, self.animationsSpeeds[name][index])
				end
				--print("STARTING AIM ANIM STATE:", animObj.IsPlaying, index)
				Thread.Delay(self.actionsDuration[name], function()
		            if self.aimedIn ~= aimId or not self.isAiming then warn("aim cancelled", self.isAiming) return end
					if typeof(animObj) == "Instance" and animObj:IsA("AnimationTrack") and self.shouldPlayAnimations then
		                animObj:Play(nil, nil, 0)
		                animObj.TimePosition = animObj.Length - 0.001
		            end
				end)
			end
		elseif name == "unaim" then
			if self.isUnequipped then return end
			
			local index = self.playingAnimationIndex["aim"]
			animObj = index and self.loadedAnimations["aim"][index]
			if animObj and self.shouldPlayAnimations then
				animObj.Priority = Enum.AnimationPriority.Action
				
				local hasFinishedPlaying = tick() - self.aimedIn >= self.actionsDuration["aim"]
				local beginAt = hasFinishedPlaying and animObj.Length or animObj.Length - animObj.TimePosition
				animObj:Play(nil, nil, -self.animationsSpeeds["aim"][index])
				animObj.TimePosition = beginAt
				--print("STOPPING AIM ANIM STATE:", animObj.IsPlaying, beginAt)
	        else
				warn("failed to stop aiming", self.playingAnimationIndex["aim"])
				--print(self.loadedAnimations["aim"])
	        end
	    elseif name == "reload" then

			animObj = self:PlayAnimation(name, {loop = false, priority = Enum.AnimationPriority.Action})
			Thread.SpawnNow(function()
	        --coroutine.wrap(function()
	            --conn:Disconnect()
	            wait(self.actionsDuration[name])
	        end)--()
		elseif name == "gunUp" or name == "atease" then
			animObj = self:PlayIdleAnim()
		elseif name == "sprint" or name == "walk" then
			-- played by ClientWeaponHandler only
			local other = name == "sprint" and "walk" or "sprint"
			local animation = self.loadedAnimations[other][self.playingAnimationIndex[other]]
			local timePos = 0
			if animation then
				timePos = animation.TimePosition
				animation:Stop()
			end
			animObj = self:PlayAnimation(name, {loop = true; priority = Enum.AnimationPriority.Core; timePosition = timePos})
	    --elseif name == "unsprint" then
	    --    animObj = self.playingAnimationIndex["sprint"] and self.loadedAnimations["sprint"][self.playingAnimationIndex["sprint"]]
	    --    if animObj then
	    --        animObj:Stop()
	    --    else
	    --        warn("failed to stop sprinting")
	    --    end
		else
			if self.shouldPlayAnimations then
				animObj:Play(0.1, 1, speed)
			end
	    end

	    return animObj
	end

	function BaseWeapon:ToggleAtEase(force, state)
		if force then if self.isAtEase == state then return true end end
		local isAtEase = not self.isAtEase
		self.isAtEase = isAtEase
		
		if self.isEquipped then
			self:PlayIdleAnim()
			
			if isAtEase then

				--if self.isReloading then
				--	self:StopReloading(false)
				--end
				if self.isFiring then
					self:SetFiring(false)
				end
				if self.isAiming then
					self:Unaim()
				end
			end
		end
		
		return true
	end

	function BaseWeapon:Aim()
		if self.isAtEase
			or self.isReloading
		then
			return false
		end
		if self.isAiming == true then return true end

		self.isAiming = true
		self.aimedIn = tick()

		self:RunAnimation("aim")
		
		self.aimedSignal:Fire()

	    return true
	end

	function BaseWeapon:Unaim()
	    if self.isAiming == false then return true end
	    
	    self.isAiming = false

		self:RunAnimation("unaim")
		
		self.unaimedSignal:Fire()

	    return true
	end

	function BaseWeapon:ToggleAim(force, state)
	    if not self:IsValid()
			or not self.isEquipped
	        then return false
	    end
	    if (force and self.isAiming == state)
	        then return true
	    end

	    local isAiming = not self.isAiming
		
		if isAiming then
	        self:Aim()
		else
	        self:Unaim()
	    end
	    
	    --self.isAiming = isAiming

	    return true
	end

	function BaseWeapon:ToggleSprint(force, state)
		--self.isSprinting == self.movementAPI.IsSprinting or

	    if (force and state == self.isSprinting) then
	        return true
	    end
	    if not self.isEquipped then
	        return false
	    end

	    local isSprinting = not self.isSprinting

	    self.isSprinting = isSprinting
	    if isSprinting then
	--        self:RunAnimation("sprint")
	    else
	--        self:RunAnimation("unsprint")
		end
		
		self:PlayIdleAnim()

	    return true
	end

	function BaseWeapon:Equip()
	    if self.isEquipped then
	        return true
	    end
	    if not self:IsValid()
	        or self.isEquipBlockedExt
	        then return false
	    end

	    --warn("equipping gun")

	    self.isEquipped = true
	    self.equippedIn = tick()

	    self:RunAnimation("equip")

	    return true
	end

	function BaseWeapon:Unequip()
	    if not self.isEquipped
	        then return true
	    end
	    if not self:IsValid()
	        or self.isUnequipBlockedExt
	        then print("unequip is blocked") return false
		end
		if self.isAiming then
			self:Unaim()
		end
		if self.isReloading then
			self:StopReloading(false)
		end

	    warn("unequipping gun")

	    self.isEquipped = false
	    self.unequippedIn = tick()

	    self:RunAnimation("unequip")

	    return true
	end

	function BaseWeapon:SetEquip(isEquipped)
	    if self.isEquipped == isEquipped then return false end
	    if not self:IsValid()
	        then return false
	    end

	    if isEquipped then
	        self:Equip()
	    else
	        self:Unequip()
	    end

	    return true
	end

	function BaseWeapon:StartPump()
	    if not self.usesPump
	    or self.isPumping
	    or self.hasPumpedBullet

	    then print("failed to start pump animation") return false end
	    --print("started pumping\n", debug.traceback())
	    local playAimFire = self.isAiming == true

	    self.lastPumpTime = tick()
	    self.isPumping = true

	    local obj = self:RunAnimation(playAimFire and "aimFirePump" or "firePump")
	    --[[
	    local conn
	    conn = obj.Stopped:Connect(function()
	        conn:Disconnect()

	        if self.isPumping and tick() - self.lastPumpTime + self.deltaTime >= self.weaponSettings.pumpTime then
	            print("finished pump", tick() - self.lastPumpTime)

	            self.hasPumpedBullet = true
	        else
	            print("pump considered cancelled", tick() - self.lastPumpTime)
	        end

	        self:StopPump()
	    end)
	    --]]

	    return true
	end

	function BaseWeapon:StopPump()
	    if not self.isPumping 
	    then return true end

	    self.isPumping = false

	    return true
	end

	function BaseWeapon:SetPumping(state)
	    if self.isPumping == state
	    then return true end

	    if not self:IsValid()
	    then return false end

	    if state then
	        self:StartPump()
	    else
	        self:StopPump()
	    end

	    return true
	end

	function BaseWeapon:Fire(origin, dir)
	    if not self:IsValid()
	        or self.isReloading
	        or self.ammo <= 0
			or not self.canFire
			or self.isAtEase
			--or self.isLineOfSightBlocked
	        then return false
	    end
	    if self.usesPump and not IsServer and not self.hasPumpedBullet then
	        self:StartPump()
	        return false
	    end

	    local function drawray(ray, parent)
	        local part = Instance.new("Part", parent or game.Workspace.CurrentCamera);
	        part.FormFactor = Enum.FormFactor.Custom;
	        part.Material = Enum.Material.Neon;
	        part.Size = Vector3.new(.2, ray.Direction.Magnitude, .2);
	        part.CFrame = CFrame.new(ray.Origin + ray.Direction/2, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2,0,0);
	        part.Anchored = true;
	        part.CanCollide = false;
	        part.BrickColor = BrickColor.new("Bright red");
	        Debris:AddItem(part, 3)
	        return part;
	    end;

	    --local p = drawray(Ray.new(origin, dir.LookVector), workspace)

	    self.lastShotTime = tick()
	    self.ammo -= 1

	    if self.usesPump then
	        self.hasPumpedBullet = false
	    end

	    if self.isAiming then
	        local obj = self:RunAnimation("aimFire")
	    else
	        local obj = self:RunAnimation("fire")
	    end

	    --FastcastHandler:fire(origin, dir, self.weaponSettings, self.character)

	    if self.ammo <= 0 and not self.isPlayer and self.isFiring then
	        self.reloadNeededSignal:Fire()

	        local fired = false
	        local conn
	        conn = self.reloadedSignal:Connect(function()
	            conn:Disconnect()
	            fired = true
	        end)
	        self:StartReloading()
	        if not fired then
	            self.reloadedSignal:Wait()
	        end
		end
		
		if IsClient then
			if self.muzzleFlashBeam then
				if not self.isHidden then
					local minFlashRotation, maxFlashRotation = -math.pi, math.pi
					local minFlashSize, maxFlashSize = 0.8, 1.2
					local flashRotation = self.randomGenerator:NextNumber(minFlashRotation, maxFlashRotation)
					local flashSize = self.randomGenerator:NextNumber(minFlashSize, maxFlashSize)
					local xpos, ypos, zpos =
						0 + flashSize/2, --(self.muzzleFlash1CFrame.X - self.muzzleFlash0CFrame.X) + 
						0 + flashSize*0.793,
						0
					--self.barrelAttachment.WorldCFrame.X
					
					local barrelCFrame = self.barrelAttachment.WorldCFrame
					
					local cf1 = (barrelCFrame)*CFrame.Angles(0,0,flashRotation)*CFrame.new(xpos,0,0)
					local cf2 = (barrelCFrame)*CFrame.Angles(0,0,flashRotation)*CFrame.new(-xpos,0,0)
					--local baseCFrame = self.receiver.barrel.WorldCFrame * CFrame.Angles(-math.pi/2, math.pi/2, math.pi + flashRotation)
					self.muzzleFlash0.WorldCFrame = cf1
					self.muzzleFlash1.WorldCFrame = cf2

					self.muzzleFlashBeam.Enabled = true
					self.muzzleFlashBeam.Width0 = flashSize
					self.muzzleFlashBeam.Width1 = flashSize
					self.muzzleFlashShown = true
				end
			end
		end
		
		self.firedSignal:Fire()

	    return true
	end

	function BaseWeapon:GetFiringDirection()
	    error("GetFiringDirection is a fake function and should be overwritten")
	end

	function BaseWeapon:GetFiringOrigin()
		return self.barrelAttachment.WorldCFrame.Position
	end

	function BaseWeapon:GetShouldFire()
	    return true
	end

	function BaseWeapon:GetCanFire()
	    return not self.isReloading and not self.isPumping and self.ammo > 0
	end

	function BaseWeapon:GetSpreadDirection(isFiring)

	end

	function BaseWeapon:SetFiring(isFiring)
	    if self.isFiring == isFiring
	        then return true
	    end
		if not self:IsValid()
			or self.isAtEase
			--or self.isLineOfSightBlocked
	        then return false
	    end


		if isFiring then
			if tick() - self.lastShotTime < 60/self.weaponSettings.rpm
				or self.ammo <= 0
				or self.isReloading
			then --[[print("BaseWeapon: Tried firing but failed ", tick() - self.lastShotTime < 60/self.weaponSettings.rpm)--]] return false
			end

			local firingId = tick()
			self.firingId = firingId

			--local wasSprintingBeforeFiring = self.movementAPI and self.movementAPI:GetIsSprinting()

			self.isFiring = true

			Thread.SpawnNow(function()
				local result = true
				local shots = 0
				while (self.isFiring
					and self.firingId == firingId
					and result
					and (not self.isPlayer or self.currentFiringMode == "auto" or shots == 0)
					and self:GetShouldFire()
					and self:IsValid()
					and (true))
				do
					if shots == 0 and self.currentFiringMode == "auto" and not self.isHidden then
						self.toggledFiringSignal:Fire(true)
					end
					--local isSprinting = self.movementAPI and self.movementAPI:GetIsSprinting()
					--if isSprinting and wasSprintingBeforeFiring == false then
					--	wasSprintingBeforeFiring = false
					--end
	                --print("repeating firing function")
	                local origin = self:GetFiringOrigin()
	                local dir = self:GetFiringDirection()

	                local allDirections = {}

	                -- spread
	                if self.weaponSettings.usesPellets then
	                    local spreadMult = self.isAiming and self.weaponSettings.aimSpreadMult or 1
	                    
	                    for i = 1, self.weaponSettings.pelletsNumber do
	                        math.randomseed(tick())
	                        local spreadRotation = self.randomGenerator:NextNumber(-math.pi, math.pi)
	                        local spreadOffset = self.randomGenerator:NextNumber(self.weaponSettings.minPelletSpread * spreadMult, self.weaponSettings.maxPelletSpread * spreadMult)
	                        
	                        local spreadTransform = CFrame.fromAxisAngle(Vector3.new(math.cos(spreadRotation), math.sin(spreadRotation), 0), spreadOffset)
	                        local unspreadCFrame = CFrame.new(Vector3.new(), dir)

	                        table.insert(allDirections, (unspreadCFrame * spreadTransform).LookVector)
	                    end
	                else
	                    allDirections[1] = dir
	                end

	                local begin = tick()

	                result = self:Fire(origin, allDirections)

	                if result then -- Because why wait if it's not valid anyway
	                    shots += 1;

	                    local target = begin + self.weaponSettings.minShootingTime --60/self.weaponSettings.rpm
	                    while tick() < target do
	                        if RunService:IsServer() then
	                            RunService.Heartbeat:Wait()
	                        else
	                            RunService.RenderStepped:Wait()
	                        end
	                    end
	                    --wait(60/self.weaponSettings.rpm)-- - (tick() - self.lastShotTime)
	                end
	            end

	            --print(not self.isFiring, not result, (self.isPlayer and self.currentFiringMode ~= "auto"), not self:GetShouldFire(), not self:IsValid())
				self.isFiring = false
				if self.currentFiringMode == "auto" and not self.isHidden then
					self.toggledFiringSignal:Fire(false)
				end
	            print("finished firing function after: ", shots)
	        end)
	    else
	        self.isFiring = false
	    end

	    return true
	end

	function BaseWeapon:StartReloading()
	    if self.isReloading == true
	        then return true
	    end
	    if not self:IsValid()
	        or self.ammo >= self.weaponSettings.magCapacity
			or self.isFiring
			or self.isAtEase
	        then return false
		end
		
		if self.isAiming then
			self:Unaim()
		end
		
		local reloadId = tick()
		local equipId = self.equippedIn

		self.reloadedIn = reloadId
		self.reloadingSince = reloadId
	    self.isReloading = true

	    local isPump = self.usesPump

	    if not isPump then
	        --[[
	        local obj = self:PlayAnimation(
	            "reload", -- name
	            nil, -- index (if possible)
	            false, -- should loop
	            self.weaponSettings.reloadTime -- how long it should play
	        )
	        --]]
			local obj = self:RunAnimation("reload")


			Thread.Delay(self.weaponSettings.reloadTime, function()
				if reloadId == self.reloadedIn and self.isReloading and self.equippedIn == equipId then
					print("finished reloading after ", tick() - self.reloadingSince)
					self:StopReloading(true)
				end
			end)
	    else
	        self.canFire = false

	        local start = tick()

	        local obj = self:PlayAnimation(
	            "reloadUp", -- name
	            nil, -- index (if possible)
	            false, -- should loop
	            self.weaponSettings.reloadUpTime -- how long it should play
	        )

			Thread.SpawnNow(function()
	        --coroutine.wrap(function()
	            --conn:Disconnect()
	            wait(self.actionsDuration["reloadUp"])
	            --conn = obj.Stopped:Connect(function()
				if self.isReloading and tick() - start + self.deltaTime >= self.weaponSettings.reloadUpTime then
					
					local reloadedNo = 0
	                while self.isReloading and self.ammo < self.weaponSettings.magCapacity do
	                    local start = tick()

	                    local obj = self:PlayAnimation(
	                        "reloadBulletInsert", -- name
	                        self.playingAnimationIndex["reload"], -- index (if possible)
	                        false, -- should loop
	                        self.weaponSettings.reloadBulletTime -- how long it should play
	                    )

	                    --obj.Stopped:Wait()
	                    wait(self.actionsDuration["reloadBulletInsert"])

	                    if tick() - start + self.deltaTime < self.weaponSettings.reloadBulletTime then
	                        print("bullet considered not inserted")
	                        break
	                    end

						self.ammo += 1
						reloadedNo += 1
	                    print("reloaded once more ", self.ammo)
	                end

	                local obj = self:PlayAnimation(
	                    "reloadDown", -- name
	                    self.playingAnimationIndex["reload"], -- index (if possible)
	                    false, -- should loop
	                    self.weaponSettings.reloadDownTime -- how long it should play
	                    --3 -- animation package phase
	                )

	                --obj.Stopped:Wait()
	                wait(self.actionsDuration["reloadDown"])

	                self.canFire = true
	                self:StopReloading(reloadedNo > 0)
	            else
	                print("failed to put gun up ", tick() - start, self.deltaTime)
	                self.canFire = true
	                self:StopReloading(false)
	            end
	        end)--()
	    end

	    return true
	end

	function BaseWeapon:StopReloading(finishedCorrectly)
	    if self.isReloading == false
	        then return true
	    end
	    if not self:IsValid()
	        then return false
	    end

		--print("called StopReloading BaseWeapon with", finishedCorrectly)

		self.isReloading = false
	    self.reloadingSince = 0
		
		if finishedCorrectly and not self.usesPump then
			self.ammo = self.weaponSettings.magCapacity
		end

		self.reloadedSignal:Fire(finishedCorrectly)

	    return true
	end

	function BaseWeapon:SetReloading(isReloading)
	    if self.isReloading == isReloading
	        then return true
	    end
	    if not self:IsValid()
	        then return false
	    end

	    if isReloading then
	        self:StartReloading()
	    else
	        self:StopReloading(false)
	    end

	    return true
	end

	function BaseWeapon:Update(dt)
	    if not self:IsValid() then return false end
		self.deltaTime = dt

		if self.muzzleFlashShown and (tick() - self.lastShotTime) >= 0.06 then
			self.muzzleFlashShown = false
			self.muzzleFlashBeam.Enabled = false
		end
		--[[
	    if self.isEquipped  then
	        if not self.usesPump and self.isReloading
	            and tick() - self.reloadingSince >= self.weaponSettings.reloadTime then

	            print("finished reloading after ", tick() - self.reloadingSince)
	            self:StopReloading(true)
	        end
	    end
	    --]]
		
		self.frameNumber += 1

	    return true
	end

	return BaseWeapon