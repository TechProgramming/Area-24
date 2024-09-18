local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local PLAYER = game:GetService("Players").LocalPlayer
local RIGHT_BAR = PLAYER.PlayerGui:WaitForChild("RightBar")
local LEFT_BAR = PLAYER.PlayerGui:WaitForChild("LeftBar")
local EMOTE_UI = PLAYER.PlayerGui:WaitForChild("Emotes")
local Animations = game.ReplicatedStorage.Animations

local EmoteController = Knit.CreateController({
	Name = "EmoteController",
	EnabledUI = false,
	VisibilityChanged = KnitSignal.new()
})

function EmoteController:KnitStart()
	local EmoteService = Knit.GetService("EmoteService")
	local ProfileService = Knit.GetService("ProfileService")
	local SideBarController = Knit.GetController("SideBarController")
	local SFXController = Knit.GetController("SFXController")
	--Handle the main menu opening and closing
	SideBarController.VisibilityChanged:Connect(function(visible)
		if visible and self.EnabledUI then
			EMOTE_UI.Enabled = true
		else
			EMOTE_UI.Enabled = false
		end
	end)
	
	for _, category in pairs(Animations.Emotes:GetChildren()) do
		if category:GetAttribute("EnableUI") then
			for _, anim in pairs(category:GetChildren()) do
				local temp = EMOTE_UI.Container.Template:Clone()
				temp.Parent = EMOTE_UI.Container[category.Name]
				temp.AnimationName.Text = anim.Name
				temp.Visible = true
				temp.MouseButton1Down:Connect(function()
					SFXController:PlayPrefab("ButtonClick")
					EmoteService.OnEmote:Fire(anim.Name)
				end)
				
				temp.MouseEnter:Connect(function()
					SFXController:PlayPrefab("ButtonHover")
				end)
			end
		end
	end
	
	EMOTE_UI.Container.View.Standard.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		EMOTE_UI.Container.Standard.Visible = true
		EMOTE_UI.Container.Duo.Visible = false
	end)
	
	EMOTE_UI.Container.View.Duo.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonError")
		--EMOTE_UI.Container.Standard.Visible = false
		--EMOTE_UI.Container.Duo.Visible = true
	end)
	
	EMOTE_UI.Container.View.Standard.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)	
	
	EMOTE_UI.Container.View.Duo.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	LEFT_BAR.Container.Emotes.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	LEFT_BAR.Container.Emotes.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		if not EMOTE_UI.Enabled then
			LEFT_BAR.Container.Emotes.BackgroundColor3 = Color3.new(0.486275, 0.486275, 0.486275)
			EmoteController.EnabledUI = true
			EMOTE_UI.Enabled = true
		else
			LEFT_BAR.Container.Emotes.BackgroundColor3 = Color3.new(0, 0, 0)
			EmoteController.EnabledUI = false
			EMOTE_UI.Enabled = false				
		end
	end)


end


return EmoteController