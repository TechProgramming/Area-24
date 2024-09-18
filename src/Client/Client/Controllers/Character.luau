local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


-- Constant Objects
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SharedModules = ReplicatedStorage:WaitForChild("Modules")

local Knit = require(SharedModules:WaitForChild("Knit"))
local Signal = require(Knit.Util:WaitForChild("Signal"))
local Thread = require(Knit.Util.Thread)

local CharacterController = Knit.CreateController({
	Name = "CharacterController";
	
	Character = nil;
	
	SpawnSignal = Signal.new();
	DeathSignal = Signal.new();
})

local FPSController

--local CharacterService = Knit.GetService("CharacterService")
local CharacterAnglesUpdateRate = 0--CharacterService.CharacterAnglesUpdateRate:Get()

local characterTargetAngles = {}

local XOffsetInstance = Instance.new("NumberValue", script)
XOffsetInstance.Value = 0.1
XOffsetInstance.Name = "XOffset"

local charactersMotorOffsets = {}

local function waitForChild(inst, name)
	local target
	for _, v in ipairs(inst:GetChildren()) do
		if v.Name == name then
			
		end
	end
end

local function applyCharacterAngles(player, xtheta, ytheta, delta)
	local offsets = charactersMotorOffsets[player]
	if offsets == nil then print(player.Name, "failed to update character's angles") return end

	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	--if humanoid == nil then return end
	--if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

	local neckC0 = offsets[1]
	local waistC0 = offsets[3]
	
	local Neck, Waist = offsets[7], offsets[8]
	
	--local Head = character and character:FindFirstChild("Head")
	--local Neck = Head and Head:FindFirstChild("Neck")

	--local Torso = character and character:FindFirstChild("UpperTorso")
	--local Waist = Torso and Torso:FindFirstChild("Waist")

	--local Humanoid = character and character:FindFirstChild("Humanoid")
	--local HumanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if Neck == nil or Waist == nil then return false end

	Neck.MaxVelocity = 1/3
	Waist.MaxVelocity = 1/3

	local NeckOriginC0 = CFrame.new(0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	local WaistOriginC0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

	Neck.C0 = Neck.C0:Lerp(neckC0 * CFrame.Angles(xtheta*0.5, ytheta*0.5, 0), delta or 0.5/2)
	Waist.C0 = Waist.C0:Lerp(waistC0 * CFrame.Angles(xtheta*0.5, ytheta*0.5, 0), delta or 0.5/2)

	--[[
	local neckC0 = CFrame.new(0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	local waistC0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local waist = root and character:FindFirstChild("UpperTorso") and character.UpperTorso:FindFirstChild("Waist")
	local neck = root and character:FindFirstChild("Head") and character.Head:FindFirstChild("Neck")
	
	if waist == nil or neck == nil then return false end

	if theta2 > math.pi/2 and theta2 < math.pi*1.5 then
		local char_angle = CFrame.Angles(0,0,0)
		if math.abs(theta2 - math.pi/2) <= math.abs(theta2 - math.pi*1.5) then
			char_angle = CFrame.Angles(0, theta2 - math.pi/2, 0)
			waist.C0 = waistC0 * CFrame.Angles(0, math.pi/2, 0)
		else
			char_angle = CFrame.Angles(0, theta2 - math.pi*1.5, 0)
			waist.C0 = waistC0 * CFrame.Angles(0, math.pi*1.5, 0)
		end
		if character == LocalPlayer.Character then
			character:SetPrimaryPartCFrame(root.CFrame * char_angle)
		end

		theta2 = math.pi-theta2
	else
		waist.C0 = waistC0 * CFrame.Angles(0, theta2, 0)
	end
	
	if waist and neck then
		neck.C0 = neckC0 * CFrame.Angles(theta*0.5, -theta2, 0)
		waist.C0 = waistC0 * CFrame.Angles(0, theta2, 0)
	end
	--]]
	return true
end

local xValue = Instance.new("NumberValue", script)
xValue.Name = "DeltaX"
local yValue = Instance.new("NumberValue", script)
yValue.Name = "DeltaY"


local function getCharacterAngles()
	--https://devforum.roblox.com/t/need-help-with-torso-and-head-following-mouse/319512/7
	local character = LocalPlayer.Character
	local offsets = charactersMotorOffsets[LocalPlayer]
	if offsets == nil then return end
	--if Neck or Torso == nil then return 0,0 end

	--local Head = character:FindFirstChild("Head")
	--local Neck = Head and Head:FindFirstChild("Neck")

	local Torso = character:FindFirstChild("UpperTorso")
	--local Waist = Torso and Torso:FindFirstChild("Waist")

	local Humanoid = character:FindFirstChild("Humanoid")
	local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	
	if Humanoid == nil or HumanoidRootPart == nil or Torso == nil then return 0,0 end
	if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return 0,0 end
	
	local Neck, Waist = offsets[7], offsets[8]

	if Neck == nil or Waist == nil then return 0,0 end

	if Camera.CameraSubject:IsDescendantOf(character) or Camera.CameraSubject:IsDescendantOf(LocalPlayer) then
		local CameraCFrame = Camera.CoordinateFrame

		local TorsoLookVector = Torso.CFrame.lookVector

		local camDirection = HumanoidRootPart.CFrame:ToObjectSpace(Camera.CFrame).LookVector
		local xtheta = XOffsetInstance.Value + camDirection.Y
		local ytheta = (FPSController and FPSController:GetIsEquipped() and not FPSController:GetIsAtEase() and 0) or -camDirection.X

		return xtheta,ytheta
	else
		return 0,0
	end
	--[[
	-- edited from: https://devforum.roblox.com/t/521597/6
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local waist = root and character:FindFirstChild("UpperTorso") and character.UpperTorso:FindFirstChild("Waist")
	local neck = root and character:FindFirstChild("Head") and character.Head:FindFirstChild("Neck")
	
	if neck and waist then
		local theta = math.asin(Camera.CFrame.LookVector.y)
		local camera_angle = math.atan2(Camera.CFrame.LookVector.X, Camera.CFrame.LookVector.Z)
		local body_angle = math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z)
		local theta2 = (camera_angle-body_angle)%(2*math.pi)

		--if theta2 > math.pi/2 and theta2 < math.pi*1.5 then
		--	theta2 = math.pi-theta2
		--end
		return theta, theta2
	else
		return 0, 0
	end
	--]]
end

local function onCharacterAdded(char)
	local root = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")

	CharacterController.Character = char

	CharacterController.SpawnSignal:Fire(char)
	
	char:GetAttributeChangedSignal("Controlled"):Connect(function()
		if char:GetAttribute("Controlled") then
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false);
			game:GetService("StarterGui"):SetCore("ResetButtonCallback", false);
			game:GetService("StarterGui"):SetCore("ChatBarDisabled", true);
			LocalPlayer.PlayerGui.RightBar.Enabled = false;
			LocalPlayer.PlayerGui.LeftBar.Enabled = false;
		end;
	end);
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true);
	game:GetService("StarterGui"):SetCore("ResetButtonCallback", true);
	game:GetService("StarterGui"):SetCore("ChatBarDisabled", false);
	LocalPlayer.PlayerGui.RightBar.Enabled = true;
	LocalPlayer.PlayerGui.LeftBar.Enabled = true;
	
	local diedFired = false
	
	local function onDied()
		if diedFired then return end
		diedFired = true
		CharacterController.DeathSignal:Fire(char)
		for _, limb in pairs(char:GetChildren()) do
			if limb:IsA("BasePart") then
				limb.CanCollide = true
				for _, v in pairs(limb:GetChildren()) do
					if v:IsA("Motor6D") then
						v:Destroy()
					end
				end
			end
		end
	end
	

	humanoid.Died:Connect(function()
		onDied()
	end)
	
	if char.Parent == nil then
		char:GetPropertyChangedSignal("Parent"):Wait()
	end
	local ancestor = char.Parent
	while ancestor ~= nil do
		ancestor = char:GetPropertyChangedSignal("Parent"):Wait()
	end
	
	onDied()
