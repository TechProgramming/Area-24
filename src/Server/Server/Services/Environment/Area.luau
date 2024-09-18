local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal	= require(Knit.Util.Remote.RemoteSignal)
local KnitSignal	= require(Knit.Util.Signal)

local CollectionService	= game:GetService("CollectionService");
local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local ServerStorage		= game:GetService("ServerStorage");
local SoundService		= game:GetService("SoundService");

local AreaService = Knit.CreateService({ 
	Name = "AreaService", 
	OnAreaEntered = KnitSignal.new(),
	Client = {
		OnAreaChange = RemoteSignal.new()
	}
})

local LightingData = ServerStorage:FindFirstChild("Plugin_LightingSaves");

local PlayerAreaHistory = {}

function AreaService:KnitStart()
	
	local NotificationService	= Knit.GetService("NotificationService");
	local ProfileService		= Knit.GetService("ProfileService");
	local DoorService			= Knit.GetService("DoorService");
	local SCPService			= Knit.GetService("SCPService");
	
	function self:AttachPlayer(player, character)
		
		character.PrimaryPart.Touched:Connect(function(part)
			
			if CollectionService:HasTag(part, "Area") and PlayerAreaHistory[player] ~= part.Name then
				
				PlayerAreaHistory[player] = part.Name
				NotificationService:ShowNotification(player, 3, part.Name, Color3.fromRGB(53, 151, 255))
				self.Client.OnAreaChange:Fire(player, part.Name, part);
				self.OnAreaEntered:Fire(player, part.Name, part);
			end
		end)
		
		character.PrimaryPart.TouchEnded:Connect(function(part)
			
			if part.Parent and part.Parent.Name == "Areas" then
				
				PlayerAreaHistory[player] = ""
				NotificationService:ShowNotification(player, 3, "", Color3.fromRGB(53, 151, 255))
				self.Client.OnAreaChange:Fire(player, "", nil)
			end		
		end);
	end;
	
	function self:AttachSCP(character)
		
		character.PrimaryPart.Touched:Connect(function(part)
			
			if CollectionService:HasTag(part, "Breakout") and CollectionService:HasTag(character.Parent, "Breached") then
				
				if part:GetAttribute("DoorGroup") then
					
					wait(1);
					DoorService:BreakDoorGroup(part:GetAttribute("DoorGroup"), true, true);
				end;
			end;
		end);
	end;
	
	function self:GetAudio(player, area)
		
		local areaSound = SoundService.Area:FindFirstChild(area.Name);
		
		if areaSound then
			return areaSound:GetChildren();
		end;
		return nil;
	end;
	
	function self:GetSync(player, area)
		return nil;
	end;
	
	ProfileService.PlayerAdded:Connect(function(player)
		PlayerAreaHistory[player] = ""
	end)
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		self:AttachPlayer(player, character);
	end);
	
	ProfileService.PlayerRemoving:Connect(function(player)
		PlayerAreaHistory[player] = nil;
	end);
	
	for _, player in pairs(game.Players:GetPlayers()) do
		PlayerAreaHistory[player] = ""
		--player.CharacterAdded:Wait()
		--AreaService:AttachNotifier(player, player.Character)
	end;
	
	if LightingData then
		LightingData.Name = "LightingSetting";
		LightingData.Parent = ReplicatedStorage;
	end;
end;

function AreaService.Client:GetAudio(player, area)
	return AreaService:GetAudio(player, area);
end;

function AreaService.Client:GetSync(player, area)
	return AreaService:GetSync(player, area);
end;

return AreaService;