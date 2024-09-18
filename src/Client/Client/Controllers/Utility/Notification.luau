local Knit = require(game:GetService("ReplicatedStorage").Knit)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local NOTIFICATION_UI = PLAYER.PlayerGui:WaitForChild("NotificationText")

local NotificationController = Knit.CreateController({
	Name = "NotificationController",
	TimeRemaining = 0,
	CoroutineRunning = false,
	CurrentTextElement = nil,
})


function NotificationController:KnitStart()
	local NotificationService = Knit.GetService("NotificationService")
	NotificationService.OnNotification:Connect(function(displayTime, text, color, custom)
		self:ShowNotification(displayTime, text, color, custom)
	end)
end


function NotificationController:ShowNotification(displayTime, text, color, customTextElementName)
	self.TimeRemaining = displayTime
	
	--Check if custom element
	if customTextElementName then
		local element = NOTIFICATION_UI:FindFirstChild(customTextElementName)
		if not element then
			return self:ShowNotification(displayTime, text, color)
		end
		self:SetNotificationText(element, text, color)		
	else
		self:SetNotificationText(NOTIFICATION_UI.DisplayText, text, color)		
	end	
	
	--Ensure coroutine is not running
	if self.CoroutineRunning then
		return
	end
	
	--Start coroutine to countdown
	coroutine.wrap(function()
		self.CoroutineRunning = true
		
		--Countdown
		while self.TimeRemaining > 0 do
			wait(1)
			self.TimeRemaining = self.TimeRemaining-1 
		end
		
		--Reset
		self.CurrentTextElement.Visible = false
		self.CoroutineRunning = false
	end)()
end


function NotificationController:SetNotificationText(textElement, text, color)
	if self.CurrentTextElement then
		self.CurrentTextElement.Visible = false
	end
	self.CurrentTextElement = textElement
	textElement.Text = text
	textElement.TextColor3 = color
	textElement.Visible = true
end

return NotificationController