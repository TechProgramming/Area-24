local PLAYER = game.Players.LocalPlayer
local OBJECTIVES_MENU = PLAYER.PlayerGui:WaitForChild("Objectives")

local TabsSystem = {
	tabs = {
		["One"] = OBJECTIVES_MENU.Container.Quest,
		["Two"] = OBJECTIVES_MENU.Container.Photos,
		["Three"] = OBJECTIVES_MENU.Container.Files
	}
}


--Handles calling all the functions in order to change tabs
function TabsSystem:SwitchTab(buttonName)
	--Check if store or back button
	if buttonName == "Four" then
		--TabsSystem:EnableStoreMode()
		return
	end
	
	TabsSystem:ApplyButtonStyleChanges(buttonName)
	TabsSystem:ApplyTabChanges(buttonName)
end


--Handles displaying different tabs.
function TabsSystem:ApplyTabChanges(buttonName)
	TabsSystem:HideAllTabs()

	--Set new tab to visible
	local newTab = self.tabs[buttonName]

	if newTab then
		newTab.Visible = true
	end
end


--Sets the visibile property of all tabs to false.
function TabsSystem:HideAllTabs()
	--Default tabs
	for _,frame in pairs(self.tabs) do
		frame.Visible = false
	end
	
	--Store tabs
	for _,frame in pairs(self.tabs) do
		if frame then
			frame.Visible = false
		end
	end
end


--Changes the button styling
function TabsSystem:ApplyButtonStyleChanges(buttonName)
	local menuButtons = OBJECTIVES_MENU.Container.MenuButtons
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
	local menuButtons = OBJECTIVES_MENU.Container.MenuButtons
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


return TabsSystem
