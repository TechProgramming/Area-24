local Knit = require(game:GetService("ReplicatedStorage").Knit)
local MainMenuService = Knit.GetService("MainMenuService")

local TweenService = game:GetService("TweenService")

local PLAYER = game:GetService("Players").LocalPlayer
local CAMERA = game.Workspace.CurrentCamera

local CameraSystem = {
	CameraTween = nil,
	TransitionPartsCFrame = MainMenuService:GetTransitionPartsCFrame(),
}


--Starts the main menu camera transition
function CameraSystem:StartTransition()
	--Setup camera so it is ready for tweening
	MainMenuService:SetCameraReplicationPart()
	CAMERA.CameraType = Enum.CameraType.Scriptable
	CAMERA.CFrame = self.TransitionPartsCFrame.TransitionOne
	
	--Start a tween that tweens the camera to tween part 2
	local tweenInfo = TweenInfo.new(50, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	self.CameraTween = TweenService:Create(CAMERA,tweenInfo,{CFrame = self.TransitionPartsCFrame.TransitionTwo})
	self.CameraTween:Play()
end


function CameraSystem:ResetCamera()
	--Cancel the tween and set the camera type back to default
	if self.CameraTween then
		self.CameraTween:Cancel()
		self.CameraTween = nil
	end
	CAMERA.CameraType = Enum.CameraType.Custom
	
	--Get character
	local character = PLAYER.Character or PLAYER.CharacterAdded:Wait()
	
	--Reset camera backt to character
	MainMenuService:ResetCameraReplicationPart()
	CAMERA.CameraSubject = character.Humanoid
end


return CameraSystem
