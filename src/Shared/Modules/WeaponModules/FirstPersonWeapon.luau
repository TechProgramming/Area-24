local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")

local FXModules = ReplicatedStorage:WaitForChild("EffectsModules")
local DisplayDamage = require(FXModules:WaitForChild("DisplayDamage"))

local BaseWeapon = require(script.Parent:WaitForChild("BaseWeapon"))

local Knit = require(SharedModules:WaitForChild("Knit"))

local Signal = require(SharedModules.Knit.Util.Signal)
local Thread = require(SharedModules.Knit.Util.Thread)

local wait = Thread.Wait

local PartCache = require(SharedModules:WaitForChild("PartCache"))
local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))

local Camera = workspace.CurrentCamera

local spring = require(SharedModules:WaitForChild("spring"))

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local GuiInset = GuiService:GetGuiInset()


local FirstPersonWeapon = setmetatable({}, BaseWeapon)
FirstPersonWeapon.__index = FirstPersonWeapon


local function getBobbing(addition, speed, modifier)
	return math.sin(tick()*addition*speed) * (modifier or 1)
end

-- Used to check the correctness of metaSettings
local function testSettingsTable(t)
    local requiredValues = {
        "aimingSensMult";
        "aimingSwayMult";
        "viewmodel";
    }


    local allFailed = {}

    local function checki(i)
        if t[i] == nil then
            --error("failed to find " .. i .. " in metaSettings table")
            table.insert(allFailed, i)
        end
    end

    for _,v in ipairs(requiredValues) do
        checki(v)
    end

    if #allFailed > 0 then
        error("failed to find " .. #allFailed .. " elements in metaSettings " .. allFailed)
        return false
    else
        return true
    end
end

local function createValue(className, defaultValue, parent)
    local value = Instance.new(className)
    value.Value = defaultValue
    if parent then
        value.Parent = parent
    end
    return value
end

function FirstPersonWeapon.new(weaponSettings, metaSettings, character, weapon)
    local base = BaseWeapon.new(weaponSettings, metaSettings, character, weapon)
    local self = setmetatable(base, FirstPersonWeapon)

    if self.weaponSettings.usesR15InFirstPerson then
        self.viewmodel = game.ReplicatedStorage.Assets.FPS.R15Viewmodel:Clone()--game.StarterPlayer.StarterCharacter:Clone()
        --[[
        self.viewmodel.HumanoidRootPart.Anchored = true

        for _, v in pairs(self.viewmodel:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Anchored = true
                --if v.Name ~= ""
                if not string.find(v.Name, "Hand") and not string.find(v.Name, "Arm") then
                    v.Transparency = 1
                end
            end
        end
        --]]
    else
		self.viewmodel = metaSettings.viewmodel
		self.viewmodel.Name = self.weaponSettings.name
	end
	
	self.clientAPI = metaSettings.clientAPI
	self.inputAPI = metaSettings.inputAPI

    self.shouldShow = false
    self.isHidden = true
    self.shouldUpdate = false

    -- Lerping Values
    self.lerpValues = {}
    self.lerpValues.aim = createValue("NumberValue", 0)
    self.lerpValues.land = createValue("NumberValue", 0)
	self.lerpValues.sprint = createValue("NumberValue", 0)
	self.lerpValues.ease = createValue("NumberValue", 1)

    -- Tween Objects
    self.tweenObjects = {}
    self.tweenObjects.aim = nil
    self.tweenObjects.land = nil
	self.tweenObjects.sprint = nil
	self.tweenObjects.ease = nil

    -- Springs
    self.springs = {}
	self.springs.walkCycle = spring.create()
	self.springs.sway = spring.create()
    self.springs.fire = spring.create()

    
    --self.serverAPI = metaSettings.serverAPI

    self.player = Player
    self.camera = workspace.CurrentCamera

    self.weaponMainPart = self.weaponSettings.usesR15InFirstPerson and self.character.HumanoidRootPart or self.viewmodel.MainPart
    self.weaponCameraPart = not self.weaponSettings.usesR15InFirstPerson and self.viewmodel.Camera

    for _, v in pairs(self.weapon:GetChildren()) do
        if string.find(v.Name, "Connections") then
            local newparent = self.viewmodel:FindFirstChild(string.sub(v.Name, 1, #v.Name - #("Connections")))
            if not newparent then
                --warn(newparent, " WASNT FOUND IN VIEWMODEL")
            else
                for _, c in pairs(v:GetChildren()) do
                    c.Parent = newparent
                    c.Part0 = newparent
                    --print("adding ", newparent, c:GetFullName(), c.Parent:GetFullName(), c.Part0, c.Part1)
                end
            end
        end
    end
    --[[
    for _, v in pairs(self.weapon:GetDescendants()) do
        if v:IsA("BasePart") and self.weapon.PrimaryPart ~= v then

            local ppoffset = (v.CFrame:Inverse() * (self.weapon.PrimaryPart.CFrame)):Inverse()
            
            local motor = Instance.new("Motor6D", self.weaponMainPart)
            motor.C0 = weaponSettings.offsets.weaponFrame.MainPart.C0 * ppoffset
            motor.Part0 = self.weaponMainPart
            motor.Part1 = v
            motor.Name = v.Name

            --print("OFFSET FOR ", v.Name, motor.C0)

        end
    end
    --]]
    if self.weaponSettings.usesR15InFirstPerson then
        local ppmotor = Instance.new("Weld", self.viewmodel.RightHand)
        ppmotor.C0 = self.viewmodel.RightHand.CFrame:Inverse() * self.viewmodel.RightHand.RightGripAttachment.WorldCFrame
        ppmotor.C1 = CFrame.new()
        ppmotor.Part0 = self.viewmodel.RightHand
        ppmotor.Part1 = self.weapon.PrimaryPart
    else
        local ppmotor = Instance.new("Motor6D", self.weaponMainPart)
        ppmotor.C0 = weaponSettings.offsets.weaponFrame.MainPart.C0
        ppmotor.C1 = weaponSettings.offsets.weaponFrame.MainPart.C1
        ppmotor.Part0 = self.weaponMainPart
        ppmotor.Part1 = self.weapon.PrimaryPart

        self.viewmodel.rootPart.Camera.C0 = self.weaponSettings.offsets.viewmodel.Camera.C0
        self.viewmodel.rootPart.Camera.C1 = self.weaponSettings.offsets.viewmodel.Camera.C1

        self.viewmodel.rootPart.MainPart.C0 = self.weaponSettings.offsets.viewmodel.MainPart.C0
        self.viewmodel.rootPart.MainPart.C1 = self.weaponSettings.offsets.viewmodel.MainPart.C1

        self.viewmodel.rootPart.RightArm.C0 = self.weaponSettings.offsets.viewmodel.RightArm.C0
        self.viewmodel.rootPart.RightArm.C1 = self.weaponSettings.offsets.viewmodel.RightArm.C1

        self.viewmodel.rootPart.LeftArm.C0 = self.weaponSettings.offsets.viewmodel.LeftArm.C0
        self.viewmodel.rootPart.LeftArm.C1 = self.weaponSettings.offsets.viewmodel.LeftArm.C1
    end
    -- ViewModel setup
	self.viewmodelBaseParts = {}
	self.viewmodelDecals = {}

    for _, v in pairs(self.weapon:GetChildren()) do
        v.Parent = self.viewmodel
	end
	
	local function addChild(v)
		if v:IsA("BasePart") and v.Name ~= "rootPart" then
			self.viewmodelBaseParts[v] = {
				Transparency = v.Transparency;
			}
			v.CanCollide = false
			v.Anchored = false
			--PhysicsService:SetPartCollisionGroup(v, "Weapons")
			if self.isHidden then
				v.Transparency = 1
			end
		elseif v:IsA("Decal") then
			self.viewmodelDecals[v] = {
				Transparency = v.Transparency;
			}
			if self.isHidden then
				v.Transparency = 1
			end
		end
	end

	for _, v in pairs(self.viewmodel:GetDescendants()) do
		addChild(v)
	end
	
	self.viewmodel.DescendantAdded:Connect(function(v)
		addChild(v)
	end)

    self.viewmodel.Parent = self.camera

    self.animationController = self.viewmodel:FindFirstChildWhichIsA("AnimationController")
        or self.viewmodel:FindFirstChildWhichIsA("Humanoid")

    self.viewmodelAnimationInstances = self.weaponSettings.animations.viewmodel
    self.loadedAnimations = {}
    --[[
    local function addAnim(source, target, index)
        target[index] = {}
        for i, v in pairs(source[index]) do
            if(typeof(v) == "table") then
                addAnim(source[index], target[index], i)
            else
                target[index][i] = self.animationController:LoadAnimation(v)
            end
        end
    end

    for i,v in pairs(self.viewmodelAnimationInstances) do
        if typeof(v) == "table" then
            addAnim(self.viewmodelAnimationInstances, self.loadedAnimations, i)
        else
            self.loadedAnimations[i] = self.animationController:LoadAnimation(v)
        end
    end
--]]
    self.playingAnimationIndex = {}

    local loadedAnimations, animationsSpeeds, animationsDuration = weaponSettings.loadAllAnimations(self.animationController, "viewmodel")
    self.loadedAnimations = loadedAnimations
	self.animationsSpeeds = animationsSpeeds
	self.animationsDuration = animationsDuration
	--[[
	if self.viewmodel:FindFirstChild("Scope") then
		local firstPart = self.viewmodel.Scope["1"]
		local secondPart = self.viewmodel.Scope["2"]
		
		local aimDirection = (secondPart.Position - firstPart.Position).Magnitude
		
		local idleAnimationKeyframes = KeyframeSequenceProvider:GetKeyframeSequenceAsync(loadedAnimations.gunUp["1"].AnimationId)
		local firstFrame
		for i, v in ipairs(idleAnimationKeyframes:GetKeyframes()) do
			if v.Time == 0 then
				firstFrame = v
				break
			end
		end
		
		local receiverOffset = firstFrame.rootPart.receiver.CFrame
		
		local target = CFrame.fromMatrix(Vector3.new(), ,Vector3.new(0,1,0), )
	end
	--]]
	self:Hide()
	
	self.barrelPositionAfterGunUp = nil
	
	self.viewmodel:SetPrimaryPartCFrame(self.camera.CFrame)

    return self
end

function FirstPersonWeapon:Destroy()
	if self.isDestroyed then return true end
	
    BaseWeapon.Destroy(self)

	Debris:AddItem(self.viewmodel, 0)
	
    return true
end

function FirstPersonWeapon:StopAllAnimations()
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

function FirstPersonWeapon:UpdateAnimations()
    if not self:IsValid()
        then return false
    end

    local function cond(b, a)
        if b then
            a:Play()
        else
            a:Stop()
        end
    end

    print("updating animations")
    --self:StopAllAnimations()

    cond(self.isReloading, self.loadedAnimations.reload)
    cond(self.isAiming, self.loadedAnimations.aim)
    cond(self.isSprinting, self.loadedAnimations.sprint)
    cond(self.isEquipped, self.loadedAnimations.gunUp)
    
    return true
end

function FirstPersonWeapon:Hide()
    --if self.isHidden then return true end
    if not self:IsValid() then return false end
	
	--warn("Hiding", self.weapon.Name)
    self.isHidden = true

    for part, settings in pairs(self.viewmodelBaseParts) do
        part.Transparency = 1
	end
	for decal, settings in pairs(self.viewmodelDecals) do
		decal.Transparency = 1
	end

    return true
end

function FirstPersonWeapon:Unhide()
    --if not self.isHidden then return true end
    if not self:IsValid() then return false end

	--warn("Unhiding", self.weapon.Name)
    self.isHidden = false

    for part, settings in pairs(self.viewmodelBaseParts) do
        part.Transparency = settings.Transparency
	end
	for decal, settings in pairs(self.viewmodelDecals) do
		decal.Transparency = settings.Transparency
	end

    return true
end

function FirstPersonWeapon:PlayIdleAnim()
	self:PlayAnimation("gunUp", nil, true)
	
	return true
end

function FirstPersonWeapon:PlayEquipAnim(name, index)
    Thread.SpawnNow(function()
        --[[
        local animationIndex = index or (#self.loadedAnimations["equip"] > 0 and math.random(1,#self.loadedAnimations["equip"])) -- self.playingAnimationIndex["equip"]
        self.playingAnimationIndex["equip"] = animationIndex
        local equipAnimId = animationIndex and self.weaponSettings.animations.viewmodel["equip"][animationIndex].AnimationId
        if equipAnimId then
            if not self.animationKeyframes["equip"] then self.animationKeyframes["equip"] = {} end
            local s = tick()
            local keyframes = self.animationKeyframes["equip"][animationIndex] or KeyframeSequenceProvider:GetKeyframeSequenceAsync(equipAnimId)
            self.animationKeyframes["equip"][animationIndex] = keyframes

            print("KEYFRAMES TOOK TO LOAD: ", tick() - s)
            local firstKeyframe = keyframes:GetKeyframes()[1]

            for _, pose in pairs(firstKeyframe:GetChildren()[1]:GetDescendants()) do
                local part = nil
                for _, v in pairs(self.viewmodel:GetDescendants()) do
                    if v.Name == pose.Name and v:IsA("BasePart") then
                        part = v
                        break
                    end
                end 

                local motor = nil
                for _, v in pairs(self.viewmodel:GetDescendants()) do
                    if v:IsA("Motor6D") and v.Part1 and v.Part1.Name == part.Name then
                        motor = v
                        break
                    end
                end
                if not motor then
                    print("FAILED TO FIND A MOTOR6D FOR ", part:GetFullName())
                else
                    motor.Transform = pose.CFrame
                end
            end
        end--]]
        --self.viewmodel:SetPrimaryPartCFrame()
        self.viewmodel.Camera.CFrame = self.camera.CFrame:ToWorldSpace(self:GetViewmodelOffset())

        BaseWeapon.PlayEquipAnim(self, name, animationIndex)

        RunService.Stepped:Wait()
        if self.shouldShow then
            self:Unhide()
        end
    end)

    return true
end

function FirstPersonWeapon:Equip(shouldShow)
    self.shouldShow = shouldShow
    self.shouldUpdate = true

    local valid = BaseWeapon.Equip(self)
    if not valid then return false end

    return true
end

function FirstPersonWeapon:Unequip()
    local valid = BaseWeapon.Unequip(self)
    if not valid then warn("unequipping failed") return false end
    --print(debug.traceback())

    local conn
    conn = self.unequippedSignal:Connect(function()
        conn:Disconnect()

        self:Hide()
		print("FINISHED UNEQUIPPING")
        --for part, settings in pairs(self.viewmodelBaseParts) do
        --    part.Transparency = 1
        --end
    end)
    --[[
    local unequipAnim = self:RunAnimation("unequip")--self.loadedAnimations.unequip
    local conn
    conn = unequipAnim.Stopped:Connect(function()
        conn:Disconnect()
        if self.isEquipped or (self.weaponSettings.unequipTime - (tick() - self.unequippedIn)) >= 0.09 then print("unequipped cancelled", tick() - self.unequippedIn, self.weaponSettings.unequipTime) return end

        for part, settings in pairs(self.viewmodelBaseParts) do
            part.Transparency = 1
        end

        self.unequippedSignal:Fire()

        self:StopAllAnimations()
        --unequipAnim:Stop()
    end)
    --unequipAnim:Play(0.1, 1, self.animationsSpeeds.unequip)
    --self:RunAnimation("unequip")
    
    if self.tweenObjects.equip then
        self.tweenObjects.equip:Cancel()
    end

    local tweeningInformation = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tweenObject = TweenService:Create(self.lerpValues.equip, tweeningInformation, { Value = 1 })
    self.tweenObjects.equip = tweenObject

    tweenObject.Completed:Connect(function(status)
        if status == Enum.PlaybackState.Cancelled then return end

        --warn("finished unequipping animation, now setting transparency to 0 for ", self.viewmodelBaseParts)
        for part, settings in pairs(self.viewmodelBaseParts) do
            part.Transparency = 1
        end
        self.shouldUpdate = false

        self:StopAllAnimations()
        --warn("SETTING shouldUpdate TO FALSE BECAUSE STATUS IS ", status, Enum.PlaybackState.Canceled.Value, Enum.TweenStatus.Completed.Value)
    end)

    --warn("playing unequipping animation")
    tweenObject:Play()
    --]]
    --[[ MOVED
	coroutine.wrap(function()
		self.serverAPI:Unequip()
	end)()
    --]]
    return true
end

function FirstPersonWeapon:SetIsLineOfSightBlocked(state)
	if self.isLineOfSightBlocked == state then return true end
	self.isLineOfSightBlocked = state
	
	if self.tweenObjects.ease then
		self.tweenObjects.ease:Cancel()
	end

	local tweenObject

	if state then
		local tweeningInformation = TweenInfo.new(0.6, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.ease, tweeningInformation, { Value = 1 })
	elseif not self.isAtEase then
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.ease, tweeningInformation, { Value = 0 })
	end
	if tweenObject then
		self.tweenObjects.ease = tweenObject
		tweenObject:Play()
	end
	
	return true
end

function FirstPersonWeapon:ToggleAtEase(force, state)
	if not BaseWeapon.ToggleAtEase(self, force, state) then return false end
	local isAtEase = self.isAtEase

	if self.tweenObjects.ease then
		self.tweenObjects.ease:Cancel()
	end

	local tweenObject

	if isAtEase then
		local tweeningInformation = TweenInfo.new(0.6, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.ease, tweeningInformation, { Value = 1 })
	else
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.ease, tweeningInformation, { Value = 0 })
	end
	self.tweenObjects.ease = tweenObject
	tweenObject:Play()
	
	return true
end

function FirstPersonWeapon:Aim(...)
	return BaseWeapon.Aim(self, ...)
end

function FirstPersonWeapon:Unaim(...)
	return BaseWeapon.Unaim(self, ...)
end

function FirstPersonWeapon:ToggleAim(force, state)
    if not BaseWeapon.ToggleAim(self, force, state) then return false end

    local isAiming = self.isAiming
	
    if self.tweenObjects.aim then
        self.tweenObjects.aim:Cancel()
    end

    local tweenObject

	if isAiming then
		local tweeningInformation = TweenInfo.new(self.weaponSettings.aimTime, Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.aim, tweeningInformation, { Value = 1 })
	else
		local tweeningInformation = TweenInfo.new(self.weaponSettings.aimTime, Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
		tweenObject = TweenService:Create(self.lerpValues.aim, tweeningInformation, { Value = 0 })
    end
    self.tweenObjects.aim = tweenObject
    tweenObject:Play()

    return true
end

function FirstPersonWeapon:ToggleSprint(force, state)
    local valid = BaseWeapon.ToggleSprint(self, force, state)
    if not valid then return false end

    local isSprinting = self.isSprinting

    if self.tweenObjects.sprint then
        self.tweenObjects.sprint:Cancel()
    end

    local tweenObject

    if isSprinting then
        local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        local properties = { Value = 1 }
        tweenObject = TweenService:Create(self.lerpValues.sprint,tweeningInformation,properties)
    else
        local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        local properties = { Value = 0 }
        tweenObject = TweenService:Create(self.lerpValues.sprint,tweeningInformation,properties)
    end

    self.tweenObjects.sprint = tweenObject
    tweenObject:Play()

    return true
end

function FirstPersonWeapon:SetJump(state)
    if not self:IsValid() then return false end

    if self.tweenObjects.land then
        self.tweenObjects.land:Cancel()
    end

    local tweenObject

	if state then
		-- customize speed at will.
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		local properties = { Value = 1 }
		tweenObject = TweenService:Create(self.lerpValues.land,tweeningInformation,properties)
	else
		local tweeningInformation = TweenInfo.new(0.5, Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		local properties = { Value = 0 }
		tweenObject = TweenService:Create(self.lerpValues.land,tweeningInformation,properties)
	end

    self.tweenObjects.land = tweenObject
    tweenObject:Play()

    return true
end

function FirstPersonWeapon:GetFiringDirection()
    --return CFrame.lookAt(self:GetFiringOrigin(), Player:GetMouse().Hit.Position, Vector3.new(0,1,0)) --self.camera.CFrame
    --return (Player:GetMouse().Hit.Position - self:GetFiringOrigin())

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

    --drawray(Camera:ScreenPointToRay((Camera.ViewportSize.X - GuiInset.X)/2, (Camera.ViewportSize.Y - GuiInset.Y)/2, 0), workspace)

    return Camera:ScreenPointToRay((Camera.ViewportSize.X - GuiInset.X)/2, (Camera.ViewportSize.Y - GuiInset.Y)/2, 0).Direction
end

function FirstPersonWeapon:GetFiringOrigin()
	return self.barrelAttachment.WorldCFrame.Position
end

function FirstPersonWeapon:StartReloading()
    if not BaseWeapon.StartReloading(self) then return false end

    local isPump = self.usesPump
    --[[
    if not isPump then
        --self.loadedAnimations.reload:Play(0.1, 1, self.animationsSpeeds.reload)
        local obj = self:PlayAnimation(
            "reload", -- name
            nil, -- index (if possible)
            false, -- should loop
            self.weaponSettings.reloadTime, -- how long it should play
            1 -- animation package phase
        )
    else
        self.canFire = false

        local start = tick()

        local obj = self:PlayAnimation(
            "reloadUp", -- name
            nil, -- index (if possible)
            false, -- should loop
            self.weaponSettings.reloadUpTime -- how long it should play
        )

        local conn;
        conn = obj.Stopped:Connect(function()
            conn:Disconnect()
            if self.isReloading and tick() - start + self.deltaTime >= self.weaponSettings.reloadUpTime then

                while self.isReloading and self.ammo < self.weaponSettings.magCapacity do
                    local start = tick()

                    local obj = self:PlayAnimation(
                        "reloadBulletInsert", -- name
                        self.playingAnimationIndex["reload"], -- index (if possible)
                        false, -- should loop
                        self.weaponSettings.reloadBulletTime -- how long it should play
                    )

                    obj.Stopped:Wait()

                    if tick() - start + self.deltaTime < self.weaponSettings.reloadBulletTime then
                        print("bullet considered not inserted")
                        break
                    end

                    self.ammo+=1
                    print("reloaded once more ", self.ammo)
                end

                local obj = self:PlayAnimation(
                    "reloadDown", -- name
                    self.playingAnimationIndex["reload"], -- index (if possible)
                    false, -- should loop
                    self.weaponSettings.reloadDownTime -- how long it should play
                    --3 -- animation package phase
                )

                obj.Stopped:Wait()
                --wait(self.weaponSettings.reloadDownTime)

                self.canFire = true
                self:StopReloading()
            else
                print("failed to put gun up ", tick() - start, self.deltaTime)
                self.canFire = true
                self:StopReloading()
            end
        end)
    end
    --]]
    return true
end

function FirstPersonWeapon:StopReloading(...)
    if not BaseWeapon.StopReloading(self, ...) then return false end
    --[[ MOVED
    self.serverAPI.ReloadEvent:Fire(false)
    --]]
    local function stop(t)
        for i,v in pairs(t) do
            if(typeof(v) == "table") then
                stop(v)
            else
                v:Stop()
            end
        end
    end

    if self.usesPump then

    else
    --    stop(self.loadedAnimations.reload)
    end

    return true
end

function FirstPersonWeapon:StartPump()
    if not BaseWeapon.StartPump(self) then warn("start pump failed") return false end

    if not self.usesPump
    or self.isPumping
    or self.hasPumpedBullet

    then print("failed to start pump animation") return false end
    --print("started pumping\n", debug.traceback())
    --[[
    local obj = self:PlayAnimation(
        playAimFire and "aimFire" or "fire", -- name
        playAimFire and self.playingAnimationIndex["aimFire"] or self.playingAnimationIndex["fire"], -- index (if possible)
        false, -- should loop
        self.weaponSettings.pumpTime, -- how long it should play
        2 -- animation package phase
    )
    
    local obj = self:PlayAnimation(
        "firePump", -- name
        playAimFire and self.playingAnimationIndex["aimFire"] or self.playingAnimationIndex["fire"], -- index (if possible)
        false, -- should loop
        self.weaponSettings.pumpTime, -- how long it should play
        2 -- animation package phase
    )
    
    local obj = self:RunAnimation(playAimFire and "aimFirePump" or "firePump")


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

function FirstPersonWeapon:StopPump()
    if not BaseWeapon.StopPump(self) then warn("stop pump failed") return false end

    if not self.isPumping 
    then return true end

    local function stop(t)
        for i,v in pairs(t) do
            if(typeof(v) == "table") then
                stop(v)
            else
                v:Stop()
            end
        end
    end

    self.isPumping = false
    --stop(self.loadedAnimations.aimFire)
    --stop(self.loadedAnimations.fire)
    --self.loadedAnimations.aimFire[self.playingAnimationIndex.aimFire]:Stop()
    --self.loadedAnimations.fire[self.playingAnimationIndex.fire]:Stop()

    return true
end

function FirstPersonWeapon:Fire(origin, allDirections)
    if (self.usesPump and not self.hasPumpedBullet) then
        self:StartPump()
        return false
    end
    if not BaseWeapon.Fire(self, origin, allDirections) then return false end

    self.hasPumpedBullet = false

    if self.isAiming then
    else
    end

    self.springs.fire:shove(self.weaponSettings.recoilStart * self.deltaTime)
    coroutine.wrap(function()
        wait(self.weaponSettings.recoilWaitTime)
        self.springs.fire:shove(self.weaponSettings.recoilFinish * self.deltaTime)
    end)()

    return true
end

function FirstPersonWeapon:SetFiring(isFiring)
    if not self:IsValid() then return false end
    if isFiring and self.ammo <= 0 then
        coroutine.wrap(function()
            self:SetReloading(true)
        end)()
        return false
    end

    local valid = BaseWeapon.SetFiring(self, isFiring)
    if not valid then warn("SHOOTING FAILED") return false end

    return true
end

function FirstPersonWeapon:GetViewmodelOffset()
    local offsetsGroup = self.weaponSettings.offsets.animations.viewmodel

    local offsetGunUpAll-- do
        local offsetGunUpGroup = offsetsGroup.gunUp
        local offsetGunUpAngle = offsetGunUpGroup.angle.Value
        local offsetGunUpPos = offsetGunUpGroup.position.Value
    --end

    local offsetLandAll-- do
        local offsetLandGroup = offsetsGroup.land
        local offsetLandAngle = offsetLandGroup.angle.Value
        local offsetLandPos = offsetLandGroup.position.Value

    --end

    local offsetSprintAll-- do
        local offsetSprintGroup = offsetsGroup.sprint
        local offsetSprintAngle = offsetSprintGroup.angle.Value
        local offsetSprintPos = offsetSprintGroup.position.Value
    --end

    local offsetAimAll-- do
        local offsetAimGroup = offsetsGroup.aim
        local offsetAimAngle = offsetAimGroup.angle.Value
        local offsetAimPos = offsetAimGroup.position.Value
	--end

	local offsetEaseAll-- do
	local offsetEaseGroup = offsetsGroup.ease
	local offsetEaseAngle = offsetEaseGroup.angle.Value
	local offsetEasePos = offsetEaseGroup.position.Value
	--end

    offsetGunUpAll = CFrame.new(offsetGunUpPos) * CFrame.Angles(offsetGunUpAngle.X, offsetGunUpAngle.Y, offsetGunUpAngle.Z)
    offsetAimAll = CFrame.new(offsetAimPos) * CFrame.Angles(offsetAimAngle.X, offsetAimAngle.Y, offsetAimAngle.Z)
    offsetLandAll = CFrame.new()
	offsetSprintAll = CFrame.new()
	offsetEaseAll = CFrame.new(offsetEasePos) * CFrame.Angles(offsetEaseAngle.X, offsetEaseAngle.Y, offsetEaseAngle.Z)

    if self.isAiming then
        local blendedLandPos = offsetAimPos
        offsetLandAll = CFrame.new(blendedLandPos) * CFrame.Angles(offsetLandAngle.X, offsetAimAngle.Y, offsetAimAngle.Z)
    else
        if self.isSprinting then
            local blendedLandPos = offsetGunUpPos + Vector3.new(0, -0.5, 0)
            offsetLandAll = CFrame.new(blendedLandPos) * CFrame.Angles(offsetSprintAngle.X, offsetSprintAngle.Y, offsetGunUpAngle.Z)
        else
            local blendedLandPos = offsetGunUpPos
            offsetLandAll = CFrame.new(blendedLandPos) * CFrame.Angles(offsetLandAngle.X, offsetGunUpAngle.Y, offsetGunUpAngle.Z)
        end
    end
	offsetSprintAll = CFrame.new(offsetSprintPos) * CFrame.Angles(offsetSprintAngle.X, offsetSprintAngle.Y, offsetSprintAngle.Z)

    local gunUpOffset = offsetGunUpAll
	local aimOffset = gunUpOffset:Lerp(offsetAimAll, self.lerpValues.aim.Value)
    local landOffset = aimOffset:Lerp(offsetLandAll, self.lerpValues.land.Value)
    local sprintOffset = landOffset:Lerp(offsetSprintAll, self.lerpValues.sprint.Value)
	local landOffsetB = sprintOffset:Lerp(offsetLandAll, self.lerpValues.land.Value)
	local easeOffset = landOffsetB:Lerp(offsetEaseAll, self.lerpValues.ease.Value)
	local final = easeOffset

	return final
end

function FirstPersonWeapon:Update(dt)
    local valid = BaseWeapon.Update(self, dt)
	if not valid then return false end
	if self.isDestroyed then return false end

    local metaSettings = self.metaSettings
    local movementAPI = self.movementAPI
    local character = self.character
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    --[[
    if self.isEquipped then
        --print("shouldUpdate", self.shouldUpdate)
        
        local p = Instance.new("Part")
        p.Size = Vector3.new(2,2,2)
        p.Color = Color3.fromRGB(255,255,255)
        p.Anchored = true
        p.CanCollide = false
        p.Position = self.viewmodel.receiver.Position
        p.Transparency = 0.8
        p.Parent = workspace
        Debris:AddItem(p, 1)
        
    end
    --]]
    if humanoid and hrp and self.shouldUpdate then
        local velocity = self.inputAPI:GetMoveVector() * humanoid.WalkSpeed --hrp.Velocity

        local baseCFrame = self.camera.CFrame--hrp.CFrame * CFrame.new(0, 3.5, 0)
        if self.weaponSettings.usesR15InFirstPerson then
            baseCFrame *= CFrame.new(0,-1.5,0)
        end
        --[[
        local p = Instance.new("Part")
        p.CFrame = baseCFrame
        p.Color = Color3.new(1,0,0)
        p.Transparency = 0.5
        p.Anchored = true
        p.CanCollide = false
        Debris:AddItem(p, 1)
        p.Parent = workspace
        --]]

        local finalOffset = self:GetViewmodelOffset()

        -- Do springs
        do
            local mouseDelta = game:GetService("UserInputService"):GetMouseDelta()
            if self.isAiming then mouseDelta = mouseDelta * metaSettings.aimingSensMult end

            local weaponMovement = self.weaponSettings.weaponMovement

            self.springs.sway:shove(
                Vector3.new(
                    mouseDelta.X / weaponMovement.turnFriction,
                    mouseDelta.Y / weaponMovement.turnFriction,
                    0
                )
            )

            local speed = weaponMovement.speed
            local modifier = weaponMovement.modifier
            local sway = weaponMovement.sway


            if self.isAiming then modifier = modifier * metaSettings.aimingSwayMult end

            local movementSway = Vector3.new(
                getBobbing(sway.X,speed),
                getBobbing(sway.Y,speed),
                getBobbing(sway.Z,speed)
            ) * modifier

            local sway = self.springs.sway:update(dt)
            local recoil = self.springs.fire:update(dt)

            self.camera.CFrame = self.camera.CFrame * CFrame.Angles(recoil.x,recoil.y,recoil.z)

            --self.viewmodel.rootPart.CFrame = self.camera.CFrame:ToWorldSpace(finalOffset)

            if movementAPI.IsOnGround then
                self.springs.walkCycle:shove((movementSway / 25) * dt * 60 * velocity.Magnitude)
            end

            local walkCycle = self.springs.walkCycle:update(dt)

            walkCycle = Vector3.new(
                math.sin(walkCycle.X),
                math.abs(math.sin(walkCycle.Y * 2)),
                0
            )

            local newRootPartCFrame =
                self.camera.CFrame:ToWorldSpace(finalOffset):ToWorldSpace(
                    CFrame.new(walkCycle.X / 2,
                    walkCycle.Y / 2,
                    0
                ))
                * CFrame.new(walkCycle.X,walkCycle.Y,walkCycle.Y)
                * CFrame.Angles(0, -sway.x, sway.y)
                
            --[[
            local p = Instance.new("Part")
            p.CFrame = newRootPartCFrame
            p.Color = Color3.new(0,1,0)
            p.Transparency = 0.5
            p.Anchored = true
            p.CanCollide = false
            Debris:AddItem(p, 1)
            p.Parent = workspace
            --]]

			if not self.isAtEase and self.frameNumber%2==1 then
				local oldEaseValue = self.lerpValues.ease.Value
				self.lerpValues.ease.Value = 0
				
				local newOffset = self:GetViewmodelOffset()
				local offsetWithEase0 = self.camera.CFrame:ToWorldSpace(newOffset):ToWorldSpace(
					CFrame.new(walkCycle.X / 2,
						walkCycle.Y / 2,
						0
					))
					* CFrame.new(walkCycle.X,walkCycle.Y,walkCycle.Y)
					* CFrame.Angles(0, -sway.x, sway.y)
				
				self.viewmodel.Camera.CFrame = offsetWithEase0
				
				self.barrelPositionAfterGunUp = self.barrelAttachment.WorldPosition
				self.lerpValues.ease.Value = oldEaseValue
			end
			--[[
			if self.lerpValues.ease.Value == 0 and self.character:FindFirstChild("HumanoidRootPart") then
				local newOffset = self.barrelAttachment.WorldPosition - self.character.HumanoidRootPart.Position
				if newOffset ~= self.barrelPositionAfterGunUpFromHRP then
					self.barrelPositionAfterGunUpFromHRP = newOffset
				end
			end
			--]]
			self.viewmodel.Camera.CFrame = newRootPartCFrame--*CFrame.new(0,0,-3)*CFrame.Angles(0, math.pi, 0)
        end
    end


    return true
end


return FirstPersonWeapon