local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")

local PLAYER = PlayerService.LocalPlayer

local MedicKitController = Knit.CreateController({
	Name = "MedicKitController",
})


function MedicKitController:KnitStart()
	local MedicKitService = Knit.GetService("MedicKitService")
	
	MedicKitService.OnTogglePrompts:Connect(function(enable, prompts)
		
		for userId, prompt in pairs(prompts) do
			if userId == tostring(PLAYER.UserId) then
				prompt.KeyboardKeyCode = Enum.KeyCode.T
				prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
				prompt.ActionText = "Heal Self"
			end
			
			prompt.Enabled = enable
			
		end
	end)
end


return MedicKitController