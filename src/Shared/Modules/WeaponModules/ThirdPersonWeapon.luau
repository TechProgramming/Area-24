local RunService = game:GetService("RunService")

local BaseWeapon = require(script.Parent:WaitForChild("BaseWeapon"))

local ThirdPersonWeapon = setmetatable({}, BaseWeapon)
ThirdPersonWeapon.__index = ThirdPersonWeapon


--[[
function ThirdPersonWeapon:function()
    if not BaseWeapon.function(self) then return false end



    return true
end
--]]

function ThirdPersonWeapon.new(weaponSettings, metaSettings, character, weapon)
    local base = BaseWeapon.new(weaponSettings, metaSettings, character, weapon)
	local self = setmetatable(base, ThirdPersonWeapon)
	
	self.clientAPI = metaSettings.clientAPI
	
    self.isHidden = true
    --weapon.PrimaryPart.weaponHold.C0 = CFrame.new(-0.682041168, -0.395236969, -1.91061211, 1, 0, 4.37113883e-08, 0, 1, 0, -4.37113883e-08, 0, 1)
    --weapon.PrimaryPart.weaponHold.Part0 = character.RightUpperArm

    self.currentlyPlayingAnimation = nil

    self.animationController = character:FindFirstChildWhichIsA("Humanoid") or
        character:FindFirstChildWhichIsA("AnimationController") or
        character:FindFirstChildWhichIsA("Animator")
    --[[
    self.charAnimationInstances = self.weaponSettings.animations.player
    self.loadedAnimations = {}

    self.loadedAnimations.aim = self.animationController:LoadAnimation(self.charAnimationInstances.aim)
    self.loadedAnimations.idle = self.animationController:LoadAnimation(self.charAnimationInstances.idle)
    self.loadedAnimations.sprint = self.animationController:LoadAnimation(self.charAnimationInstances.sprint)
    self.loadedAnimations.reload = self.animationController:LoadAnimation(self.charAnimationInstances.reload)
    --]]
    local loadedAnimations, animationsSpeeds, animationsDuration = weaponSettings.loadAllAnimations(self.animationController, "player")
    self.loadedAnimations = loadedAnimations
    self.animationsSpeeds = animationsSpeeds
	self.animationsDuration = animationsDuration
	
	self.weaponBaseParts = {}
	self.weaponDecals = {}
	local function addChild(v)
		if v:IsA("BasePart") and v.Name ~= "rootPart" then
			self.weaponBaseParts[v] = {
				Transparency = v.Transparency;
			}
			v.CanCollide = false
			v.Anchored = false
			if self.isHidden then
				v.Transparency = 1
			end
		elseif v:IsA("Decal") then
			self.weaponDecals[v] = {
				Transparency = v.Transparency;
			}
			if self.isHidden then
				v.Transparency = 1
			end
		end
	end

	for _, v in pairs(self.weapon:GetDescendants()) do
		addChild(v)
	end
	self.weapon.DescendantAdded:Connect(function(v)
		addChild(v)
	end)

	if self.animationController and self.animationController:IsA("Humanoid") and self.shouldPlayAnimations
		and self.loadedAnimations.walk and self.loadedAnimations.sprint and self.animationController.Parent.Name == game:GetService("Players").LocalPlayer.Name then
		local walkAnims = self.loadedAnimations.walk
		local sprintAnims = self.loadedAnimations.sprint

		local function changeTableSpeeds(t, s, n)
			for i, v in ipairs(t) do
				t[i] = s
				if self.playingAnimationIndex[n] == i then
					local anim = self.loadedAnimations[n][self.playingAnimationIndex[n]]
					if anim.IsPlaying then
						anim:AdjustSpeed(s)
					end
				end
			end
		end

		local walkInstance = weaponSettings.walkAnimSpeedInstance
		local sprintInstance = weaponSettings.sprintAnimSpeedInstance
		walkInstance.Changed:Connect(function(s)
			changeTableSpeeds(self.animationsSpeeds.walk, s, "walk")
		end)
		sprintInstance.Changed:Connect(function(s)
			changeTableSpeeds(self.animationsSpeeds.sprint, s, "sprint")
		end)
		changeTableSpeeds(self.animationsSpeeds.walk, walkInstance.Value, "walk")
		changeTableSpeeds(self.animationsSpeeds.sprint, sprintInstance.Value, "sprint")
		--self.onDestroyedMaid:GiveTask(self.animationController:GetPropertyChangedSignal("WalkSpeed"):Connect(function(newWalkSpeed)
		--	local animSpeed = 
		--end))
	end

	self.barrelCFrameAfterGunUpFromUT = nil

    return self
end
--[[
function ThirdPersonWeapon:StopAllAnimations()
    for _,v in pairs(self.loadedAnimations) do
        v:Stop()
    end
    return true
end

function ThirdPersonWeapon:UpdateAnimations()
    if not self:IsValid()
        then return false
    end

    print("updating animations")
    self:StopAllAnimations()

    if self.isReloading then
        self.loadedAnimations.reload:Play()
    elseif self.isAiming then
        self.loadedAnimations.aim:Play()
    elseif self.isSprinting then
        self.loadedAnimations.sprint:Play()
    elseif self.isEquipped then
        self.loadedAnimations.idle:Play()
    end

    return true
end
--]]
function ThirdPersonWeapon:ToggleAim(force, state)
	if not BaseWeapon.ToggleAim(self, force, state) then warn("THIRD PERSON: aim failed") return false end

    local isAiming = self.isAiming
    --[[
    self:UpdateAnimations()
    
    if isAiming then
        self.loadedAnimations.idle:Stop()
        self.loadedAnimations.aim:Play()
    else
        self.loadedAnimations.idle:Play()
        self.loadedAnimations.aim:Stop()
    end
    --]]
    return true
