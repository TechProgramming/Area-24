local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Knit"))
local Thread = require(Knit.Util:WaitForChild("Thread"))

local weaponsData = script.Parent--:WaitForChild("WeaponsData")
local weaponModels = workspace:WaitForChild("Scripted"):WaitForChild("Weapons")
local weaponSkins = workspace:WaitForChild("Scripted"):WaitForChild("WeaponSkins")

local function findFirstChildWhichIsA(inst, name, classname, recur)
	for _, v in ipairs(recur and inst:GetDescendants() or inst:GetChildren()) do
		if v.Name == name and v:IsA(classname) then return v end
	end
end

local function makeAnimation(id)
	local i = Instance.new("Animation")
	i.AnimationId = typeof(id) == "string" and id or ("rbxassetid://" .. id)
	return i
end

local tries = 3
local function preloadAsset(orgqueue)
	local queue = {}
	local idToInstance = {}
	local retry
	for i, v in ipairs(orgqueue) do
		queue[i] = v
		if v:IsA("Animation") then
			idToInstance[string.match(v.AnimationId, "%d+")] = v
		elseif v:IsA("Sound") then
			idToInstance[string.match(v.SoundId, "%d+")] = v
		end
	end
	local cur = 0
	while cur <= tries do
		retry = {}
		cur = cur + 1
		ContentProvider:PreloadAsync(queue,
			function(asset, status)
				if status == Enum.AssetFetchStatus.Failure then
					retry[#retry+1] = idToInstance[asset]
				end
			end
		)
		if #retry == 0 then
			break
		end
	end
	if #retry > 0 then
		for _, v in pairs(retry) do
			warn("Failed to load", v:GetFullName())
		end
	end
end

local data = {
    weapons = {};

    crosshairs = {
        sprint = "rbxassetid://5871831570";
        aim = "rbxassetid://5871923965";
        inAir = "rbxassetid://5871831850";
        default = "rbxassetid://5871831940";
    };

	weaponsSettings = {
		M1911 = require(weaponsData:WaitForChild("M1911"));
		AK74 = require(weaponsData:WaitForChild("AK74"));
		SPAS12 = require(weaponsData:WaitForChild("SPAS12"));
		MP5 = require(weaponsData:WaitForChild("MP5"));
		['AK74 Red Dragon'] = require(weaponsData:WaitForChild("AK74 Red Dragon"));
		['AK74 Obsidian'] = require(weaponsData:WaitForChild("AK74 Obsidian"));
	};
	
	weaponSkins = {
		-- Added later
	};
	weaponStickers = {
		-- Added later
	};
	
    crosshair = {
        size = UDim2.new(0, 15, 0, 4);
        transparency = 0.4;
        color = Color3.new(0,0,0);
        positiveDelta = 50;
        negativeDelta = 20;
    };
	
	animations = {
		-- animations here are played in ClientWeaponHandler for 3rd person only
		pistol = {
			walk = {makeAnimation(6888632964)};
			sprint = {makeAnimation(6888640983)};
		};
		ar = {
			walk = {makeAnimation(6893966616)};
			sprint = {makeAnimation(6893969145)};
		};
	};
	
    bulletGravity = -100;
	thirdPersonCameraOffset = Vector3.new(1.5, 1.4, 0);
	firstPersonCameraOffset = Vector3.new(0, 0, 0);
	ateaseCameraOffset = Vector3.new(0,0,0);
	unequippedCameraOffset = Vector3.new(0, 0, 0);
	
	defaultFOV = workspace.Camera.FieldOfView;
	aimingFOV = 50;
	
	aimingCameraOffset = Vector3.new(0,0,-5);
}
--[[
do -- Weapon customisation
	local SkinDynamicProperties = {
		"Transparency"; "Reflectance"; "Color"; "Material";
	}

	for weaponName, _ in pairs(data.weaponsSettings) do
		data.weaponSkins[weaponName] = {}
		data.weaponStickers[weaponName] = {}

		local skinData = {}

		local originalModel = weaponModels:FindFirstChild(weaponName)
		--[[
		for _, v in ipairs(originalModel:GetChildren()) do
			if v.Name:find("Sticker") ~= nil then
				local stickerName = v.Name:split("_")[2]
				local stickerPart = v:Clone()
				stickerPart:SetAttribute("IsSticker", true)
				stickerPart.Name = stickerName
				local stickerData = {
					part = stickerPart;
					part0Name = v.Motor6D.Part0.Name;
				}
				data.weaponStickers[weaponName][stickerName] = stickerData
				v:Destroy()
			end
		end
		--]
		for _, part in ipairs(originalModel:GetDescendants()) do
			if part:IsA("BasePart") then
				for _, property in ipairs(SkinDynamicProperties) do
					if skinData[part.Name] == nil then skinData[part.Name] = {} end
					skinData[part.Name][property] = part[property]
				end
			end
		end

		data.weaponSkins[weaponName]["Default"] = skinData
	end
	--[
	for _, weaponSkinModel in ipairs(weaponSkins:GetChildren()) do
		local weaponName = weaponSkinModel.Name:split("_")[1]
		local skinName = weaponSkinModel.Name:split("_")[2]
		
		local originalModel = weaponModels:FindFirstChild(weaponName)
		assert(originalModel, "Couldn't add skin because couldn't find weapon with name " .. weaponName .. " from " .. weaponSkinModel.Name)
		
		local skinData = {}
		
		for _, part in ipairs(originalModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local eqvPart = findFirstChildWhichIsA(weaponSkinModel, part.Name, "BasePart", true)
				assert(eqvPart, "Couldn't find part with name " .. part.Name .. " in " .. weaponSkinModel:GetFullName())
				for _, property in ipairs(SkinDynamicProperties) do
					if part[property] ~= eqvPart[property] then
						if skinData[part.Name] == nil then skinData[part.Name] = {} end
						skinData[part.Name][property] = eqvPart[property]
					end
				end
			end
		end
		
		data.weaponSkins[weaponName][skinName] = skinData
	end
	--]
end
--]]
data.isIdWeaponAnimationId = function(id)
	id = string.match(id, "%d+")
	for _, data in pairs(data.weaponsSettings) do
		for _, animType in pairs(data.animations.player) do
			for _, anim in pairs(animType) do
				if string.match(anim.AnimationId, "%d+") == id then
					return true, data.name, animType
				end
			end
		end
	end
	return false
end

local aimingFOV = Instance.new("IntValue", script)
aimingFOV.Name = "aimingFOV"
aimingFOV.Value = 50
data.aimingFOV = aimingFOV.Value
aimingFOV.Changed:Connect(function()
	data.aimingFOV = aimingFOV.Value
end)

local aimingCameraOffset = Instance.new("Vector3Value", script)
aimingCameraOffset.Name = "aimingCameraOffset"
aimingCameraOffset.Value = Vector3.new(0,0,-5)
data.aimingCameraOffset = aimingCameraOffset.Value
aimingCameraOffset.Changed:Connect(function()
	data.aimingCameraOffset = aimingCameraOffset.Value
end)

for _, weaponSettings in pairs(data.weaponsSettings) do
	weaponSettings.minShootingTime = (60/weaponSettings.rpm)
	
	table.insert(data.weapons, weaponSettings.name)
	
	local animationType = weaponSettings.walkAndSprintAnimType
	local extraAnimations = data.animations[animationType]
	if not extraAnimations then error("type " .. animationType .. " doesn't have animations in FrameworkData") end
	for i, v in pairs(extraAnimations) do
		weaponSettings.animations.player[i] = v
	end
	
	local loadQueue = {}
	local function addToLoadQueue(tbl)
		for _, v in pairs(tbl) do
			if typeof(v) == "table" then
				addToLoadQueue(v)
			elseif typeof(v) == "Instance" then
				if v:IsA("Animation")
					or v:IsA("Sound")
				then
					table.insert(loadQueue, v)
				end
			end
		end
	end
	addToLoadQueue(weaponSettings)
	if not RunService:IsServer() then
		Thread.Spawn(function()
			preloadAsset(loadQueue)
		end)
	end
	
	if not RunService:IsServer() then
		local walkInstance = Instance.new("NumberValue")
		walkInstance.Parent = weaponSettings.script
		walkInstance.Name = "walk"
		walkInstance.Value = weaponSettings.walkAnimSpeed
		
		local sprintInstance = Instance.new("NumberValue")
		sprintInstance.Parent = weaponSettings.script
		sprintInstance.Name = "sprint"
		sprintInstance.Value = weaponSettings.sprintAnimSpeed
		
		weaponSettings.walkAnimSpeedInstance = walkInstance
		weaponSettings.sprintAnimSpeedInstance = sprintInstance
	end

    weaponSettings.actionsDuration = {}
    local actDur = weaponSettings.actionsDuration

	actDur.reload = weaponSettings.reloadTime
    actDur.reloadUp = weaponSettings.reloadUpTime
    actDur.reloadDown = weaponSettings.reloadDownTime
    actDur.reloadBulletInsert = weaponSettings.reloadBulletTime

    actDur.fire = weaponSettings.firingAnimationTime
    actDur.aimFire = weaponSettings.firingAnimationTime
    actDur.firePump = weaponSettings.pumpTime
    actDur.aimFirePump = weaponSettings.pumpTime

    actDur.equip = weaponSettings.equipTime
	actDur.unequip = weaponSettings.unequipTime

	actDur.aim = weaponSettings.aimTime

	weaponSettings.loadAllAnimations = function(animationController, type)
		preloadAsset(loadQueue)
		local isDescendant = workspace:IsAncestorOf(animationController)
		while not isDescendant do
			--error("animationController is not Descendant of workspace")
			animationController:GetPropertyChangedSignal("Parent"):Wait()
			isDescendant = workspace:IsAncestorOf(animationController)
		end
        if animationController:IsA("Humanoid") then
            --print("animationController ", animationController:GetFullName())
        end
        local loadedAnimations = {}
		local animationsSpeeds = {}
        local animationsDuration = {}
        for name, anims in pairs(weaponSettings.animations[type]) do
            loadedAnimations[name] = {}
			animationsSpeeds[name] = {}
            animationsDuration[name] = {}

            for i, anim in pairs(anims) do
                loadedAnimations[name][i] = animationController:LoadAnimation(anim)

                --loadedAnimations[name][i].Stopped:Connect(function()
                --    print(name, "was stopped")
                --end)

                local speed = 1
                local len = loadedAnimations[name][i].Length
                if actDur[name] then
                    speed = len/actDur[name]
				end
				--print("FRAMEWORK DATA:", name, i, len, speed)
                --[[
                if name == "reloadUp" then
                    speed = len/weaponSettings.reloadUpTime
                elseif name == "reloadDown" then
                    speed = len/weaponSettings.reloadDownTime
                elseif name == "reloadBulletInsert" then
                    speed = len/weaponSettings.reloadBulletTime
                elseif name == "fire" or name == "aimFire" then
                    --if len > 60/weaponSettings.firing.rpm then
                        speed = len/(weaponSettings.firingAnimationTime)
                    --end
                    print(name, "'s speed is ", speed, len)
                elseif name == "firePump" or name == "aimFirePump" then
                    speed = len/weaponSettings.pumpTime
                elseif name == "equip" then
                    speed = len/weaponSettings.equipTime
                elseif name == "unequip" then
                    speed = len/weaponSettings.unequipTime
                elseif name == "aim" then
                    speed = len/weaponSettings.aimTime
                --elseif name == "reloadDown" then
                --    speed = len/weaponSettings.reloadDownTime
                end
                --]]
				animationsSpeeds[name][i] = speed
                animationsDuration[name][i] = speed * len
            end
        end
		return loadedAnimations, animationsSpeeds, animationsDuration
    end

end


return data