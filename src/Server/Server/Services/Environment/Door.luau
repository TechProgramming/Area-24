local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService	= game:GetService("CollectionService");
local TweenService		= game:GetService("TweenService");

local DoorService = Knit.CreateService({
	Name = "DoorService",
	Client = {},
});

DoorService.DoorGroup =
{
	["Cell Door"] = true;
	["Blast Door"] = true;
	["Close on Lockdown Door"] = true;
};--Documented Door Groups

--[[ Service API

BreakDoorGroup(string groupName, Op-Boolean doBreak, doOpen)
	"Break or Repair a group of doors, can be specified"
	"Only possible on doors with Broken Attribute"
	
BreakDoor(Instance door, Op-Boolean doBreak, doOpen)
	"Break or Repair a door, can be specified"
	"Only possible on doors with Broken Attribute"

LockDoorGroup(String groupName, Op-Boolean doLock)
	"Lock or Unlock a group of doors, can be specified"

LockDoor(Instance door, Op-Boolean doLock)
	"Lock or Unlock a door, can be specified"

OperateDoorGroup(String groupName, Op-Boolean doOpen)
	"Open or Close a group of doors, can be specified"

OperateDoor(String groupName, Op-Boolean doOpen)
	"Open or Close a door, can be specified"
	
GetGroup(Instance door)
	"Returns the door's Primary Door Group, or nil"
	String primaryDoorGroup
]]

function DoorService:KnitStart()
	
	local doors = CollectionService:GetTagged("Door")
	local NotificationService	= Knit.GetService("NotificationService");
	local AccessLevelService	= Knit.Services.AccessLevelService;
	local ProfileService 		= Knit.Services.ProfileService;
	local JobService			= Knit.Services.JobService
	local LevelService			= Knit.Services.LevelService
	
	for _, door in pairs(doors) do
		
		local config = door:FindFirstChild("Configuration");
		
		if not config then

			warn(string.format("%s doesn't have a Configuration Folder!", door:GetFullName()));
			continue;
		end;
		
		if not door.PrimaryPart then
			continue;
		end;
		
		for _, item in ipairs(door:GetDescendants()) do
			if item:IsA("BasePart") then
				local mod = Instance.new("PathfindingModifier")
				mod.Label = "Door"
				mod.PassThrough = true
				mod.Parent = item
			end
		end
		
		local interaction = door.PrimaryPart:FindFirstChild("Interaction");
		
		if interaction then
			local prompt = interaction:FindFirstChild("OperatePrompt");
			if not prompt then
				
				warn(string.format("%s doesn't have a ProximityPrompt!", door:GetFullName()));
				continue;
			end;
			prompt.Triggered:Connect(function(player)
				local allowedIn = false
				local errorMessage = ""
				if door:GetAttribute("Coolup") then return end
				if door:GetAttribute("Cooldown") then return end
				if door:GetAttribute("Broken") then prompt.Enabled = false; end
				
				if door:GetAttribute("Locked") then
					return NotificationService:ShowNotification(player, 2, "The Door is Locked", Color3.fromRGB(255, 55, 55));
				end
				
				--if door:GetAttribute("Scientist")  then
				--	local teamLevel = door:GetAttribute("TeamLevel")
				--	local profile = ProfileService:GetProfile(player)
				--	local teamlevelFromprofile = LevelService:GetLevel(player, "Scientific Department")
	
				--	local team = player.Team
				--	if team:GetAttribute("SCPAccess") then
						
				--	end
				--end
				
				if (door:GetAttribute("AccessLevel") or 0) <= (AccessLevelService:Get(player) or 0) then
					allowedIn = true
				else	
					errorMessage = string.format("You must have a Level %s Access Card!", door:GetAttribute("AccessLevel") or 0)
				end
				
				if allowedIn then
					self:OperateDoor(door);
					if not door:GetAttribute("Broken") then
						if door:GetAttribute("XP") then
							JobService:Award(player)
						end
					end;
				else
					NotificationService:ShowNotification(player, 2, errorMessage, Color3.fromRGB(255, 55, 55));
				end
			end);
			
			local prompt = interaction:FindFirstChild("RepairPrompt");
			if not prompt then
				continue;
			end;
			prompt.Triggered:Connect(function(player)
				
				if player.Team:GetAttribute("Engineer") then
					
					if door:GetAttribute("Broken") then
						self:BreakDoor(door, false);
						JobService:Award(player)
					end;
				else
					NotificationService:ShowNotification(player, 2, "You need to be an Engineer", Color3.fromRGB(255, 55, 55));
				end;
			end);
		end;
	end;
