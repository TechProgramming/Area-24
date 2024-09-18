local CollectionService = game:GetService("CollectionService");
local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local RunService		= game:GetService("RunService");
local PlayerService		= game:GetService("Players");

local Knit = require(ReplicatedStorage.Knit);

local SenseDetectionService = Knit.CreateService({
	Name = "SenseDetectionService",
	Client = {},
	Spawns = {},
});

--[[ Service API

AddSenseDetector(Instance target, Number size, Tuple whitelist)
	"Adds a SenseDetector to specified target with specified size, returns SenseDetector Instance"
	"Assigns whitelist to SenseDetector {String or Array of String}"
	"Use the Bindable Events Prefabricated within SenseDetector"
	String senseDetector
	
RemoveSenseDetector(Instance target)
	"Destroy the target if it is a SenseDetector or if it contain a SenseDetector child"
	
AddSenseTarget(Instance target, Tuple whitelist)
	"Adds a SenseTarget to specified target, returns SenseTarget Instance"
	"Assigns whitelist to SenseTarget {String or Array of String}"
	String senseTarget
	
RemoveSenseTarget(Instance target)
	"Destroy the target if it is a SenseTarget or if it contain a SenseTarget child"

]]

function SenseDetectionService:KnitStart()
	
	local ProfileService	= Knit.GetService("ProfileService");
	
	function self:AddSenseDetector(target, size, whitelist)
		
		if target and size and typeof(size) == "number" and whitelist then
			
			local newSenseDetector = script.SenseDetector:Clone();
			local targetPart;
			
			if target:IsA("Model") and target.PrimaryPart then
				targetPart = target.PrimaryPart;
			elseif target:IsA("Part") then
				targetPart = target;
			else
				newSenseDetector:Destroy();
				warn("Target is not a valid Model or Part");
			end;
			
			if not newSenseDetector.Parent then
				
				newSenseDetector.Size	= Vector3.new(size, size, size);
				newSenseDetector.Parent	= target;
				newSenseDetector.CFrame = targetPart.CFrame;
				newSenseDetector.Weld.Part0 = targetPart;
				
				CollectionService:AddTag(newSenseDetector, "SenseDetector");
				
				local Touching		= newSenseDetector.Touching;
				local TouchEnding	= newSenseDetector.TouchEnding;
				newSenseDetector.Touched:Connect(function(touchObject)
					
					if CollectionService:HasTag(touchObject, "SenseTarget") then
						if typeof(whitelist) == "string" then
							if CollectionService:HasTag(touchObject, whitelist) then
								Touching:Fire(touchObject);
							end;
						else
							for _, whitelisted in pairs(whitelist) do
								if CollectionService:HasTag(touchObject, whitelisted) then
									Touching:Fire(touchObject);
									break;
								end;
							end;
						end;
					end;
				end);
				
				newSenseDetector.TouchEnded:Connect(function(touchObject)
					
					if CollectionService:HasTag(touchObject, "SenseTarget") then
						if typeof(whitelist) == "string" then
							if CollectionService:HasTag(touchObject, whitelist) then
								TouchEnding:Fire(touchObject);
							end;
						else
							for _, whitelisted in pairs(whitelist) do
								if CollectionService:HasTag(touchObject, whitelisted) then
									TouchEnding:Fire(touchObject);
									break;
								end;
							end;
						end;
					end;
				end);
				
				return newSenseDetector;
			end;
		else
			warn("No Target or Whitelist or Size or Size isn't number");
		end;
	end;
	
	function self:RemoveSenseDetector(target)
		
		if target then
			
			if CollectionService:HasTag(target, "SenseDetector") then
				target:Destroy();
			elseif target:FindFirstChild("SenseDetector") then
				target = target.SenseDetector;
				if CollectionService:HasTag(target, "SenseDetector") then
					target:Destroy();
				end;
			end;
		end;
	end;
	
	function self:AddSenseTarget(target, whitelist)
		
		if target and whitelist then
			
			local newSenseTarget = script.SenseTarget:Clone();
			local targetPart;
			
			if target:IsA("Model") and target.PrimaryPart then
				targetPart = target.PrimaryPart;
			elseif target:IsA("Part") then
				targetPart = target;
			else
				newSenseTarget:Destroy();
				warn("Target is not a valid Model or Part");
			end;
			
			if not newSenseTarget.Parent then
				
				newSenseTarget.Parent = target;
				newSenseTarget.CFrame = targetPart.CFrame;
				newSenseTarget.Weld.Part0 = targetPart;
				
				CollectionService:AddTag(newSenseTarget, "SenseTarget");
				
				if typeof(whitelist) == "string" then
					CollectionService:AddTag(newSenseTarget, whitelist);
				else
					for _, whitelisted in pairs(whitelist) do
						CollectionService:AddTag(newSenseTarget, whitelisted);
					end;
				end;
				return newSenseTarget;
			end;
		else
			warn("No Target or Whitelist");
		end;
	end;
	
	function self:RemoveSenseTarget(target)
		
		if target then

			if CollectionService:HasTag(target, "SenseTarget") then
				target:Destroy();
			elseif target:FindFirstChild("SenseTarget") then
				target = target.SenseTarget;
				if CollectionService:HasTag(target, "SenseTarget") then
					target:Destroy();
				end;
			end;
		end;
	end;
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		self:AddSenseTarget(character, "Sense_Player");
	end);
end;

return SenseDetectionService;