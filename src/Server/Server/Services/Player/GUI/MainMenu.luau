
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local SCRIPTED = game.Workspace:WaitForChild("Scripted")

local MainMenuService = Knit.CreateService({
	Name = "MainMenuService",
	Client = {},
})


--Change a players replication
function MainMenuService.Client:GetTransitionPartsCFrame()
	return {
		TransitionOne = SCRIPTED.MainMenu.TransitionOne.CFrame,
		TransitionTwo = SCRIPTED.MainMenu.TransitionTwo.CFrame
	}
end


function MainMenuService.Client:RequestStreamingAtCameraTransition(player)
	player:RequestStreamAroundAsync(SCRIPTED.MainMenu.TransitionOne.Position)
end


--Set camera replication part
function MainMenuService.Client:SetCameraReplicationPart(player)
	player.ReplicationFocus = SCRIPTED.MainMenu.TransitionOne
end


--Reset camera replication part
function MainMenuService.Client:ResetCameraReplicationPart(player)
	player.ReplicationFocus = nil
end


return MainMenuService