local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local Knit				= require(ReplicatedStorage:WaitForChild("Knit"));

local PathfindingService	= game:GetService("PathfindingService");
local CollectionService		= game:GetService("CollectionService");
local HttpService			= game:GetService("HttpService");
local RunService			= game:GetService("RunService");

local AgentService = Knit.CreateService({ 
	Name	= "AgentService",
	Agent	= {},
});

--[[ Service API

New(Instance target, Path path, Op-Instance container)
	"Creates a new Agent from provided target character and precreated Pathfinding Path Instance"
	"Optionally use container folder"
	Tuple[] agent

CreateDirective(Tuple agent, Vector3 targetPosition, Instance nodeMap)
	"Create Node Map Target from NavigationService and assigns it to the Agent"
	"Can be called multiple times to update"
	Vector3[] directive
	
ClearDirective(Tuple agent)
	"Clear Node Map Target from the specified Agent"

CreateWaypoints(Tuple agent, Vector3 targetPosition, String waypointType)
	"Creates Waypoints using PathfindingService and assigns it to the Agent, returns path success status"
	"Assigns Waypoint Type for usage statement"
	"Can be called multiple times to update"
	Boolean success
	
ClearWaypoints(Tuple agent)
	"Clear Waypoints created by PathfindingService from specified Agent"
	
]]

function AgentService:KnitStart()
	
	local NavigationService = Knit.Services.NavigationService;
	
	function self:New(character, path, container)
		
		self.Agent[character] = {
			Name		= character.Name;
			Character	= character;
			Container	= container;
			Path		= path;
		};
		
		return self.Agent[character];
	end;
	
	function self:Remove(target)
		
		self.Agent[target] = nil;
	end;
	
	function self:CreateDirective(agent, targetPosition, nodeMap)
		
		local start = agent.Character.HumanoidRootPart.Position;
		
		local success, directive = NavigationService:FindDirective(start, targetPosition, nodeMap);
		agent.Directive = directive;
		if script:GetAttribute("Debug_Main") then
			print(string.format("%s Requested to create directive of %s, result as %s", agent.Name, nodeMap.Name, tostring(success)));
		end;
		return success;
	end;
	
	function self:ClearDirective(agent)
		agent.Directive = nil;
	end;
	
	function self:CreateWaypoints(agent, startPosition, targetPosition, waypointType)
		
		agent.Path:ComputeAsync(startPosition, targetPosition);
		agent.Waypoints = agent.Path:GetWaypoints();
		agent.WaypointType = waypointType;
		if script:GetAttribute("Debug_Main") then
			print(string.format("%s Requested to create waypoint of %s, result as %s", agent.Name, waypointType, tostring(agent.Path.Status == Enum.PathStatus.Success)));
		end;
		
		return agent.Path.Status == Enum.PathStatus.Success;
	end;
	
	function self:ClearWaypoints(agent)
		
		agent.Waypoints = nil;
		agent.WaypointType = nil;
	end;
end;

return AgentService;