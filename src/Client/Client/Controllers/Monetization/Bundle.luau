local Knit = require(game:GetService("ReplicatedStorage").Knit);
local BundleService = Knit.GetService("BundleService")
local GamepassService = Knit.GetService("GamepassService")

local PLAYER = game:GetService("Players").LocalPlayer
local BUNDLES_GUI = PLAYER.PlayerGui:WaitForChild("Bundles")
local BUNDLE_MENU = BUNDLES_GUI.Container.Bundle
local BUNDLE_MENU_THUMBNAIL = BUNDLE_MENU.Thumbnail
local BUNDLE_MENU_DESCRIPTION = BUNDLE_MENU_THUMBNAIL.Description



local BUNDLE_MENU_CLOSE = BUNDLES_GUI.Container.Close.CloseButton
local BUNDLE_MENU_BUTTONS = BUNDLES_GUI.Container.MenuButtons:GetChildren()
local temp = {}
for _, item in pairs(BUNDLE_MENU_BUTTONS) do
	if item:IsA("TextButton") then
		table.insert(temp, item)
	end
end
BUNDLE_MENU_BUTTONS = temp

local BUNDLE_PURHCASE = BUNDLE_MENU_DESCRIPTION.Purchase
local BUNDLE_DESCRIPTION = BUNDLE_MENU_DESCRIPTION.Description
local BUNDLE_TITLE = BUNDLE_MENU_DESCRIPTION.Title

local DEFAULT_TEXT_COLOR = Color3.fromRGB(229, 229, 229)
local DEFAULT_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(103,127,136)),
	ColorSequenceKeypoint.new(.476, Color3.fromRGB(109,133,143)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(75,92,99)),
})

local ACTIVE_TEXT_COLOR = Color3.fromRGB(235, 212, 212)
local ACTIVE_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(203,74,74)),
	ColorSequenceKeypoint.new(.476, Color3.fromRGB(156,62,62)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(117,35,35)),
}) 

local PURCHASE_TEXT_COLOR = Color3.fromRGB(202, 235, 200)
local PURCHASE_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 203, 70)),
	ColorSequenceKeypoint.new(.476, Color3.fromRGB(80, 156, 58)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 140, 42)),
}) 

local BUNDLES = {
	["Mobile Task Force"] = {
		GamepassName = "Mobile Task Force",
		PlayerOwns = false,
		ThumbnailId = 7118495487,
		Title = "Mobile Task Force",
		Description = [[Tired of being beaten up by Chaos Insurgency or being murdered by breached SCPs? Take matters into your own hands and provide backup to your fellow guards!
			
			+ Join the Mobile Task Force team!
			+ Help protect and guard the facility.
			+ 20% More Health
			+ More Gear Soon!
			]],
	},
	["Chaos Insurgency"] = {
		GamepassName = "Chaos Insurgency",
		PlayerOwns = false,
		ThumbnailId = 7118495709,
		Title = "Chaos Insurgency",
		Description = [[Chaos has reigned upon the facility! What do you do? Will you turn against the Foundation or will you protect those in danger? Only you decide.
			
			+ Join the Chaos Insurgency team without having to escape!
			
			+ Help Class - D Escape
			+ 20% More Health
			+ More Gear Soon!
			]],

	},
	["Radio"] = {
		GamepassName = "Radio",
		PlayerOwns = false,
		ThumbnailId = 7131664273,
		Title = "Radio",
		Description = [[Time to get funky! With this little bundle you'll be able to listen to all the tunes you want.
			
			
			+ Unlimited access to Radio
			]],
	},
	["Night Vision"] = {
		GamepassName = "Night Vision",
		PlayerOwns = false,
		ThumbnailId = 7139245829,
		Title = "Night Vision",
		Description = [[+ Unlimited access to Night Vision]],
	},
	["Site Director"] = {
		GamepassName = "Site Director",
		PlayerOwns = false,
		ThumbnailId = 7139594972,
		Title = "Site Director",
		Description = [[+ Ability to use all the tools of the foundation's team and perform their task.
+ Deagle and Shotgun (WIP)
+ 140 Health
+ Level 4 Access
+ Offices only you can open the doors for. (WIP)
+ Accessories only you can wear. 
+ Access to all foundation uniforms.
+ Suits (WIP)]],
	},
	["VIP"] = {
		GamepassName = "VIP",
		PlayerOwns = false,
		ThumbnailId = 7154559987,
		Title = "VIP",
		Description = [[+ Red skinned AK74 (Combat and Foundation Staff Teams Only)
+ Bonus daily login award.
+ Exclusive Accessories
+ Chat Tag 
+ Extra $15 for Work
+ Extra 2 XP for Work
+ Health Pack]],
	},	
	
}


