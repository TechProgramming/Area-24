local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService	= game:GetService("CollectionService");
local TweenService		= game:GetService("TweenService");
local StarterGui		= game:GetService("StarterGui");

local PLAYER = game:GetService("Players").LocalPlayer;
local VISION_UI = PLAYER.PlayerGui:WaitForChild("Vision");

local VisionController = Knit.CreateController({
	Name = "VisionController",
});

local TweensOpen	= {};
local TweensClose	= {};

local tween = TweenService:Create(VISION_UI.Container.Background, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.1});
table.insert(TweensOpen, tween);
local tween = TweenService:Create(VISION_UI.Container.Foreground, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0});
table.insert(TweensOpen, tween);
local tween = TweenService:Create(VISION_UI.Container.Icon, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0});
table.insert(TweensOpen, tween);

local tween = TweenService:Create(VISION_UI.Container.Background, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1});
table.insert(TweensClose, tween);
local tween = TweenService:Create(VISION_UI.Container.Foreground, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1});
table.insert(TweensClose, tween);
local tween = TweenService:Create(VISION_UI.Container.Icon, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 1});
table.insert(TweensClose, tween);

function VisionController:KnitStart()
	
	function self:BlinkActivation(activate)
		
		if activate then
			
			VISION_UI.Enabled = true;
			for _, tween in pairs(TweensOpen) do
				tween:Play();
			end;
		else
			
			TweenService:Create(VISION_UI.Container.Foreground, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play();
			for _, tween in pairs(TweensClose) do
				tween:Play();
			end;
			wait(1);
			VISION_UI.Enabled = false;
		end;
	end;
	
	PLAYER.CharacterAdded:Connect(function(character)
		
		self:BlinkActivation(false);
		character:GetAttributeChangedSignal("BlinkIn"):Connect(function()
			TweenService:Create(VISION_UI.Container.Foreground, TweenInfo.new((character:GetAttribute("BlinkIn") - os.time()) - 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Position = UDim2.new(-1, 0, 0, 0)}):Play();
		end);
	end);
	
	CollectionService:GetInstanceRemovedSignal("173-To-Player_Seen"):Connect(function(character)
		if character == PLAYER.Character then
			self:BlinkActivation(false);
		end;
	end);
	
	CollectionService:GetInstanceAddedSignal("173-To-Player_Seen"):Connect(function(character)
		if character == PLAYER.Character then
			self:BlinkActivation(true);
		end;
	end);
	
	CollectionService:GetInstanceAddedSignal("Player-To-173_Blinking"):Connect(function(character)
		if character == PLAYER.Character then
			TweenService:Create(VISION_UI.Container.Foreground, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play();
		end;
	end);
end;

return VisionController;