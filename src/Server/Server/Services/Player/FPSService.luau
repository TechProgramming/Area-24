local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local DISABLE_ANTI_CHEAT = true

-- Constant Objects
local SharedModules = ReplicatedStorage:WaitForChild("Modules")
local ServerModules = ServerStorage:WaitForChild("Modules")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local FPSAssets = Assets:WaitForChild("FPS")
local WeaponModules = SharedModules:WaitForChild("WeaponModules")

local TimeSync = require(SharedModules:WaitForChild("TimeSync"))
local BaseWeapon = require(WeaponModules:WaitForChild("BaseWeapon"))
local ThirdPersonWeapon = require(WeaponModules:WaitForChild("ThirdPersonWeapon"))
local WeaponUtils = require(WeaponModules:WaitForChild("WeaponUtils"))

local FastCast = require(WeaponModules:WaitForChild("FastCastRedux"))

local GameData = ReplicatedStorage:WaitForChild("GameData")

local FastCastBulletsFolder = Instance.new("Folder", workspace)
FastCastBulletsFolder.Name = "fastCast"
local UnequippedWeaponsFolder = Instance.new("Folder", ReplicatedStorage)
UnequippedWeaponsFolder.Name = "unequippedWeaponsFolder"

local raycastFilter = {
	FastCastBulletsFolder;
}

local TYPE_ERR_STR = "Expected '%s' to be %s got %s"

local MAX_DIST_ROOT_ORIGIN = 25
local MAX_STICKER_NUMBER = 3

local GlobalFastCastIgnoreTag = "globalFastCastIgnoreTag"
local BulletPierceTransparencyThreshold = 0.9
local MaxAllowedNetworkDelay = 700/1000 -- In seconds
local MaxHitRaycast = 10

local CharacterEditorService
local TransactionService
local TeamRulesService
local ProfileService
local ToolService
local ItemService

-- Requires
local Knit = require(SharedModules:WaitForChild("Knit"))
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)
local Thread = require(Knit.Util:WaitForChild("Thread"))
local Signal = require(Knit.Util.Signal)
local FrameworkData = require(GameData:WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))

local PlayersData = {} -- Table for keeping track of weapons
local CurrentShots = {} -- Table for each player's shots that still didn't hit yet
local CharactersPositions = {} -- Table for part positions
local TrackedCharacterParts = {
	"HumanoidRootPart", "Head", "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"
} -- HRP must be number 1. MUST BE!
local BulletRejectionReasons = {
	"Part not met";
	""
}