end

function ThirdPersonWeapon:ToggleSprint(force, state)
    if not BaseWeapon.ToggleSprint(self, force, state) then return false end

    --self:UpdateAnimations()

    return true
end

function ThirdPersonWeapon:Hide()
	self.isHidden = true
	
	for v, _ in pairs(self.weaponBaseParts) do
		v.Transparency = 1
	end
	for decal, _ in pairs(self.weaponDecals) do
		decal.Transparency = 1
	end
	
    return true
end


function ThirdPersonWeapon:Unhide()
	self.isHidden = false
	
	for v, settings in pairs(self.weaponBaseParts) do
		v.Transparency = settings.Transparency
	end
	for decal, settings in pairs(self.weaponDecals) do
		decal.Transparency = settings.Transparency
	end
    
    return true
end

function ThirdPersonWeapon:PlayEquipAnim(index)
	local char = self.character
	local weapon = self.weapon
	
	char:WaitForChild("RightUpperArm")

	weapon.Parent = char

	local backweld = self.weapon.receiver.backweld
	local weaponHold = self.weapon.receiver.weaponHold

	backweld.Part0 = nil

	weaponHold.C0 = self.weaponSettings.offsets.weaponFrame.weaponHold.C0
	weaponHold.C1 = self.weaponSettings.offsets.weaponFrame.weaponHold.C1

	if self.weaponSettings.usesHand then
		weaponHold.C0 = char.RightHand.CFrame:Inverse() * char.RightHand.RightGripAttachment.WorldCFrame
		weaponHold.Part0 = char.RightHand
        --[[
        local p = Instance.new("Part")
        p.Anchored = true
        p.Size = Vector3.new(0.5,0.5,0.5)
        p.Parent = char

        local rightGrip = Instance.new("Weld")
        rightGrip.Name = "RightGrip"
        rightGrip.C0 = char.RightHand.CFrame:Inverse() * char.RightHand.RightGripAttachment.WorldCFrame
        rightGrip.Part0 = char.RightHand
        rightGrip.Part1 = weapon.PrimaryPart

        RunService.Heartbeat:Connect(function()
            p.CFrame = char.RightHand.RightGripAttachment.WorldCFrame
        end)

        weapon.PrimaryPart.weaponHold.Part0 = p
        --]]
	else
		weaponHold.Part0 = char.RightUpperArm
	end
	
	BaseWeapon.PlayEquipAnim(self, index)
	
	return true
end

function ThirdPersonWeapon:PlayUnequipAnim(index)
	
	local unequipId = self.unequippedIn -- this is just tick but can be used as an ID
	local conn
	conn = self.unequippedSignal:Connect(function()
		conn:Disconnect()
		if self.unequippedIn ~= unequipId then return end
		--print("changing 3rd person motor")
		if not self.isDestroyed then
			
			local weaponHold = self.weapon.receiver:FindFirstChild("weaponHold")
			if self.weaponSettings.hidesOnUnequip then
				self:Hide()
			end
			local backweld = self.weapon.receiver:FindFirstChild("backweld")
			
			if weaponHold and backweld then
				backweld.C0 = self.weaponSettings.offsets.weaponFrame.backweld.C0
				backweld.C1 = self.weaponSettings.offsets.weaponFrame.backweld.C1

				backweld.Part0 = self.character.UpperTorso

				self.weapon.receiver.weaponHold.Part0 = nil
			end
		end
		--print("finished changing 3rd person motor")
	end)
	
	BaseWeapon.PlayUnequipAnim(self, index)
	
	return true
end

function ThirdPersonWeapon:Equip(shouldShow)
	if not BaseWeapon.Equip(self) then warn("THIRD PERSON: equip failed") return false end
    
    if shouldShow then
        self:Unhide()
    end

	--local animObj = self:PlayAnimation("equip", nil, false, nil)
	
    return true
end


function ThirdPersonWeapon:Unequip()
    if not BaseWeapon.Unequip(self) then warn("THIRD PERSON: unequip failed") return false end

	--local animObj = self:PlayAnimation("unequip", nil, false, nil)
	
    return true
end

function ThirdPersonWeapon:SetIsLineOfSightBlocked(state)
	if self.isLineOfSightBlocked == state then return true end
	self.isLineOfSightBlocked = state
	
	if self.isAiming then
		self:Unaim()
	end
	
	self:PlayIdleAnim()
	
	return true
end

function ThirdPersonWeapon:Fire(...)
	return BaseWeapon.Fire(self, ...)
end

function ThirdPersonWeapon:SetFiring(isFiring)
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

function ThirdPersonWeapon:StartReloading()
    if not BaseWeapon.StartReloading(self) then return false end

    --self:UpdateAnimations()

    return true
end

function ThirdPersonWeapon:StopReloading(...)
    if not BaseWeapon.StopReloading(self, ...) then return false end

    --self:UpdateAnimations()

    return true
end

function ThirdPersonWeapon:Update(...)
	
	if self:GetIsAnimationPlaying("gunUp") and not self:GetIsAnimationPlaying("atease") and self.character:FindFirstChild("RightUpperArm") and self.frameNumber%2==0 then
		local newOffset = self.character.UpperTorso.CFrame:Inverse() * self.barrelAttachment.WorldCFrame --self.barrelAttachment.WorldPosition - self.character.HumanoidRootPart.Position
		if newOffset ~= self.barrelCFrameAfterGunUpFromUT then
			self.barrelCFrameAfterGunUpFromUT = newOffset
		end
	end
	
	return BaseWeapon.Update(self, ...)
end

return ThirdPersonWeapon