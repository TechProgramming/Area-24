local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local EffectsModules = script.Parent
local FXStorage = EffectsModules.FXStorage
local InstanceModule = require(EffectsModules.InstanceModule)

local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local ExplosionColors = {
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(170, 85, 0),
}
local ExplosionEffects = {}

function ExplosionEffects.Blast(targetCFrame, size)
	local UniversalDebrisTime = 5
	local BallInfo = {
		Color = Color3.fromRGB(170, 85, 0),
		Material = Enum.Material.Neon,
		Transparency = 1,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local SmokeInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size + ((50/ 100) * size),
			size + ((50/ 100) * size),
			size + ((50/ 100) * size)),
		Location = (targetCFrame * CFrame.Angles(
			math.rad(math.random(1, 4) * 90),
			math.rad(math.random(1, 4) * 90),
			math.rad(math.random(1, 4) * 90)
			)).p,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local Ball = InstanceModule.CloneMesh("Ball", BallInfo)
	local BurstParticles = InstanceModule.CloneParticles("BurstParticles", Ball, UniversalDebrisTime)

	BurstParticles.Fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size + ((50/ 100) * size)),
		NumberSequenceKeypoint.new(1, 0)
	})
	BurstParticles.Fire.Speed = NumberRange.new(50 + (4 * size))
	BurstParticles.Fire.Drag = 10 - ((50/ 100) * size)
	--BurstParticles.Fire.Lifetime = NumberRange.new(((1/ 100) * size), ((10/ 100) * size))
	BurstParticles.Glow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size - ((50/ 100) * size)),
		NumberSequenceKeypoint.new(1, 1)
	})
	BurstParticles.Glow.Speed = NumberRange.new(20 + (5 * size))
	BurstParticles.Debris.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size - ((90.5/ 100) * size)),
		--size - ((90.5/ 100) * size)
		NumberSequenceKeypoint.new(1, 0)
	})
	BurstParticles.Debris.Speed = NumberRange.new(20 + (4 * size))
	--BurstParticles.Debris.Lifetime = NumberRange.new(((10/ 100) * size))
	BurstParticles.Smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size + ((50/ 100) * size)),
		NumberSequenceKeypoint.new(1, size + (2 * size))
	})
	BurstParticles.Smoke.Speed = NumberRange.new(20 + (5 * size))
	--[[
	BurstParticles.Smoke.Acceleration = Vector3.new(
		0, 
		-(10 * size), 
		0)
	]]
	for _, Particle in pairs(BurstParticles:GetChildren()) do
		Particle.Enabled = true
	end	
	local loopConnection
	local stepTimer = 0
	loopConnection = RunService.Heartbeat:Connect(function(step)
		stepTimer += step
		if stepTimer >= .1 then
			loopConnection:Disconnect()
			for _, Particle in pairs(BurstParticles:GetChildren()) do
				Particle.Enabled = false
			end
		end
	end)
