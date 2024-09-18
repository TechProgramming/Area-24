local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local TweenService		= game:GetService("TweenService");
local StarterGui		= game:GetService("StarterGui");
local Players			= game:GetService("Players");

local Knit = require(ReplicatedStorage.Knit);
local KnitSignal = require(Knit.Util.Signal)

local HelpTipController = Knit.CreateController({
	Name = "HelpTipController",
});

local PLAYER = Players.LocalPlayer;

local TipPool = require(script:WaitForChild("TipPool"));

local SHOW_POSITION	= UDim2.new(0.99, 0, 0.345, 0);
local HIDE_POSITION	= UDim2.new(1.25, 0, 0.345, 0);

local HELPTIP_COOLDOWN	= NumberRange.new(150, 300);--.new(150, 300);
local HELPTIP_DURATION	= 15;

function HelpTipController:KnitStart()
	
	local ProfileService = Knit.GetService("ProfileService");
	
	function self:GetTip()
		
		local tipList = {};
		for _, tip in pairs(TipPool) do
			
			if tip.TypePool == "Neutral" then
				table.insert(tipList, tip);
			elseif tip.TypePool == "Easter Egg" then
				if math.random(1, 100000) == 1 then
					table.insert(tipList, tip);
				end;
			elseif tip.TypePool == PLAYER.Team.Name then
				table.insert(tipList, tip);
			end;
		end;
		return tipList;
	end;
	
	function self:Show(interface)
		interface.Enabled = true;
		interface.Frame:TweenPosition(SHOW_POSITION, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1, true);
		spawn(function()
			wait(1);
			TweenService:Create(interface.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 1, true), {BackgroundColor3 = Color3.fromRGB(150, 150, 150)}):Play();
		end);
	end;
	
	function self:Hide(interface)
		interface.Frame:TweenPosition(HIDE_POSITION, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1, true);
		spawn(function()
			wait(1);
			interface.Enabled = false;
		end);
	end;
	
	PLAYER.CharacterAdded:Connect(function(character)

		local helpTip = PLAYER.PlayerGui:WaitForChild("HelpTip");
		if character then

			helpTip.Frame.MouseButton1Click:Connect(function()
				self:Hide(helpTip);
			end);
			local success, response = pcall(function()
				while character and character.Parent do wait(math.random(HELPTIP_COOLDOWN.Min, HELPTIP_COOLDOWN.Max));
					
					local tipList = self:GetTip();
					local chosenTip = tipList[math.random(1, #tipList)];
					if chosenTip then
						
						if chosenTip.Title then
							helpTip.Frame.Title.Text = chosenTip.Title;
						end;
						if chosenTip.Description then
							helpTip.Frame.Description.Text = chosenTip.Description;
						end;
					end;
					self:Show(helpTip);
					wait(HELPTIP_DURATION);
					self:Hide(helpTip);
				end;
			end);
		end;
	end);
end;

return HelpTipController;