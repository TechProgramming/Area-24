local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SharedModules = ReplicatedStorage:WaitForChild("Modules")

local Knit = require(SharedModules:WaitForChild("Knit"))
local Signal = require(Knit.Util:WaitForChild("Signal"))
local RemoteSignal = require(Knit.Util:WaitForChild("Remote"):WaitForChild("RemoteSignal"))
local RemoteProperty = require(Knit.Util:WaitForChild("Remote"):WaitForChild("RemoteProperty"))

local CharacterService = Knit.CreateService({
	Name = "CharacterService";
	
	Client = {
		UpdateCharacterAngles = RemoteSignal.new();
		CharacterAnglesUpdateRate = RemoteProperty.new(1/20);
		
		RecreateMotors = RemoteSignal.new(); -- fired by the server with Neck and Waist's C0 and C1
	};
})

local charactersMotorOffsets = {}

local NeckOriginC0 = CFrame.new(0, 0.8, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local WaistOriginC0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

local function applyCharacterAngles(player, xtheta, ytheta, delta)
	local offsets = charactersMotorOffsets[player]
	if offsets == nil then return end
	
	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid")
	--if humanoid == nil then return end
	--if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
	
	local neckC0 = offsets[1]
	local waistC0 = offsets[3]
	
	local Head = character and character:FindFirstChild("Head")
	local Neck = Head and Head:FindFirstChild("Neck")

	local Torso = character and character:FindFirstChild("UpperTorso")
	local Waist = Torso and Torso:FindFirstChild("Waist")

	local Humanoid = character and character:FindFirstChild("Humanoid")
	local HumanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if Neck == nil or Waist == nil then return false end

	Neck.MaxVelocity = 1/3
	Waist.MaxVelocity = 1/3

	Neck.C0 = Neck.C0:Lerp(neckC0 * CFrame.Angles(xtheta*0.5, ytheta*0.5, 0), delta or 0.5/2)
	Waist.C0 = Waist.C0:Lerp(waistC0 * CFrame.Angles(xtheta*0.5, ytheta*0.5, 0), delta or 0.5/2)

	return true
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		local hum = character:WaitForChild("Humanoid")
		hum.RequiresNeck = false

		local head = character and character:WaitForChild("Head")
		local neck = head and head:WaitForChild("Neck")

		local torso = character and character:WaitForChild("UpperTorso")
		local waist = torso and torso:WaitForChild("Waist")

		local parent = character.Parent
		while parent == nil do
			parent = character.AncestryChanged:Wait()
		end

		local newNeck = neck:Clone()
		local newWaist = waist:Clone()

		neck:Destroy()
		waist:Destroy()

		newNeck.Parent = character.Head
		newWaist.Parent = character.UpperTorso

		local neckC0 = newNeck.C0
		local neckC1 = newNeck.C1
		local waistC0 = newWaist.C0
		local waistC1 = newWaist.C1

		--print("CharacterService::RecreateMotors ", character:GetFullName())

		charactersMotorOffsets[player] = {neckC0, neckC1, waistC0, waistC1, newNeck, newWaist}
		CharacterService.Client.RecreateMotors:FireAll(player, neckC0, neckC1, waistC0, waistC1, newNeck, newWaist)
		--[[
		local conn
		conn = character.DescendantRemoving:Connect(function(v)
			if player.Character ~= character or hum:GetState() == Enum.HumanoidStateType.Dead then conn:Disconnect() return end
			
			if not v:IsA("Motor6D") then return end
			if (v.Name ~= "Neck" or v.Parent ~= character.Head) and (v.Name ~= "Waist" or v.Parent ~= character.UpperTorso) then return end
			local newMotor = v:Clone()
			if v.Name == "Neck" then
				newMotor.Parent = character.Head
			else
				newMotor.Parent = character.UpperTorso
			end
		end)
		--]]
	end)
	
	for owner, offsets in pairs(charactersMotorOffsets) do
		if owner.Character then
			CharacterService.Client.RecreateMotors:Fire(player, owner, unpack(offsets))
		end
	end
end

local lastUpdates = {}
local function onPlayerRemoving(player)
	charactersMotorOffsets[player] = nil
	lastUpdates[player] = nil
end

function CharacterService:KnitInit()
	
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in pairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	self.Client.UpdateCharacterAngles:Connect(function(player, theta, theta2)
		if lastUpdates[player] and
			tick() - lastUpdates[player] < self.Client.CharacterAnglesUpdateRate:Get()*1.5 then
			return -- kick player?
		end

		lastUpdates[player] = tick()
		applyCharacterAngles(player, theta, theta2, 1)
		
		for i, _ in pairs(lastUpdates) do
			-- instead of using a PlayerLoaded Signal (to avoid exhaust), we can just arbitrarly use this
			if i == player then continue end
			self.Client.UpdateCharacterAngles:Fire(i, player, theta, theta2)
		end
	end)
end

return CharacterService