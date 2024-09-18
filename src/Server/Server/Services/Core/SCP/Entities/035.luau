local PathfindingService	= game:GetService("PathfindingService");
local CollectionService		= game:GetService("CollectionService");
local ReplicatedStorage		= game:GetService("ReplicatedStorage");
local ServerStorage			= game:GetService("ServerStorage");
local PlayerService			= game:GetService("Players");

local MASK = script.Mask:Clone()
MASK.Parent = game.ServerStorage

local Knit = require(ReplicatedStorage.Knit);

local servicesLoaded	= false;
local PlayerCollectorService;
local TerminationService;
local ProfileService;
local VisionService;
local AgentService;
local DoorService;
local AreaService;
local SCPService;

local SCP = Knit.CreateService({
	Name = "_SCP_035",
	Client = {},
});

local Container		= game.Workspace.Scripted.SCPs[script.Name];
local SCPNodemap	= ReplicatedStorage.NodeMapProjects.SCP;

local path = PathfindingService:CreatePath({
	AgentRadius = 4,
	AgentHeight = 6,
	AgentCanJump = false,
	WaypointSpacing = 25
});

local DIRECT_TIMEOUT	= 3;
local THINK_TIMEOUT		= 3;
local PATH_TIMEOUT		= 3;

local PATH_START_BIAS			= 4;
local PATH_END_BIAS				= 2;
local DIRECTIVE_REACH_RADIUS	= 10;

local ATTACK_RANGE	= 6;
local ATTACK_DAMAGE	= math.huge;

local SPEECH_CHANCE	= 30;

local CurrentNextWaypoint;

function SCP:KnitStart() 
	
	PlayerCollectorService	= Knit.GetService("PlayerCollectorService");
	TerminationService		= Knit.GetService("TerminationService");
	ProfileService 			= Knit.GetService("ProfileService");
	VisionService 			= Knit.GetService("VisionService");
	AgentService 			= Knit.GetService("AgentService");
	DoorService 			= Knit.GetService("DoorService");
	AreaService 			= Knit.GetService("AreaService");
	SCPService 				= Knit.GetService("SCPService");
	
	servicesLoaded			= true;
	
	PlayerCollectorService.Touched:Connect(function(part, player, character)
		if part.Name == "PickUpMask" then
			if CollectionService:HasTag(character, "PickUpMask") and Container:GetAttribute("Contained") then
				SCP:Escape(Container, character);
			end;
		end;
	end);
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
		
		Container.Spawn.Transparency = 0;
		Container.Spawn.ProximityPrompt.Enabled = true;
		Container.Spawn.ProximityPrompt.Triggered:Connect(function(player)
			SCP:Escape(Container, player.Character);
		end);
		
		self.Agent = AgentService:New(script, path, Container);
	end;
end;

function SCP:Clear()
	if self.CurrentPlayer then
		CollectionService:RemoveTag(self.CurrentPlayer, "Unprotected")
	end
	
	if not CollectionService:HasTag(Container, "SCP Respawning") then
		
		CollectionService:AddTag(Container, "SCP Respawning");
		if self.Agent then
			if self.Agent.Character then
				self.Agent.Character.Humanoid.Health = 0;
			end;
			AgentService:Remove(script);
			self.Agent = nil;
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

function SCP:RemoveWaypoint()
	
	AgentService:ClearWaypoints(self.Agent);
	if CurrentNextWaypoint then
		CurrentNextWaypoint:Destroy();
	end;
	self.Agent.Pathing = false;
	self.Agent.Pathed = 0;
end;

function SCP:NextWaypoint()
	
	local targetPosition = self.Agent.Waypoints[1].Position;
	local newPing = script.Ping:Clone();
	newPing.CFrame = CFrame.new(targetPosition);
	if script:GetAttribute("Debug_Pathfinding") then
		newPing.Transparency = 0.5;
	end;
	newPing.Parent = self.Agent.Character;
	CurrentNextWaypoint = newPing;
	game:GetService("Debris"):AddItem(newPing, 8);
	if self.Agent.Waypoints[1].Action == Enum.PathWaypointAction.Jump then
		self.Agent.Character.Humanoid.Jump = true;
	end;
	self.Agent.Character.Humanoid:MoveTo(targetPosition);
	self.Agent.Pathed = 0;
	self.Agent.Directed = 0;
end;

function SCP:DoWaypoint()
	
	SCP:DebugWaypoints();
	if not self.Agent.Pathing and #self.Agent.Waypoints > 0 then
		self.Agent.Pathing = true;
		self:NextWaypoint();
	elseif #self.Agent.Waypoints <= 0 then
		self:RemoveWaypoint();
	elseif self.Agent.Pathing then
		if not self.Agent.Pathed then
			self.Agent.Pathed = 0;
		end;
		self.Agent.Pathed += 1;
		if self.Agent.Pathed >= PATH_TIMEOUT then
			self:RemoveWaypoint();
		end;
	end;
