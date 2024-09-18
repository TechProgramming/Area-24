local Knit = require(game:GetService("ReplicatedStorage").Knit);
local LightingService = game:GetService("Lighting")


local NightVisionController = Knit.CreateController({
	Name = "NightVisionController",
	Enabled = false,
})


local DEFAULT_AMBIENT = LightingService.Ambient
local NIGHT_VISION_AMBIENT = Color3.fromRGB(25, 210, 25)

function NightVisionController:Toggle()
	local JobService = Knit.GetService("JobService")
	if self.Enabled then
		--disable
		LightingService.Ambient = DEFAULT_AMBIENT
		self.Enabled = false
	else
		--enable
		LightingService.Ambient = NIGHT_VISION_AMBIENT
		self.Enabled = true
	end
end


return NightVisionController