end

function DoorService:BreakDoorGroup(groupName, doBreak, doOpen)
	
	if self.DoorGroup[groupName] then
		
		local groupedDoors = CollectionService:GetTagged(groupName);
		for _,door in pairs(groupedDoors) do
			DoorService:BreakDoor(door, doBreak, doOpen);
		end;
	else
		warn(string.format("Door Group %s do not Exist!", groupName));
	end;
end;

function DoorService:BreakDoor(door, doBreak, doOpen)

	if CollectionService:HasTag(door, "Door") then

		local broken = door:GetAttribute("Broken");
		if broken ~= nil then
			if doBreak then
				--Specified Break
				if not broken then
					Break(door, true, doOpen);
				end;
			elseif doBreak == false then
				--Specified Repair
				if broken then
					Break(door, false, doOpen);
				end;
			else
				--Toggle Break/Repair
				if broken then
					Break(door, false, doOpen);
				else
					Break(door, true, doOpen);
				end;
			end;
		end;
	end;
end;

function Break(door, doBreak, doOpen)

	if doBreak then
		
		if (door:GetAttribute("Coolup") or door:GetAttribute("Cooldown")) then
			repeat
				task.wait();
			until not (door:GetAttribute("Coolup") or door:GetAttribute("Cooldown"));
		end;
		door:SetAttribute("Broken", true);
		door.PrimaryPart.Interaction.OperatePrompt.Enabled = false;
		door.PrimaryPart.Interaction.RepairPrompt.Enabled = true;
		if door.Configuration:FindFirstChild("Broken") then
			require(door.Configuration.Broken):Start(door);
		end;
		if doOpen then
			DoorService:OperateDoor(door, true);
		elseif doOpen == false then
			DoorService:OperateDoor(door, false);
		end;
	else
		
		door:SetAttribute("Broken", false);
		door.PrimaryPart.Interaction.OperatePrompt.Enabled = true;
		door.PrimaryPart.Interaction.RepairPrompt.Enabled = false;
		if door.Configuration:FindFirstChild("Broken") then
			require(door.Configuration.Broken):Stop(door);
		end;
	end;
end;

function DoorService:LockDoorGroup(groupName, doLock)
	
	if self.DoorGroup[groupName] then
		
		local groupedDoors = CollectionService:GetTagged(groupName);
		for _,door in pairs(groupedDoors) do
			DoorService:LockDoor(door, doLock);
		end;
	else
		warn(string.format("Door Group %s do not Exist!", groupName));
	end;
end;

function DoorService:LockDoor(door, doLock)
	
	if CollectionService:HasTag(door, "Door") then
		
		local locked = door:GetAttribute("Locked") or false;
		if doLock then
			--Specified Lock
			if not locked then
				door:SetAttribute("Locked", true);
			end;
		elseif doLock == false then
			--Specified Unlock
			if locked then
				door:SetAttribute("Locked", false);
			end;
		else
			--Toggle Lock/Unlock
			if locked then
				door:SetAttribute("Locked", false);
			else
				door:SetAttribute("Locked", true);
			end;
		end;
	end;
end;

function DoorService:OperateDoorGroup(groupName, doOpen)
	
	if self.DoorGroup[groupName] then
		
		local groupedDoors = CollectionService:GetTagged(groupName);
		for _, door in pairs(groupedDoors) do
			
			DoorService:OperateDoor(door, doOpen);
		end;
	else
		warn(string.format("Door Group %s do not Exist!", groupName));
	end;