end
function ExplosionEffects.Burst(targetCFrame, size)
	--targetCFrame *= CFrame.new(0, size/ 2, 0)
	local UniversalDebrisTime = 5
	local BallInfo = {
		Color = Color3.fromRGB(170, 85, 0),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local ForceFieldInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.ForceField,
		Transparency = 0,
		Size = Vector3.new(
			size * 2.5,
			size * 2.5,
			size * 2.5),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local BallMeshInfo = {
		Color = Color3.fromRGB(255, 255, 0),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local BallSwirlInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size * 1.5,
			size * 1.5,
			size * 1.5),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local CircleLinesInfo = {
		Color = Color3.fromRGB(105, 64, 40),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size + ((50/ 100) * size),
			size - ((50/ 100) * size),
			size + ((50/ 100) * size)),
		Location = (targetCFrame * CFrame.new(0, 1, 0)).p,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local SmokeInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size + ((50/ 100) * size),
			size + ((50/ 100) * size),
			size + ((50/ 100) * size)),
		Location = (targetCFrame * CFrame.Angles(
			math.rad(math.random(1, 4) * 90),
			math.rad(math.random(1, 4) * 90),
			math.rad(math.random(1, 4) * 90)
			)).p,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local Ball = InstanceModule.CloneMesh("Ball", BallInfo)
	local ForceField = InstanceModule.CloneMesh("Ball", ForceFieldInfo)
	local BallMesh = InstanceModule.CloneMesh("BallMesh", BallMeshInfo)
	local BallSwirl = InstanceModule.CloneMesh("BallSwirl", BallSwirlInfo)
	local CircleLines = InstanceModule.CloneMesh("CircleLines", CircleLinesInfo)
	local Smoke = InstanceModule.CloneMesh("Smoke", SmokeInfo)
	
	for i = 1, 10 do
		local LineInfo = {
			Color = ExplosionColors[math.random(1, #ExplosionColors)],
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(
				size - ((90/ 100) * size),
				size - ((math.random(50, 70)/ 100) * size),
				size - ((90/ 100) * size)
			), --.3, 4, .3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneMesh("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			1,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				CFrame = CFrame.new(Line.CFrame.upVector * (Line.Size.Y * 6)) * Line.CFrame,
				Size = Vector3.new(
					Line.Size.X,
					Line.Size.Y + ((math.random(10, 30)/ 100) * size),
					Line.Size.Z
				),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	
	local TweenBallSwirl = TweenService:Create(BallSwirl, TweenInfo.new(
		.25,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				BallSwirl.Size.X * 2.5,
				BallSwirl.Size.Y * 2.5,
				BallSwirl.Size.Z * 2.5),
			CFrame = BallSwirl.CFrame * CFrame.Angles(
				math.rad(180),
				math.rad(180),
				math.rad(180)
			),
			Transparency = 1,
		})
	local TweenForceField = TweenService:Create(ForceField, TweenInfo.new(
		.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				ForceField.Size.X * 3,
				ForceField.Size.Y * 3,
				ForceField.Size.Z * 3),
			Transparency = 1,
		})
	local TweenCircleLines = TweenService:Create(CircleLines, TweenInfo.new(
		2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				CircleLines.Size.X * 3,
				CircleLines.Size.Y - ((20/ 100) * size),
				CircleLines.Size.Z * 3),
			CFrame = CircleLines.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(
				0,
				math.rad(math.random(-1, 1) * 90),
				0),
			Color = Color3.fromRGB(213, 115, 61),
			Transparency = 1,
		})
	local TweenBall = TweenService:Create(Ball, TweenInfo.new(
		1.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				Ball.Size.X * 1.5,
				Ball.Size.Y * 1.5,
				Ball.Size.Z * 1.5),
			Transparency = 1,
		})
	local TweenBallMesh = TweenService:Create(BallMesh, TweenInfo.new(
		.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				BallMesh.Size.X * 1.5,
				BallMesh.Size.Y * 1.5,
				BallMesh.Size.Z * 1.5),
			Color = Color3.fromRGB(213, 115, 61)
		})
	local TweenBallMeshDisappear = TweenService:Create(BallMesh, TweenInfo.new(
		.25,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Transparency = 1,
		})
	local TweenSmoke = TweenService:Create(Smoke, TweenInfo.new(
		2,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				Smoke.Size.X * 3,
				Smoke.Size.Y * 3,
				Smoke.Size.Z * 3),
			CFrame = Smoke.CFrame * CFrame.Angles(
				math.rad((math.random(-1, 1) * 20) + 10),
				math.rad((math.random(-1, 1) * 20) + 10),
				math.rad((math.random(-1, 1) * 20) + 10)
			),
			Transparency = .5,
		})
	local TweenSmokeDisappear = TweenService:Create(Smoke, TweenInfo.new(
		.25,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				Smoke.Size.X * 2,
				Smoke.Size.Y * 2,
				Smoke.Size.Z * 2),
			Transparency = 1,
		})
	TweenBallSwirl:Play()
	TweenForceField:Play()
	TweenCircleLines:Play()
	TweenBall:Play()
	TweenBallMesh:Play()
	TweenSmoke:Play()
	TweenBallMesh.Completed:Wait()
	TweenBallMeshDisappear:Play()
	TweenSmokeDisappear:Play()
