
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local LightingService = game:GetService("Lighting")

local PLAYER = game:GetService("Players").LocalPlayer
local TIME_GUI = PLAYER.PlayerGui:WaitForChild("Time")

local TimeController = Knit.CreateController({
	Name = "TimeController",
})


function TimeController:KnitStart()
	local MainMenuController = Knit.GetController("MainMenuController")
	
	--Handle the main menu opening and closing
	MainMenuController.VisibilityChanged:Connect(function(visible)
		TIME_GUI.Enabled = not visible
	end)
	
	--Handle the time changing
	TimeController:UpdateTimeGui()
	LightingService:GetPropertyChangedSignal('ClockTime'):Connect(function()
		TimeController:UpdateTimeGui()
	end)
end


function TimeController:UpdateTimeGui()
	local Hours = tonumber(string.sub(LightingService.TimeOfDay, 1, 2)) -- Gets the hours, turns 05 --> 5
	local Minutes = string.sub(LightingService.TimeOfDay, 4, 5) -- Gets the minutes, keeps the extra 0

	local String = '%s:%s %s'

	if LightingService.ClockTime >= 13 and LightingService ~= 0 then -- It's between 1pm and 11:59pm
		String = String:format(Hours - 12, Minutes, 'PM')
	elseif LightingService.ClockTime >= 12 and LightingService.ClockTime < 13 then -- It's between 12pm and 12:59pm
		String = String:format(Hours, Minutes, 'PM')
	elseif LightingService.ClockTime >= 0 and LightingService.ClockTime < 1 then -- It's between 12:00am and 12:59am
		String = String:format(12, Minutes, 'AM')
	else -- It's between 1:00am and 11:59 am
		String = String:format(Hours, Minutes, 'AM')
	end

	TIME_GUI.Time.Text = String
end


return TimeController