end

local function updateCharacterMotors(player)
	local character = player.Character
	if character == nil or not workspace:IsAncestorOf(character) then return end
	
	local data = charactersMotorOffsets[player]
	if data == nil then return end
	
	local neck, waist
	local descConn
	descConn = character.DescendantAdded:Connect(function(motor)
		if not motor:IsA("Motor6D") or (motor.Name ~= "Neck" and motor.Name ~= "Waist") then return end
		if motor == neck or motor == waist then return end

		motor.Enabled = false
	end)
	
	local serverNeck, serverWaist = data[5], data[6]
	if serverNeck then serverNeck.Enabled = false end
	if serverWaist then serverWaist.Enabled = false end

	local humanoid = character:WaitForChild("Humanoid")
	if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
	
	local head = character:WaitForChild("Head")
	local upperTorso = character:WaitForChild("UpperTorso")
	local lowerTorso = character:WaitForChild("LowerTorso")
	
	if head == nil or upperTorso == nil or lowerTorso == nil or humanoid == nil then return end
	
	local neckC0, neckC1, waistC0, waistC1 = data[1], data[2], data[3], data[4]

	neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.C0 = neckC0
	neck.C1 = neckC1
	neck.Part0 = upperTorso
	neck.Part1 = head

	waist = Instance.new("Motor6D")
	waist.Name = "Waist"
	waist.C0 = waistC0
	waist.C1 = waistC1
	waist.Part0 = lowerTorso
	waist.Part1 = upperTorso
	
	-- destroy client motors if exist
	if data[7] then data[7]:Destroy() end
	if data[8] then data[8]:Destroy() end
	
	neck.Parent = head
	waist.Parent = upperTorso

	data[7] = neck
	data[8] = waist
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		--updateCharacterMotors(player)
	end)
