local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local EDITOR_UI = PLAYER.PlayerGui:WaitForChild("CharacterEditor")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local CharacterEditorController = Knit.CreateController({
	Name = "CharacterEditorController",
	VisibilityChanged = KnitSignal.new(),
	CategoryChanged = KnitSignal.new(),
	AvatarSetChanged = KnitSignal.new(),
	HighlightCache = {
		Hair = nil,
		Outfit = nil,
		Face = nil,
		SkinTone = nil,
		Accessories = {}
	}
})

local TEMPLATE_BUTTON = EDITOR_UI.Template:Clone()
local DISPLAY_UI = EDITOR_UI.Editor.Container.Display
local SLOTS_UI = EDITOR_UI.Editor.AvatarSets

function CharacterEditorController:KnitStart()
	local CharacterEditorService = Knit.GetService("CharacterEditorService")
	local ItemService = Knit.GetService("ItemService")
	local ProfileService = Knit.GetService("ProfileService")
	local LevelController = Knit.GetController("LevelController")
	
	-- Note to self, check if team changed.
	local profile = ProfileService:GetProfile()
	local team = PLAYER.Team
	local teamId = team.Id.Value
	local avatarSetNumber = profile.CurrentAvatarSet[teamId]
	local avatarSetData = profile.AvatarSets[teamId][avatarSetNumber]
	
	local currentCategory = EDITOR_UI.Editor.Categories.Hairs
	
	local skins = ItemService:GetSkinTones()
	local faces = ItemService:GetFaces()
	local hairs = ItemService:GetHairs()
	local accessory = ItemService:GetAccessories()
	local outfits = ItemService:GetOutfits(teamId)
	
	PLAYER:GetPropertyChangedSignal("Team"):Connect(function()
		profile = ProfileService:GetProfile()
		team = PLAYER.Team
		teamId = team.Id.Value
		outfits = ItemService:GetOutfits(teamId)
		avatarSetNumber = profile.CurrentAvatarSet[teamId]
		CharacterEditorController:DisplayCategory(currentCategory)
		CharacterEditorController.AvatarSetChanged:Fire(EDITOR_UI.Editor.AvatarSets[tostring(avatarSetNumber)])
		--EDITOR_UI.Editor.AvatarSets[tostring(avatarSetNumber)].TextLabel.TextColor3 = Color3.fromRGB(255, 152, 34)
	end)
	
	function CharacterEditorController:Highlight(category, itemId)
		if category ~= "Accessories" then
			local previousItem = CharacterEditorController.HighlightCache[category]
			if previousItem ~= nil then
				local previousButton = DISPLAY_UI:FindFirstChild(previousItem) or false
				if previousButton then
					previousButton.InUse.Visible = false
				end
			end
			
			local itemButton = DISPLAY_UI:FindFirstChild(itemId) or false
			if itemButton then
				itemButton.InUse.Visible = true
				CharacterEditorController.HighlightCache[category] = itemId
			end
		else
			local itemButton = DISPLAY_UI:FindFirstChild(itemId) or false
			if itemButton then
				itemButton.InUse.Visible = not itemButton.InUse.Visible
				--CharacterEditorController.HighlightCache[category] = itemId
			end
		end
	end
	
	function CharacterEditorController:UpdateOwnedSlots() 
		local profile = ProfileService:GetProfile()
		local purchasedCharacterSlots = profile.PurchasedCharacterSlots
		for slot = 1, 3 + purchasedCharacterSlots do
			local slotUI = SLOTS_UI:FindFirstChild(slot) 
			if slotUI then
				slotUI.UIGradient.Enabled = false
				slotUI.TextLabel.Text = slot
				slotUI.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
			end
		end
	end
	
	CharacterEditorService.OnUpdateSlotsOwned:Connect(function(itemId)
		CharacterEditorController:UpdateOwnedSlots()
	end)
	
	CharacterEditorService.OnFaceChange:Connect(function(itemId)
		CharacterEditorController:Highlight("Face", itemId)
	end)
	
	CharacterEditorService.OnHairChange:Connect(function(itemId)
		CharacterEditorController:Highlight("Hair", itemId)
	end)
	
	CharacterEditorService.OnAccessoryChange:Connect(function(itemId)
		CharacterEditorController:Highlight("Accessories", itemId)
	end)
	
	CharacterEditorService.OnOutfitChange:Connect(function(itemId)
		CharacterEditorController:Highlight("Outfit", itemId)
	end)
	
	CharacterEditorService.OnSkinToneChange:Connect(function(itemId)
		CharacterEditorController:Highlight("SkinTone", itemId)
	end)
	
	CharacterEditorService.OnAvatarSetChange:Connect(function(itemId)
		CharacterEditorController:Highlight("SkinTone", itemId)
	end)

	--OnWeaponChange = RemoteSignal.new(),
	--OnAvatarSetChange = RemoteSignal.new() 
	
	function CharacterEditorController:DisplayCategory(category)
		local playerLevel = LevelController.CachedLevel
		--print("LOADING PROFILE", playerLevel)
		profile = ProfileService:GetProfile()
		team = PLAYER.Team
		teamId = team.Id.Value
		avatarSetNumber = profile.CurrentAvatarSet[teamId]
		--CharacterEditorController.AvatarSetChanged:Fire(avatarSetNumber)
		avatarSetData = profile.AvatarSets[teamId][avatarSetNumber]
		--print(avatarSetData)
		for _, button in pairs(DISPLAY_UI:GetChildren()) do
			if button:IsA("ImageButton") then
				button:Destroy()
			end
		end
		-- Get All Outfits
		-- Outfits, Faces, Hairs, SkinTones
		if category.Name == "SkinTones" then
			for itemId, itemData in pairs(skins) do
				local button = TEMPLATE_BUTTON:Clone()
				button.Visible = true
				button.Parent = DISPLAY_UI
				button.Name = itemId
				button.BackgroundColor3 = itemData.Color
				button.MouseButton1Down:Connect(function()
					CharacterEditorService:ChangeSkinTone(itemId)
				end)
			end
			CharacterEditorController:Highlight("SkinTone", avatarSetData["SkinTone"])
			--DISPLAY_UI[avatarSetData.SkinTone]
		elseif category.Name == "Faces" then
			for itemId, itemData in pairs(faces) do
				local button = TEMPLATE_BUTTON:Clone()
				button.Visible = true
				button.Parent = DISPLAY_UI
				button.Name = itemId
				button.Icon.Visible = true
				button.Icon.Image = "rbxthumb://type=Asset&id="..itemData.Id.."&w=150&h=150"
				button.MouseButton1Down:Connect(function()
					CharacterEditorService:ChangeFace(itemId)
				end)
			end
			CharacterEditorController:Highlight("Face", avatarSetData["Face"])
		elseif category.Name == "Hairs" then
			for itemId, itemData in pairs(hairs) do
				local button = TEMPLATE_BUTTON:Clone()
				button.Visible = true
				button.Parent = DISPLAY_UI
				button.Name = itemId
				button.Icon.Visible = true
				button.Icon.Image = "rbxthumb://type=Asset&id="..itemData.Id.."&w=150&h=150"
				button.LayoutOrder = itemData.Level
				if itemData.Level ~= nil and playerLevel < itemData.Level then
					button.Level.Visible = true
					button.Level.Amount.Text = "LV "..itemData.Level
				else
					button.Level.Visible = false
				end
				button.MouseButton1Down:Connect(function()
					CharacterEditorService:ChangeHair(itemId)
				end)
			end
			CharacterEditorController:Highlight("Hair", avatarSetData["Hair"])
		elseif category.Name == "Outfits" then
			for itemId, itemData in pairs(outfits) do
				local displayModel = script.OutfitDisplayTemp:Clone()
				local button = TEMPLATE_BUTTON:Clone()
				button.Visible = true
				button.Parent = DISPLAY_UI
				button.Name = itemId
				displayModel.Parent = button.ViewportFrame
				displayModel.Shirt.ShirtTemplate = "http://www.roblox.com/asset/?id="..itemData.Shirt
				displayModel.Pants.PantsTemplate = "http://www.roblox.com/asset/?id="..itemData.Pants
				button.LayoutOrder = itemData.Level
				if itemData.Level ~= nil and playerLevel < itemData.Level then
					button.Level.Visible = true
					button.Level.Amount.Text = "LV "..itemData.Level
				else
					button.Level.Visible = false
				end
				
				button.MouseButton1Down:Connect(function()
					CharacterEditorService:ChangeOutfit(itemId)
				end)
			end
			CharacterEditorController:Highlight("Outfit", avatarSetData["Outfit"])
		elseif category.Name == "Accessories" then
			for itemId, itemData in pairs(accessory) do
				local button = TEMPLATE_BUTTON:Clone()
				button.Visible = true
				button.Parent = DISPLAY_UI
				button.Name = itemId
				button.Icon.Visible = true
				button.Icon.Image = "rbxthumb://type=Asset&id="..itemData.Id.."&w=150&h=150"
				button.LayoutOrder = itemData.Level
				if itemData.Level ~= nil and playerLevel < itemData.Level then
					button.Level.Visible = true
					button.Level.Amount.Text = "LV "..itemData.Level
				else
					button.Level.Visible = false
				end
				if itemData.Gamepass ~= nil then
					button[itemData.Gamepass].Visible = true
				--else
					--button[itemData.Gamepass].Visible = false
				end
				button.MouseButton1Down:Connect(function()
					CharacterEditorService:ChangeAccessory(itemId)
				end)
			end
			for _, itemId in pairs(avatarSetData["Accessories"]) do
				CharacterEditorController:Highlight("Accessories", itemId)
			end
		end
	end
	
	for _, category in pairs(EDITOR_UI.Editor.Categories:GetChildren()) do
		if category:IsA("ImageButton") then

			CharacterEditorController.CategoryChanged:Connect(function(open)
				if category == open then
					category.Icon.ImageColor3 = Color3.fromRGB(255, 152, 34)
					currentCategory = category
					self:DisplayCategory(currentCategory)
				else
					category.Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
				end
			end)


			category.MouseButton1Down:Connect(function()
				CharacterEditorController.CategoryChanged:Fire(category)
			end)
			

			category.MouseEnter:Connect(function()
				SOUNDS.Click:Play()
			end)

		end
	end
	
	for _, set in pairs(EDITOR_UI.Editor.AvatarSets:GetChildren()) do
		if set:IsA("ImageButton") then

			CharacterEditorController.AvatarSetChanged:Connect(function(open)
				if set == open then
					set.TextLabel.TextColor3 = Color3.fromRGB(255, 152, 34)
					self:DisplayCategory(currentCategory)
				else
					set.TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end)


			set.MouseButton1Down:Connect(function()
				CharacterEditorService:ChangeAvatarSet(set.Set.Value)
				CharacterEditorController.AvatarSetChanged:Fire(set)
			end)


			set.MouseEnter:Connect(function()
				SOUNDS.Click:Play()
			end)

		end
	end
	
	function CharacterEditorController:Show()
		CharacterEditorController:DisplayCategory(currentCategory)
		EDITOR_UI.Enabled = true
		self.VisibilityChanged:Fire(true)
	end
	
	function CharacterEditorController:Hide()
		EDITOR_UI.Enabled = false
		self.VisibilityChanged:Fire(false)
	end
	
	EDITOR_UI.Done.MouseButton1Down:Connect(function()
		CharacterEditorController:Hide()
	end)

	EDITOR_UI.Editor.AvatarSets[tostring(avatarSetNumber)].TextLabel.TextColor3 = Color3.fromRGB(255, 152, 34)
	CharacterEditorController:DisplayCategory(currentCategory)
	CharacterEditorController:UpdateOwnedSlots() 
end


return CharacterEditorController