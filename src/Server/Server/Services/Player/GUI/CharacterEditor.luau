local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ServerStorage = game:GetService("ServerStorage")
local ItemStorage = ServerStorage.GameItems
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local KnitSignal = require(Knit.Util.Signal)
local ProfileService = false

local GunFrameworkData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameData"):WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))

local OutfitDisplayTemp = script.OutfitDisplayTemp:Clone()

local CharacterEditorService = Knit.CreateService({
	Name = "CharacterEditorService",
	Ready = false,
	LoadMenuAvatar = KnitSignal.new(),
	PurchasedSlot = KnitSignal.new(),
	
	OnAvatarSetChange = KnitSignal.new();
	
	Client = {
		OnFaceChange = RemoteSignal.new(), 
		OnHairChange = RemoteSignal.new(), 
		OnAccessoryChange = RemoteSignal.new(),
		OnOutfitChange = RemoteSignal.new(),
		OnSkinToneChange = RemoteSignal.new(), 
		OnWeaponChange = RemoteSignal.new(),
		OnAvatarSetChange = RemoteSignal.new(),
		OnUpdateSlotsOwned = RemoteSignal.new(),
	},

	TemporaryAvatar = {},
	OriginalAvatar = {},
})

function CharacterEditorService.Client:ChangeFace(player, itemId)
	return CharacterEditorService:ChangeFace(player, itemId, nil, true)
end

function CharacterEditorService.Client:ChangeSkinTone(player, itemId)
	return CharacterEditorService:ChangeSkinTone(player, itemId, nil, true)
end

function CharacterEditorService.Client:ChangeHair(player, itemId)
	return CharacterEditorService:ChangeHair(player, itemId, nil, true)
end

function CharacterEditorService.Client:ChangeOutfit(player, itemId)
	return CharacterEditorService:ChangeOutfit(player, itemId, nil, true)
end

function CharacterEditorService.Client:ChangeAccessory(player, itemId)
	return CharacterEditorService:ChangeAccessory(player, itemId, nil, true)
end

function CharacterEditorService.Client:ChangeAvatarSet(player, avatarSet)
	return CharacterEditorService:ChangeAvatarSet(player, avatarSet)
end

CharacterEditorService.LoadMenuAvatar:Connect(function(character, avatarSetData)
	repeat wait() until CharacterEditorService.Ready == true
	CharacterEditorService:LoadNPCSet(character, avatarSetData)
end)

CharacterEditorService.PurchasedSlot:Connect(function(player, slots)
	CharacterEditorService.Client.OnUpdateSlotsOwned:Fire(player)
end)

