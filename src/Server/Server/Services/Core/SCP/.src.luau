local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal	= require(Knit.Util.Remote.RemoteSignal);
local KnitSignal	= require(Knit.Util.Signal);

local CollectionService = game:GetService("CollectionService");

local PlayerService	= game:GetService("Players");

local SCPService = Knit.CreateService({ 
	Name = "SCPService",
	SCPs = {},
	OnContainmentBreach = KnitSignal.new(),
	OnContain			= KnitSignal.new(),
	OnSpawn				= KnitSignal.new(),
	OnDespawn			= KnitSignal.new(),
});

function SCPService:KnitStart()
	
	local ProfileService	= Knit.Services.ProfileService;
	local EventService		= Knit.Services.EventService;
	local DoorService		= Knit.Services.DoorService;
	
	function self:AI()
		if script:GetAttribute("Active") then
			script:SetAttribute("Active", false);
			return false;
		else
			script:SetAttribute("Active", true);
			return true;
		end;
	end;
	
	self.OnContainmentBreach:Connect(function(container)
		
		EventService:StartEvent("Emergency");
		CollectionService:AddTag(container, "Breached");
		DoorService:BreakDoor(container.Door, true, true);
		print(container.Name, "breached containment!");
	end);
	
	self.OnContain:Connect(function(container)
		
		CollectionService:RemoveTag(container, "Breached");
		print(container.Name, "recontained");
		
		if #CollectionService:GetTagged("Breached") <= 0 then
			EventService:EndEvent("Emergency");
		end;
	end);
	
	for _, scpModule in pairs(script.Entities:GetChildren()) do

		self.SCPs[scpModule.Name] = require(scpModule);
		self.SCPs[scpModule.Name]:Setup();
	end;
	
	coroutine.wrap(function()
		while true do task.wait(1);
			if script:GetAttribute("Active") then
				for scp, module in pairs(SCPService.SCPs) do
					module:Update();
				end;
			end;
		end;
	end)();
end;

return SCPService;