local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")

local PartCache = require(SharedModules:WaitForChild("PartCache"))
local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))

local Assets = ReplicatedStorage:WaitForChild("Assets")
local FPSAssets = Assets:WaitForChild("FPS")

local Knit = require(SharedModules:WaitForChild("Knit"))
local Signal = require(Knit.Util.Signal)

local FPSService = Knit.Services["FPSService"]

local ThirdPersonWeapon = require(script.Parent:WaitForChild("ThirdPersonWeapon"))

local NPCWeapon = setmetatable({}, ThirdPersonWeapon)
NPCWeapon.__index = NPCWeapon

NPCWeapon.Enums = {
    ActionFailed = {
        ShouldReload = 1;
        ShouldPump = 2;
        ActionInProgress = 3;
    };
}

local function copy(a)
	local t = {}
	for i,v in pairs(a) do
		t[i] = v
	end
	return t
end

function drawray(ray, parent)
    local part = Instance.new("Part");
    part.FormFactor = Enum.FormFactor.Custom;
    part.Material = Enum.Material.Neon;
    part.Size = Vector3.new(.2, ray.Direction.Magnitude, .2);
    part.CFrame = CFrame.new(ray.Origin + ray.Direction/2, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2,0,0);
    part.Anchored = true;
    part.CanCollide = false;
    part.BrickColor = BrickColor.new("Bright red");
    part.Transparency = 0.6
    part.Parent = parent or game.Workspace.Camera
    Debris:AddItem(part, 3)
    return part;
end;

function NPCWeapon.new(weaponSettings, metaSettings, character, weapon)
    local base = ThirdPersonWeapon.new(weaponSettings, metaSettings, character, weapon)
    local self = setmetatable(base, NPCWeapon)

    self.firingDirectionFunction = function() return Vector3.new(0,1,0) end
    self.shouldFireFunction = function() return false end

    self.serverIgnoreList = FPSService:GetIgnoreList()

    self.rayParams = RaycastParams.new()
    self.rayParams.IgnoreWater = true
    self.rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.rayParams.FilterDescendantsInstances = self.serverIgnoreList
    
    self.castBehavior = FastCast.newBehavior()
    self.castBehavior.RaycastParams = self.rayParams
    self.castBehavior.MaxDistance = weaponSettings.range
    self.castBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default
    
    --self.cosmeticPartProvider = PartCache.new(FPSAssets.bullet, 50, workspace.fastCast)

    --self.castBehavior.CosmeticBulletProvider = self.cosmeticPartProvider
    --self.castBehavior.CosmeticBulletTemplate = FPSAssets.bullet
    self.castBehavior.CosmeticBulletContainer = workspace.fastCast
    self.castBehavior.Acceleration = Vector3.new(0, 0, 0)
    self.castBehavior.AutoIgnoreContainer = false
    self.castBehavior.CanPierceFunction = self.CanPierceFunction
    
    self.caster = FastCast.new()

    self.caster.RayHit:Connect(self.OnRayHit)
    --self.caster.LengthChanged:Connect(self.OnRayUpdated)
    self.caster.CastTerminating:Connect(self.OnRayTerminated)

    return self
end

function NPCWeapon.CanPierceFunction(cast, result, segmentVelocity)
    if CollectionService:HasTag(result.Instance, FPSService.GlobalFastCastIgnoreTag) then
        return true
    else
        return false
    end
end

function NPCWeapon:Equip()
    local valid = ThirdPersonWeapon.Equip(self)
    if not valid then return false end

    return true
end

function NPCWeapon:Unequip()
    local valid = ThirdPersonWeapon.Unequip(self)
    if not valid then return false end


    return true
end

function NPCWeapon:GetFiringDirection()
    local dir = self.firingDirectionFunction()
    --print("NPCWEAPON: GET FIRING DIRECTION CALLED ", dir)
    return dir
end

function NPCWeapon:GetFiringOrigin()
    return self.weapon.PrimaryPart.barrel.WorldCFrame.Position
end

