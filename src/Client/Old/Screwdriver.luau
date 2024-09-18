local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PlayerService = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local PLAYER = PlayerService.LocalPlayer

local ScrewdriverController = Knit.CreateController({
	Name = "ScrewdriverController",
	ScrewdriverEquipped = false,
})


function ScrewdriverController:KnitStart() 		
	--Connect tagged instance added
	CollectionService:GetInstanceAddedSignal("ScrewdriverInteractable"):Connect(function(item)
		self:ChangePromptState(item)
	end)
	
	--Connect character added
	PLAYER.CharacterAdded:Connect(function(character)
		self.ScrewdriverEquipped = false
		self:ConnectSignals(character)
	end)
	
	self:ConnectSignals(PLAYER.Backpack)
	
	local character = PLAYER.Character
	if character then
		self:ConnectSignals(character)
	end
	
	--Check if player already has item
	local hasItem = self:DoesPlayerHaveItem()
	self.ScrewdriverEquipped = hasItem
	self:ChangeAllInteractableEnabledState(hasItem)
end


function ScrewdriverController:ConnectSignals(item)
	--If screwdriver equipped, set to true
	item.ChildAdded:Connect(function(item)
		if item:IsA("Tool") and item:FindFirstChild("IsScrewdriver") then
			self.ScrewdriverEquipped = true
			self:ChangeAllInteractableEnabledState(true)
		end
	end)	
	
	item.ChildRemoved:Connect(function(item)
		local hasItem = self:DoesPlayerHaveItem()
		self.ScrewdriverEquipped = hasItem
		self:ChangeAllInteractableEnabledState(hasItem)
	end)
	
end


function ScrewdriverController:DoesPlayerHaveItem()
	
	--Check backpack
	local backpackItems = PLAYER.Backpack:GetChildren()
	for _,item in pairs(backpackItems) do
		if item:IsA("Tool") and item:FindFirstChild("IsScrewdriver") then
			return true
		end
	end
	
	--Check character
	local character = PLAYER.Character
	if not character then
		return
	end	
	
	local item = character:FindFirstChildOfClass("Tool")
	if item and item:FindFirstChild("IsScrewdriver") then
		return true
	end
	
	return false
end


function ScrewdriverController:ChangeAllInteractableEnabledState(newValue)
	local interactables = CollectionService:GetTagged("ScrewdriverInteractable")
	for _,item in pairs(interactables) do
		self:ChangePromptState(item)
	end
end


function ScrewdriverController:ChangePromptState(item)
	--Get item
	local config = item:FindFirstChild("Config")
	if not config then
		return
	end

	--Get prompt and change state
	local prompt = config:FindFirstChild("Prompt")
	local keepPromptOpen = config:FindFirstChild("KeepPromptOpen")
	local originalHoldDuration = config:FindFirstChild("OriginalHoldDuration")
	
	--Check if prompt exists
	if not prompt or not prompt.Value then
		return
	end
	
	--Check if prompt should be kept open, if not close/open prompt
	if not keepPromptOpen or (keepPromptOpen and keepPromptOpen.Value == false) then
		prompt.Value.Enabled = self.ScrewdriverEquipped
	end
	
	--Handle keeping prompt open but changing duration to 0
	if keepPromptOpen and keepPromptOpen.Value then
		prompt.Value.Enabled = true
		
		if not self.ScrewdriverEquipped then
			prompt.Value.HoldDuration = 0
		else 
			local holdDuration = originalHoldDuration.Value or 3
			prompt.Value.HoldDuration = holdDuration 			
		end
	end
end


return ScrewdriverController