end

function CharacterController:KnitInit()
	FPSController = Knit.Controllers["FPSController"]
	
	--[
	if LocalPlayer.Character then Thread.Spawn(function() onCharacterAdded(LocalPlayer.Character) end) end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	--]]
	local lastCharacterAnglesUpdate, lastX, lastY = tick(), nil, nil
	RunService:BindToRenderStep(CharacterController.Name, Enum.RenderPriority.Character.Value, function()
		local xtheta, ytheta = getCharacterAngles()
		xValue.Value = xtheta
		yValue.Value = ytheta

		if xtheta and ytheta and (xtheta ~= lastX or ytheta ~= lastY) then
			applyCharacterAngles(LocalPlayer, xtheta, ytheta, 1)
			lastX = xtheta
			lastY = ytheta

			if tick() - lastCharacterAnglesUpdate >= CharacterAnglesUpdateRate then
				lastCharacterAnglesUpdate = tick()
				--CharacterService.UpdateCharacterAngles:Fire(xtheta, ytheta)
			end
		end
		
		for updater, data in pairs(characterTargetAngles) do
			local delta = math.clamp((tick() - data[3])/(CharacterAnglesUpdateRate),0,1)
			applyCharacterAngles(updater, data[1], data[2], delta)
		end
	end)

	--CharacterService.UpdateCharacterAngles:Connect(function(updater, theta, theta2)
	--	characterTargetAngles[updater] = {theta, theta2, tick()}
	--	--applyCharacterAngles(updater.Character, theta, theta2)
	--end)
	
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		
		onPlayerAdded(player)
	end
	
	Players.PlayerRemoving:Connect(function(player)
		characterTargetAngles[player] = nil
	end)
	
	--CharacterService.RecreateMotors:Connect(function(player, neckC0, neckC1, waistC0, waistC1, serverNeck, serverWaist)
	--	local data = {neckC0, neckC1, waistC0, waistC1, serverNeck, serverWaist}
	--	charactersMotorOffsets[player] = data
		
	--	local character = player.Character or player.CharacterAdded:Wait()
		
	--	updateCharacterMotors(player)
	--	--humanoid.StateChanged:Connect(function(oldstate, newstate)
	--	--	if newstate == Enum.HumanoidStateType.Dead then
	--	--		waist:Destroy()
	--	--		neck:Destroy()
	--	--	end
	--	--end)
	--end)
end

return CharacterController