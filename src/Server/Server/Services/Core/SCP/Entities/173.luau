local PathfindingService	= game:GetService("PathfindingService");
local CollectionService		= game:GetService("CollectionService");
local ReplicatedStorage		= game:GetService("ReplicatedStorage");
local ServerStorage			= game:GetService("ServerStorage");
local PlayerService			= game:GetService("Players");

local Knit	= require(ReplicatedStorage.Knit);

local servicesLoaded    = false;
local ProfileService;
local VisionService;
local AgentService;
local DoorService;
local AreaService;
local SCPService;

local SCP = Knit.CreateService({
	Name = "_SCP_173",
	Client = {},
});

local Container		= game.Workspace.Scripted.SCPs[script.Name];
local SCPNodemap	= ReplicatedStorage.NodeMapProjects.SCP;
	
local path = PathfindingService:CreatePath({
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = false,
});

local DIRECT_TIMEOUT	= 3;
local THINK_TIMEOUT		= 3;
local PATH_TIMEOUT		= 3;

local PATH_START_BIAS			= 8;
local PATH_END_BIAS				= 4;
local WANDER_SIZE_BIAS			= 8;
local DIRECTIVE_REACH_RADIUS	= 10;

local ESCAPE_DISTANCE = 150;

local ATTACK_RANGE	= 6;
local ATTACK_DAMAGE	= math.huge;

function SCP:KnitStart() 
	
	ProfileService 	= Knit.GetService("ProfileService");
	VisionService 	= Knit.GetService("VisionService");
	AgentService 	= Knit.GetService("AgentService");
	DoorService 	= Knit.GetService("DoorService");
	AreaService 	= Knit.GetService("AreaService");
	SCPService 		= Knit.GetService("SCPService");

	servicesLoaded = true;
end;

function Normalize(vector)
	return Vector3.new(vector.X, 0, vector.Z);
end;

function SCP:DebugWaypoints()
	if script:GetAttribute("Debug_Pathfinding") then
		for _, waypoint in ipairs(self.Agent.Waypoints) do
			local newWay = Instance.new("Part");
			newWay.Anchored = true;
			newWay.Size = Vector3.new(0.5, 0.5, 0.5);
			newWay.Material = Enum.Material.Neon;
			newWay.CFrame = CFrame.new(waypoint.Position);
			newWay.CanCollide = false;
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				newWay.Color = Color3.fromRGB(255, 255, 0);
			end;
			newWay.Parent = game.Workspace.Debug;
			game:GetService("Debris"):AddItem(newWay, 1);
		end;
	end;
end;

function SCP:DebugDirective()
	if script:GetAttribute("Debug_Pathfinding") then
		for _, node in ipairs(self.Agent.Directive) do
			local newWay = Instance.new("Part");
			newWay.Anchored = true;
			newWay.Size = Vector3.new(2, 2, 2);
			newWay.Material = Enum.Material.Neon;
			newWay.CFrame = CFrame.new(node);
			newWay.CanCollide = false;
			newWay.Color = Color3.fromRGB(0, 255, 0);
			newWay.Parent = game.Workspace.Debug;
			game:GetService("Debris"):AddItem(newWay, 1);
		end;
	end;
end;

function SCP:Setup()
	if not script:GetAttribute("Disabled") then
		if not servicesLoaded then
			repeat task.wait(1) until servicesLoaded;
		end;
		
		ServerStorage.Asset.SCP[script.Name].Character:Clone().Parent = Container;
		self.Agent = AgentService:New(Container.Character, path, Container);
		self.Agent.Character.HumanoidRootPart.CFrame = Container.Spawn.CFrame + Vector3.new(0, self.Agent.Character.Humanoid.HipHeight, 0);
		self.Agent.HipVector = Vector3.new(0, self.Agent.Character.Humanoid.HipHeight, 0);
		VisionService:AddTarget("Player-To-173", self.Agent.Character, self.Agent.Character.Head);
		VisionService:AddWatcher("173-To-Player", self.Agent.Character, self.Agent.Character.Head);
		SCPService.OnSpawn:Fire(self.Agent.Character);
		AreaService:AttachSCP(self.Agent.Character);
		self.Agent.Character.HumanoidRootPart.ProximityPrompt.Triggered:Connect(function(player)
			
			if math.random(1, 3) == 1 then
				self.Agent.Character.HumanoidRootPart.ProximityPrompt.Enabled = false;
				local profile = ProfileService:GetProfile(player);
				profile.SCPData[script.Name].Contained += 1;
				SCP:Clear();
			else
				Knit.Services.NotificationService:ShowNotification(player, 2, string.format("Containment Failed! (%s%% Chance)", tostring(33)), Color3.fromRGB(255, 55, 55));
			end;	
		end);
		self.Agent.Character.HumanoidRootPart.Touched:Connect(function(part)
			if CollectionService:HasTag(part, "EntityReset") then
				SCP:Clear();
			end;
		end);
	end;