function CharacterEditorService:KnitStart()
	ProfileService = Knit.Services.ProfileService
	local ItemService = Knit.Services.ItemService
	local NotificationService	= Knit.Services.NotificationService;
	local LevelService	= Knit.Services.LevelService;
	local DeveloperProductService = Knit.Services.DeveloperProductService;
	local BundleService = Knit.Services.BundleService;
	local GamepassService = Knit.Services.GamepassService;
	local FPSService = Knit.Services.FPSService;
	
	local DefaultSets = {
		["Class - D"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },
		["Security Department"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },
		["Engineering and Technical"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },
		["Chaos Insurgency"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },
		["Scientific Department"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
		["Mobile Task Force"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
		["Site Director"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Site Director", Accessories = {}, Weapon = "Default"  },
		["O5 Council"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
		["Global Occult Coalition"] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Site Director", Accessories = {}, Weapon = "Default"  },	
	}

	function CharacterEditorService:GetAvatarData(player)
		local profile = ProfileService:GetProfile(player)
		local team = player.Team
		local teamId = team.Id.Value
		local avatarSetNumber = profile.CurrentAvatarSet[teamId]
		local avatarSetData = profile.AvatarSets[teamId][avatarSetNumber]
		--print("AVATAR SET NUMBER", avatarSetNumber)
		return {
			Profile = profile,
			Team = team,
			TeamId = teamId,
			AvatarSetNumber = avatarSetNumber,
			AvatarSetData = avatarSetData
		}
	end

	function CharacterEditorService:GetAvatarSet(player)
		if self.TemporaryAvatar[player.Name] then
			return self.TemporaryAvatar[player.Name]
		else
			return self.OriginalAvatar[player.Name]
		end
	end

	function CharacterEditorService:LoadAvatarSet(player)
		--print("LOADING OUTFIT FOR", player)
		local profile = ProfileService:GetProfile(player)
		local team = player.Team
		local teamId = team.Id.Value
		local avatarSetNumber = profile.CurrentAvatarSet[teamId]
		if avatarSetNumber == nil then
			profile.CurrentAvatarSet[teamId] = 1
			avatarSetNumber = 1
		end
		if profile.AvatarSets[teamId] == nil then return end 
		if profile.AvatarSets[teamId][avatarSetNumber] == nil then 
			profile.AvatarSets[teamId][avatarSetNumber] = {}
			for key, value in pairs(DefaultSets[teamId]) do 
				profile.AvatarSets[teamId][avatarSetNumber][key] = value
			end
			profile.AvatarSets[teamId][avatarSetNumber].Accessories = {}
		end
		
		local avatarSetData = profile.AvatarSets[teamId][avatarSetNumber]
		for _, component in pairs(player.Character:GetChildren()) do
			if component:IsA("Accessory") then
				component:Destroy()
			end
		end
		for avatarComponent, itemId in pairs(avatarSetData) do
			if avatarComponent == "Face" then
				local save = false
				if itemId == "Random" then
					itemId = ItemService:GetRandomFace()
					save = true
				end
				CharacterEditorService:ChangeFace(player, itemId, nil, save)

			elseif avatarComponent == "Hair" then
				local save = false
				if itemId == "Random" then
					itemId = ItemService:GetRandomHair()
					save = true
				end
				CharacterEditorService:ChangeHair(player, itemId, nil, save)

			elseif avatarComponent == "SkinTone" then
				local save = false
				if itemId == "Random" then
					itemId = ItemService:GetRandomSkinTone()
					save = true
				end
				CharacterEditorService:ChangeSkinTone(player, itemId, nil, save)

			elseif avatarComponent == "Accessories" then
				local accessoriesList = itemId
				for _, accessoryId in pairs(accessoriesList) do
					CharacterEditorService:ChangeAccessory(player, accessoryId, nil, false)
				end

			elseif avatarComponent == "Outfit" then
				CharacterEditorService:ChangeOutfit(player, itemId, nil, false)	
			end
		end
	end

	function CharacterEditorService:LoadNPCSet(character, avatarSetData)
		for _, component in pairs(character:GetChildren()) do
			if component:IsA("Accessory") then
				component:Destroy()
			end
		end
		for avatarComponent, itemId in pairs(avatarSetData) do
			if avatarComponent == "Face" then
				if itemId == "Random" then
					itemId = ItemService:GetRandomFace()
				end
				CharacterEditorService:ChangeFace(nil, itemId, character)

			elseif avatarComponent == "Hair" then
				if itemId == "Random" then
					itemId = ItemService:GetRandomHair()
				end
				CharacterEditorService:ChangeHair(nil, itemId, character)

			elseif avatarComponent == "SkinTone" then
				if itemId == "Random" then
					itemId = ItemService:GetRandomSkinTone()
				end
				CharacterEditorService:ChangeSkinTone(nil, itemId, character)
				
			elseif avatarComponent == "Accessories" then
				local accessoriesList = itemId
				for _, accessoryId in pairs(accessoriesList) do
					CharacterEditorService:ChangeAccessory(nil, accessoryId, character, false)
				end
				
			elseif avatarComponent == "Outfit" then
				CharacterEditorService:ChangeOutfit(nil, itemId, character)	
			end
		end
	end

	function CharacterEditorService:SaveChange(player, category, itemId)
		local profile = ProfileService:GetProfile(player)
		local team = player.Team
		local teamId = team.Id.Value
		local avatarSetNumber = profile.CurrentAvatarSet[teamId]
		local avatarSetData = profile.AvatarSets[teamId][avatarSetNumber]
		if category ~= "Accessories" then
			avatarSetData[category] = itemId
		end
	end




	function CharacterEditorService:ChangeAvatarSet(player, avatarSet)
		local profile = ProfileService:GetProfile(player)
		local team = player.Team
		local teamId = team.Id.Value
		local purchasedCharacterSlots = profile.PurchasedCharacterSlots
		local totalOwnedSlots = purchasedCharacterSlots + 3
		print("SLOT", totalOwnedSlots, avatarSet)
		if totalOwnedSlots >= avatarSet == false then 
			DeveloperProductService:Prompt(player, "+1 Avatar Slot")
			return false
		else
			if profile.AvatarSets[teamId] == nil then return end 
			if profile.AvatarSets[teamId][avatarSet] == nil then 
				profile.AvatarSets[teamId][avatarSet] = {}
				for key, value in pairs(DefaultSets[teamId]) do 
					profile.AvatarSets[teamId][avatarSet][key] = value
				end
				profile.AvatarSets[teamId][avatarSet].Accessories = {}
			end
			profile.CurrentAvatarSet[teamId] = avatarSet
			CharacterEditorService:LoadAvatarSet(player)
			CharacterEditorService.OnAvatarSetChange:Fire(player, avatarSet)
			CharacterEditorService.Client.OnAvatarSetChange:Fire(player, avatarSet)
			return true
		end
	end

	function CharacterEditorService:ChangeFace(player, itemId, character, save)
		local itemData = ItemService:GetFace(itemId)
		local character = character or player.Character
		character.Head.face.Texture = "rbxthumb://type=Asset&id="..itemData.Id.."&w=150&h=150"
		if player then
			if save then
				CharacterEditorService:SaveChange(player, "Face", itemId)
			end
			CharacterEditorService.Client.OnFaceChange:Fire(player, itemId)
		end
	end

	function CharacterEditorService:ChangeSkinTone(player, itemId, character, save)
		local itemData = ItemService:GetSkinTone(itemId)
		local skinObject = itemData.Object:Clone()
		local character = character or player.Character
		local findExistingSkin = character:FindFirstChildOfClass("BodyColors")
		if findExistingSkin then findExistingSkin:Destroy() end
		skinObject.Parent = character
		if player then
			if save then
				CharacterEditorService:SaveChange(player, "SkinTone", itemId)
			end
			CharacterEditorService.Client.OnSkinToneChange:Fire(player, itemId)
		end
	end

	function CharacterEditorService:loadObject(itemId, itemData, character, category, avatarSetData, player, save)
		local findObj = character:FindFirstChild(itemId)
		if findObj then 
			findObj:Destroy()
			if save and category == "Accessory" then
				for pos, accessory_itemId in pairs(avatarSetData.Accessories) do
					if accessory_itemId == itemId then
						CharacterEditorService.Client.OnAccessoryChange:Fire(player, itemId)
						table.remove(avatarSetData.Accessories, pos)
					end
				end
			end
			if itemId ~= "Hair" then
				return true
			end
		end

		if save and category == "Accessory" then
			local accessoriesInSet = avatarSetData.Accessories
			if #accessoriesInSet >= 9 then
				return NotificationService:ShowNotification(player, 3, "You are only allowed up to 9 accessories!", Color3.fromRGB(255, 0, 0))
			end
			table.insert(avatarSetData.Accessories, itemId)
			CharacterEditorService.Client.OnAccessoryChange:Fire(player, itemId)
		end

		local obj = itemData.Object:Clone()
		obj.Parent = character
		obj.Name = itemId
		game:GetService("CollectionService"):AddTag(obj, "VisionBlacklist");

	end

	function CharacterEditorService:ChangeHair(player, itemId, character, save)
		local itemData = ItemService:GetHair(itemId)
		local hairObject = itemData.Object:Clone()
		local character = character or player.Character

		if player then
			local profile = ProfileService:GetProfile(player)
			local playerLevel = LevelService:GetLevel(player, player.Team.Name)
			if itemData.Level ~= nil and playerLevel < itemData.Level then
				NotificationService:ShowNotification(player, 3, "You need to be LEVEL "..itemData.Level.. " to wear this.", Color3.fromRGB(255, 0, 0))
			else
				CharacterEditorService.Client.OnHairChange:Fire(player, itemId)
				CharacterEditorService:SaveChange(player, "Hair", itemId)
				CharacterEditorService:loadObject("Hair", itemData, character)
			end
		else
			CharacterEditorService:loadObject("Hair", itemData, character)
		end
	end

	function CharacterEditorService:ChangeAccessory(player, itemId, character, save)
		local character = character or player.Character
		local itemData = ItemService:GetAccessory(itemId)

		if player then
			local data = CharacterEditorService:GetAvatarData(player) 
			local avatarSetData = data.AvatarSetData
			local playerLevel = LevelService:GetLevel(player, player.Team.Name)
			if itemData.Level ~= nil and playerLevel < itemData.Level then
				NotificationService:ShowNotification(player, 3, "You need to be LEVEL "..itemData.Level.. " to wear this.", Color3.fromRGB(255, 0, 0))
			elseif itemData.Gamepass ~= nil then
				local gamepassName = itemData.Gamepass
				local hasGamepass = GamepassService:HasGamepass(player, itemData.Gamepass)
				local rank = player:GetRankInGroup(4889827)
				if rank < 9 then -- Not an admin
					if hasGamepass then
						CharacterEditorService:loadObject(itemId, itemData, character, "Accessory", avatarSetData, player, save)
					else
						BundleService:Prompt(player, gamepassName)
					end
				else
					CharacterEditorService:loadObject(itemId, itemData, character, "Accessory", avatarSetData, player, save)
				end
				

			else
				CharacterEditorService:loadObject(itemId, itemData, character, "Accessory", avatarSetData, player, save)
			end
		else
			CharacterEditorService:loadObject(itemId, itemData, character)
		end
	end

	function CharacterEditorService:loadOutfit(itemData, character)
		local shirtObject = character:FindFirstChildOfClass("Shirt")
		local pantsObject = character:FindFirstChildOfClass("Pants")
		shirtObject.ShirtTemplate = "http://www.roblox.com/asset/?id="..itemData.Shirt
		pantsObject.PantsTemplate = "http://www.roblox.com/asset/?id="..itemData.Pants
	end

	function CharacterEditorService:ChangeOutfit(player, itemId, character)
		local itemData = ItemService:GetOutfit(itemId)
		local character = character or player.Character
		if player then
			local profile = ProfileService:GetProfile(player)
			local playerLevel = LevelService:GetLevel(player, player.Team.Name)
			if itemData.Level ~= nil and playerLevel < itemData.Level then
				NotificationService:ShowNotification(player, 3, "You need to be LEVEL "..itemData.Level.. " to wear this.", Color3.fromRGB(255, 0, 0))
			else
				CharacterEditorService:loadOutfit(itemData, character)
				CharacterEditorService.Client.OnOutfitChange:Fire(player, itemId)
				CharacterEditorService:SaveChange(player, "Outfit", itemId)
			end
		else
			CharacterEditorService:loadOutfit(itemData, character)
		end
	end

	function CharacterEditorService:ChangeWeaponSkin(player, weaponName, itemId, save)
		local weaponModel = FPSService:GetWeaponModel(player, weaponName)
		
		local skinData = ItemService:GetWeaponSkin(itemId)
		
		--local skinData = GunFrameworkData.weaponSkins[weaponName][itemId]
		assert(skinData, "FPSService:ChangeWeaponSkin Couldn't find " .. weaponName .. "'s " .. skinData .. " skin")

		if weaponModel then
			for partName, partData in pairs(skinData) do
				local part = weaponModel:FindFirstChild(partName, true)
				for property, value in pairs(partData) do
					part[property] = value
				end
			end
		end
	end

	ProfileService.CharacterAdded:Connect(function(player, character)
		Instance.new("Shirt", character)
		Instance.new("Pants", character)
		CharacterEditorService:LoadAvatarSet(player)
		--self:ChangeFace(player, "Err")
		--self:ChangeSkinTone(player, "Ivory")
		--self:ChangeHair(player, "Blonde Hair w/ White Cap")
	end)


	CharacterEditorService.Ready = true
end

return CharacterEditorService
