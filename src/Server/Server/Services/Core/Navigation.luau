local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local Knit				= require(ReplicatedStorage:WaitForChild("Knit"));

local NavigationService = Knit.CreateService({ 
	Name		= "NavigationService",
	pathNodes	= {},
});

-- Pathfinder
-- Stephen Leitnick
-- March 31, 2021

--[[

	This utilizes the nodes created with the Node Map V2 plugin.

	Pathfinder:FindPath(startPosition: Vector3, endPosition: Vector3): Vector3[]

--]]

--[[ Service API

FindDirective(Vector3 startPosition, Vector3 goalPosition, Instance nodeMap)
	"Find a Path from generated nodemap from start to goal, will create new nodemap if one doesn't exist"
	Vector3[] path

Init(Instance nodeMap)
	"Create a new nodemap from provided Nodemap Project Folder"
	Tuple[] pathNodes
]]

function NavigationService:KnitStart()
	
	function self:FindDirective(startPosition, goalPosition, nodemap)
		
		local availableNodes = self.pathNodes[nodemap.Name];
		if (not availableNodes) then
			availableNodes = self:Init(nodemap);
		end;
		
		local path = {};
		local pathFound = false;
		
		local startNode = self:FindNearestNode(startPosition, availableNodes);
		local goalNode = self:FindNearestNode(goalPosition, availableNodes);
		
		local open = {[startNode] = true};
		local closed = {};
		-- Find node with lowest F score within the "open" list:
		local function FindLowestFNode()
			
			local lowestF, node = math.huge, nil;
			for targetNode in pairs(open) do
				if (targetNode.F < lowestF) then
					lowestF, node = targetNode.F, targetNode;
				end;
			end;
			return node;
		end;
		-- Find path via A* algorithm:
		while (next(open)) do
			-- Find node with lowest F score in open list.
			-- Switch that node from open list to closed list.
			local node = FindLowestFNode();
			open[node] = nil;
			closed[node] = true;
			-- If the node we just got is the goal node, we found the path!
			if (node == goalNode) then
				
				pathFound = true;
				break;
			end;
			-- Scan through all neighbors of this node.
			for _, neighbor in ipairs(node.Neighbors) do
				-- If it's not closed, let's examine it.
				if (not closed[neighbor]) then
					-- If it's not in the open list, let's add it to the list and do some calculations on it.
					if (not open[neighbor]) then
						
						open[neighbor] = true;
						neighbor.Parent = node;
						neighbor.G = node.G + (neighbor.Position - node.Position).Magnitude;
						neighbor.H = (neighbor.Position - goalNode.Position).Magnitude;
						neighbor.F = (neighbor.G + neighbor.H);
					else
						-- If it is on the open list and is a good pick for the next path, let's redo some of the calculations
						if (neighbor.G < node.G) then
							neighbor.Parent = node;
							neighbor.G = node.G + (neighbor.Position - node.Position).Magnitude;
							neighbor.F = (neighbor.G + neighbor.H);
						end;
					end;
				end;
			end;
		end;
		-- Backtrace path:
		if (pathFound) then
			
			local node = goalNode;
			while (node) do
				
				table.insert(path, 1, node.Position);
				node = node.Parent;
			end;
		end;
		-- Reset nodes:
		local function ResetNodeDictionary(dict)
			
			for node in pairs(dict) do
				
				node.F = 0;
				node.G = 0;
				node.H = 0;
				node.Parent = nil;
			end;
		end;
		ResetNodeDictionary(open);
		ResetNodeDictionary(closed);
		
		return pathFound or nil, path or nil;
	end;
	
	function self:BuildNodes(nodemap)
		
		local nodeProjectFolder = nodemap;
		local nodes = {};
		local dict = {};
		-- Get nodes:
		for _, folder in ipairs(nodeProjectFolder:GetChildren()) do

			if (folder:IsA("Folder")) then

				local node =
					{
						Position = folder:GetAttribute("NodePosition"),
						Neighbors = {},
						F = 0,
						G = 0,
						H = 0,
						Parent = nil,
					};
				table.insert(nodes, node);
				dict[folder:GetAttribute("NodeId")] = node;
			end;
		end;
		-- Get node neighbors:
		for _, folder in ipairs(nodeProjectFolder:GetChildren()) do

			if (folder:IsA("Folder")) then

				local links = folder:GetAttribute("NodeLinks"):split(",");
				local node = dict[folder:GetAttribute("NodeId")];
				for _, linkId in ipairs(links) do

					local neighborNode = dict[linkId];
					table.insert(node.Neighbors, neighborNode);
					table.insert(neighborNode.Neighbors, node);
				end;
			end;
		end;
		self.pathNodes[nodemap.Name] = nodes;
		return self.pathNodes[nodemap.Name];
	end;
	
	function self:FindNearestNode(position, pathNodes)

		local dist, nearest = math.huge, nil;
		for _, node in ipairs(pathNodes) do

			local d = (position - node.Position).Magnitude;
			if (d < dist) then
				dist, nearest = d, node;
			end;
		end;
		return nearest;
	end;
	
	function self:Init(nodemap)
		
		local availableNodes = self:BuildNodes(nodemap);
		return availableNodes;
	end;
end;

return NavigationService;