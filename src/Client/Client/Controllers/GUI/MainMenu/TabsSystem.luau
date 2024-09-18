local PLAYER = game.Players.LocalPlayer
local MAIN_MENU = PLAYER.PlayerGui:WaitForChild("MainMenu")

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local ItemService = Knit.GetService("ItemService")
local GamepassService = Knit.GetService("GamepassService")
local DeveloperProductService = Knit.GetService("DeveloperProductService")
local SFXController 		= Knit.GetController("SFXController")
local Template = MAIN_MENU.Container.Store.Template:Clone()
local ProfileService = Knit.GetService("ProfileService")
local profile = ProfileService:GetProfile()
-- INITIALIZE

--- Description
--- IconImageAssetId
--- IsForSale
--- Name
--- PriceInRobux
--- ProductId
--- ProductType
--- TargetId
--- Id
--- Cash

function UpdateGamepasses(gamepasses)
	for _, item in pairs(MAIN_MENU.Container.Gamepasses:GetChildren()) do
		if item:IsA("ImageButton") then
			item:Destroy()
		end
	end
	for name, data in pairs(gamepasses) do
		local button = Template:Clone()
		button.Name = name
		button.Parent = MAIN_MENU.Container.Gamepasses
		button.Icon.Image = "http://roblox.com/asset/?id="..data.IconImageAssetId
		button.Price.Text = data.PriceInRobux or 0
		button.DisplayName.Text = name
		button.Visible = true
		button.Obtained.Visible = profile.Gamepasses[name] or false
		button.MouseButton1Down:Connect(function()
			GamepassService:Prompt(name)
			SFXController:PlayPrefab("ButtonClick")
		end)

		button.MouseEnter:Connect(function()
			SFXController:PlayPrefab("ButtonHover")
		end)
	end
end

function UpdateDevProducts(devProducts)
	for _, item in pairs(MAIN_MENU.Container.DevProducts:GetChildren()) do
		if item:IsA("ImageButton") then
			item:Destroy()
		end
	end
	for name, data in pairs(devProducts) do
		local button = Template:Clone()
		button.Name = name
		button.Parent = MAIN_MENU.Container.DevProducts
		button.Icon.Image = "http://roblox.com/asset/?id="..data.IconImageAssetId
		button.Price.Text = data.PriceInRobux
		button.DisplayName.Text = name
		button.Visible = true

		button.MouseButton1Down:Connect(function()
			DeveloperProductService:Prompt(name)
			SFXController:PlayPrefab("ButtonClick")
		end)

		button.MouseEnter:Connect(function()
			SFXController:PlayPrefab("ButtonHover")
		end)
	end
end

GamepassService.OnUpdate:Connect(function(gamepasses)
	UpdateGamepasses(gamepasses)
end)

DeveloperProductService.OnUpdate:Connect(function(devProducts)
	UpdateDevProducts(devProducts)
end)

coroutine.wrap(function()
	GamepassService.OnRequestItems:Fire()
	DeveloperProductService.OnRequestItems:Fire()
	--GamepassService:GetGamepasses()
	--DeveloperProductService:GetProducts()


end)()


local TabsSystem = {
	storeModeEnabled = false,
	storeMode = {
		["One"] = MAIN_MENU.Container.Gamepasses,
		["Two"] = nil,
		["Three"] = MAIN_MENU.Container.DevProducts
	},
	regularMode = {
		["One"] = MAIN_MENU.Container.News,
		["Two"] = MAIN_MENU.Container.Teams,
		["Three"] = MAIN_MENU.Container.Store,
		["Four"] = MAIN_MENU.Container.Rules,
	},
	storeSale = false,
}