local BundleController = Knit.CreateController({
	Name = "BundleController",
	SelectedBundle = BUNDLES["Chaos Insurgency"],
})


function BundleController:KnitStart()
	local SFXController = Knit.GetController("SFXController")
	local GamepassService = Knit.GetService("GamepassService")
	
	
	BundleService.OnPrompt:Connect(function(gamepassName, ownsGamepass)	
		BundleController:SetBundle(gamepassName)
		BUNDLES_GUI.Enabled = true
	end)
	
	
	for _, button in pairs(BUNDLE_MENU_BUTTONS) do
		button.MouseButton1Down:Connect(function()
			SFXController:PlayPrefab("ButtonClick")
			
			self:RefreshGamepassOwnership()
			self:SetBundle(button.Name)
		end)
	end
	
	BUNDLE_PURHCASE.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		if self.SelectedBundle.PlayerOwns then
			return
		end
		
		GamepassService:Prompt(self.SelectedBundle.GamepassName)
		self:RefreshGamepassOwnership()
	end)
	
	BUNDLE_MENU_CLOSE.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		BUNDLES_GUI.Enabled = false
	end)
	
	self:SetBundle(self.SelectedBundle.GamepassName)
end


function BundleController:Show(bundleName)
	bundleName = bundleName or self.SelectedBundle.GamepassName
	
	self:SetBundle(bundleName)
	BUNDLES_GUI.Enabled = true
end


function BundleController:RefreshGamepassOwnership()
	for key, data in pairs(BUNDLES) do
		local owns = GamepassService:HasGamepass(key)
		if owns then
			BUNDLES[key].PlayerOwns = true
			if self.SelectedBundle == data then
				self:SetDefault(BUNDLE_PURHCASE)
			end
		end
	end
end


function BundleController:SetBundle(bundleName) 
	local bundle = BUNDLES[bundleName]
	if not bundle then
		return
	end
	
	self.SelectedBundle = bundle
	
	--Prevent network latency slowing menu down
	coroutine.wrap(function() 
		self:RefreshGamepassOwnership()
	end)()
	
	BUNDLE_DESCRIPTION.Text = bundle.Description
	BUNDLE_TITLE.Text = bundle.Title
	BUNDLE_MENU_THUMBNAIL.Image = "rbxassetid://"..bundle.ThumbnailId

	--if bundle.PlayerOwns then
	--	self:SetDefault(BUNDLE_PURHCASE)
	--	BUNDLE_PURHCASE.DisplayText.Text = "Purchased"
	--end
	
	--Reset button
	for _, button in pairs(BUNDLE_MENU_BUTTONS) do
		if button.Name == bundleName then
			self:SetEnabled(button)
		else
			self:SetDefault(button)			
		end
	end
	
	
end


function BundleController:SetEnabled(item)
	item.Gradient.Color = ACTIVE_GRADIENT
	item.DisplayText.TextColor3 = ACTIVE_TEXT_COLOR
end


function BundleController:SetPurchase(item)
	item.Gradient.Color = PURCHASE_GRADIENT
	item.DisplayText.TextColor3 = PURCHASE_TEXT_COLOR
end


function BundleController:SetDefault(item)
	item.Gradient.Color = DEFAULT_GRADIENT
	item.DisplayText.TextColor3 = DEFAULT_TEXT_COLOR
end


return BundleController