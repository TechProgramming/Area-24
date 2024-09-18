local Knit				= require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat		= require(Knit.Util.NumberFormat)
local CollectionService	= game:GetService("CollectionService")
local StarterGui		= game:GetService("StarterGui")
local LightingService = game:GetService("Lighting")

local PLAYER	= game:GetService("Players").LocalPlayer

local SCHEDULE	= PLAYER.PlayerGui:WaitForChild("Schedule")

local SanityController = Knit.CreateController({
	Name = "SanityController",
	Issue = "None",
	Sanity = 0,
	LastWhisper = 0
})

local OriginalExposureCompensation = 0.23

function SanityController:KnitStart()
	
	local SanityService = Knit.GetService("SanityService")
	local SFXController = Knit.GetController("SFXController")
	
	SanityService.OnIssueChanged:Connect(function(issue)
		SanityController.Issue = issue
	end)
	
	SanityService.OnSanityChanged:Connect(function(sanity)
		SanityController.Sanity = sanity
	end)
	
	LightingService:GetPropertyChangedSignal('ClockTime'):Connect(function()
		if SanityController.Issue == "Haunt" then
			LightingService.ExposureCompensation = math.clamp(LightingService.ExposureCompensation - 0.05, -3, 1)
			--print("Expose", LightingService.ExposureCompensation <= -3)
			if LightingService.ExposureCompensation <= -3 then
				local timeSinceLastWhisper = tick() - SanityController.LastWhisper
				--print("Time", timeSinceLastWhisper, timeSinceLastWhisper >= 300)
				if timeSinceLastWhisper >= 300 then
					SanityController.LastWhisper = tick()
					SFXController:Play("Whisper_1")
				end
			end
		end
	end)
end

return SanityController