end
function ExplosionEffects.Explode(targetCFrame, size)
	ExplosionEffects.Blast(targetCFrame, size)
	
	local UniversalDebrisTime = 5
	--[[
	for i = 1, 10 do
		local LineInfo = {
			Color = ExplosionColors[math.random(1, #ExplosionColors)],
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(
				size - ((95/ 100) * size),
				size - ((math.random(50, 70)/ 100) * size),
				size - ((95/ 100) * size)
			), --.3, 4, .3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneMesh("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			1,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				CFrame = CFrame.new(Line.CFrame.upVector * (Line.Size.Y * 6)) * Line.CFrame,
				Size = Vector3.new(
					Line.Size.X,
					Line.Size.Y + ((math.random(10, 30)/ 100) * size),
					Line.Size.Z
				),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	]]
	
	local ForceFieldInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.ForceField,
		Transparency = 0,
		Size = Vector3.new(
			size * 1.5,
			size * 1.5,
			size * 1.5),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local BallSwirlInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size,
			size,
			size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local CircleLinesInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(
			size + ((50/ 100) * size),
			size - ((50/ 100) * size),
			size + ((50/ 100) * size)),
		Location = (targetCFrame * CFrame.new(0, 1, 0)).p,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local ForceField = InstanceModule.CloneMesh("Ball", ForceFieldInfo)
	local BallSwirl = InstanceModule.CloneMesh("BallSwirl", BallSwirlInfo)
	local CircleLines = InstanceModule.CloneMesh("CircleLines", CircleLinesInfo)
	
	local TweenBallSwirl = TweenService:Create(BallSwirl, TweenInfo.new(
		.25,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				BallSwirl.Size.X * 2,
				BallSwirl.Size.Y * 2,
				BallSwirl.Size.Z * 2),
			CFrame = BallSwirl.CFrame * CFrame.Angles(
				math.rad(math.random(-30, 30)),
				math.rad(180),
				math.rad(math.random(-30, 30))
			),
			Transparency = 1,
		})
	local TweenForceField = TweenService:Create(ForceField, TweenInfo.new(
		.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				ForceField.Size.X * 2.5,
				ForceField.Size.Y * 2.5,
				ForceField.Size.Z * 2.5),
			Transparency = 1,
		})
	local TweenCircleLines = TweenService:Create(CircleLines, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				CircleLines.Size.X * 3,
				CircleLines.Size.Y - ((10/ 100) * size),
				CircleLines.Size.Z * 3),
			CFrame = CircleLines.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(
			0,
			math.rad(math.random(-1, 1) * 90),
			0),
			Color = Color3.fromRGB(98, 32, 0),
			Transparency = 1,
		})

	TweenBallSwirl:Play()
	TweenForceField:Play()
	TweenCircleLines:Play()
end

return ExplosionEffects

