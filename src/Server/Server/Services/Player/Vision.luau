local CollectionService = game:GetService("CollectionService");
local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local ServerStorage		= game:GetService("ServerStorage");
local PlayersService	= game:GetService("Players");
local DebrisService		= game:GetService("Debris");

local Knit			= require(ReplicatedStorage.Knit);
local KnitSignal	= require(Knit.Util.Signal);

local VisionService = Knit.CreateService({
	Name = "VisionService",
	Seen = KnitSignal.new(),
	Unseen = KnitSignal.new(),
	Group = {}
});

local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist;
raycastParams.IgnoreWater = true;

local function BlinkLoop(character)
	
	task.spawn(function()
		
		character:SetAttribute("BlinkIn", os.time() + script:GetAttribute("BlinkCooldown"));
		task.wait(script:GetAttribute("BlinkCooldown"));
		if character:GetAttribute("BlinkIn") <= os.time() and CollectionService:HasTag(character, "173-To-Player_Seen") then
			CollectionService:AddTag(character, "Player-To-173_Blinking");
		end;
	end);
end;

CollectionService:GetInstanceAddedSignal("Player-To-173_Blinking"):Connect(function(character)
	
	print(character.Name, "is Blinking");
	wait(script:GetAttribute("BlinkDuration"));
	CollectionService:RemoveTag(character, "Player-To-173_Blinking");
	BlinkLoop(character);
end);

CollectionService:GetInstanceAddedSignal("173-To-Player_Seen"):Connect(function(character)
	
	BlinkLoop(character);
end);

function VisionService:AddWatcher(group, body, object, angle)
	
	if not table.find(self.Group, group) then
		table.insert(self.Group, group);
	end;
	for _, component in pairs(body:GetDescendants()) do
		if component ~= object then
			CollectionService:AddTag(component, "VisionBlacklist");
		end;
	end
	object:SetAttribute("Vision_Watcher_Angle", angle);
	CollectionService:AddTag(object, "Vision_Watcher"..group);
	return object;
end;

function VisionService:RemoveWatcher(group, body, object) 
	
	object:SetAttribute("Vision_Watcher_Angle", nil);
	CollectionService:RemoveTag(object, "Vision_Watcher"..group);
end;

function VisionService:AddTarget(group, body, object) 
	
	for _, component in pairs(body:GetDescendants()) do
		if component ~= object then
			CollectionService:AddTag(component, "VisionBlacklist");
		end;
	end
	CollectionService:AddTag(object, "Vision_Target"..group);
	return object;
end	

function VisionService:RemoveTarget(group, body, object) 
	
	CollectionService:RemoveTag(object, "Vision_Target"..group);
	CollectionService:RemoveTag(object.Parent, group.."_Seen");
end;

VisionService.Seen:Connect(function(groupName, watcherObject, targetObject)
	
	if groupName == "Player-To-173" then
		CollectionService:AddTag(watcherObject.Parent, groupName.."_Seeing");
	else
		CollectionService:AddTag(targetObject.Parent, groupName.."_Seen");
	end;
end)

VisionService.Unseen:Connect(function(groupName, watcherObject, targetObject)
	
	if groupName == "Player-To-173" then
		CollectionService:RemoveTag(watcherObject.Parent, groupName.."_Seeing");
	else
		CollectionService:RemoveTag(targetObject.Parent, groupName.."_Seen");
	end;
end)

function VisionService:KnitStart()
	
	local ProfileService = Knit.Services.ProfileService;
	
	-----------------------------------------------
	ProfileService.CharacterAdded:Connect(function(player, character)
		
		local team = player.Team
		local Humanoid = character:WaitForChild("Humanoid");
		local Head = character:WaitForChild("Head");
		-- PLAYERS WATCH SCP-173
		VisionService:AddWatcher("Player-To-173", character, Head, 10);
		
		--SCP WATCHES PLAYER
		VisionService:AddTarget("173-To-Player", character, Head);
		VisionService:AddTarget("049-To-Player", character, Head);
		VisionService:AddTarget("035-To-Player", character, Head);
		--[[CERTAIN TEAMS WATCH CLASS
		if team:GetAttribute("WatchClassD") then
			VisionService:AddWatcher("Player-To-ClassD", character, character:WaitForChild("Head"), player) 
		elseif team.Name == "Class - D" then
			VisionService:AddTarget("Player-To-ClassD", character, character:WaitForChild("Head"), player) 
		end]]
	end);
	
	coroutine.wrap(function()
		while true do task.wait(1);
			
			if not script:GetAttribute("Disabled") then
				local VisionBlacklist = CollectionService:GetTagged("VisionBlacklist");
				table.insert(VisionBlacklist, workspace.Debug);
				raycastParams.FilterDescendantsInstances = VisionBlacklist;
				
				for _, group in pairs(self.Group) do
					for _, watcher in pairs(CollectionService:GetTagged("Vision_Watcher"..group)) do
						for _, target in pairs(CollectionService:GetTagged("Vision_Target"..group)) do
							local origin = watcher.Position;
							local direction = (target.Position - origin).Unit;
							local raycastResult = workspace:Raycast(watcher.Position, direction*300, raycastParams);
							local inVisionAngle = true;
							
							if watcher:GetAttribute("Vision_Watcher_Angle") then
								inVisionAngle = math.deg(watcher.CFrame.LookVector:Dot(direction)) > watcher:GetAttribute("Vision_Watcher_Angle");
							end;
							
							if script:GetAttribute("Debug_Ray") and raycastResult and raycastResult.Position then
								
								local distance = (watcher.Position-raycastResult.Position).Magnitude;
								local bullet = Instance.new("Part");
								bullet.Anchored = true;
								bullet.CanCollide = false;
								bullet.Transparency = 0.5;
								bullet.Size = Vector3.new(distance,0.1,0.1);
								bullet.CFrame = CFrame.new(watcher.Position, target.Position)*CFrame.new(0, 0, -distance/2)*CFrame.Angles(0, math.rad(90), 0);
								bullet.Parent = workspace.Debug;
								
								if inVisionAngle then
									bullet.Color = Color3.fromRGB(0, 255, 127);
								else
									bullet.Color = Color3.fromRGB(255, 0, 0);
								end;
								
								DebrisService:AddItem(bullet, 1);
							end;
							
							if raycastResult and raycastResult.Instance and CollectionService:HasTag(raycastResult.Instance, "Vision_Target"..group) and inVisionAngle then
								if group ~= "Player-To-173" and CollectionService:HasTag(target.Parent, "Protected") then
									continue;
								end;
								VisionService.Seen:Fire(group, watcher, target);
							else
								if CollectionService:HasTag(target.Parent, group.."_Seen") or CollectionService:HasTag(watcher.Parent, group.."_Seeing") then
									VisionService.Unseen:Fire(group, watcher, target);
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end)();
end;

return VisionService;