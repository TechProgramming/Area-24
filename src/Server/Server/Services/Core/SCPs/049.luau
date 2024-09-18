-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local WorkspaceService = game:GetService("Workspace")
local PlayersService = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ChatService = game:GetService("Chat")
local Knit = require(ReplicatedStorage.Knit)

-- CONSTANTS
local PESTILENCE_TAG_NAME = "Pestilence"
local TIME_UNTIL_FORGOTTEN = 10

local SCP_049_CHAR = ServerStorage.Asset.SCP["049"].Character
local CHAMBER = WorkspaceService.Scripted.SCPs["049"]
local ANIMATIONS = ReplicatedStorage.Animations["049"]

local MESSAGES = {
	Idle = {
		"I need to get to work before the disease consumes the rest of these poor souls.",
		"Do they not realize the severity of the disease..?",
		"Hmmm...",
		"Let's see..",
	},
	Ack = {
		"Ah, I wasn't aware we had company. We rarely get visitors down here.",
		"Hello, are you a doctor?",
		"Why hello there.",
		"Great, more company..."
	},
	AckDisease = {
		"Oh my, yet another victim of the disease.",
		"I am the cure.",
		"Do not be afraid, I am the cure.",
		"Stop resisting, I am here to cure you.",
		"Hold still, I am trying to cure you."
	},
}

local PATH = PathfindingService:CreatePath({
	AgentRadius = 4,
	AgentHeight = 6,
	AgentCanJump = true,
	WaypointSpacing = math.huge,
})


-- SERVICE
local SCP = Knit.CreateService({
	Name = "SCP-049",
	Client = {},
	CurrentChar = nil,
	Players = {}, -- plr = {timeUntilForgotten, isAttacking}
	PauseWander = false,
	CurrentlyAttacking = nil,
})