--[[
function ExplosionEffects.Spark(targetCFrame)
	local size = 10
	local sizeIncrement = 1
	local expandIncrement = 10
	local UniversalDebrisTime = 5
	local BallInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size - sizeIncrement, size - sizeIncrement, size - sizeIncrement),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local WindSwirlInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local BallSwirlInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size + sizeIncrement, size + sizeIncrement, size + sizeIncrement),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local Ball = InstanceModule.CloneFX("Ball", BallInfo)
	local WindSwirl = InstanceModule.CloneFX("WindSwirl", WindSwirlInfo)
	local BallSwirl = InstanceModule.CloneFX("BallSwirl", BallSwirlInfo)
	local TweenBallStart = TweenService:Create(Ball, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + expandIncrement,
				size + expandIncrement,
				size + expandIncrement),
			Color = Color3.fromRGB(106, 57, 9),
		})
	local TweenBallEnd = TweenService:Create(Ball, TweenInfo.new(
		2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 1.5),
				size + (expandIncrement/ 1.5),
				size + (expandIncrement/ 1.5)),
			Transparency = 1,
		})
	local TweenWindSwirl = TweenService:Create(WindSwirl, TweenInfo.new(
		.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				WindSwirl.Size.X + (expandIncrement/ 2),
				WindSwirl.Size.Y + (expandIncrement/ 2),
				WindSwirl.Size.Z + (expandIncrement/ 2)),
			Transparency = 1,
			Color = Color3.fromRGB(213, 115, 61),
			CFrame = BallSwirl.CFrame * CFrame.Angles(0, -360, 0)
		})
	local TweenBallSwirl = TweenService:Create(BallSwirl, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				WindSwirl.Size.X + (expandIncrement/ 3),
				WindSwirl.Size.Y + (expandIncrement/ 3),
				WindSwirl.Size.Z + (expandIncrement/ 3)),
			Transparency = 1,
			Color = Color3.fromRGB(170, 85, 0),
			CFrame = BallSwirl.CFrame * CFrame.Angles(0, 360, 0)
		})
	TweenBallStart:Play()
	TweenBallEnd:Play()
	TweenWindSwirl:Play()
	TweenBallSwirl:Play()
	
	for i = 1, 3 do
		local LineInfo = {
			Color = Color3.fromRGB(170, 85, 0),
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(1.5, 30, 1.5),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			.5,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				Size = Vector3.new(2, math.random(35, 45), 2),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	for i = 1, 10 do
		local LineInfo = {
			Color = ExplosionColors[math.random(1, #ExplosionColors)],
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(.3, 4, .3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			1,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				CFrame = CFrame.new(Line.CFrame.upVector * math.random(10, 20)) * Line.CFrame,
				Size = Vector3.new(.6, 8, .6),
				Transparency = 1,
			})
		TweenLine:Play()
	end
end
function ExplosionEffects.Burst(targetCFrame)
	local size = 5
	local sizeIncrement = 5
	local expandIncrement = 7
	local UniversalDebrisTime = 5
	
	for i = 1, 3 do
		local LineInfo = {
			Color = Color3.fromRGB(170, 85, 0),
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(1.5, 30, 1.5),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			.5,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				Size = Vector3.new(2, math.random(35, 45), 2),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	for i = 1, 2 do
		local SmokeInfo = {
			Color = Color3.fromRGB(91, 93, 105),
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(size + 10, size + 3, size + 3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-1, 1) * 45),
				math.rad(math.random(-1, 1) * 45),
				math.rad(math.random(-1, 1) * 45)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Smoke = InstanceModule.CloneFX("Smoke", SmokeInfo)
		
		local TweenSmoke = TweenService:Create(Smoke, TweenInfo.new(
			3,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				Size = Vector3.new(
					size + (expandIncrement * 2.5),
					size + (expandIncrement * 2.5),
					size + (expandIncrement * 2.5)),
				Transparency = 1,
			})
		TweenSmoke:Play()
	end
	for i = 1, 10 do
		local LineInfo = {
			Color = ExplosionColors[math.random(1, #ExplosionColors)],
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(.3, 4, .3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			1,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				CFrame = CFrame.new(Line.CFrame.upVector * math.random(10, 15)) * Line.CFrame,
				Size = Vector3.new(.6, 8, .6),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	
	local BallInfo = {
		Color = Color3.fromRGB(255, 85, 0),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local SpiralBallInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size + sizeIncrement, size + sizeIncrement, size + sizeIncrement),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local Ball = InstanceModule.CloneFX("Ball", BallInfo)
	local SpiralBall = InstanceModule.CloneFX("SpiralBall", SpiralBallInfo)
	local TweenBallStart = TweenService:Create(Ball, TweenInfo.new(
		.1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.In
		), {
			Size = Vector3.new(
				size + expandIncrement,
				size + expandIncrement,
				size + expandIncrement),
			Color = Color3.fromRGB(255, 170, 0),
		})
	local TweenBallEnd = TweenService:Create(Ball, TweenInfo.new(
		2,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement * 1.5),
				size + (expandIncrement * 1.5),
				size + (expandIncrement * 1.5)),
			Color = Color3.fromRGB(157, 0, 0),
			Transparency = 1,
		})
	local TweenSpiralBall = TweenService:Create(SpiralBall, TweenInfo.new(
		1,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement * 2),
				size + (expandIncrement * 2),
				size + (expandIncrement * 2)),
			Transparency = 1,
			Color = Color3.fromRGB(170, 85, 0),
			CFrame = SpiralBall.CFrame * CFrame.Angles(math.rad(-90), math.rad(-90), math.rad(-90))
		})
	TweenSpiralBall:Play()
	TweenBallStart:Play()
	TweenBallStart.Completed:Wait()
	TweenBallEnd:Play()
end
function ExplosionEffects.Blast(targetCFrame)
	local size = 20
	local sizeIncrement = 10
	local expandIncrement = 40
	local UniversalDebrisTime = 5
	
	for i = 1, 3 do
		local LineInfo = {
			Color = Color3.fromRGB(170, 85, 0),
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(2, 70, 2),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			.5,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				Size = Vector3.new(5, math.random(80, 120), 5),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	for i = 1, 10 do
		local LineInfo = {
			Color = ExplosionColors[math.random(1, #ExplosionColors)],
			Material = Enum.Material.Neon,
			Transparency = 0,
			Size = Vector3.new(.3, 4, .3),
			Location = targetCFrame * CFrame.Angles(
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60),
				math.rad(math.random(-3, 3) * 60)),
			Parent = HumanoidRootPart,
			DebrisTime = UniversalDebrisTime
		}
		local Line = InstanceModule.CloneFX("Ball", LineInfo)
		local TweenLine = TweenService:Create(Line, TweenInfo.new(
			1,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
			), {
				CFrame = CFrame.new(Line.CFrame.upVector * math.random(30, 50)) * Line.CFrame,
				Size = Vector3.new(1.6, 8, 1.6),
				Transparency = 1,
			})
		TweenLine:Play()
	end
	
	local BallInfo = {
		Color = Color3.fromRGB(213, 115, 61),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size - sizeIncrement, size - sizeIncrement, size - sizeIncrement),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local WindSwirlInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size, size, size),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local BallSwirlInfo = {
		Color = Color3.fromRGB(91, 93, 105),
		Material = Enum.Material.Neon,
		Transparency = 0,
		Size = Vector3.new(size + sizeIncrement, size + sizeIncrement, size + sizeIncrement),
		Location = targetCFrame,
		Parent = HumanoidRootPart,
		DebrisTime = UniversalDebrisTime
	}
	local Ball = InstanceModule.CloneFX("Ball", BallInfo)
	local WindSwirl = InstanceModule.CloneFX("WindSwirl", WindSwirlInfo)
	local BallSwirl = InstanceModule.CloneFX("BallSwirl", BallSwirlInfo)
	local TweenBallStart = TweenService:Create(Ball, TweenInfo.new(
		.1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4)),
			Color = Color3.fromRGB(255, 85, 0),
		})
	local TweenBallEnd = TweenService:Create(Ball, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 3),
				size + (expandIncrement/ 3),
				size + (expandIncrement/ 3)),
			Transparency = 1,
			Color = Color3.fromRGB(85, 0, 0),
		})
	local TweenWindSwirlStart = TweenService:Create(WindSwirl, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 2),
				size + (expandIncrement/ 2),
				size + (expandIncrement/ 2)),
			Color = Color3.fromRGB(177, 20, 0),
			CFrame = WindSwirl.CFrame * CFrame.Angles(0, -360, 0)
		})
	local TweenBallSwirlStart = TweenService:Create(BallSwirl, TweenInfo.new(
		3,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4)),
			Color = Color3.fromRGB(255, 85, 0),
			CFrame = BallSwirl.CFrame * CFrame.Angles(0, -360, 0)
		})
	local TweenWindSwirlEnd = TweenService:Create(WindSwirl, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4),
				size + (expandIncrement/ 4)),
			Transparency = 1,
			CFrame = BallSwirl.CFrame * CFrame.Angles(0, -90, 0)
		})
	local TweenBallSwirlEnd = TweenService:Create(BallSwirl, TweenInfo.new(
		1,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
		), {
			Size = Vector3.new(
				size + (expandIncrement/ 3),
				size + (expandIncrement/ 3),
				size + (expandIncrement/ 3)),
			Transparency = 1,
			CFrame = BallSwirl.CFrame * CFrame.Angles(0, -90, 0)
		})
	TweenWindSwirlStart:Play()
	TweenBallSwirlStart:Play()
	TweenBallStart:Play()
	TweenBallStart.Completed:Wait()
	TweenWindSwirlEnd:Play()
	TweenBallSwirlEnd:Play()
	TweenBallEnd:Play()
end
]]