end;

function DoorService:OperateDoor(door, doOpen, doOverwrite)
	
	if not (door:GetAttribute("Coolup") or door:GetAttribute("Cooldown")) then
		
		door:SetAttribute("Coolup", true);
		door.PrimaryPart.Interaction.OperatePrompt.Enabled = false;
		
		if not door:GetAttribute("Locked") then
			if doOpen then
				--Specified Open
				if not door:GetAttribute("Open") then
					DoorService:GoThroughSteps(door.Configuration.Step.Open);
					door:SetAttribute("Open", true);
				end;
			elseif doOpen == false then
				--Specified Close
				if door:GetAttribute("Open") then
					DoorService:GoThroughSteps(door.Configuration.Step.Close);
					door:SetAttribute("Open", false);
				end;
			else
				--Toggle Open/Close
				if door:GetAttribute("Open") then
					DoorService:GoThroughSteps(door.Configuration.Step.Close);
					door:SetAttribute("Open", false);
				else
					DoorService:GoThroughSteps(door.Configuration.Step.Open);
					door:SetAttribute("Open", true);
					task.wait(3);
					DoorService:GoThroughSteps(door.Configuration.Step.Close);
					door:SetAttribute("Open", false);
				end;
			end;
		else
			warn(string.format("%s attempted to operate while Locked!", door:GetFullName()));
			door:SetAttribute("Coolup", false);
			return;
		end;
		if not door:GetAttribute("Broken") then
			door.PrimaryPart.Interaction.OperatePrompt.Enabled = true;
		end;
		
		door:SetAttribute("Coolup", false);
		
		if door:GetAttribute("Cooldown_Time") or 0 > 0 then
			door:SetAttribute("Cooldown", true);
			wait(door:GetAttribute("Cooldown_Time"));
		end;
		door:SetAttribute("Cooldown", false);
	end;
end;

function DoorService:GetGroup(door)
	return door:GetAttribute("PrimaryGroup");
end;

function DoorService:GoThroughSteps(steps)
	--Internal Use
	for _, step in pairs(steps:GetChildren()) do
		
		local audio = step:FindFirstChild("Audio");
		local audioCenter = step:FindFirstChild("AudioCenter");
		
		if audio and audioCenter and audioCenter.Value then
			--Play Door Audio if Exists in step
			local clonedAudio = audio:Clone();
			clonedAudio.Parent = audioCenter.Value;
			clonedAudio.Ended:Connect(function()
				clonedAudio:Destroy()
			end)
			clonedAudio:Play();
		end;
		
		self:PerformTween(step);
	end;
end

function DoorService:PerformTween(step)
	--Internal Use
	for _, target in pairs(step:GetChildren()) do
		
		if target:IsA("Folder") then
			
			local audio = target:FindFirstChild("Audio");
			if audio then
				--Play Part Audio if Exists in step
				local clonedAudio = audio:Clone();
				clonedAudio.Parent = target.Part.Value;
				clonedAudio.Ended:Connect(function()
					clonedAudio:Destroy()
				end)
				clonedAudio:Play();
			end;
			
			local animation = target:FindFirstChild("Animation");
			if animation and animation.Value then
				--Play Animation if Exists in step
				--//NOT IMPLEMENTED YET
			end;
			
			local attachment = target.TweenTo.Value;
			local tweenInfo = TweenInfo.new(step:GetAttribute("Time") or 1, Enum.EasingStyle[step:GetAttribute("Type") or "Linear"], Enum.EasingDirection[step:GetAttribute("Direction") or "Out"], 0, false, 0);
			local tween = TweenService:Create(target.Part.Value, tweenInfo, {
				CFrame = CFrame.new(attachment.WorldPosition)*CFrame.Angles(math.rad(attachment.WorldOrientation.X), math.rad(attachment.WorldOrientation.Y), math.rad(attachment.WorldOrientation.Z));
			}):Play();
			
		end;
	end;
	
	wait(step:GetAttribute("Time"));
end

return DoorService