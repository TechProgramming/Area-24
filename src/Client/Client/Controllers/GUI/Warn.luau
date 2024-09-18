local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local TweenService		= game:GetService("TweenService");
local StarterGui		= game:GetService("StarterGui");
local Players			= game:GetService("Players");

local Knit = require(ReplicatedStorage.Knit);

local WarnController = Knit.CreateController({
	Name = "WarnController",
});

local PLAYER = Players.LocalPlayer;

local WARNGUI = PLAYER.PlayerGui:WaitForChild("Warn");

function WarnController:KnitStart()
	local WarnService = Knit.GetService("WarnService");
	WARNGUI.Frame.Close.MouseButton1Click:Connect(function()
		if WARNGUI.Frame.BorderSizePixel == 0 then
			WARNGUI.Enabled = false;
		end;
	end);
	
	WarnService.OnWarn:Connect(function(description)
		WARNGUI.Frame.Description.Text = description;
		WARNGUI.Frame.BorderSizePixel = 20;
		WARNGUI.Enabled = true;
		TweenService:Create(WARNGUI.Frame, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BorderSizePixel = 0}):Play();
	end);
end;

return WarnController;