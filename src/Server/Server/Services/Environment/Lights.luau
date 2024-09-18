local Knit = require(game:GetService("ReplicatedStorage").Knit)

local CollectionService = game:GetService("CollectionService")
local Lights = CollectionService:GetTagged("Light")
local PowerSounds = CollectionService:GetTagged("PowerSound")
local EmergencySpinLights = CollectionService:GetTagged("EmergencySpinLight")

local OriginalHistory = {
	LightColor = {}
}

local LightsService = Knit.CreateService({
	Name = "LightsService",
	Client = {},
})


function LightsService:KnitStart()
	-- SAMPLE HISTORY
	for _, light in pairs(Lights) do
		OriginalHistory.LightColor[light] = light.Color
		for _, sub in pairs(light:GetChildren()) do
			if sub:IsA("Light") then
				OriginalHistory.LightColor[sub] = sub.Color
			end
		end
	end
	
	-- FUNCTIONS

	function LightsService:SetLightPower(light, power)
		if power then
			light.Material = Enum.Material.SmoothPlastic
			light.Color = Color3.fromRGB(0, 0, 0)
			for _, sub in pairs(light:GetChildren()) do
				if sub:IsA("Light") then
					sub.Enabled = false
				end
			end
		else
			light.Material = Enum.Material.Neon
			light.Color = OriginalHistory.LightColor[light]
			for _, sub in pairs(light:GetChildren()) do
				if sub:IsA("Light") then
					sub.Enabled = true
				end
			end			
		end
	end
	
	function LightsService:SetEmergencyRed(light, emergency)
		if emergency then

			light.Color = Color3.fromRGB(255, 0, 0)
			for _, sub in pairs(light:GetChildren()) do
				if sub:IsA("Light") then
					sub.Color = Color3.fromRGB(255,0, 0)
				end
			end
		else
			light.Color = OriginalHistory.LightColor[light]
			for _, sub in pairs(light:GetChildren()) do
				if sub:IsA("Light") then
					sub.Color = OriginalHistory.LightColor[sub]
				end
			end			
		end
	end
	
	function LightsService:SetEmergencySpinLight(light, emergency, dontChangeColor)
	
		if emergency then
			if not dontChangeColor then
				light.Bulb.Color = Color3.fromRGB(255,0,0)
			end
			light.Light.SurfaceLight.Enabled = true
			light.Light.HingeConstraint.AngularVelocity = 5
			--light.Light.HingeConstraint.Enabled = true
		else
			if not dontChangeColor then
				light.Bulb.Color = Color3.fromRGB(91, 93, 105)
			end
			light.Light.SurfaceLight.Enabled = false
			light.Light.HingeConstraint.AngularVelocity = 0
			--light.Light.HingeConstraint.Enabled = false
		end
	end
	
	function LightsService:SetFacilityPower(power)
		for _, light in pairs(Lights) do
			LightsService:SetLightPower(light, power)
		end
		if not power then
			for _, sound in pairs(PowerSounds) do
				local soundObj = sound:FindFirstChildOfClass("Sound")
				soundObj.Volume = 0
			end
		else
			for _, sound in pairs(PowerSounds) do
				local soundObj = sound:FindFirstChildOfClass("Sound")
				soundObj.Volume = 1
			end		
		end
	end

	function LightsService:SetFacilityEmergencyLights(power)
		for _, light in pairs(Lights) do
			LightsService:SetEmergencyRed(light, power)
		end
		for _, light in pairs(EmergencySpinLights) do
			LightsService:SetEmergencySpinLight(light, power)
		end	
	end

	--end
end

return LightsService