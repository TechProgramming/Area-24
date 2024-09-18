local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

local PLAYER		= game:GetService("Players").LocalPlayer
local ACCESSLEVEL	= PLAYER.PlayerGui:WaitForChild("AccessLevel")

local AccessLevelController = Knit.CreateController({
	Name = "AccessLevelController",
})

function AccessLevelController:KnitStart()
	
	local AccessLevelService = Knit.GetService("AccessLevelService")
	
	function self:Update(level)
		ACCESSLEVEL.Display.Text = string.format("Access Level: %s", level or AccessLevelService:Get(PLAYER) or 0);
	end;

	AccessLevelService.OnUpdate:Connect(function(total, newLevel)
		self:Update(newLevel);
	end)
	self:Update();
	
	ACCESSLEVEL.Display.Info.MouseButton1Click:Connect(function()
		ACCESSLEVEL.InfoText.Visible = not ACCESSLEVEL.InfoText.Visible
	end)
end

return AccessLevelController