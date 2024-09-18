local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService	= game:GetService("CollectionService");
local TweenService		= game:GetService("TweenService");

local LampService = Knit.CreateService({
	Name = "LampService",
	Client = {},
});

LampService.LampGroup =
{
	
};

--[[ Service Class Structure

Model Lamp
	Required | Part "Center" : Lamp's Primary Class Object
		Optional | Attachment "Interaction" : Required when prompt is needed
			Per-Required | [Proximity Prompt] "OperatePrompt"
				Optional | Sound "Audio" : Plays when Lamp is prompt activated
	Required | Bool	Attribute "Active" : Determines if a Lamp is on
	Optional | Num	Attribute "AccessLevel" : Used for AccessLevel
	Optional | Str	Attribute "PrimaryGroup"
]]

--[[ Service API

GetLightData(Instance lamp)
	"Attempt to get custom module function, and light instances in the provided lamp model"
	"Used as a public internal function"
	Table lights, Function activate, Function deactivate
	
ActivateLight(Instance lamp, Op-Boolean doActivate)
	"Activate or Deactivate a lamp based on doActivate, or Toggle"
	
ActivateLightGroup(String groupName, Op-Boolean doActivate)
	"Activate or Deactivate a group of lamps based on doActivate, or Toggle"

]]

function LampService:KnitStart()
	
	local lamps = CollectionService:GetTagged("Lamp");
	
	local AccessLevelService	= Knit.GetService("AccessLevelService");
	
	function self:GetLightData(lamp)
		
		local module = lamp:FindFirstChildOfClass("ModuleScript");
		local activate, deactivate;
		if module then
			
			activate	= require(module)["Activate"];
			deactivate	= require(module)["Deactivate"];
		end;
		
		local lights = {};
		for _, instance in pairs(lamp:GetDescendants()) do
			if instance:IsA("SpotLight") then
				table.insert(lights, instance);
			end;
		end;
		
		return lights, activate, deactivate;
	end;
	
	function self:ActivateLightGroup(groupName, doActivate)
		
		if self.LampGroup[groupName] then
			
			local groupedLamps = CollectionService:GetTagged(groupName);
			for _, lamp in pairs(groupedLamps) do
				self:ActivateLight(lamp, doActivate);
			end;
		else
			warn(string.format("Door Group %s do not Exist!", groupName));
		end;
	end;
	
	function self:ActivateLight(lamp, doActivate)
		
		local active = lamp:GetAttribute("Active");
		if doActivate then
			--Specified On
			if not active then
				Activate(lamp, true);
			end;
		elseif doActivate == false then
			--Specified Off
			if active then
				Activate(lamp, false);
			end;
		else
			--Toggle On/Off
			if active then
				Activate(lamp, false);
			else
				Activate(lamp, true);
			end;
		end;
	end;
	
	for _, lamp in pairs(lamps) do
		
		local interaction = lamp.PrimaryPart:FindFirstChild("Interaction");
		if interaction then
			local prompt = interaction:FindFirstChild("OperatePrompt");
			if not prompt then
				
				warn(string.format("%s doesn't have a ProximityPrompt!", lamp:GetFullName()));
				continue;
			end;
			prompt.Triggered:Connect(function(player)
				
				if (lamp:GetAttribute("AccessLevel") or 0) > (AccessLevelService:Get(player) or 0) then
					Knit.Services.NotificationService:ShowNotification(player, 2, string.format("You need a Level %s Access Card!", lamp:GetAttribute("AccessLevel") or 0), Color3.fromRGB(255, 55, 55))
				else
						
					prompt.Enabled = false;
					local audio = prompt:FindFirstChild("Audio")
					if audio then
							local clonedAudio = audio:Clone();
						clonedAudio.Parent = prompt.Parent;
						clonedAudio.Ended:Connect(function()
							clonedAudio:Destroy()
						end)
						clonedAudio:Play();
					end;
					LampService:ActivateLight(lamp);
					prompt.Enabled = true;
				end;
			end);
		end;
	end;
end;

function Activate(lamp, doActivate)
	
	local lights, activate, deactivate = LampService:GetLightData(lamp);
	if doActivate then
		
		lamp:SetAttribute("Active", true);
		if activate then
			activate();
		else
			for _, light in pairs(lights) do
				
				light.Enabled = true;
				light.Parent.Material = Enum.Material.Neon;
				light.Parent.Color = light.Color;
			end;
		end;
	else
		
		lamp:SetAttribute("Active", false);
		if activate then
			deactivate();
		else
			for _, light in pairs(lights) do
				
				light.Enabled = false;
				light.Parent.Material = Enum.Material.SmoothPlastic;
				light.Parent.Color = Color3.fromRGB(0, 0, 0);
			end;
		end;
	end;
end;

return LampService;