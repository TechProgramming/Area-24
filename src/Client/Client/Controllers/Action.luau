local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local KnitSignal = require(Knit.Util.Signal)

local PLAYER = game:GetService("Players").LocalPlayer
local ACTION = PLAYER.PlayerGui:WaitForChild("Action")

local ActionController = Knit.CreateController({
	Name = "ActionController",
	VisibilityChanged = KnitSignal.new(),
})

function ActionController:KnitStart()
	local ActionService = Knit.GetService("ActionService")
	local SFXController = Knit.GetController("SFXController")
	
	function ActionController:Show()
		ACTION.Enabled = true
		self.VisibilityChanged:Fire(true)
	end

	function ActionController:Hide()
		ACTION.Enabled = false
		self.VisibilityChanged:Fire(false)
	end

	ACTION.Close.CloseButton.MouseButton1Down:Connect(function()
		ActionService.OnStopAction:Fire()
		ActionController:Hide()
	end)

	ACTION.Close.CloseButton.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)

	ActionService.OnActionStarted:Connect(function()
		ActionController:Show()
	end)

end


return ActionController