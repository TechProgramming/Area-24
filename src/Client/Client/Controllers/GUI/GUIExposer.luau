local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local CurrentStates = {}

local GUIExposerController = Knit.CreateController({
	Name = "GUIExposerController";
	VisibilityChanged = KnitSignal.new();
	CurrentStates = CurrentStates;
})

local TrackedControllers = {
	"FoodStandController";
	--"SideBarController";
	"CDShopController";
	"ObjectivesController";
	"LoginAwardController";
	"TeamHelpController";
	"HelpMenuController";
	"CharacterEditorController";
	"MainMenuController";
	"AuthorizationController";
	"FactionController";
	"EmoteController";
}
function GUIExposerController:GetVisibilityState(controllerName)
	if CurrentStates[controllerName]==nil then warn("Asked to get visiblity of "..controllerName.. " but it doesn't exist") end
	return CurrentStates[controllerName]
end

function GUIExposerController:GetIsAnyEnabled()
	for controllerName, state  in pairs(CurrentStates) do
		if state then return true end
	end
	return false
end

function GUIExposerController:GetIsAnyDisabled()
	for controllerName, state  in pairs(CurrentStates) do
		if not state then return true end
	end
	return false
end

function GUIExposerController:KnitInit()
	for _, controllerName in ipairs(TrackedControllers) do
		local controller = Knit.Controllers[controllerName]
		if not controller then continue end
		
		CurrentStates[controllerName] = false
		controller.VisibilityChanged:Connect(function(state)
			CurrentStates[controllerName] = state
			
			self.VisibilityChanged:Fire(controllerName, state)
		end)
	end
end

return GUIExposerController