end;

function SCP:BreachWander()
	
	if script:GetAttribute("Debug_Print") then
		print("035 Breach Wandering");
	end;
	local scpHumanoidRootPart = self.Agent.Character.HumanoidRootPart;
	local scpPosition = scpHumanoidRootPart.Position;
	
	if not self.Agent.Directive then
		if script:GetAttribute("Debug_Print") then
			print("035 No Directive is Available, requesting new Directive");
		end;
		math.randomseed(tick());
		local nodeTarget = SCPNodemap:GetChildren()[math.random(1, #SCPNodemap:GetChildren())]:GetAttribute("NodePosition");
		local success = AgentService:CreateDirective(self.Agent, nodeTarget, SCPNodemap);
		self:BreachWander();
	else
		if script:GetAttribute("Debug_Print") then
			print("035 Directive Available, continuing");
		end;
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
				self:RemoveWaypoint();
				if not self.Agent.Directed then
					self.Agent.Directed = 0;
				end;
				self.Agent.Directed += 1;
				if self.Agent.Directed >= DIRECT_TIMEOUT then
					AgentService:ClearDirective(self.Agent);
				end;
			end;
		else
			
			self:DoWaypoint();
			
			if (Normalize(self.Agent.Directive[1]) - Normalize(scpHumanoidRootPart.Position)).magnitude <= DIRECTIVE_REACH_RADIUS then
				
				if math.random(1, 100) <= SPEECH_CHANCE then
					SCP:Speak();
				end;
				table.remove(self.Agent.Directive, 1);
				self:RemoveWaypoint();
				if #self.Agent.Directive <= 0 then
					AgentService:ClearDirective(self.Agent);
				else
					self:BreachWander();
				end;
			end;
		end;
	end;
end

function SCP:ContainmentWander()
	
	local characters = PlayerCollectorService:GetCharacterCollection("SCP-035-Cell")
	for _, character in pairs(characters) do
		
		local pickupIgnore = character:GetAttribute("035PickupIgnore") or 0
		
		if character:FindFirstChild("Humanoid") and pickupIgnore < 6 then
			
			CollectionService:AddTag(character, "PickUpMask")
			character.Humanoid.WalkToPoint = character.HumanoidRootPart.Position
			character.Humanoid.WalkToPoint = Container.Detectors.PickUpMask.Position
			character:SetAttribute("035PickupIgnore", (character:GetAttribute("035PickupIgnore") or 0) + 1);
			if character:GetAttribute("035PickupIgnore") > 5 then
				task.wait(5);
				character:SetAttribute("035PickupIgnore", 0);
			end;
		end;
	end
end

function SCP:TryToKill(character)
	
	local scpPosition = self.Agent.Character.HumanoidRootPart.Position;
	local targetPosition = character.HumanoidRootPart.Position;
	
	if self.Agent.WaypointType ~= "Kill" then
		local success = AgentService:CreateWaypoints(self.Agent,
			Vector3.new(math.random(scpPosition.X - PATH_START_BIAS, scpPosition.X + PATH_START_BIAS), scpPosition.Y, math.random(scpPosition.Z - PATH_START_BIAS, scpPosition.Z + PATH_START_BIAS)),
			Vector3.new(math.random(targetPosition.X - PATH_END_BIAS, targetPosition.X + PATH_END_BIAS), targetPosition.Y, math.random(targetPosition.Z - PATH_END_BIAS, targetPosition.Z + PATH_END_BIAS)),
			"Kill");
		if success then
			self:TryToKill(character);
		else
			self:RemoveWaypoint();
		end;
	else
		self:DoWaypoint();
		
		if (scpPosition - targetPosition).magnitude <= ATTACK_RANGE then
			print(character:GetFullName());
			character.Humanoid:TakeDamage(ATTACK_DAMAGE);
			self:RemoveWaypoint();
		end;
	end;
end;

function SCP:Escape(container, character) 
	
	if not character then
		return false, "Target Character is Missing";
	end;
	
	--unprotect protected cmd people
	local ff = character:FindFirstChildOfClass("ForceField")
	if ff then
		ff:Destroy()
	end
	
	local plr = PlayerService:GetPlayerFromCharacter(character)
	if not plr then
		return false, "Player is missing"
	end
	local conn = nil
	conn = PlayerService.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == plr then
			conn:Disconnect();
			SCP:Clear();
		end
	end)
	
	self.CurrentPlayer = plr
	CollectionService:AddTag(plr, "Unprotected")
	
	container.Spawn.ProximityPrompt.Enabled = false;
	container.Spawn.Transparency = 1;
	character:SetAttribute("Controlled", true);
	
	self.Agent.Character = character;
	self.Agent.Character.Humanoid.MaxHealth	= 1000;
	self.Agent.Character.Humanoid.Health	= 1000;
	self.Agent.Character.Humanoid.WalkSpeed	= 20;
	self.Agent.Character.HumanoidRootPart.Touched:Connect(function(part)
		if CollectionService:HasTag(part, "Ping") and part.Parent == self.Agent.Character and self.Agent.Waypoints and part.Position == self.Agent.Waypoints[1].Position then
			part:Destroy();
			table.remove(self.Agent.Waypoints, 1);
			if #self.Agent.Waypoints <= 0 then
				self:RemoveWaypoint();
			else
				self:NextWaypoint();
			end;
		elseif CollectionService:HasTag(part, "SCPDoorTrigger") and not part.Target.Value:GetAttribute("Open") then
			DoorService:OperateDoor(part.Target.Value, true);
		elseif CollectionService:HasTag(part, "EntityReset") then
			SCP:Clear();
		end;
	end);
	
	for _, obj in pairs(character:GetChildren()) do
		if obj:IsA("Accessory") and obj.Name ~= "Hair" then
			obj:Destroy();
		end;
	end;
	character.HumanoidRootPart:SetNetworkOwner(nil);
	local mask = MASK:Clone()
	mask.Parent = self.Agent.Character;
	
	task.wait();
	
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		tool:Destroy()
	end
	
	local player = PlayerService:GetPlayerFromCharacter(character);
	for _, item in pairs(player.Backpack:GetChildren()) do
		item:Destroy()
	end
	
	TerminationService:Set(player, true);
	VisionService:RemoveTarget("035-To-Player", character, character.Head);
	VisionService:AddWatcher("035-To-Player", character, character.Head);
	container:SetAttribute("Contained", false);
	container:SetAttribute("State", "BreachWander");
	
	character.HumanoidRootPart.CFrame = Container.Escape.CFrame + Vector3.new(0, character.Humanoid.HipHeight, 0);
	
	SCPService.OnContainmentBreach:Fire(container);
	
	task.spawn(function()
		task.wait(300);
		if self.Agent and self.Agent.Character == character then
			SCP:Clear();
		end;
	end);
end;

local speechOptions = {
	"Where is the exit...",
	"This body won't last forever.",
	"*sigh* I'm starting to lose my patience here.",
	"What are you doing just standing there?",
	"Well what are you waiting for...?",
	"Don't just stand there!",
	"Can you tell me where the exit is?",
	"Why are you shooting me!?",
	"Do you have a medkit?",
};

function SCP:Speak()
	
	if script:GetAttribute("Debug_Print") then
		print("035 Spoke");
	end;
	local dialogueObject = self.Agent.Character.Head;
	local targetSpeech = speechOptions[math.random(1, #speechOptions)];
	game:GetService("Chat"):Chat(dialogueObject, targetSpeech);
end;

function SCP:Update()
	if not script:GetAttribute("Disabled") then
		local success, stack = pcall(function()
			if self.Agent and not self.Agent.Thinking then
				self.Agent.Thinking = true;
				if Container:GetAttribute("Contained") then
					
					local state = self.Agent.Container:GetAttribute("State");
					if state == "ContainmentWander" then
						self:ContainmentWander();
					end
				elseif self.Agent.Character and self.Agent.Character.Parent and not CollectionService:HasTag(self.Agent.Character, "Dead") and self.Agent.Character:GetAttribute("Controlled") and not CollectionService:HasTag(Container, "SCP Respawning") then
					if #CollectionService:GetTagged("035-To-Player_Seen") > 0 then
						
						local chosen;
						local distance = math.huge;
						for _, character in pairs(CollectionService:GetTagged("035-To-Player_Seen")) do
							if not CollectionService:HasTag(character, "Dead") then
								local targetDistance = (character.PrimaryPart.Position - self.Agent.Character.PrimaryPart.Position).magnitude;
								if targetDistance < distance then
									distance = targetDistance;
									chosen = character;
								end;
							end;
						end;
						
						if chosen then
							self:TryToKill(chosen);
						end;
					else
						
						local state = self.Agent.Container:GetAttribute("State");
						if state == "BreachWander" then
							self:BreachWander();
						end;
					end;
				else
					SCP:Clear();
				end
				self.Agent.Thinking = false;
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