local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService	= game:GetService("CollectionService");

local LampControlService = Knit.CreateService({
	Name = "LampControlService",
	Client = {},
});

function LampControlService:KnitStart()
	
	local lampcontrols = CollectionService:GetTagged("Lamp Control");
	
	local AccessLevelService	= Knit.GetService("AccessLevelService");
	local LampService			= Knit.GetService("LampService");
	
	for _, panel in pairs(lampcontrols) do
		
		local target = panel:GetAttribute("Target");
		if not target then
			local config = panel:FindFirstChild("Configuration");
			if not config then
				
				warn(string.format("%s doesn't have a Configuration Folder!", panel:GetFullName()));
				continue;
			end;
			target = config:FindFirstChild("Target");
			if not target then
				
				warn(string.format("%s doesn't have a Target Value!", panel:GetFullName()));
				continue;
			end;
		end;
		
		local interaction = panel.PrimaryPart:FindFirstChild("Interaction");
		if interaction then
			
			local prompt = interaction:FindFirstChild("OperatePrompt");
			if not prompt then
				
				warn(string.format("%s doesn't have a ProximityPrompt!", panel:GetFullName()));
				continue;
			end;
			prompt.Triggered:Connect(function(player)
				
				if (panel:GetAttribute("AccessLevel") or 0) > (AccessLevelService:Get(player) or 0) then
					Knit.Services.NotificationService:ShowNotification(player, 2, string.format("You need a Level %s Access Card!", panel:GetAttribute("AccessLevel") or 0), Color3.fromRGB(255, 55, 55))
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
					if typeof(target) == "string" then
						LampService:ActivateLightGroup(target);
					else
						LampService:ActivateLight(target.Value);
					end;
					prompt.Enabled = true;
				end;
			end);
		end;
	end;
end;

return LampControlService;