local FPSService = Knit.CreateService({
	Name = "FPSService";

	PlayersData = PlayersData;

	OnInstanceAddedToIgnore = Signal.new();
	OnNPCFired = Signal.new();
	NPCDamagedSignal = Signal.new();

	GlobalFastCastIgnoreTag = GlobalFastCastIgnoreTag;

	Client = {
		OrderClientSetup = RemoteSignal.new();

		OrderWeaponRigToggle = RemoteSignal.new();

		EquipEvent = RemoteSignal.new();
		UnequipEvent = RemoteSignal.new();
		AimEvent = RemoteSignal.new();
		ReloadEvent = RemoteSignal.new();
		FireEvent = RemoteSignal.new();
		PlayerHitEvent = RemoteSignal.new();
		NPCHitEvent = RemoteSignal.new();
		
		OnFiredEvent = RemoteSignal.new();
		OnNPCFired = RemoteSignal.new();
		
		PlaySoundEvent = RemoteSignal.new();
		-- Fired by client when a sound should be played (e.g reload's MagRemove)
		-- Fired by server when a client's request is approved

		OnInstanceAddedToIgnore = RemoteSignal.new();
		
		OrderWeaponSkinChange = RemoteSignal.new();
		OrderWeaponStickerChange = RemoteSignal.new();
		OrderWeaponCharmChange = RemoteSignal.new();
		OrderAllWeaponStickerRemove = RemoteSignal.new();

		-- Properties
		GlobalFastCastIgnoreTag = RemoteProperty.new(GlobalFastCastIgnoreTag);

		UnequippedWeaponsFolder = RemoteProperty.new(UnequippedWeaponsFolder);
		BulletPierceTransparencyThreshold = RemoteProperty.new(BulletPierceTransparencyThreshold, "NumberValue");
		TrackedCharacterParts = RemoteProperty.new(TrackedCharacterParts);
	};
})

local function copy(a)
	local t = {}
	for i,v in pairs(a) do
		t[i] = v
	end
	return t
end

local function copyArray(a, customLength)
	local t = table.create(customLength and math.max(customLength, #a) or #a, a[1])
	for i,v in ipairs(a) do
		t[i] = v
	end
	return t
end

local function getLength(t)
	local n = 0
	for _,_ in pairs(t) do
		n+=1
	end
	return n
end

local function findFirstChildWhichIsA(inst, name, classname, recur)
	for _, v in ipairs(recur and inst:GetDescendants() or inst:GetChildren()) do
		if v.Name == name and v:IsA(classname) then return v end
	end
end

local SyncedNow = tick()
--[[
local function lowerbound(t, x, optionalIndex)
	local l, r = 1, #t
	local m = 
	while l < r do
		
	end
end
--]]
local magazineCount = 5

local getCharHumanoid = WeaponUtils.getCharHumanoid

local function doPlayerDamage(shooter, targetPlayer, hitPart, weaponSettings)
	local humanoid, limb = getCharHumanoid(hitPart)
	if humanoid then
		
		local damage = limb.Name == "Head" and weaponSettings.headshot
			or weaponSettings.damage

		local canHarm = TeamRulesService:CanKillPlayer(shooter, targetPlayer)

		if canHarm then
			humanoid:TakeDamage(damage)


			if humanoid.Health <= 0 and not humanoid:GetAttribute("KillerAwardedXP") then
				humanoid:SetAttribute("KillerAwardedXP", true)

				--award
				local JobService = Knit.GetService("JobService")
				JobService:Award(shooter, true, false, "Kill")
			end

		print("PLAYER doing damage worth", damage, "to", targetPlayer and "targetPlayer" or "NPC")
		end
	end
end

local function doNPCDamage(shooter, hitPart, weaponSettings)
	local humanoid, limb = getCharHumanoid(hitPart)--hitPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then

		local damage = limb.Name == "Head" and weaponSettings.headshot
			or weaponSettings.damage

		local canHarm = TeamRulesService:CanKillEntity(shooter, humanoid.Parent)

		if canHarm then
			humanoid.Health -= damage

			if humanoid.Health <= 0 and not humanoid:GetAttribute("KillerAwardedXP") then
				humanoid:SetAttribute("KillerAwardedXP", true)

				--award
				local JobService = Knit.GetService("JobService")
				JobService:Award(shooter, true, false, "Kill")
			end

			print("PLAYER doing damage worth", damage, "to NPC")
		end
	end
end

-- Called on ray hit
local function onRayHit(cast, raycastResult, segmentVelocity, bullet)
	--print("RAY HIT ", cast, raycastResult, segmentVelocity, bullet)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal

	local shooter = cast.UserData.player
	--[[
	local p = Instance.new("Part")
	p.Size = Vector3.new(2,2,2)
	p.BrickColor = BrickColor.new("Black")
	p.Anchored = true
	p.CanCollide = false
	p.Position = hitPoint
	p.Transparency = 0.8
	p.Parent = workspace
	Debris:AddItem(p, 1)
	--]]
	if hitPart ~= nil and hitPart.Parent ~= nil then
		local humanoid, limb = getCharHumanoid(hitPart)--hitPart.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local damage = limb.Name == "Head" and cast.UserData.weaponSettings.headshot
				or cast.UserData.weaponSettings.damage

			local targetPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)

			local canHarm = false
			if targetPlayer then
				canHarm = TeamRulesService:CanKillPlayer(shooter, targetPlayer)
			else
				canHarm = TeamRulesService:CanKillEntity(shooter, humanoid.Parent)
			end

			if canHarm then
				humanoid:TakeDamage(damage)
				
				
				if humanoid.Health <= 0 and not humanoid:GetAttribute("KillerAwardedXP") then
					humanoid:SetAttribute("KillerAwardedXP", true)
					
					--award
					local JobService = Knit.GetService("JobService")
					JobService:Award(shooter, true, false, "Kill")
				end

				print("PLAYER doing damage worth ", damage, " to ", targetPlayer and "targetPlayer" or "NPC")
			end
		end

	end

end

function canPierceFunction(cast, result, segmentVelocity)
	if not result.Instance:IsA("Terrain")
		and (CollectionService:HasTag(result.Instance, FPSService.GlobalFastCastIgnoreTag)
		or result.Instance.Transparency >= BulletPierceTransparencyThreshold
		)--or result.Instance.CanCollide == false)
	then
		--warn("passed through", result.Instance:GetFullName())
		return true
	else
		--warn("failed to pass through", result.Instance:GetFullName())
		return false
	end
end

local function getCustomisationData(player, weaponName)
	local profile = ProfileService:GetProfile(player)
	local avaterSetData = CharacterEditorService:GetAvatarData(player)
	-- GG TODO: Debug avatarSetData's content to fix ChangeWeaponSkin
	--print("AVATAR SET", avaterSetData)
	local customisationData = profile.WeaponCustomisation[avaterSetData.TeamId][avaterSetData.AvatarSetNumber][weaponName]
	
	return customisationData, avaterSetData.AvatarSetNumber
end

function FPSService:AddWeapon(player, weaponName, tool, skin, stickers)
	--print("ADDING", weaponName, "FOR", player.Name, "WITH", skin, "AND", stickers and #stickers or 0)
	local weaponsTable = PlayersData[player.UserId]
	if weaponsTable.weapons[weaponName] then weaponsTable.weapons[weaponName]:Destroy() end
	--[[
	local customisationData, avatarSetNumber = getCustomisationData(player, weaponName)
	local skin = customisationData.Skin
	local stickers = customisationData.Stickers
	local charm = customisationData.Charm
	--]]
	local weaponModel = ItemService:GetItem(weaponName).Model:Clone() --WeaponsModels[weaponName]:Clone()
	weaponModel.Name = player.Name .. "'s " .. weaponName
	--[[
	for partName, partData in pairs(skinData) do
		local part = findFirstChildWhichIsA(weaponModel, partName, "BasePart", true)
		for property, value in pairs(partData) do
			part[property] = value
		end
	end
	for _, stickerName in pairs(stickers) do
		local stickerData = FrameworkData.weaponStickers[weaponName][stickerName]
		local stickerPart = stickerData.part:Clone()
		stickerPart.Motor6D.Part0 = weaponModel:FindFirstChild(stickerData.part0Name, true)
	end
	--]]
	for _, v in pairs(weaponModel:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Massless = true
			v.Anchored = false
		end
	end
	
	weaponModel.Parent = UnequippedWeaponsFolder

	local weaponSettings = FrameworkData.weaponsSettings[weaponName]

	local weaponData = {
		name = weaponName;
		weapon = weaponModel;
		settings = weaponSettings;
		lastShot = 0;
		tool = tool;
		skin = skin;
		avatarSetNumber = avatarSetNumber;
	}
	weaponsTable.weapons[weaponName] = weaponData

	local weaponObj = BaseWeapon.new( --ThirdPersonWeapon.new(
		weaponSettings, -- weapon's settings
		{ -- meta settings
			isPlayer = false;
			shouldPlayAnimations = false;
		},
		player.Character, -- holder's character
		weaponModel -- weapon's model
	)

	weaponData.object = weaponObj

	local loadedAnimations, animationsSpeeds = {}, {} --weaponSettings.loadAllAnimations(player.Character.Humanoid, "player")
	weaponData.loadedAnimations = loadedAnimations
	weaponData.animationsSpeeds = animationsSpeeds

	weaponObj.loadedAnimations = loadedAnimations
	weaponObj.animationsSpeeds = animationsSpeeds

	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = true
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = raycastFilter

	--[[
	local caster = FastCast.new()
	
	local castBehavior = FastCast.newBehavior()
	castBehavior.RaycastParams = rayParams
	castBehavior.MaxDistance = weaponSettings.range
	castBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Default

	castBehavior.CosmeticBulletContainer = workspace.fastCast
	castBehavior.Acceleration = Vector3.new(0, 0, 0)--weaponSettings.bulletGravity
	castBehavior.AutoIgnoreContainer = false
	castBehavior.CanPierceFunction = canPierceFunction

	caster.RayHit:Connect(onRayHit)
	
	weaponData.caster = caster
	weaponData.castBehavior = castBehavior
	--]]
	weaponData.rayParams = rayParams


	weaponData.magData = {
		current = weaponSettings.magCapacity;
		spare = weaponSettings.magCapacity * magazineCount;
	}

	--weaponObj.onDestroyedMaid:GiveTask(player.CharacterRemoving:Connect(function()
	--	weaponObj:Destroy()
	--	weaponsTable.weapons[weaponName] = nil
	--end))

	weaponObj.onDestroyedMaid:GiveTask(tool.Changed:Connect(function(property)
		if property == "Parent" then
			if tool.Parent == nil then
				weaponObj:Destroy()
				if weaponData == weaponsTable.weapons[weaponName] then
					weaponsTable.weapons[weaponName] = nil
				end
			end
		end
	end))

	weaponObj.onDestroyedMaid:GiveTask(function()
		if weaponData == weaponsTable.weapons[weaponName] then
			weaponsTable.weapons[weaponName] = nil
		end
	end)
	--[
	if skin ~= nil then
		self:ChangeWeaponSkin(player, weaponName, skin, false, true)
	end
	if stickers ~= nil then
		for _, v in ipairs(stickers) do
			warn("Adding sticker " .. v)
			self:AddWeaponSticker(player, weaponName, v, false, true)
		end
	end
	--if charm ~= "N/A" then
	--	self:ChangeWeaponCharm(player, weaponName, charm, false)
	--end
	--]]
	
	local function onAttributeChanged(attribute)
		if attribute == "Skin" then
			self:ChangeWeaponSkin(player, weaponName, tool:GetAttribute("Skin"), false, true)
		elseif attribute == "Stickers" and tool:GetAttribute("Stickers") then
			local stickers = tool:GetAttribute("Stickers"):split("_")
			self:RemoveAllWeaponStickers(player, weaponName)
			for _, v in ipairs(stickers) do
				if v ~= "" then
					self:AddWeaponSticker(player, weaponName, v, false, true)
				end
			end
		end
	end
	
	tool.AttributeChanged:Connect(onAttributeChanged)
	onAttributeChanged("Stickers")
	onAttributeChanged("Skin")

	self.Client.OrderClientSetup:Fire(player, weaponName, tool, weaponModel)
	
	--wait(2) print("next") self:AddWeaponSticker(player, weaponName, "Red Dragon", false)
	--print("CHANGING SKIN") self:ChangeWeaponSkin(player, weaponName, "Red Dragon", false) TransactionService:Purchase(player, "AK74_Red Dragon_Skin") self:ChangeWeaponSkin(player, weaponName, "Red Dragon", false)
	--Thread.Spawn(function() if weaponName ~= "AK74" then return end wait(4) self:ChangeWeaponCharm(player, weaponName, "White Dominus", false) TransactionService:Purchase(player, "AK74_White Dominus_Charm") self:ChangeWeaponCharm(player, weaponName, "White Dominus", false) end)
end

function FPSService:RemoveWeapon(player, weaponName)
	local weapons = PlayersData[player.UserId] and PlayersData[player.UserId].weapons
	if weapons == nil then return true end
	if weapons[weaponName] == nil then return true end
	
	weapons[weaponName].object:Destroy()
	
	return true
end

function FPSService:RemoveAllWeapons(player)
	local weapons = PlayersData[player.UserId] and PlayersData[player.UserId].weapons
	if weapons == nil then return true end

	for weaponName, _ in pairs(weapons) do
		self:RemoveWeapon(player, weaponName)
	end

	return true
end

function FPSService:DoesPlayerOwnItem(player, itemData)
	--return true
	--[
	if itemData.Gamepass then
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, itemData.Gamepass)
	else
		local profile = ProfileService:GetProfile(player)
		if itemData.ItemId:split("_")[2] ~= "Default" and table.find(profile.PurchasedItems, itemData.ItemId) == nil then return false end
		return true
	end--]]
end


-- GG TODO: Remove ignoreOwn and instead check on client function call
function FPSService:ChangeWeaponSkin(player, weaponName, skinName, save, ignoreOwn)
	if skinName == nil then skinName = "Default" end
	
	local customisationData = getCustomisationData(player, weaponName)

	--if customisationData.Skin == skinName then return true end
	
	local weaponsTable = PlayersData[player.UserId]
	--if not weaponsTable then return false end
	--if not weaponsTable.weapons then print("FPSService:ChangeWeaponSkin No weapons table") return false end
	--if not weaponData then print("FPSService:ChangeWeaponSkin No weapon with name " .. weaponName .. " found") return false end

	local skinData = ItemService:GetWeaponSkin(weaponName, skinName)
	assert(skinData ~= nil, "FPSService:ChangeWeaponSkin Couldn't find " .. weaponName .. "'s " .. skinName .. " skin")
	
	local ownsItem = ignoreOwn or FPSService:DoesPlayerOwnItem(player, skinData)
	if ownsItem == false then warn(player.Name .. " doesn't own " .. skinName) return false end
	
	if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
		local weaponModel = weaponsTable.weapons[weaponName].weapon

		for partName, partData in pairs(skinData.PropertyData) do
			local part = findFirstChildWhichIsA(weaponModel, partName, "BasePart", true)
			for property, value in pairs(partData) do
				part[property] = value
			end
		end

		self.Client.OrderWeaponSkinChange:Fire(player, weaponName, skinData.PropertyData)
		-- Sending skinData because might as well save the client a roundtrip
		-- Also only using requester because all players use server's weapon model except the player with the weapon itself
	end
	
	if save then
		customisationData.Skin = skinName
	end
	
	return true
end
function FPSService.Client:ChangeWeaponSkin(player, weaponName, skinName)
	return FPSService:ChangeWeaponSkin(player, weaponName, skinName, true)
end

function FPSService:AddWeaponSticker(player, weaponName, stickerName, save, ignoreOwn)
	assert(typeof(stickerName) == "string", "stickerName isn't string but is " .. typeof(stickerName))

	local weaponsTable = PlayersData[player.UserId]
	
	local customisationData = getCustomisationData(player, weaponName)
	local profileStickers = customisationData.Stickers
	
	--for _, v in ipairs(profileStickers) do if v == stickerName then return true end end
	if #profileStickers >= MAX_STICKER_NUMBER then return false end
	
	local stickerData = ItemService:GetWeaponSticker(weaponName, stickerName)
	assert(stickerData ~= nil, "FPSService:AddWeaponSticker Couldn't find " .. weaponName .. "'s " .. stickerName .. " sticker")

	local ownsItem = ignoreOwn or FPSService:DoesPlayerOwnItem(player, stickerData)
	if ownsItem == false then warn(player.Name .. " doesn't own " .. stickerName) return false end
	
	if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
		local weaponModel = weaponsTable.weapons[weaponName].weapon

		local stickerPart = stickerData.Part:Clone()
		stickerPart.Motor6D.Part0 = findFirstChildWhichIsA(weaponModel, stickerData.Part0Name, "BasePart", true)
		
		self.Client.OrderWeaponStickerChange:Fire(player, weaponName, true, stickerData)
	end
	
	if save then
		profileStickers[#profileStickers+1] = stickerName
	end
	
	return true
end
function FPSService.Client:AddWeaponSticker(player, weaponName, stickerName)
	return FPSService:AddWeaponSticker(player, weaponName, stickerName, true)
end

function FPSService:RemoveWeaponSticker(player, weaponName, stickerName, save)
	assert(typeof(stickerName) == "string", "stickerName isn't string but is " .. typeof(stickerName))

	local weaponsTable = PlayersData[player.UserId]

	local customisationData = getCustomisationData(player, weaponName)
	local profileStickers = customisationData.Stickers
	
	local idx = table.find(profileStickers, stickerName)
	
	if idx then
		if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
			local weaponModel = weaponsTable.weapons[weaponName].weapon
			if weaponModel:FindFirstChild(stickerName) then
				weaponModel:FindFirstChild(stickerName):Destroy()
			end
			
			self.Client.OrderWeaponStickerChange:Fire(player, weaponName, false, stickerName)
		end
		if save then
			table.remove(profileStickers, idx)
		end
	end
	
	return true
end
function FPSService.Client:RemoveWeaponSticker(player, weaponName, stickerName)
	return FPSService:RemoveWeaponSticker(player, weaponName, stickerName, true)
end

function FPSService:RemoveAllWeaponStickers(player, weaponName)
	local weaponsTable = PlayersData[player.UserId]
	
	if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
		local weaponModel = weaponsTable.weapons[weaponName].weapon
		for _, v in ipairs(weaponModel:GetChildren()) do
			if v:GetAttribute("IsSticker") then v:Destroy() end
		end
		--[[
		for _, stickerName in ipairs(profileStickers) do
			if weaponModel:FindFirstChild(stickerName) then
				weaponModel:FindFirstChild(stickerName):Destroy()
			end
		end--]]
	end
	
	self.Client.OrderAllWeaponStickerRemove:Fire(player, weaponName)
	
	return true
end

function FPSService:ChangeWeaponCharm(player, weaponName, charmName, save)
	if charmName == "N/A" then return self:RemoveWeaponCharm(player, weaponName) end
	
	local customisationData = getCustomisationData(player, weaponName)
	
	--if customisationData.Charm == charmName then return true end
	local lastCharm = customisationData.Charm
		
	local weaponsTable = PlayersData[player.UserId]

	local charmData = ItemService:GetWeaponCharm(weaponName, charmName)
	assert(charmData ~= nil, "FPSService:ChangeWeaponCharm Couldn't find " .. weaponName .. "'s " .. charmName .. " skin")

	local ownsItem = FPSService:DoesPlayerOwnItem(player, charmData)
	if ownsItem == false then warn(player.Name .. " doesn't own " .. charmName) return false end

	if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
		local weaponModel = weaponsTable.weapons[weaponName].weapon
		
		if weaponModel:FindFirstChild(lastCharm) then
			weaponModel[lastCharm]:Destroy()
		end
		
		--if weaponModel:FindFirstChild("CharmHolder") then
		--	weaponModel["CharmHolder"]:Destroy()
		--end
		local charmPart = charmData.Part:Clone()
		
		local charmHolder = weaponModel.CharmHolder
		charmHolder.RopeConstraint.Attachment1 = charmPart.Attachment1
		charmPart.Position = player.Character.HumanoidRootPart.Position + Vector3.new(-1.5,0,0)
		charmPart.Parent = weaponModel
		
		self.Client.OrderWeaponCharmChange:Fire(player, weaponName, true, charmData)
		-- Sending skinData because might as well save the client a roundtrip
		-- Also only using requester because all players use server's weapon model except the player with the weapon itself
	end

	if save then
		customisationData.Charm = charmName
	end
end

function FPSService:RemoveWeaponCharm(player, weaponName, save)
	local customisationData = getCustomisationData(player, weaponName)
	
	local charmName = customisationData.Charm
	if charmName then
		local weaponModel = self:GetWeaponModel(player, weaponName)
		if weaponModel then
			if weaponModel:FindFirstChild(charmName) then
				weaponModel[charmName]:Destroy()
			end
		end
		self.Client.OrderWeaponCharmChange:Fire(player, weaponName, false)
	end
	
	if save then
		customisationData.Charm = "N/A"
	end
end

function FPSService:GetWeaponModel(player, weaponName)
	local weaponsTable = PlayersData[player.UserId]
	if weaponsTable and weaponsTable.weapons and weaponsTable.weapons[weaponName] then
		return weaponsTable.weapons[weaponName].weapon
	end
end

local function playerAdded(player)
	local values = {
		{name = "gun"; value = nil; type = "ObjectValue"};
	}

	for _, v in pairs(values) do
		local value = Instance.new(v.type)
		value.Name = v.name
		value.Value = v.value
		value.Parent = player
	end
	
	local characterHeartbeatConn
	
	local function resetCharData()
		characterHeartbeatConn:Disconnect()
		CharactersPositions[player] = nil
	end

	player.CharacterAdded:Connect(function(character)
		if not player.Character then return end
		local humanoid = character:WaitForChild("Humanoid")
		character:WaitForChild("HumanoidRootPart")

		local ancestor = character and character.Parent
		while ancestor == nil do
			character.AncestryChanged:Wait()
			ancestor = character.Parent
		end

		PlayersData[player.UserId] = {
			unequippedSignal = Signal.new();
			equippedSignal = Signal.new();

			magData = {};
			weapons = {};
			loadedAnimations = {};

			-- set default values
			isReloading = false;
			isEquipping = false;
			isUnequipping = false;
			
			-- debug values
			failedEquip = false;
		}
		
		humanoid.Died:Connect(function()
			FPSService:RemoveAllWeapons(player)
		end)
		
		if characterHeartbeatConn then
			characterHeartbeatConn:Disconnect()
		end
		
		local waitSuccessful = true
		local characterParts = table.create(#TrackedCharacterParts, Instance.new("Part"))
		for i, partName in ipairs(TrackedCharacterParts) do
			local part = character:WaitForChild(partName, 15)
			if part == nil then waitSuccessful = false warn("Failed to find " .. partName) break end
			characterParts[i] = part
		end
		if not waitSuccessful then return end
		
		local characterPositions = table.create(60 * MaxAllowedNetworkDelay, {0, table.create(#TrackedCharacterParts, Vector3.new())})
		table.clear(characterPositions)
		local ttlRecordedTime = 0
		--characterPositions[1] = 0 -- Total recorded time
		CharactersPositions[player] = characterPositions
		
		characterHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
			if character == nil or
				not workspace:IsAncestorOf(character) or
				CharactersPositions[player] == nil
			then resetCharData() return end
			
			if ttlRecordedTime >= MaxAllowedNetworkDelay then
				local curTtl = 0
				local curIndex = 0
				for i, posData in ipairs(characterPositions) do
					if characterPositions[i+1] == nil then break end
					curTtl += characterPositions[i+1][1] - posData[1]
					curIndex = i
					
					if (ttlRecordedTime - curTtl) < MaxAllowedNetworkDelay then break end
				end
				for i = curIndex, 1, -1 do
					table.remove(characterPositions, i)
				end
				ttlRecordedTime -= curTtl
			end
			
			local newPositions = table.create(#TrackedCharacterParts, Vector3.new())
			for i, part in ipairs(characterParts) do
				newPositions[i] = part.Position
			end
			characterPositions[#characterPositions+1] = {SyncedNow, newPositions}
		end)
	end)
	
	player.CharacterRemoving:Connect(function()
		resetCharData()
		
		FPSService:RemoveAllWeapons(player)
	end)

	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player then
			local currentWeapon = PlayersData[v.UserId] and PlayersData[v.UserId].currentWeapon
			if currentWeapon then
				FPSService.Client.OrderWeaponRigToggle:Fire(player, v, currentWeapon.weapon, currentWeapon.name, true)
			end
		end
	end
end

function FPSService.Client:Equip(player, wepName)
	warn("equiping ", wepName)
	--if PlayersData[player.UserId].currentWeapon then return end
	--print("currentweapon check")
	local weaponTable = PlayersData[player.UserId]
	if not weaponTable then return false end
	if not weaponTable.weapons then print("failed weapons table check") weaponTable.failedEquip = true return false end
	if not weaponTable.weapons[wepName] then print("failed weapon's table check") weaponTable.failedEquip = true return false end
	if not player.Character then print("failed character check") weaponTable.failedEquip = true return false end
	
	local currentWeapon = weaponTable.currentWeapon
	if currentWeapon and currentWeapon.object.isEquipped then
		if weaponTable.name ~= wepName then
			FPSService.Client:Unequip(player, currentWeapon.name)
		else
			warn(player.Name, "has already equipped", wepName)
			return true
		end
	end
	--[[
	if weaponTable.isEquipping then
		warn("is equipping another weapon so waiting")
		weaponTable.equippedSignal:Wait()
		warn("waiting for unequipping now")
		weaponTable.unequippedSignal:Wait()
	end
	--]]
	--print("is not equipping another weapon")

	weaponTable.isEquipping = true
	weaponTable.failedEquip = false
	--[[
	if weaponTable.isUnequipping then
		warn("waiting to finish unequipping")
		weaponTable.unequippedSignal:Wait()
	end
	--]]
	local weaponData = weaponTable.weapons[wepName]
	local weaponObj = weaponData.object

	weaponTable.currentWeapon = weaponData
	player.gun.Value = weaponData.weapon

	FPSService.Client.OrderWeaponRigToggle:FireExcept(player, player, weaponData.weapon, weaponData.name, true)
	
	local conn
	local onEquipped = function()
		if conn then conn:Disconnect() end
		weaponTable.isEquipping = false
		weaponTable.equippedSignal:Fire()
		warn("finished equiping ", wepName, "for", player.Name)
	end
	
	if weaponObj.isEquipped then
		weaponTable.isEquipping = false
	else
		weaponTable.isUnequipping = false
		local equipId
		conn = weaponObj.equippedSignal:Connect(function()
			if not weaponObj.isEquipped or (equipId ~= nil and weaponObj.equippedIn ~= equipId) then return end
			onEquipped()
		end)
		weaponObj:Equip()
		equipId = weaponObj.equippedIn
	end
	
	return true 
end

function FPSService.Client:Unequip(player, wepName)

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return true end
	local weaponTable = PlayersData[player.UserId]
	local weaponData = weaponTable.weapons[wepName]
	if weaponData == nil then warn(wepName, "is not intialized for", player.Name) return true end
	
	local weapon = weaponData.weapon
	local weaponObj = weaponData.object
	if not weaponObj.isEquipped then
		warn(player.Name, "has already unequipped", wepName)
		return true
	end

	warn("unequiping ", wepName)

	if weaponTable.isUnequipping then warn("failed unequip because already unequipping") return false end

	weaponTable.isUnequipping = true
	--[[
	if weaponTable.isEquipping then
		weaponTable.equippedSignal:Wait()
	end
	--]]
	if not weaponObj.isEquipped then
		weaponTable.isUnequipping = false
	else
		weaponTable.isEquipping = false
		local conn, unequipId
		conn = weaponObj.unequippedSignal:Connect(function()
			conn:Disconnect()
			if weaponObj.isEquipped or (unequipId ~= nil and weaponObj.unequippedIn ~= unequipId) then return end

			-- we mark the inexistence of the current gun
			FPSService.Client.OrderWeaponRigToggle:FireExcept(player, player, weaponData.weapon, weaponData.name, false)

			if weaponTable.currentWeapon.name ~= weaponObj.name then return end
			
			weaponTable.currentWeapon = nil
			player.gun.Value = nil

			weaponTable.isUnequipping = false
			weaponTable.unequippedSignal:Fire()
		end)
		weaponObj:Unequip()
		unequipId = weaponObj.unequippedIn
	end

	return true 
end

FPSService.Client.AimEvent:Connect(function(player, toaim)

	if not PlayersData[player.UserId].currentWeapon then return end
	if not player.Character then return end
	local weaponTable = PlayersData[player.UserId]
	local weaponObj = weaponTable.currentWeapon.object
	-- we mark this for firing animations
	weaponTable.aiming = toaim
	--[[
	-- load the aim animation
	if not weaponTable.loadedAnimations.aim then 
		
		weaponTable.loadedAnimations.aim = player.Character.Humanoid:LoadAnimation(weaponTable.currentWeapon.settings.animations.player.aim)
		
	end
	
	-- play or stop it
	if toaim then
		weaponTable.loadedAnimations.aim:Play()
	else
		weaponTable.loadedAnimations.aim:Stop()
	end 
	--]]

	local weapon = weaponTable.currentWeapon.weapon
	local weaponObj = weaponTable.currentWeapon.object

	weaponObj:ToggleAim(true, toaim)
end)

FPSService.Client.ReloadEvent:Connect(function(player, reload)
	local plrData = PlayersData[player.UserId]

	if plrData.isReloading == reload then return end

	local weaponTable = PlayersData[player.UserId]
	if weaponTable.currentWeapon == nil then
		error("Failed to start reloading. No. of weapons intialized " .. tostring(getLength(weaponTable.weapons)) .. " failedEquip:" .. tostring(weaponTable.failedEquip))
	end
	local weaponObj = weaponTable.currentWeapon.object

	if reload then
		weaponObj:StartReloading()
	else
		weaponObj:StopReloading()
	end

	plrData.isReloading = reload
	if reload then
		--if plrData.loadedAnimations.reload then
		--	plrData.loadedAnimations.reload:Play()
		--	wait(plrData.loadedAnimations.reload.Length)
		--end

		--plrData.currentWeapon.magData.current = plrData.currentWeapon.settings.magCapacity
		--plrData.isReloading = false
	end
end)

FPSService.OnNPCFired:Connect(function(npc, weaponName, origin, allDirections)
	FPSService.Client.OnNPCFired:FireAll(npc, weaponName, origin, allDirections)
end)

FPSService.Client.FireEvent:Connect(function(player, shotTime, origin, allDirections)
	print("fired shooting event by ", player)
	if not typeof(allDirections) == "table" then print("allDirections is not a table") return end
	for i, v in pairs(allDirections) do
		local dir = v[1]
		if typeof(dir) ~= "Vector3" or dir.Magnitude == 0 then
			warn("Not all directions are vector3 or have 0 magnitude")
			return
		else
			allDirections[i][1] = dir.Unit
		end
	end
	
	local weaponTable = PlayersData[player.UserId]

	
	if not weaponTable.currentWeapon then warn("Does not has currentweapon") return end
	if not player.Character then warn("Does not have character") return end
	
	local weaponData = PlayersData[player.UserId].currentWeapon
	local weaponObj = weaponData.object
	local weaponSettings = weaponData.settings
	
	--if weaponTable.currentWeapon.magData.current <= 0 then return end
	--print("has more than 0 bullets")
	if not DISABLE_ANTI_CHEAT then
		if (player.Character.HumanoidRootPart.Position - origin).Magnitude >= MAX_DIST_ROOT_ORIGIN then
			warn("TOO MUCH DIFF BETWEEN org ", origin)

			local p = Instance.new("Part")
			p.Size = Vector3.new(2,2,2)
			p.Color = Color3.fromRGB(255,0,0)
			p.Anchored = true
			p.CanCollide = false
			p.Position = origin
			p.Transparency = 0.5
			p.Parent = workspace
			Debris:AddItem(p, 4)

			local p = Instance.new("Part")
			p.Size = Vector3.new(2,2,2)
			p.Color = Color3.fromRGB(0,0,255)
			p.Anchored = true
			p.CanCollide = false
			p.Transparency = 0.5
			p.Position = player.Character.HumanoidRootPart.Position
			p.Parent = workspace
			Debris:AddItem(p, 4)

			return
		end

		local lastShotDiff = tick() - weaponData.lastShot
		--60/weaponSettings.rpm
		if weaponData.lastShot ~= 0 and lastShotDiff < (weaponSettings.minShootingTime + MaxAllowedNetworkDelay) then
			warn(player.Name, "is shooting too quickly")
			return
		end
		
	end
	
	if #allDirections ~= (weaponSettings.usesPellets and weaponSettings.pelletsNumber or 1)
	then warn("Number of directions is not correct ", #allDirections, (weaponSettings.usesPellets and weaponSettings.pelletsNumber or 1)) return
	end
	print("firing authorized")
	
	if CurrentShots[player] == nil then
		CurrentShots[player] = table.create(10, {0, Vector3.new(), Vector3.new()}) -- Allocate storage
		table.clear(CurrentShots[player]) -- Keep storage but make length = 0
	end
	
	local playerShots = CurrentShots[player]
	for _, dirData in ipairs(allDirections) do
		playerShots[dirData[2]] = {shotTime, origin, dirData[1]}
	end
	
	local clientDirections = {}
	for i, v in ipairs(allDirections) do
		clientDirections[i] = v[1]
	end
	FPSService.Client.OnFiredEvent:FireExcept(
		player, -- ignore this player
		player, -- shooter
		origin, -- origin
		clientDirections, -- direction
		weaponData.name -- weapon name
	)

	weaponData.lastShot = tick()

	weaponTable.currentWeapon.magData.current -= 1;
	--[[
	local newFilterList = copy(raycastFilter)
	table.insert(newFilterList, player.Character)

	weaponData.rayParams.FilterDescendantsInstances = newFilterList
	weaponData.castBehavior.RaycastParams = weaponData.rayParams

	for i, dir in pairs(allDirections) do
		local activeCast = weaponData.caster:Fire(
			origin,
			dir,
			weaponSettings.speed,
			weaponData.castBehavior
		)

		activeCast.UserData.player = player
		activeCast.UserData.weaponSettings = weaponSettings
		activeCast.UserData.weaponData = weaponData

	end
	--]]
	weaponObj:Fire(origin, clientDirections)
	
	if weaponSettings.sounds and weaponSettings.sounds.fire then
		local fireSound = weaponSettings.sounds.fire[math.random(1, #weaponSettings.sounds.fire)]
		FPSService.Client.PlaySoundEvent:FireExcept(player, player, fireSound, weaponData.weapon)
	end 
	
	Thread.Delay(weaponSettings.range/weaponSettings.speed + MaxAllowedNetworkDelay, function()
		for _, dirData in ipairs(allDirections) do
			playerShots[dirData[2]] = nil
		end
	end)
end)

FPSService.Client.NPCHitEvent:Connect(function(player, shotId, hitTime, hitPosition, hitPart)
	print("Fired NPCHitEvent by", player.Name)

	assert(typeof(shotId)=="number", TYPE_ERR_STR:format("shotId", "number", typeof(shotId)))
	assert(typeof(hitTime)=="number", TYPE_ERR_STR:format("hitTime", "number", typeof(hitTime)))
	assert(typeof(hitPosition)=="Vector3", TYPE_ERR_STR:format("hitPosition", "Vector3", typeof(hitPosition)))
	assert(typeof(hitPart)=="Instance", TYPE_ERR_STR:format("hitPart", "Instance", typeof(hitPart)))
	
	local shotData = CurrentShots[player][shotId]
	if shotData == nil then return end

	local weaponData = PlayersData[player.UserId].currentWeapon
	if weaponData == nil then return end
	
	if not hitPart:IsDescendantOf(workspace) then return end
	local character = getCharHumanoid(hitPart)
	if character == nil then return end
	if not DISABLE_ANTI_CHEAT and Players:GetPlayerFromCharacter(character) then return end
	
	CurrentShots[player][shotId] = nil
	
	doNPCDamage(player, hitPart, weaponData.settings)
end)

FPSService.Client.PlayerHitEvent:Connect(function(player, targetPlayer, shotId, hitTime, hitPosition, hitPart, hitPartPosition)
	print("Fired PlayerHitEvent by", player.Name)
	
	assert(targetPlayer:IsA("Player"), TYPE_ERR_STR:format("Player", "Player", targetPlayer.ClassName))
	assert(typeof(shotId)=="number", TYPE_ERR_STR:format("shotId", "number", typeof(shotId)))
	assert(typeof(hitTime)=="number", TYPE_ERR_STR:format("hitTime", "number", typeof(hitTime)))
	assert(typeof(hitPosition)=="Vector3", TYPE_ERR_STR:format("hitPosition", "Vector3", typeof(hitPosition)))
	assert(typeof(hitPart)=="Instance", TYPE_ERR_STR:format("hitPart", "Instance", typeof(hitPart)))
	assert(typeof(hitPartPosition)=="Vector3", TYPE_ERR_STR:format("hitPartPosition", "Vector3", typeof(hitPartPosition)))
	
	if player == targetPlayer then warn("player == targetPlayer") return end
	if CurrentShots[player] == nil then warn("Player has no CurrentShots table") return end
	
	local shotData = CurrentShots[player][shotId]
	if shotData == nil then warn(shotId, "doesn't exist") return end
	
	local weaponData = PlayersData[player.UserId].currentWeapon
	if weaponData == nil then warn("Weapon data doesn't exist") return end
	
	if not DISABLE_ANTI_CHEAT and tick() <= hitTime then warn("HitTime is >= server tick") return end
	
	local targetCharacter = targetPlayer.Character
	if targetCharacter == nil or not targetCharacter:IsAncestorOf(hitPart) then return end 

	CurrentShots[player][shotId] = nil
	
	local shotTime, origin, directionData = unpack(shotData)
	local playerPositions, targetPositions = CharactersPositions[player], CharactersPositions[targetPlayer]
	--[[
	local correctedHitTime, hitTimeIdx
	do
		local curMinDiff, minDiffIdx = 1, 0
		for i, posData in ipairs(playerPositions) do
			local diff = math.abs(posData[1] - hitTime)
			if diff <= curMinDiff then
				curMinDiff = diff
				minDiffIdx = i
			end
		end
		correctedHitTime = playerPositions[minDiffIdx][1]
		hitTimeIdx = minDiffIdx
	end
	--]]
	local partNameIdx
	do
		for i, partName in ipairs(TrackedCharacterParts) do
			if hitPart.Name == partName then partNameIdx = i break end
		end
		if partNameIdx == nil then warn("Couldn't find a part with name", hitPart.Name) return end
	end
	
	local thenTargetPositions
	do
		local curMinDiff, minDiffIdx = 99, 0
		for i, posData in ipairs(targetPositions) do
			if posData[1] > hitTime then break end
			local diff = (posData[2][partNameIdx] - hitPartPosition).Magnitude
			if curMinDiff > diff then
				curMinDiff = diff
				minDiffIdx = i
			end
		end
		if minDiffIdx == 0 then
			warn("Passed time position without finding intended target part position")
			return
		elseif not DISABLE_ANTI_CHEAT and curMinDiff >= 1 then
			warn("Diff between target position and recorded position is too big", curMinDiff)
			return
		else
			print("Found acceptable position with mag diff of", curMinDiff)
			thenTargetPositions = targetPositions[2]
		end
	end
	
	-- Part size magnitude should techincally be half but this is acceptable
	if not DISABLE_ANTI_CHEAT and (hitPartPosition - hitPosition).Magnitude > hitPart.Size.Magnitude then
		warn("Diff between then part position and hitPosition is too big", (hitPartPosition - hitPosition).Magnitude)
		return
	end
	
	--[[
	local thenPlayerPos
	do
		local function getPos(t)
			for i, posData in ipairs(t) do
				if posData[1] == correctedHitTime then
					return posData
				end
			end
		end
		thenPlayerPos = getPos(playerPositions)
		thenTargetPos = getPos(targetPositions)
	end
	--]]
	
	local newFilterList = copyArray(raycastFilter, #raycastFilter + #Players:GetPlayers() + MaxHitRaycast)
	for _, v in ipairs(Players:GetPlayers()) do
		if v.Character then
			newFilterList[#newFilterList+1] = v.Character
		end
	end
	--newFilterList[#newFilterList+1] = player.Character
	--newFilterList[#newFilterList+1] = targetPlayer.Character
	
	local params = weaponData.rayParams
	params.FilterDescendantsInstances = newFilterList
	
	--for _, orgDir in ipairs(allDirections) do
	local lastOrg = origin
	local newDir = (hitPosition - origin)
	local result = workspace:Raycast(origin, newDir, params)
	local targetDistance = newDir.Magnitude
	local distanceCovered = result == nil and targetDistance or 0
	local currentTries = 0
	while result
		and (result.Instance.Transparency >= BulletPierceTransparencyThreshold and result.Instance.Name ~= "HumanoidRootPart")
		and distanceCovered < targetDistance
		and currentTries <= MaxHitRaycast
	do
		newFilterList[#newFilterList+1] = result.Instance
		params.FilterDescendantsInstances = newFilterList
		lastOrg = result.Position
		result = workspace:Raycast(result.Position, (hitPosition - result.Position), params)
		if result then
			distanceCovered = distanceCovered + (result.Position - lastOrg).Magnitude
		else
			distanceCovered = targetDistance
		end
		currentTries += 1
	end
	
	local isSuccessful = result == nil and math.abs(targetDistance-distanceCovered) <= 0.1
	
	if isSuccessful then
		doPlayerDamage(player, targetPlayer, hitPart, weaponData.settings)
	end
	
	print(isSuccessful, currentTries, distanceCovered, targetDistance, result and result.Instance)
	--end
end)

FPSService.Client.PlaySoundEvent:Connect(function(player, name)
	if typeof(name) ~= "string" then return end
	local weaponData = PlayersData[player.UserId].currentWeapon
	if not weaponData then return end
	if not weaponData.weapon then error(player.Name .. "'s " .. weaponData.name .. " doesnt exist on server") return end
	local weaponSettings = weaponData.settings
	
	local animationEvents = weaponSettings.animationEventsSounds
	
	local reloadData = (animationEvents.reload and animationEvents.reload[name])
		or (animationEvents.reloadDown and animationEvents.reloadDown[name])
		or (animationEvents.reloadUp and animationEvents.reloadUp[name])
		or (animationEvents.reloadBulletInsert and animationEvents.reloadBulletInsert[name])
	
	if reloadData then
		if weaponData.object.isReloading then
			local sound = reloadData[math.random(1, #reloadData)]
			FPSService.Client.PlaySoundEvent:FireExcept(player, player, sound, weaponData.weapon)
		else
			print("FPSService.PlaySoundEvent Requested Reload sound but isn't reloading")
		end
	else
		print("FPSService.PlaySoundEvent Couldn't identify where",name,"'s sounds are")
	end
end)

function FPSService:GetIgnoreList()
	return raycastFilter
end

function FPSService:PrintIgnoreList()
	print(raycastFilter)
end

function FPSService.Client:GetIgnoreList()
	return raycastFilter
end

function FPSService:AddToIgnoreList(inst)
	CollectionService:AddTag(inst, GlobalFastCastIgnoreTag)
end

function FPSService:KnitInit()
	CharacterEditorService = Knit.Services["CharacterEditorService"]
	TransactionService = Knit.Services["TransactionService"]
	TeamRulesService = Knit.Services["TeamRulesService"]
	ProfileService = Knit.Services["ProfileService"]
	ToolService = Knit.Services["ToolService"]
	ItemService = Knit.Services["ItemService"]
	
	self.Client.TrackedCharacterParts:Replicate()
end

function FPSService:KnitStart()
	TimeSync:Initialize()

	RunService.Heartbeat:Connect(self.OnHeartbeat)
	RunService.PreSimulation:Connect(self.OnPreSimulation)

	for _, player in pairs(Players:GetPlayers()) do
		Thread.Spawn(function()
			playerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		playerAdded(player)
	end)
	--[
	CharacterEditorService.OnAvatarSetChange:Connect(function(player, avatarSetNumber)
		if PlayersData[player.UserId] and PlayersData[player.UserId].weapons then
			for weaponName, weaponData in pairs(PlayersData[player.UserId].weapons) do
				local oldSetNumber = weaponData.avatarSetNumber --[[
				if oldSetNumber ~= avatarSetNumber then
					local customisationData = getCustomisationData(player, weaponName)
					self:ChangeWeaponSkin(player, weaponName, customisationData.Skin)
					self:RemoveAllWeaponStickers(player, weaponName)
					for _, stickerName in ipairs(customisationData.Stickers) do
						self:AddWeaponSticker(player, weaponName, stickerName)
					end
					if customisationData.Charm then
						self:ChangeWeaponCharm(player, weaponName, customisationData.Charm, false)
					end
				end--]]
			end
		end
	end)
	--]]
end

function FPSService.OnHeartbeat(dt)
	for _, player in pairs(Players:GetPlayers()) do
		local weaponsTable = PlayersData[player.UserId]
		if weaponsTable then
			for name, data in pairs(weaponsTable.weapons) do
				data.object:Update(dt)
			end
		end
		--local weaponData = weaponTable.weapons[wepName]
	end
end

function FPSService.OnPreSimulation(dt)
	SyncedNow = tick()
end

return FPSService