--Handles calling all the functions in order to change tabs
function TabsSystem:SwitchTab(buttonName)
	--Check if store or back button
	if buttonName == "Three" and not self.storeModeEnabled then
		TabsSystem:EnableStoreMode()
		return
	elseif buttonName == "Four" and self.storeModeEnabled then
		TabsSystem:DisableStoreMode()
		return
	end
	
	if self.storeModeEnabled then
		if buttonName == "One" then
			-- Gamepass
			MAIN_MENU.Container.Gamepasses.Visible = true
			MAIN_MENU.Container.DevProducts.Visible = false
			
		elseif buttonName == "Three" then
			-- DevProducts
			MAIN_MENU.Container.Gamepasses.Visible = false
			MAIN_MENU.Container.DevProducts.Visible = true			
			
		end
	end
	
	--Only apply button styling if store mode is disabled
	if not self.storeModeEnabled then
		TabsSystem:ApplyButtonStyleChanges(buttonName)
	end
	
	--Change the tab
	TabsSystem:ApplyTabChanges(buttonName)
end


--Handles displaying different tabs.
function TabsSystem:ApplyTabChanges(buttonName)
	TabsSystem:HideAllTabs()

	--Set new tab to visible
	local newTab = self.regularMode[buttonName]
	if self.storeModeEnabled then
		newTab = self.storeMode[buttonName]
	end

	if newTab then
		newTab.Visible = true
	end
end


--Sets the visibile property of all tabs to false.
function TabsSystem:HideAllTabs()
	--Default tabs
	for _,frame in pairs(self.regularMode) do
		frame.Visible = false
	end
	
	--Store tabs
	for _,frame in pairs(self.storeMode) do
		if frame then
			frame.Visible = false
		end
	end
end


--Changes the button styling
function TabsSystem:ApplyButtonStyleChanges(buttonName)
	local menuButtons = MAIN_MENU.Container.MenuButtons
	TabsSystem:ResetButtonColors()
	
	--Set new button text color to red
	menuButtons[buttonName].DisplayText.TextColor3 = Color3.fromRGB(235, 212, 212)
	
	--Create new gradient and place into button
	local gradient = menuButtons[buttonName]:FindFirstChildWhichIsA("UIGradient")
	if not gradient then
		return
	end
	
	--Set gradients color
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(203,74,74)),
		ColorSequenceKeypoint.new(.476, Color3.fromRGB(156,62,62)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(117,35,35)),
	})
	gradient.Color = colorSequence
end


--Resets all buttons to default style.
function TabsSystem:ResetButtonColors()
	local menuButtons = MAIN_MENU.Container.MenuButtons
	for _, item in pairs(menuButtons:GetChildren()) do
		if item:IsA("TextButton") then
			--Set color to white
			item.DisplayText.TextColor3 = Color3.fromRGB(229, 229, 229)
			
			--Replace gradient color with new one if gradient exists
			local gradient = item:FindFirstChildWhichIsA("UIGradient")
			if gradient then
				local colorSequence = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(103,127,136)),
					ColorSequenceKeypoint.new(.476, Color3.fromRGB(109,133,143)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(75,92,99)),
				})
				gradient.Color = colorSequence
			end
		end
	end
end


--Handles switching the mode from default to store
function TabsSystem:EnableStoreMode()
	self.storeModeEnabled = true
	TabsSystem:HideAllTabs()
	TabsSystem:SwitchTab("One")
	TabsSystem:ApplyButtonStyleChanges("Four")
	local menuButtons = MAIN_MENU.Container.MenuButtons
	menuButtons.One.DisplayText.Text = "GAMEPASSES"
	--menuButtons.Two.DisplayText.Text = "BOOSTERS"
	menuButtons.Two.Visible = false
	menuButtons.Three.DisplayText.Text = "PRODUCTS"
	menuButtons.Four.DisplayText.Text = "BACK"
	
	menuButtons.Three.Notification.Visible = false
end


--Handles switching the mode from store to default
function TabsSystem:DisableStoreMode()
	self.storeModeEnabled = false
	TabsSystem:HideAllTabs()
	TabsSystem:SwitchTab("One")
	local menuButtons = MAIN_MENU.Container.MenuButtons
	menuButtons.One.DisplayText.Text = "NEWS"
	menuButtons.Two.DisplayText.Text = "TEAMS"
	menuButtons.Two.Visible = true
	menuButtons.Three.DisplayText.Text = "STORE"
	menuButtons.Four.DisplayText.Text = "RULES"
	
	if self.storeSale then
		menuButtons.Three.Notification.Visible = true
	end
end


return TabsSystem
