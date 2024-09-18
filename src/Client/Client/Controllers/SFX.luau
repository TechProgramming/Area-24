
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local LightingService = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local PLAYER = game:GetService("Players").LocalPlayer
local SFX = game:GetService("SoundService"):WaitForChild("SFX")

local WeaponsSFX = SoundService:WaitForChild("Weapons")

local DEBUG = false

-- Bullet flyby sounds
local FlybyMaxDist = Instance.new("NumberValue", script)
FlybyMaxDist.Name = "FlybyMaximumDistance"
FlybyMaxDist.Value = 5
local FlybyMinVol = Instance.new("NumberValue", script)
FlybyMinVol.Name = "FlybyMinimumVolume"
FlybyMinVol.Value = 0.5


local ImpactSounds = {
	Plastic = "Body";
	SmoothPlastic = "Body";

	Wood = "Wood";
	WoodPlanks = "Wood";

	Slate = "Gravel";
	Marble = "Gravel";
	Granite = "Gravel";
	Asphalt = "Gravel";
	Pavement = "Gravel";

	Brick = "Concrete";
	Concrete = "Concrete";

	CorrodedMetal = "Metal";
	DiamondPlate = "Metal";
	Metal = "Metal";

	Grass = "Grass";
	LeafyGrass = "Grass";
	Ground = "Grass";

	Neon = "Glass";
	Glass = "Glass";

	Ice = "Ice";
	Glacier = "Ice";

	Pebble = "Rock";
	CrackedLava = "Rock";
	Basalt = "Rock";
	Salt = "Rock";
	Limestone = "Rock";
	Cobblestone = "Rock";
	Rock = "Rock";
	Sandstone = "Rock";

	Sand = "Snow";
	Snow = "Snow";

	Water = "Water";

	Mud = "Mud";

	--ForceField = ;
	--Foil = ;
	--Fabric = ;
	--Air = ;
}

local function MakeTempPart(position)
	local tempPart = Instance.new("Part")
	tempPart.Anchored = true
	tempPart.CanCollide = false
	if not DEBUG then
		tempPart.Transparency = 1
	else
		tempPart.Size = Vector3.new(1,1,1)
		tempPart.Color = Color3.new(0, 0.666667, 1)
	end
	tempPart.Position = position
	tempPart.Name = "TempSoundPart"
	tempPart.Parent = workspace.CurrentCamera

	Debris:AddItem(tempPart, 2) -- make sure it gets destroyed no matter what
	
	return tempPart
end

local SFXController = Knit.CreateController({
	Name = "SFXController",
	
	FlybyMaxDist = FlybyMaxDist;
})

function SFXController:KnitStart()
	for _, audio in pairs(SFX:GetDescendants()) do
		if audio:IsA("Sound") then
			SFXController[audio.Name] = audio 
			local pitch = Instance.new("PitchShiftSoundEffect")
			pitch.Parent = audio
			pitch.Octave = 1
		end
	end
	
	function SFXController:PlayRandomFromList(list)
		local num = math.random(1, #list)
		local pick = list[num]
		SFXController[pick]:Play()
	end
	
	function SFXController:Play(sound, options)
		--if options ~= nil then
		--	if options.RandomPitchFromList ~= nil then
		--		local num = math.random(1, #options.RandomPitchFromList)
		--		local pitch = options.RandomPitchFromList[num]
		--		SFXController[sound].PitchShiftSoundEffect.Octave = pitch
		--	end
		--end
		if sound == "impact" then
			local material = options.material and options.material.Name
			local position = options.position
			assert(Enum.Material[material], "SFXController::Play called impact while no material exists with name " .. tostring(material))
			assert(typeof(position)=="Vector3", "SFXController::Play 'position' is " .. typeof(position))
			
			local soundType = ImpactSounds[material] or "Body"
			local sounds = WeaponsSFX.Bullets.Impact[soundType]:GetChildren()
			
			local index = math.random(1, #sounds)
			sound = sounds[index]
			
			-- create pitch if doesnt exist
			local pitch = sound:FindFirstChildWhichIsA("PitchShiftSoundEffect")
			if pitch == nil then
				pitch = Instance.new("PitchShiftSoundEffect", sound)
				pitch.Octave = 1
			end
			
			sound = sound:Clone()
			pitch = sound[pitch.Name]
			pitch.Octave = math.random()*0.1 + pitch.Octave
			
			local tempPart = MakeTempPart(position)
			sound.Parent = tempPart
			
			sound.Ended:Connect(function()
				tempPart:Destroy()
			end)
			sound.Stopped:Connect(function()
				tempPart:Destroy()
			end)
			
			sound:Play()
			
			return sound
		elseif sound == "flyby" then
			local position = options.position
			local distance = options.distance
			assert(typeof(position)=="Vector3", "SFXController::Play 'position' is " .. typeof(position))
			assert(typeof(distance)=="number", "SFXController::Play 'distance' is " .. typeof(distance))
			
			local distAlpha = distance/FlybyMaxDist.Value
			local volAlpha = FlybyMinVol.Value + (1-FlybyMinVol.Value)*distAlpha
			
			local sounds = WeaponsSFX.Bullets.Flyby:GetChildren()
			local index = math.random(1,#sounds)
			local sound = sounds[index]:Clone()
			sound.Volume = volAlpha
			
			local tempPart = MakeTempPart(position)
			sound.Parent = tempPart
			
			sound:Play()
		else
			SFXController[sound]:Play()
		end
	end
	
	function SFXController:Stop(sound)
		SFXController[sound]:Stop()
	end	
	
	-- SPECIAL
	
	local Prefabs = {
		["ButtonClick"] = function()
			SFXController:Play("Click_1", {
				RandomPitchFromList = {0.95, 1, 1.05}
			})
		end,
		["ButtonError"] = function()
			SFXController:Play("Error_1", {
				RandomPitchFromList = {0.95, 1, 1.05}
			})
		end,		
		["ButtonHover"] = function()
			SFXController:Play("Select", {
				RandomPitchFromList = {0.95, 1, 1.05}
			})
		end,			
	}
	
	function SFXController:PlayPrefab(prefab)
		Prefabs[prefab]()
	end
end


return SFXController