local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PlayerService = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local PLAYER = PlayerService.LocalPlayer

local ScrewdriverController = Knit.CreateController({
	Name = "ScrewdriverController",
})


function ScrewdriverController:KnitStart() 		
	local VentService = Knit.GetService("VentService")
	
	VentService.OnToggle:Connect(function(set)
		--ScrewdriverController:ChangeAllInteractableEnabledState(set)
	end)
end

--function ScrewdriverController:ChangeAllInteractableEnabledState(newValue)
--	local interactables = CollectionService:GetTagged("ScrewdriverInteractable")
--	for _,item in pairs(interactables) do
--		self:ChangePromptState(item)
--	end
--end


--function ScrewdriverController:ChangePromptState(item)
--	--Get item
--	local config = item:FindFirstChild("Config")
--	if not config then
--		return
--	end

--	--Get prompt and change state
--	local prompt = config:FindFirstChild("Prompt")
--	local keepPromptOpen = config:FindFirstChild("KeepPromptOpen")
--	local originalHoldDuration = config:FindFirstChild("OriginalHoldDuration")
	
--	--Check if prompt exists
--	if not prompt or not prompt.Value then
--		return
--	end
	
--	--Check if prompt should be kept open, if not close/open prompt
--	if not keepPromptOpen or (keepPromptOpen and keepPromptOpen.Value == false) then
--		prompt.Value.Enabled = self.ScrewdriverEquipped
--	end
	
--	--Handle keeping prompt open but changing duration to 0
--	if keepPromptOpen and keepPromptOpen.Value then
--		prompt.Value.Enabled = true
		
--		if not self.ScrewdriverEquipped then
--			prompt.Value.HoldDuration = 0
--		else 
--			local holdDuration = originalHoldDuration.Value or 3
--			prompt.Value.HoldDuration = holdDuration 			
--		end
--	end
--end


return ScrewdriverController