function SCP:KnitStart() 
	local ProfileService = Knit.Services.ProfileService
	
	--Add to list
	ProfileService.PlayerAdded:Connect(function(plr, _profile)
		self.Players[plr] = {timeUntilForgotten = 0, isAttacking = false}
		
		plr.CharacterRemoving:Connect(function()
			self.Players[plr] = {timeUntilForgotten = 0, isAttacking = false}
		end)
	end)
	
	--Cleanup
	ProfileService.PlayerRemoving:Connect(function(plr)
		self.Players[plr] = nil 
	end)	
	
	--Randomly give pestilence
	ProfileService.CharacterAdded:Connect(function(plr, char)
		local pestilence = math.random(1, 3) < 3
		if pestilence then
			CollectionService:AddTag(char, PESTILENCE_TAG_NAME)
		end
	end)
	
	--Spawn 049 character
	self:Spawn()
	
	--init wandering loop
	coroutine.wrap(function()
		while true do
			if not self.CurrentChar then
				repeat task.wait(0.05) until self.CurrentChar
			end
			
			local animator = self.CurrentChar.Humanoid:WaitForChild("Animator")
			
			if math.random(0, 100) <= 40 then
				ChatService:Chat(self.CurrentChar.Head, MESSAGES.Idle[math.random(1, #MESSAGES.Idle)])
				
				--chin rub
				local chinTrack = animator:LoadAnimation(ANIMATIONS.IdleVarient)
				chinTrack:Play()
				chinTrack.Stopped:Wait()
			end
			
			--play idle animation
			local track = animator:LoadAnimation(ANIMATIONS.Idle)
			track:Play()
			
			--pause as another action is occuring
			if self.PauseWander then
				repeat task.wait(1) until not self.PauseWander
			end
			
			--wait random time before moving again
			task.wait(math.random(2, 10))
			track:Stop()
			self:Wander()
		end
	end)()
	
	--check if player in sight
	while true do
		self:CheckLOS()
		task.wait(1)
	end
end


function SCP:Spawn()
	self.CurrentChar = SCP_049_CHAR:Clone()
	
	--Move character into world
	self.CurrentChar.HumanoidRootPart.CFrame = 
		CHAMBER.Spawn.CFrame +
		Vector3.new(0, self.CurrentChar.Humanoid.HipHeight, 0);
	
	--Show character
	self.CurrentChar.Parent = WorkspaceService
	
	--On touch
	local debounce = false
	self.CurrentChar.HumanoidRootPart.Touched:Connect(function(hit)
		if not hit.Parent:FindFirstChild("Humanoid") then
			return
		end
		
		local char = hit.Parent
		local plr = PlayersService:GetPlayerFromCharacter(char)
		if not plr then
			return
		end
		debounce = true
		
		--check if pestilence then turn to zombo
		if CollectionService:HasTag(char, PESTILENCE_TAG_NAME) then
			self:TurnToZombie(plr)
		end
		wait(2)
		debounce = false
	end)
	
	--set network ownership to avoid stuttering
	for _, item in pairs(self.CurrentChar:GetDescendants()) do
		if item:IsA("BasePart") then
			item:SetNetworkOwner(nil)
		end
	end
	
	--Prevent SCP from disappearing forever, may cause a stack overflow but meh, that's only if it respawns too often (which shouldn't be happening!!!)
	self.CurrentChar.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Spawn()
		end
	end)
end

local zombieDebounce = false

function SCP:TurnToZombie(plr)
	if zombieDebounce then
		return
	end
	zombieDebounce = true
	
	local ZombieService = Knit.Services["SCP-049-02"]
	ZombieService:SpawnZombie(plr, plr.Character.HumanoidRootPart.CFrame)
	plr.Character:Destroy()
	plr.Character = nil
	
	wait(.5)
	zombieDebounce = false
	
	wait(2)
	plr:LoadCharacter()
end


function SCP:Wander()
	if not self.CurrentChar then
		return
	end
	
	--get random location
	local moveToPos = CHAMBER.WanderArea.Position + Vector3.new(
		math.random(-CHAMBER.WanderArea.Size.X/2, CHAMBER.WanderArea.Size.X/2),
		self.CurrentChar.HumanoidRootPart.Position.Y,
		math.random(-CHAMBER.WanderArea.Size.Z/2, CHAMBER.WanderArea.Size.Z/2)
	)
	
	--compute path
	PATH:ComputeAsync(self.CurrentChar.HumanoidRootPart.Position, moveToPos)
	if PATH.Status == Enum.PathStatus.NoPath then
		return
	end
	
	--make character follow path
	local points = PATH:GetWaypoints()
	
	--animate
	local animator = self.CurrentChar.Humanoid:WaitForChild("Animator")
	local track = animator:LoadAnimation(ANIMATIONS.Walking)
	track:Play()

	--walk/jump to waypoint
	for _, point in ipairs(points) do
		self.CurrentChar.Humanoid:MoveTo(point.Position)
		if point.Action == Enum.PathWaypointAction.Jump then
			self.CurrentChar.Humanoid.Jump = true
		end
		
		self.CurrentChar.Humanoid.MoveToFinished:Wait()
	end
	
	track:Stop()
end


function SCP:_GetAllPlayersCharExcept(toIgnore)
	local plrs = PlayersService:GetPlayers()
	local characters = {}
	
	
	for _, plr in ipairs(plrs) do
		if plr == toIgnore then
			continue
		end
		
		local char = plr.Character
		if not char then
			continue
		end
		
		table.insert(characters, char)
	end
	
	return characters
end


function SCP:CheckLOS()
	for plr, data in pairs(self.Players) do
		--print(data)
		--ensure character, if not, reset
		if not plr.Character then
			self.Players[plr] = {timeUntilForgotten = 0, isAttacking = false}
			continue
		end
		
		--create ray
		local rayParams = RaycastParams.new()
		
		--see through other players
		local ignoreChars = self:_GetAllPlayersCharExcept(plr)
		table.insert(ignoreChars, self.CurrentChar)
		rayParams.FilterDescendantsInstances = ignoreChars
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		
		if not plr.Character or not plr.Character:FindFirstChild("Head") then
			continue
		end
		
		--cast the ray :hammer:
		local rayResult = WorkspaceService:Raycast(self.CurrentChar.Head.Position, (plr.Character.Head.Position - self.CurrentChar.Head.Position).Unit * 50, rayParams)
		
		--check if result
		if not rayResult or not rayResult.Instance then
			self.Players[plr] = {timeUntilForgotten = 0, isAttacking = false}
			continue
		end
		
		--check for LOS
		if rayResult.Instance.Parent == plr.Character or rayResult.Instance.Parent.Parent == plr.Character then
			--has LOS
			if data.timeUntilForgotten <= 0 and not self.CurrentlyAttacking then
				--Acknowledge player			
				self:Acknowledge(plr)
			end
	
			if not self.CurrentlyAttacking and not data.isAttacking and CollectionService:HasTag(plr.Character, PESTILENCE_TAG_NAME) then
				coroutine.wrap(function()
					self:Attack(plr)
				end)()
			end
			
			self.Players[plr] = {timeUntilForgotten = TIME_UNTIL_FORGOTTEN, isAttacking = true}
		else
			--no LOS
			if plr == self.CurrentlyAttacking then
				
				self.CurrentlyAttacking = nil
				self.Players[plr].isAttacking = false
				self.Players[plr].timeUntilForgotten = 0
				self.CurrentChar.Humanoid:MoveTo(Vector3.new(self.CurrentChar.HumanoidRootPart.Position))
			elseif data.timeUntilForgotten > 0 then
				self.Players[plr].timeUntilForgotten = self.Players[plr].timeUntilForgotten-1
			end
		end
	end
end


function SCP:Acknowledge(plr)
	self.PauseWander = true
	self.CurrentChar.Humanoid:MoveTo(Vector3.new(self.CurrentChar.HumanoidRootPart.Position))
	
	local char = plr.Character
	if not char then
		return
	end
	
	--Tween to face new face in LOS
	local plrPos = plr.Character.HumanoidRootPart.Position
	local tweenCFrame = CFrame.new(self.CurrentChar.HumanoidRootPart.Position, Vector3.new(plrPos.X, self.CurrentChar.HumanoidRootPart.Position.Y, plrPos.Z))
	local tweenInfo = TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
	local tween = TweenService:Create(self.CurrentChar.HumanoidRootPart, tweenInfo, {CFrame = tweenCFrame})
	tween:Play()
	
	local hasPestilence = CollectionService:HasTag(char, PESTILENCE_TAG_NAME)
	if hasPestilence then
		--turn player to zombo
		ChatService:Chat(self.CurrentChar.Head, MESSAGES.AckDisease[math.random(1, #MESSAGES.AckDisease)])
	else
		--send ack message
		ChatService:Chat(self.CurrentChar.Head, MESSAGES.Ack[math.random(1, #MESSAGES.Ack)])
		wait(3)
		self.PauseWander = false
	end
end


function SCP:Attack(plr)
	self.CurrentlyAttacking = plr
	
	--animate
	local animator = self.CurrentChar.Humanoid:WaitForChild("Animator")
	local track = animator:LoadAnimation(ANIMATIONS.WalkingAttack)
	track:Play()
	
	while self.CurrentlyAttacking and plr.Character and self.CurrentChar do
		--compute path
		PATH:ComputeAsync(self.CurrentChar.HumanoidRootPart.Position, plr.Character.HumanoidRootPart.Position)
		if PATH.Status == Enum.PathStatus.NoPath then
			break
		end

		--make character follow path
		local points = PATH:GetWaypoints()

		--walk/jump to waypoint
		for _, point in ipairs(points) do
			if not self.CurrentlyAttacking or not plr.Character or not self.CurrentChar then
				break
			end
			
			self.CurrentChar.Humanoid:MoveTo(point.Position)
			if point.Action == Enum.PathWaypointAction.Jump then
				self.CurrentChar.Humanoid.Jump = true
			end

			self.CurrentChar.Humanoid.MoveToFinished:Wait()
		end
	end
	
	track:Stop()
	self.PauseWander = false
end


return SCP