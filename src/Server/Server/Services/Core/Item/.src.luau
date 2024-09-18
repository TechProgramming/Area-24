local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Thread = require(Knit.Util.Thread)

local MarketplaceService	= game:GetService("MarketplaceService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local ServerStorage			= game:GetService("ServerStorage")
local InsertService			= game:GetService("InsertService")
local PlayersService		= game:GetService("Players")
local PhysicsService		= game:GetService("PhysicsService")

local ItemStorage = ServerStorage.GameItems

local ProfileService = false

local ItemService = Knit.CreateService({
	Name = "ItemService"
})

ItemService.ItemStorage = ItemStorage

local ItemsFolder = Instance.new("Folder", ReplicatedStorage)
ItemsFolder.Name = "ItemsFolder"

-- https://devforum.roblox.com/t/api-method-to-easily-get-the-properties-of-an-object/7536/43
-- Fuck you Roblox. Fuck you.
local WeaponSkinDynamicProperties = {
	"Reflectance"; "Color"; "Material"; "TextureID";
}
local WeaponSkinIgnoredNames = {
	"CharmHolder";
}

--[[

	INJECTED:
		- Description
		- IconImageAssetId
		- IsForSale
		- Name
		- PriceInRobux
		- ProductId
		- ProductType
		- TargetId

]]

ItemService.SkinTonesArray = {}
ItemService.SkinTones = require(script.SkinTones)

ItemService.FacesArray = {}
ItemService.Faces = require(script.Faces)

ItemService.AccessoriesArray = {}
ItemService.Accessories = require(script.Accessories)
	
ItemService.HairsArray = {}
ItemService.Hairs = require(script.Hairs)

ItemService.OutfitsArray = {}
ItemService.OutfitsByTeam = {}
ItemService.Outfits = require(script.Outfits)

ItemService.FoodArray = {}
ItemService.FoodByCategory = {}
ItemService.Food = {}

ItemService.WeaponSkins = {}
ItemService.WeaponStickers = {}
ItemService.WeaponCharms = {}

ItemService.Gamepasses =
{
	["LegacyEngineer"] = {
		Id = 7831190,
	},	
} 

ItemService.DevProducts =
{
	["100 Cash"] = {
		Id = 1167519935,
		Cash = 100
	},
	["50 Cash"] = {
		Id = 1167516395,
		Cash = 50
	},	
}

ItemService.GameItems =
{
	["Level 4 Access Card"] = {
		TeamWhitelist = {
			["Class - D"] = true,
			["Chaos Insurgency"] = true
		},
		DisplayName = "Level 4 Access Card",
		Category = "Misc",
		Price = 500,
		ForSale = true,
		Visible = true,
		CDCShop = true
	},
	--["Screwdriver"] = {
	--	DisplayName = "Screwdriver",
	--	Category = "Tool",
	--	Object = ItemStorage.Tools.Screwdriver,
	--	ImageId = 5565923014,
	--	Price = 10,
	--	ForSale = true,
	--	Visible = true,
	--},
	--["Riot"] = {
	--	TeamWhitelist = {
	--		["Class - D"] = true,
	--		["Chaos Insurgency"] = true
	--	},
	--	EventCooldown = {
	--		"Riot"
	--	},
	--	DisplayName = "Riot",
	--	Category = "Event",
	--	Price = 10,
	--	ForSale = true,
	--	Visible = true,
	--	CDCShop = true
	--},
	["25 Cash Award"] = {
		DisplayName = "25 Cash",
		Category = "Currency",
		ForSale = false,
		Visible = true,
	},
	["50 Cash Award"] = {
		DisplayName = "50 Cash",
		Category = "Currency",
		ForSale = false,
		Visible = true,
	},	
	["75 Cash Award"] = {
		DisplayName = "75 Cash",
		Category = "Currency",
		ForSale = false,
		Visible = true,
	},
	["100 Cash Award"] = {
		DisplayName = "100 Cash",
		Category = "Currency",
		ForSale = false,
		Visible = true,
	},	
	["120 Cash Award"] = {
		DisplayName = "120 Cash",
		Category = "Currency",
		ForSale = false,
		Visible = true,
	},
};

ItemService.DevProductByRobloxId = {} -- SCRIPT POPULATED
ItemService.GamepassByRobloxId = {} -- SCRIPT POPULATED

function ItemService.Client:GetItem(player, itemId)
	return ItemService:GetItem(itemId)
end

function ItemService.Client:GetDevProduct(player, itemId)
	return ItemService:GetDevProduct(itemId)
end

function ItemService.Client:GetGamepass(player, itemId)
	return ItemService:GetGamepass(itemId)
end

function ItemService.Client:GetFace(player, itemId)
	return ItemService:GetFace(itemId)
end

function ItemService.Client:GetSkinTone(player, itemId)
	return ItemService:GetSkinTone(itemId)
end

function ItemService.Client:GetHair(player, itemId)
	return ItemService:GetHair(itemId)
end

function ItemService.Client:GetOutfit(player, itemId)
	return ItemService:GetOutfit(itemId)
end

function ItemService.Client:GetAccessory(player, itemId)
	return ItemService:GetAccessory(itemId)
end

function ItemService.Client:GetFood(player, itemId)
	return ItemService:GetFood(itemId)
end

---

function ItemService.Client:GetItems()
	return ItemService:GetItems()
end

function ItemService.Client:GetDevProducts()
	return ItemService:GetDevProducts()
end

function ItemService.Client:GetGamepasses()
	return ItemService:GetGamepasses()
end

function ItemService.Client:GetFaces()
	return ItemService:GetFaces()
end

function ItemService.Client:GetSkinTones()
	return ItemService:GetSkinTones()
end

function ItemService.Client:GetHairs()
	return ItemService:GetHairs()
end

function ItemService.Client:GetOutfits(player, teamName)
	return ItemService:GetOutfits(teamName)
end

function ItemService.Client:GetAccessories()
	return ItemService:GetAccessories()
end

function ItemService.Client:GetFoods(player, category)
	return ItemService:GetFoods(category)
end
---

function ItemService:GetItem(itemId)
	return ItemService.GameItems[itemId]
end

function ItemService:GetDevProduct(itemId)
	return ItemService.DevProducts[itemId]
end

function ItemService:GetGamepass(itemId)
	return ItemService.Gamepasses[itemId]
end

function ItemService:GetFace(itemId)
	return ItemService.Faces[itemId]
end

function ItemService:GetSkinTone(itemId)
	return ItemService.SkinTones[itemId]
end

function ItemService:GetHair(itemId)
	return ItemService.Hairs[itemId]
end

function ItemService:GetOutfit(itemId)
	return ItemService.Outfits[itemId]
end

function ItemService:GetAccessory(itemId)
	return ItemService.Accessories[itemId]
end

function ItemService:GetFood(itemId)
	return ItemService.GetFood[itemId]
end

function ItemService:GetWeaponSkin(weaponName, skinName)
	--return ItemService.GameItems[weaponName .. "_" .. itemId]
	return ItemService.WeaponSkins[weaponName][skinName]
end

function ItemService:GetWeaponSticker(weaponName, stickerName)
	--return ItemService.GameItems[weaponName .. "_" .. itemId]
	return ItemService.WeaponStickers[weaponName][stickerName]
end

function ItemService:GetWeaponCharm(weaponName, charmName)
	--return ItemService.GameItems[weaponName .. "_" .. itemId]
	return ItemService.WeaponCharms[weaponName][charmName]
end
---

function ItemService:GetItems()
	return ItemService.GameItems
end

function ItemService:GetDevProducts()
	return ItemService.DevProducts
end

function ItemService:GetGamepasses()
	return ItemService.Gamepasses
end

function ItemService:GetFaces()
	return ItemService.Faces
end

function ItemService:GetSkinTones()
	return ItemService.SkinTones
end

function ItemService:GetHairs()
	return ItemService.Hairs
end

function ItemService:GetFoods(foodCategory)
	if foodCategory == nil then
		return ItemService.Food
	else
		return ItemService.FoodByCategory[foodCategory]
	end
end

function ItemService:GetOutfits(teamName)
	
	if not teamName then
		return ItemService.Outfits
	else
		return ItemService.OutfitsByTeam[teamName]
	end;
end

function ItemService:GetAccessories()
	return ItemService.Accessories
end

-----

function ItemService:GetRandomHair()
	local num = math.random(1, #ItemService.HairsArray)
	return ItemService.HairsArray[num]
end

function ItemService:GetRandomFace()
	local num = math.random(1, #ItemService.FacesArray)
	return ItemService.FacesArray[num]
end

function ItemService:GetRandomSkinTone()
	local num = math.random(1, #ItemService.SkinTonesArray)
	return ItemService.SkinTonesArray[num]
end

-----

function ItemService:GetDevProductByRobloxId(assetId)
	return ItemService.DevProductByRobloxId[assetId]
end

function ItemService:GetGamepassByRobloxId(assetId)
	return ItemService.GamepassByRobloxId[assetId]
end

function ItemService:UpdateGamepasses()
	
	for _, itemData in pairs(ItemService.Gamepasses) do
		
		local productData = MarketplaceService:GetProductInfo(itemData.Id, Enum.InfoType.GamePass)
		for key, value in pairs(productData) do
			itemData[key] = value
		end
	end
end

function ItemService:UpdateDevProducts()
	
	for _, itemData in pairs(ItemService.DevProducts) do
		
		local productData = MarketplaceService:GetProductInfo(itemData.Id, Enum.InfoType.Product)
		for key, value in pairs(productData) do
			itemData[key] = value
		end
	end
end

function ItemService:KnitStart()

	ProfileService = Knit.Services.ProfileService
	--local TransactionService = Knit.Services.TransactionService

	local InsertService = game:GetService("InsertService")

	for itemId, itemData in pairs(ItemService.DevProducts) do
		ItemService.DevProductByRobloxId[itemData.Id] = itemId
	end
	for itemId, itemData in pairs(ItemService.Gamepasses) do
		ItemService.GamepassByRobloxId[itemData.Id] = itemId
	end
	for itemId, itemData in pairs(ItemService.Faces) do
		table.insert(ItemService.FacesArray, itemId)
	end
	for itemId, itemData in pairs(ItemService.SkinTones) do

		local skinObj = script.SkinTone:Clone()
		skinObj.HeadColor3 = itemData.Color
		skinObj.LeftArmColor3 = itemData.Color
		skinObj.RightArmColor3 = itemData.Color
		skinObj.LeftLegColor3 = itemData.Color
		skinObj.RightLegColor3 = itemData.Color	
		skinObj.TorsoColor3 = itemData.Color
		itemData.Object = skinObj
		table.insert(ItemService.SkinTonesArray, itemId)
	end
	
	local hairModels = workspace.Scripted.Hairs:GetChildren()
	workspace.Scripted.Hairs.Parent = game.ReplicatedStorage
	
	local accessoryModels = workspace.Scripted.Accessories:GetChildren()
	workspace.Scripted.Accessories.Parent = game.ReplicatedStorage
	
	local foodModels = ReplicatedStorage.Food:GetChildren()
	--workspace.Scripted.Food.Parent = game.ReplicatedStorage
	
	local gearModels = workspace.Scripted.Gear:GetChildren()
	workspace.Scripted.Gear.Parent = game.ReplicatedStorage
	
	local weaponModels = workspace.Scripted.Weapons:GetChildren()
	--workspace.Scripted.Weapons.Parent = game.ReplicatedStorage
	
	local weaponSkins = workspace:WaitForChild("Scripted"):WaitForChild("WeaponSkins"):GetChildren()
	
	local outfitModels = workspace.Scripted.Outfits:GetChildren()
	
	for _, hairObject in pairs(hairModels) do
		hairObject.Handle.Anchored = false
		--if not hairObject then
		--	local model = InsertService:LoadAsset(itemData.Id)
		--	hairObject = model:GetChildren()[1]
		--	hairObject.Parent = ServerStorage.Hairs
		--	hairObject.Name = itemId
		--end
		ItemService.Hairs[hairObject.Name] = {
			DisplayName = hairObject:GetAttribute("DisplayName"),
			Id = hairObject:GetAttribute("Id"),
			Usable = hairObject:GetAttribute("Usable"),
			Level = hairObject:GetAttribute("Level"),
			Object = hairObject:Clone()
		}
		
		table.insert(ItemService.HairsArray, hairObject.Name)
	end

	
	for _, hatObject in pairs(accessoryModels) do
		hatObject.Handle.Anchored = false
		--local hatObject = ServerStorage.Accessories:FindFirstChild(itemId);

		--if not hatObject then
		--	local model = InsertService:LoadAsset(itemData.Id)
		--	hatObject = model:GetChildren()[1]
		--	hatObject.Parent = ServerStorage.Accessories
		--	hatObject.Name = itemId
		--end
		ItemService.Accessories[hatObject.Name] = {
			DisplayName = hatObject:GetAttribute("DisplayName"),
			Id = hatObject:GetAttribute("Id"),
			Usable = hatObject:GetAttribute("Usable"),
			Level = hatObject:GetAttribute("Level"),
			Gamepass = hatObject:GetAttribute("Gamepass"),
			Object = hatObject:Clone()
		}

		table.insert(ItemService.AccessoriesArray, hatObject.Name)
	end
	
	local siteDirectorOutfits = {
		'Security Department',
		'Mobile Task Force',
		'Engineering and Technical',
		'Scientific Department'
	}
	
	local o5DirectorOutfits = {
		'Security Department',
		'Mobile Task Force',
		'Engineering and Technical',
		'Scientific Department',
		'Site Director'
	}

	
	for _, team in pairs(outfitModels) do
		--["Scientist"] = {
		--	Shirt = 6485166220,
		--	Pants = 6485168597,
		--	Team = "Scientist Department",
		--	Level = 0
		--},

		for _, outfit in pairs(team:GetChildren()) do
			--print("Shut the fuck up", string.gsub(outfit.Shirt.ShirtTemplate)
			local shirtId = string.match(outfit.Shirt.ShirtTemplate, "%d+") or "0"
			local pantsId = string.match(outfit.Pants.PantsTemplate, "%d+") or "0"
			ItemService.Outfits[outfit.Name] =
				{
					Shirt = tonumber(shirtId),
					Pants = tonumber(pantsId),
					Level = outfit:GetAttribute("Level"),
					Team = team.Name
				}

			if not ItemService.OutfitsByTeam[team.Name] then
				ItemService.OutfitsByTeam[team.Name] = {}
			end
			ItemService.OutfitsByTeam[team.Name][outfit.Name] = ItemService.Outfits[outfit.Name]
		end
		
	end
	
	for _, teamName in pairs(siteDirectorOutfits) do
		local outfits = ItemService.OutfitsByTeam[teamName]
		for key, value in pairs(outfits) do
			ItemService.OutfitsByTeam["Site Director"][key] = value
		end
	end
	
	for _, teamName in pairs(o5DirectorOutfits) do
		local outfits = ItemService.OutfitsByTeam[teamName]
		for key, value in pairs(outfits) do
			ItemService.OutfitsByTeam["O5 Council"][key] = value
		end
	end
	
	for _, foodCategory in pairs(foodModels) do

		for _, foodSubCategory in pairs(foodCategory:GetChildren()) do
			for _, foodItem in pairs(foodSubCategory:GetChildren()) do
				
				local tool = Instance.new("Tool");
				tool.Name = foodItem.Name;
				tool.CanBeDropped = false;
				tool:SetAttribute("ToolType", "Food");
				
				local model = foodItem:Clone();
				model.PrimaryPart.Transparency = 1;
				
				local gripPos = model:GetAttribute("GripPos") or Vector3.new(0,0,0)
				tool.GripPos = gripPos
				tool:SetAttribute("ActionAnimation", model:GetAttribute("ActionAnimation"))
				
				for _, part in pairs(model:GetChildren()) do
					part.Parent = tool;
					part.Anchored = false;
				end;

				--model.Handle.Parent = tool
				ItemService.Food[foodItem.Name] = {
					DisplayName = foodItem.Name,
					ProcessType = "Tool",
					Category = foodCategory.Name,
					SubCategory = foodSubCategory.Name,
					Price = model:GetAttribute("Price") or 0,
					Model = foodItem:Clone(),
					Tool = tool:Clone()
				}	

				
				if ItemService.FoodByCategory[foodCategory.Name] == nil then
					ItemService.FoodByCategory[foodCategory.Name] = {}
				end

				ItemService.GameItems[foodItem.Name] = ItemService.Food[foodItem.Name]
				ItemService.FoodByCategory[foodCategory.Name][foodItem.Name] = ItemService.Food[foodItem.Name]
			end
		end
	end
	

	
	for _, gearItem in pairs(gearModels) do
		local tool = Instance.new("Tool")
		tool.Name = gearItem.Name
		tool.CanBeDropped = false
		tool:SetAttribute("ToolType", "Gear")
		local model = gearItem:Clone()
		model.Handle.Transparency = 1
		model.PrimaryPart = model.Handle
		tool.GripPos = model:GetAttribute("GripPos") or Vector3.new(0,0,0)
		--tool:SetAttribute("ActionAnimation", model:GetAttribute("ActionAnimation"))
		for _, object in pairs(model:GetChildren()) do
			object.Parent = tool
			if object.Name == "Handle" then
				object.Anchored = false
			end
		end

		--model.Handle.Parent = tool
			--["Screwdriver"] = {
	--	DisplayName = "Screwdriver",
	--	Category = "Tool",
	--	Object = ItemStorage.Tools.Screwdriver,
	--	ImageId = 5565923014,
	--	Price = 10,
	--	ForSale = true,
	--	Visible = true,
	--},
		ItemService.GameItems[gearItem.Name] = {
			DisplayName = gearItem.Name,
			ProcessType = "Tool",
			Category = "Tool",
			Price = model:GetAttribute("Price") or 0,
			ForSale = true,
			Visible = true,
			ImageId = 5565923014,
			Model = gearItem:Clone(),
			Tool = tool:Clone(),
			CDCShop = model:GetAttribute("CDCShop") or false
		}	

		--ItemService.GameItems[foodItem.Name] = ItemService.Food[foodItem.Name]
		--ItemService.FoodByCategory[foodCategory.Name][foodItem.Name] = ItemService.Food[foodItem.Name]
	end


	-- Weapon customisation
	local function FindFirstChildWhichIsA(inst, name, classname, recur)
		for _, v in ipairs(recur and inst:GetDescendants() or inst:GetChildren()) do
			if v.Name == name and v:IsA(classname) then return v end
		end
	end

	for _, originalModel in ipairs(weaponModels) do
		local weaponName = originalModel.Name

		ItemService.WeaponSkins[weaponName] = {}
		ItemService.WeaponStickers[weaponName] = {}
		ItemService.WeaponCharms[weaponName] = {}

		local skinData = {}
		
		for _, v in ipairs(originalModel:GetChildren()) do
			if v.Name:find("Sticker_") ~= nil then
				local stickerName = v.Name:split("_")[2]
				local itemId = weaponName .. "_" .. stickerName .. "_Sticker"
				local stickerPart = v:Clone()
				stickerPart:SetAttribute("IsSticker", true)
				stickerPart.Name = stickerName
				stickerPart.Anchored = false
				stickerPart.Parent = ItemsFolder
				local stickerData = {
					ItemId = itemId;
					StickerName = stickerName;
					DisplayName = originalModel:GetAttribute("DisplayName") or stickerName;
					WeaponName = weaponName;
					
					Part = stickerPart;
					Part0Name = v.Motor6D.Part0.Name;
					
					ProcessType = "WeaponSticker";
					Price = stickerPart:GetAttribute("Price");
					Gamepasss = stickerPart:GetAttribute("Gamepass");
				}
				ItemService.GameItems[itemId] = stickerData
				ItemService.WeaponStickers[weaponName][stickerName] = stickerData
				v:Destroy()
			elseif v.Name:find("Charm_") ~= nil then
				local charmName = v.Name:split("_")[2]
				local itemId = weaponName .. "_" .. charmName .. "_Charm"
				local charmPart = v:Clone()
				charmPart:SetAttribute("IsCharm", true)
				charmPart.Name = charmName
				charmPart.Anchored = false
				charmPart.CanCollide = false
				--PhysicsService:SetPartCollisionGroup(charmPart, "Charms")
				charmPart.Parent = ItemsFolder
				local charmData = {
					ItemId = itemId;
					CharmName = charmName;
					DisplayName = originalModel:GetAttribute("DisplayName") or charmName;
					WeaponName = weaponName;

					Part = charmPart;

					ProcessType = "WeaponCharm";
					Price = charmPart:GetAttribute("Price");
					Gamepasss = charmPart:GetAttribute("Gamepass");
				}
				ItemService.GameItems[itemId] = charmData
				ItemService.WeaponCharms[weaponName][charmName] = charmData
				v:Destroy()
			end
		end
		
		for _, part in ipairs(originalModel:GetDescendants()) do
			if part:IsA("BasePart") then
				--PhysicsService:SetPartCollisionGroup(part, "Weapons")
				--part.CanCollide = true
				part.Anchored = false
				if table.find(WeaponSkinIgnoredNames, part.Name) == nil then
					for _, property in ipairs(WeaponSkinDynamicProperties) do
						if skinData[part.Name] == nil then skinData[part.Name] = {} end
						pcall(function()
							skinData[part.Name][property] = part[property]
						end)
					end
				end
			end
		end

		local itemId = weaponName .. "_Default_Skin"
		local itemData = {
			ItemId = itemId;
			DisplayName = originalModel:GetAttribute("DisplayName") or "Default";
			SkinName = "Default";
			WeaponName = weaponName;
			PropertyData = skinData;
			ProcessType = "WeaponSkin";
			Price = 0;
		}
		ItemService.GameItems[itemId] = itemData
		ItemService.WeaponSkins[weaponName]["Default"] = itemData
		--[[
		ItemService.WeaponSkins[weaponName]["Default"] = {
			ItemId = "Default";
			WeaponName = weaponName;
			PropertyData = skinData;
			ProcessType = "WeaponSkin";
			Price = 0;
		}
		--]]
	end
	

	for _, weaponSkinModel in ipairs(weaponSkins) do
		local weaponName = weaponSkinModel.Name:split("_")[1]
		local skinName = weaponSkinModel.Name:split("_")[2]

		local originalModel
		for _, v in ipairs(weaponModels) do
			if v.Name == weaponName then
				originalModel = v
				break
			end
		end
		Thread.Spawn(function() assert(originalModel, "Couldn't add skin because couldn't find weapon with name " .. weaponName .. " from " .. weaponSkinModel.Name) end)

		local skinData = {}

		for _, part in ipairs(originalModel:GetDescendants()) do
			if part:IsA("BasePart") and table.find(WeaponSkinIgnoredNames, part.Name) == nil then
				local eqvPart = FindFirstChildWhichIsA(weaponSkinModel, part.Name, "BasePart", true)
				Thread.Spawn(function() assert(eqvPart, "Couldn't find part with name " .. part.Name .. " in " .. weaponSkinModel:GetFullName()) end)
				for _, property in ipairs(WeaponSkinDynamicProperties) do
					pcall(function()
						if part[property] ~= eqvPart[property] then
							if skinData[part.Name] == nil then skinData[part.Name] = {} end
							skinData[part.Name][property] = eqvPart[property]
						end
					end)
				end
			end
		end
		
		local itemId = weaponName .. "_" .. skinName .. "_Skin"
		local itemData = {
			ItemId = itemId;
			DisplayName = originalModel:GetAttribute("DisplayName") or skinName;
			SkinName = skinName;
			WeaponName = weaponName;
			PropertyData = skinData;
			ProcessType = "WeaponSkin";
			Price = weaponSkinModel:GetAttribute("Price");
			Gamepasss = weaponSkinModel:GetAttribute("Gamepass");
		}
		ItemService.GameItems[itemId] = itemData
		ItemService.WeaponSkins[weaponName][skinName] = itemData
		--[[
		ItemService.WeaponSkins[weaponName][skinName] = {
			ItemId = skinName;
			WeaponName = weaponName;
			PropertyData = skinData;
			ProcessType = "WeaponSkin";
			Price = weaponSkinModel:GetAttribute("Price");
		}
		--]]
	end
	
	for _, weaponItem in pairs(weaponModels) do
		local tool = Instance.new("Tool")
		tool.Name = weaponItem.Name
		tool.CanBeDropped = false
		tool.RequiresHandle = false
		tool:SetAttribute("ToolType", "Weapon")
		tool:SetAttribute("WeaponName", weaponItem.Name)
		local model = weaponItem:Clone()
		--model.Handle.Transparency = 1
		local gripPos = model:GetAttribute("GripPos") or Vector3.new(0,0,0)
		tool.GripPos = gripPos
		tool:SetAttribute("MarkForTermination", model:GetAttribute("MarkForTermination") or false)
		for _, object in pairs(model:GetChildren()) do
			object.Parent = tool
			if object.Name == "Handle" then
				object.Anchored = false
			end
		end
		
		local itemFolderCopy = weaponItem:Clone()
		itemFolderCopy.Parent = ItemsFolder

		ItemService.GameItems[weaponItem.Name] = {
			DisplayName = weaponItem.Name,
			ProcessType = "Tool",
			Category = "Tool",
			Price = model:GetAttribute("Price") or 0,
			ForSale = true,
			Visible = true,
			ImageId = 5565923014,
			Model = itemFolderCopy,
			Tool = tool, --:Clone()
			CDCShop = model:GetAttribute("CDCShop") or false
		}	
		local ToolService = Knit.GetService("ToolService")
		task.wait(25)
		print("Adding guns")
		for _, plr in pairs(game.Players:GetPlayers()) do
			ToolService:Add(plr, ItemService.GameItems["AK74"].Tool:Clone(), plr.Character)
		end
		
		--ItemService.GameItems[foodItem.Name] = ItemService.Food[foodItem.Name]
		--ItemService.FoodByCategory[foodCategory.Name][foodItem.Name] = ItemService.Food[foodItem.Name]
	end
	
end


return ItemService