end;

function SCP:Clear()
	if not CollectionService:HasTag(Container, "SCP Respawning") then
		
		CollectionService:AddTag(Container, "SCP Respawning");
		if self.Agent then
			if self.Agent.Character then
				self.Agent.Character:Destroy();
			end;
			AgentService:Remove(self.Agent.Character);
			self.Agent = nil;
		end;
		if Container:FindFirstChild("Character") then
			Container.Character:Destroy();
		end;
		Container:SetAttribute("Contained", true);
		Container:SetAttribute("ContainmentHealth", 10000);
		Container:SetAttribute("State", "ContainmentWander");
		SCPService.OnContain:Fire(Container);
		
		task.wait(1);
		
		SCP:Setup();
		CollectionService:RemoveTag(Container, "SCP Respawning");
	end;
end;

function SCP:Move(scpPosition, targetPosition)
	
	local lookVector = targetPosition - scpPosition;
	self.Agent.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + self.Agent.HipVector, (targetPosition + lookVector) + (self.Agent.HipVector*2));
end;

function SCP:BreachWander()
	
	local scpHumanoidRootPart = self.Agent.Character.HumanoidRootPart;
	local scpPosition = scpHumanoidRootPart.Position;
	
	if not self.Agent.Directive then
		
		math.randomseed(tick());
		local nodeTarget = SCPNodemap:GetChildren()[math.random(1, #SCPNodemap:GetChildren())]:GetAttribute("NodePosition");
		local success = AgentService:CreateDirective(self.Agent, nodeTarget, SCPNodemap);
		self:BreachWander();
	else
		
		SCP:DebugDirective();
		if self.Agent.WaypointType ~= "Breach" then
			
			local nodeTarget = self.Agent.Directive[1];
			local success = AgentService:CreateWaypoints(self.Agent,
				Vector3.new(math.random(scpPosition.X - PATH_START_BIAS, scpPosition.X + PATH_START_BIAS), scpPosition.Y,math.random(scpPosition.Z - PATH_START_BIAS, scpPosition.Z + PATH_START_BIAS)),
				Vector3.new(math.random(nodeTarget.X - PATH_END_BIAS, nodeTarget.X + PATH_END_BIAS), nodeTarget.Y, math.random(nodeTarget.Z - PATH_END_BIAS, nodeTarget.Z + PATH_END_BIAS)),
				"Breach");
			if success then
				self:BreachWander();
			else
				AgentService:ClearWaypoints(self.Agent);
				if not self.Agent.Directed then
					self.Agent.Directed = 0;
				end;
				self.Agent.Directed += 1;
				if self.Agent.Directed >= DIRECT_TIMEOUT then
					AgentService:ClearDirective(self.Agent);
				end;
			end;
		else
			
			local targetWaypoint;
			if #self.Agent.Waypoints > 8 then
				targetWaypoint = 8;
			else
				targetWaypoint = #self.Agent.Waypoints;
			end;
			
			SCP:DebugWaypoints();
			
			local targetPosition = self.Agent.Waypoints[targetWaypoint].Position;
			self:Move(scpPosition, targetPosition);
			
			if (Normalize(self.Agent.Directive[1]) - Normalize(scpHumanoidRootPart.Position)).magnitude <= DIRECTIVE_REACH_RADIUS then
				
				table.remove(self.Agent.Directive, 1);
				AgentService:ClearWaypoints(self.Agent);
				if #self.Agent.Directive <= 0 then
					AgentService:ClearDirective(self.Agent);
				else
					self:BreachWander();
				end;
			else
				
				for _ = 1, targetWaypoint do
					table.remove(self.Agent.Waypoints, 1);
				end;
				if #self.Agent.Waypoints <= 0 then
					AgentService:ClearWaypoints(self.Agent);
				end;
			end;
		end;
	end;
end

function SCP:ContainmentWander()
	
	if math.random(1, 100) <= 40 then
		
		if self.Agent.WaypointType ~= "Wander" then
			
			local scpPosition = self.Agent.Character.HumanoidRootPart.Position;
			local spawnPosition	= Container.Spawn.Position;
			repeat task.wait(1/10);
				local success = AgentService:CreateWaypoints(self.Agent, scpPosition, Vector3.new(math.random(spawnPosition.X - 40, spawnPosition.X + 40), scpPosition.Y, math.random(spawnPosition.Z - 10, spawnPosition.Z + 10)), "Wander");
			until success;
			
			SCP:DebugWaypoints();
			
			local targetPosition = self.Agent.Waypoints[#self.Agent.Waypoints].Position;
			self:Move(scpPosition, targetPosition);
			
			AgentService:ClearWaypoints(self.Agent);
		end;
	end;
end

function SCP:SnapRun(character)
	
	local scpPosition = self.Agent.Character.HumanoidRootPart.Position;
	local count = 0;
	repeat
		local success = AgentService:CreateWaypoints(self.Agent,
			Vector3.new(math.random(scpPosition.X - PATH_START_BIAS, scpPosition.X + PATH_START_BIAS), scpPosition.Y,math.random(scpPosition.Z - PATH_START_BIAS, scpPosition.Z + PATH_START_BIAS)),
			character.HumanoidRootPart.Position,
			"Snap");
		count += 1;
	until success or count >= 10;
	
	if count < 10 then
		local targetWaypoint;
		if #self.Agent.Waypoints > 16 then
			targetWaypoint = 16;
		else
			targetWaypoint = #self.Agent.Waypoints;
		end;
		
		SCP:DebugWaypoints();
		
		local targetPosition = self.Agent.Waypoints[targetWaypoint].Position;
		self:Move(scpPosition, targetPosition);
		
		if (scpPosition - character.PrimaryPart.Position).magnitude <= ATTACK_RANGE then
			character.Humanoid:TakeDamage(ATTACK_DAMAGE);
		end;
		AgentService:ClearWaypoints(self.Agent);
	end;
end;

function SCP:Escape(container)
	
	container:SetAttribute("Contained", false);
	container:SetAttribute("State", "BreachWander");
	container.Character.HumanoidRootPart.ProximityPrompt.Enabled = true;
	SCPService.OnContainmentBreach:Fire(container);
	self.Agent.Character.HumanoidRootPart.CFrame = Container.Escape.CFrame + Vector3.new(0, self.Agent.Character.Humanoid.HipHeight, 0);
	
	task.spawn(function()
		task.wait(300);
		if self.Agent and self.Agent.Character == container.Character then
			SCP:Clear();
		end;
	end);
end;

function SCP:EscapePulse()
	
	local container			= self.Agent.Container;
	local containmentHealth	= container:GetAttribute("ContainmentHealth");
	local containmentDecay	= container:GetAttribute("ContainmentDecay");
	local escapeTolerance	= container:GetAttribute("EscapeTolerance");
	local contained			= container:GetAttribute("Contained");
	local decayAmount		= math.random(containmentDecay.Min, containmentDecay.Max);
	local newHealth			= math.clamp(containmentHealth - decayAmount, 0, 10000);
	
	container:SetAttribute("ContainmentHealth", newHealth);
	
	if contained and newHealth <= escapeTolerance then
		
		SCP:Escape(container);
	end;
end;

function SCP:Update()
	if not script:GetAttribute("Disabled") then
		local success, stack = pcall(function()
			if self.Agent and not self.Agent.Thinking and Container:FindFirstChild("Character") and Container.Character.PrimaryPart and not CollectionService:HasTag(Container, "SCP Respawning") then
					
				-- TECHSPECTRUMS FIX
				if not CollectionService:HasTag(Container.Character.Head, "173-To-Player") then
					--VisionService:AddTarget("Player-To-173", self.Agent.Character, self.Agent.Character.Head, nil);
					--VisionService:AddWatcher("173-To-Player", self.Agent.Character, self.Agent.Character.Head, nil);
					--SCP:Clear()
					--SCP:Setup()
				end
				
				self.Agent.Thinking = true;
				if (#CollectionService:GetTagged("Player-To-173_Seeing") - #CollectionService:GetTagged("Player-To-173_Blinking")) <= 0 then
					
					if #CollectionService:GetTagged("173-To-Player_Seen") > 0 then
						
						local chosen;
						local distance = math.huge;
						for _, character in pairs(CollectionService:GetTagged("173-To-Player_Seen")) do
							
							if not CollectionService:HasTag(character, "Dead") then
								
								local targetDistance = (character.PrimaryPart.Position - self.Agent.Character.PrimaryPart.Position).magnitude;
								if targetDistance < distance then
									
									distance = targetDistance;
									chosen = character;
								end;
							end;
						end;
						if chosen then
							self:SnapRun(chosen);
						end;
					else
							
						local state = self.Agent.Container:GetAttribute("State");
						if state == "ContainmentWander" then
							self:ContainmentWander();
						elseif state == "BreachWander" then
							self:BreachWander();
						end;
						self:EscapePulse();
					end;
				end;
				if Container:GetAttribute("Contained") and (self.Agent.Character.PrimaryPart.Position - Container.Spawn.Position).magnitude > ESCAPE_DISTANCE then
					self:Escape(Container);
				end;
				self.Agent.Thinking = false;
			elseif not Container:FindFirstChild("Character") or not Container.Character.PrimaryPart and not CollectionService:HasTag(Container, "SCP Respawning") then
				SCP:Clear();
			elseif self.Agent.Thinking then

				if not self.Agent.Thinked then
					self.Agent.Thinked = 0;
				else
					self.Agent.Thinked += 1;
					if self.Agent.Thinked >= THINK_TIMEOUT then
						self.Agent.Thinked = 0;
						SCP:Clear();
					end;
				end;
			end;
		end);
		if not success then
			warn(stack);
		end;
	end;
end;

return SCP;