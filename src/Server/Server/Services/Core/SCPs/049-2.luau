-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local WorkspaceService = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local Knit = require(ReplicatedStorage.Knit)

local DAMAGE = 30

local NODES = ReplicatedStorage.NodeMapProjects.SCP:GetChildren()
local ZOMBIE_TEMPLATE = ServerStorage.Asset.SCP["049"].Zombie

-- SERVICE
local SCP = Knit.CreateService({
	Name = "SCP-049-02",
	Client = {},
	Zombies = {},
})


function SCP:SpawnZombie(ofPlayer, location)
	local CharacterEditorService = Knit.Services.CharacterEditorService
	
	local avatarSetData = CharacterEditorService:GetAvatarData(ofPlayer).AvatarSetData
	local zombie = ZOMBIE_TEMPLATE:Clone()
	if avatarSetData then
		CharacterEditorService:LoadNPCSet(zombie, avatarSetData)
	end
	
	local bodyColors = zombie:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors:Destroy()
	end
	
	local newBodyColors = script.Colors:Clone()
	newBodyColors.Parent = zombie
	
	zombie.HumanoidRootPart.CFrame = location
	zombie.Parent = WorkspaceService
	
	self:StartWanderLoop(zombie)
	table.insert(self.Zombies, zombie)
	return zombie
end


function SCP:ClearZombies()
	-- Instead of calling Destry() make the zombies take 
	-- damage so they die and have a clean error-free cleanup.
	
	for _, zombie in ipairs(self.Zombies) do
		zombie.Humanoid:TakeDamage(math.huge)
	end
end

function SCP:RemoveZombie(zombie)
	for index, zombo in ipairs(self.Zombies) do
		if zombo == zombie then
			table.remove(self.Zombies, index)
		end
	end
end


function SCP:StartWanderLoop(zombie)
	coroutine.wrap(function()
		local PATH = PathfindingService:CreatePath({
			AgentRadius = 1,
			AgentHeight = 4,
			AgentCanJump = true,
			WaypointSpacing = math.huge,
			Costs = {
				Door = 10,
				CanPassThrough = 1,
			},
		})
		
		
		local debounce = false
		local DoorService = Knit.Services.DoorService
		zombie.HumanoidRootPart.Touched:Connect(function(hit)
			if debounce then
				return
			end
			debounce = true
			
			local door = nil
			if CollectionService:HasTag(hit.Parent, "Door") then
				door = hit.Parent
			elseif CollectionService:HasTag(hit.Parent.Parent, "Door") then
				door = hit.Parent.Parent
			elseif CollectionService:HasTag(hit.Parent.Parent.Parent, "Door") then
				door = hit.Parent.Parent.Parent
			end
			
			if door then
				DoorService:OperateDoor(door, true)
			end
			
			if hit.Parent:FindFirstChild("Humanoid") then
				local plr = PlayersService:GetPlayerFromCharacter(hit.Parent)
				if plr then
					hit.Parent.Humanoid:TakeDamage(DAMAGE)
				end
			elseif hit.Parent.Parent:FindFirstChild("Humanoid") then
				local plr = PlayersService:GetPlayerFromCharacter(hit.Parent.Parent)
				if plr then
					hit.Parent.Parent.Humanoid:TakeDamage(DAMAGE)
				end
			end
			
			wait(2)
			debounce = false
		end)
		
		--change to false to signal pathfinding to stop
		local run = true
		
		--cleanup on death
		zombie.Humanoid.Died:Connect(function()
			run = false
			
			if zombie then
				SCP:RemoveZombie(zombie)
				zombie:Destroy()
			end
		end)
		
		--prevent sitting
		zombie.Humanoid.Seated:Connect(function(active, _seat)
			if active then
				zombie.Humanoid.Jump = true
			end
		end)
		
		
		while run do
			
			--Get closest player
			local closestPlayer = nil
			local closestPlayerDistance = math.huge
			
			local plrs = PlayersService:GetPlayers()
			for _, plr in ipairs(plrs) do
				local char = plr.Character
				if not char then
					continue
				end
				
				--get dist and check if closest
				local dist = (zombie.HumanoidRootPart.Position - char.HumanoidRootPart.Position).magnitude
				if dist < closestPlayerDistance then
					closestPlayer = plr 
					closestPlayerDistance = dist
				end
			end
			
			if not closestPlayer then
				task.wait(0.1)
				continue
			end
			
			--Move to closest player
			local plrPos = closestPlayer.Character.HumanoidRootPart.Position
			local currentPos = zombie.HumanoidRootPart.Position
			
			--Compute path
			PATH:ComputeAsync(currentPos, plrPos)
			if PATH.Status == Enum.PathStatus.NoPath then
				task.wait(.1)
				continue
			end
			
			--walk/jump to waypoint
			local points = PATH:GetWaypoints()
			local iteration = 0
			
			for _, point in ipairs(points) do
				
				--max five points
				if iteration > 5 then
					break
				end
				iteration = iteration+1
				
				if not zombie:FindFirstChild("Humanoid") then
					break
				end
				
				zombie.Humanoid:MoveTo(point.Position)
				if point.Action == Enum.PathWaypointAction.Jump then
					zombie.Humanoid.Jump = true
				end

				zombie.Humanoid.MoveToFinished:Wait()
			end
		end
	end)()
end


return SCP