function NPCWeapon:GetFiringOrigin()
    return self.weapon.PrimaryPart.barrel.WorldCFrame.Position
end

function NPCWeapon:GetShouldFire()
    return self.shouldFireFunction()
end

function NPCWeapon.OnRayHit(cast, raycastResult, segmentVelocity, bullet)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
    local normal = raycastResult.Normal

	print("NPCWEAPON: RAY HIT ", hitPart:GetFullName())
    
    local self = cast.UserData.self
    --[[
	local p = Instance.new("Part")
	p.Size = Vector3.new(4,4,4)
	p.BrickColor = BrickColor.new("Black")
	p.Anchored = true
	p.CanCollide = false
	p.Position = hitPoint
	p.Parent = workspace
	Debris:AddItem(p, 1)
    --]]

    local function getCharHumanoid(model)
        local curParent = model
        local hum = curParent:FindFirstChildOfClass("Humanoid")
        while curParent ~= workspace and hum == nil do
            curParent = curParent.Parent
            hum = curParent:FindFirstChildOfClass("Humanoid")
        end
        return hum
    end

	if hitPart ~= nil and hitPart.Parent ~= nil then
        local humanoid = getCharHumanoid(hitPart)--hitPart.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local player = Players:GetPlayerFromCharacter(humanoid.Parent)

            local damage = hitPart.Name == "Head" and self.weaponSettings.headshot
                or self.weaponSettings.damage

            if player then
                humanoid:TakeDamage(damage)
            end

            print("NPC doing damage worth ", damage, " to ", (player and "player"))
        end

	end

end

function NPCWeapon.OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, bullet)
	local BulletLength = bullet.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	bullet.CFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection) * CFrame.new(0, 0, -(length - BulletLength))
end

function NPCWeapon.OnRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
    local self = cast.UserData.self
    local castBehavior = self.castBehavior

	--print("RAY TERMINATED ", cosmeticBullet)
	if cosmeticBullet ~= nil then
		-- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example gun works out of the box.
		-- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.
        castBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
        --cosmeticBullet:Destroy()
	end
end

function NPCWeapon:GetNPCFireError()
    if self.ammo <= 0 then
        return self.Enums.ActionFailed.ShouldReload
    elseif (self.usesPump and not self.hasPumpedBullet) then
        return self.Enums.ActionFailed.ShouldPump
    elseif (self.isReloading) then
        return self.Enums.ActionFailed.ActionInProgress
    end

    return nil
end

function NPCWeapon:Fire(origin, allDirections)
    --local origin = self:GetFiringOrigin()

    local err = self:GetNPCFireError()
    if err then
        return err
    end

    if not ThirdPersonWeapon.Fire(self, origin, allDirections) then print("FIRING FAILED") return false end
    --print("NPCWEAPON: FIRING DIRECTION ", dir)
    --print(debug.traceback())

    FPSService.OnNPCFired:Fire(self.character, self.weaponSettings.name, origin, allDirections)

	local newFilterList = copy(self.serverIgnoreList)
	table.insert(newFilterList, self.character)
	table.insert(newFilterList, self.weapon)

	self.rayParams.FilterDescendantsInstances = newFilterList
    self.castBehavior.RaycastParams = self.rayParams

    for _, dir in ipairs(allDirections) do
    	local activeCast = self.caster:Fire(
    		origin,
    		dir.Unit,
    		self.weaponSettings.speed,
    		self.castBehavior
        )

        --local p = drawray(Ray.new(origin, dir), workspace)
        
        activeCast.UserData.self = self
    end

    return true
end

function NPCWeapon:SetFiring(shouldFireFunction, dirFunc)
    self.firingDirectionFunction = dirFunc
    self.shouldFireFunction = shouldFireFunction

    local err = self:GetNPCFireError()
    if err then
        return err
    end

    local valid = ThirdPersonWeapon.SetFiring(self, self:GetShouldFire())
    if not valid then warn("SHOOTING FAILED") return false end

    return true
end

return NPCWeapon