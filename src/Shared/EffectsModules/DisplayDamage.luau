local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local EffectsModules = script.Parent
local FXStorage = EffectsModules.FXStorage

local LocalPlayer = game:GetService("Players").LocalPlayer

local DisplayModule = {}
local DEBRIS_TIME = 3
local CritColors = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 85, 0),
	Color3.fromRGB(255, 0, 0),
}

function DisplayModule.Display(character, model, damage, critical)
	local HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	local switch = {true, false}
	local positive = switch[math.random(#switch)]
	local UI = FXStorage.DamageUI:Clone()
	UI.Adornee = model.PrimaryPart or model:GetChildren()[1]
	UI.DamageText.Text = damage
	UI.DamageText.TextColor3 = CritColors[critical]
	UI.ExtentsOffsetWorldSpace = Vector3.new(
		positive and (math.random(5, 20) * .1) or (math.random(-20, -5) * .1),
		math.random(-1, 1),
		math.random(-1, 1)
	)
	UI.Parent = HumanoidRootPart
	game:GetService("Debris"):AddItem(UI, DEBRIS_TIME)
	local OffsetGoal
	if positive then
		OffsetGoal = Vector3.new(
			math.random(1, 10) * .1,
			0,
			math.random(-20, 20) * .1
		)
	else
		OffsetGoal = Vector3.new(
			-math.random(1, 10) * .1,
			0,
			math.random(-20, 20) * .1
		)
	end
	local TweenUI = TweenService:Create(UI, TweenInfo.new(
		.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			--SizeOffset = OffsetGoal,
			StudsOffsetWorldSpace = OffsetGoal,
		})
	local TweenUIEnd = TweenService:Create(UI.DamageText, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
	TweenUI:Play()
	TweenUI.Completed:Connect(function()
		TweenUIEnd:Play()
	end)
end

local numHitParticles = 3

function DisplayModule.BulletContact(hitPoint, hitPart, hitMaterial, humanoid)
	local hitPartColor = hitPart and hitPart.Color or Color3.fromRGB(255, 255, 255)
	if hitPart and hitPart:IsA("Terrain") then
		hitPartColor = workspace.Terrain:GetMaterialColor(hitMaterial or Enum.Material.Sand)
	end
	
	local hitEffect = FXStorage.HitEffect:Clone()
	local hitParticles = hitEffect:WaitForChild("HitParticles")
	local visualEffectsLingerTime = 0
	
	hitEffect.Parent = workspace.CurrentCamera
	hitEffect.Position = hitPoint
	
	local humanoid = humanoid or (hitPart and hitPart.Parent:FindFirstChildWhichIsA("Humanoid"))
	
	if humanoid and numHitParticles > 0 then
		-- Show particle effect for hitting a player/humanoid
		hitParticles.Color = ColorSequence.new(Color3.fromRGB(255, 48, 51))
		hitParticles:Emit(numHitParticles)
		visualEffectsLingerTime = math.max(visualEffectsLingerTime, hitParticles.Lifetime.Max)
	elseif (not hitPart or not humanoid) and numHitParticles > 0 then
		-- Show particle effect for hitting anything else
		if hitPart then
			local existingSeq = hitParticles.Color
			local newKeypoints = {}

			for i, keypoint in pairs(existingSeq.Keypoints) do
				local newColor = keypoint.Value
				if newColor == Color3.fromRGB(255, 0, 255) then
					newColor = hitPartColor
				end
				newKeypoints[i] = ColorSequenceKeypoint.new(keypoint.Time, newColor)
			end

			hitParticles.Color = ColorSequence.new(newKeypoints)
		end

		hitParticles:Emit(numHitParticles)
		visualEffectsLingerTime = math.max(visualEffectsLingerTime, hitParticles.Lifetime.Max)
	end
	
	Debris:AddItem(hitEffect, visualEffectsLingerTime)
	
	return hitEffect
end


return DisplayModule