local Knit = require(game:GetService("ReplicatedStorage").Knit);
local CollectionService = game:GetService("CollectionService")

local SPIN_LIGHT_INDEFINITELY = CollectionService:GetTagged("SpinLightIndefinitely")

local EnvUtilService = Knit.CreateService({
	Name = "EnvUtilService"
})


function EnvUtilService:KnitStart()
	local LightsService = Knit.GetService("LightsService")
	
	for _, light in pairs(SPIN_LIGHT_INDEFINITELY) do
		LightsService:SetEmergencySpinLight(light, true, true)
	end
end


return EnvUtilService

