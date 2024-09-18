local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local FPSAssets = Assets:WaitForChild("FPS")
local Sounds = SoundService:WaitForChild("Weapons"):WaitForChild(script.Name)

local function makeAnimation(id,name)
	local i = Instance.new("Animation")
	i.AnimationId = typeof(id) == "string" and id or ("rbxassetid://" .. id)
	if name then i.Name = name end
	i.Parent = script
	return i
end
local function makeSound(id)
	local i = Instance.new("Sound")
	i.SoundId = typeof(id) == "string" and id or ("rbxassetid://" .. id)
	if not RunService:IsServer() then
	end
	return i
end
local function makeValue(className, defaultValue, parent, name)
	if RunService:IsServer() then return nil end
	local value = Instance.new(className)
	value.Name = name
	value.Value = defaultValue
	if parent then
		value.Parent = parent
	end
	return value
end
if not RunService:IsServer() then
	aimFolder = Instance.new("Folder", script); aimFolder.Name = "aim";
	gunUpFolder = Instance.new("Folder", script); gunUpFolder.Name = "gunUp";
	landFolder = Instance.new("Folder", script); landFolder.Name = "land";
	sprintFolder = Instance.new("Folder", script); sprintFolder.Name = "sprint";
	easeFolder = Instance.new("Folder", script); easeFolder.Name = "ease";
end

local data = {
	script = script;
	name = script.Name;
	displayName = "SPAS12";
	weaponType = "shotgun";
	walkAndSprintAnimType = "ar";

	hidesOnUnequip = true; -- weapon doesn't use backweld basically

	offsets = {
		viewmodel = {
			Camera = {
				C0 = CFrame.new(0.588623047, 0.222846508, 4.30106258, -1, 2.44042135e-12, -1.95541361e-11, -2.44042135e-12, 1, -2.38428255e-23, -1.95541361e-11, 2.38428255e-23, -1);
				C1 = CFrame.new(0,0,0);
			};
			MainPart = {
				C0 = CFrame.new(0.118708938, -0.158359706, 4.71916008, -1, 9.07903882e-07, -5.727602e-07, 9.07903768e-07, 1, 1.65019969e-07, 5.72760371e-07, 1.65019443e-07, -1);
				C1 = CFrame.new(0,0,0);
			};
			LeftArm = {
				C0 = CFrame.new(1.50755799, -0.242300421, 4.45455122, -2.2444604e-07, -3.8928809e-07, -1, -7.90195198e-09, 1, -3.8928809e-07, 1, 7.90186494e-09, -2.24446083e-07);
				C1 = CFrame.new(3, 2.98023224e-08, -7.15255737e-07, 1, 0, -2.84217094e-14, 0, 1, -1.77354268e-15, -2.84217094e-14, -1.77354257e-15, 1);
			};
			RightArm = {
				C0 = CFrame.new(-1.06257117, -0.242301419, 4.45455027, -2.2444604e-07, -3.8928809e-07, -1, -7.90195198e-09, 1, -3.8928809e-07, 1, 7.90186494e-09, -2.24446083e-07);
				C1 = CFrame.new(3, 2.98023224e-08, -7.15255737e-07, 1, 0, -2.84217094e-14, 0, 1, -1.77354268e-15, -2.84217094e-14, -1.77354257e-15, 1);
			};
		};
		weaponFrame = {
			MainPart = {
				C0 = CFrame.new(0,0,0);
				C1 = CFrame.new(0,0,0);
			};
			backweld = {
				C0 = CFrame.new(0,0,0);
				C1 = CFrame.new(0,0,0);
			};
			weaponHold = {
				C0 = CFrame.new(-0.1,-0.2,0);
				C1 = CFrame.new(0,0,0);
			};
		};

		animations = {

			viewmodel = {
				aim = {
					angle = makeValue("Vector3Value", Vector3.new(-0.025, 0.017, 0), aimFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(-0.755, 0.45, -0.1), aimFolder, "position");
				};
				gunUp = {
					angle = makeValue("Vector3Value", Vector3.new(0, 0, 0), gunUpFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0, 0.05, 0), gunUpFolder, "position");
				};
				land = {
					angle = makeValue("Vector3Value", Vector3.new(-0.4, 0, 0), landFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0, -0.3, 0), landFolder, "position");
				};
				ease = {
					angle = makeValue("Vector3Value", Vector3.new(-0.2, 1.2, -0.1), easeFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.9, 0.15, -0.4), easeFolder, "position");
				};
				sprint = {
					angle = makeValue("Vector3Value", Vector3.new(-0.23, 0.1, 0.1), sprintFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.2, 0.18, -0.4), sprintFolder, "position");
				};
			};
		}
	};


	animations = {
		viewmodel = {
			equip = {makeAnimation(7223224157);};
			unequip = {makeAnimation(7223236974);};
			
			gunUp = {makeAnimation(7237397902);};
			
			fire = {makeAnimation(7223228693);};
			firePump = {makeAnimation(7223233322);};
			
			aimFire = {makeAnimation(7237390512);};
			aimFirePump = {makeAnimation(7237392390);};
			
			reloadUp = {makeAnimation(7223250841);};
			reloadDown = {makeAnimation(7223262141);};
			reloadBulletInsert = {makeAnimation(7223255027);};
		};

		player = {
			equip = {makeAnimation(7222993541)};
			unequip = {makeAnimation(7223152557)};

			atease = {makeAnimation(7223156080)};
			gunUp = {makeAnimation(7223145556)};

			fire = {makeAnimation(7223001977)};
			firePump = {makeAnimation(7223149148)};
			
			aim = {makeAnimation(7223183196)};
			aimFirePump = {makeAnimation(7223207714)};
			aimFire = {makeAnimation(7223202988)};

			reloadUp = {makeAnimation(7223161692)};
			reloadDown = {makeAnimation(7223175446)};
			reloadBulletInsert = {makeAnimation(7223165148)};
		};

	};

	--firing = {
	firingModes = {
		["semi"] = true;
	};
	defaultFiringMode = "semi";
	usesPump = true;

	damage = 50;
	headshot = 75;

	rpm = 60;
	speed = 1000;--1500
	range = 1000;

	bulletGravity = -100;

	magCapacity = 15;

	bullet = FPSAssets:WaitForChild("bullet");
	poolNumber = {
		player = 60;
		npc = 60;
	};
	--};

	-- pellets
	usesPellets = true;
	pelletsNumber = 4;

	minPelletSpread = 0;
	maxPelletSpread = math.pi/24;
	aimSpreadMult = 0.4;


	-- recoil
	recoilStart = Vector3.new(2, 0, 0);
	recoilFinish = Vector3.new(-2, 0, 0);
	recoilWaitTime = 0.15;


	-- animations time
	firingAnimationTime = 0.45;
	pumpTime = 0.55;

	reloadUpTime = 0.5;
	reloadDownTime = 0.5 + 0.54;
	reloadBulletTime = 0.4;

	aimTime = 0.5;
	equipTime = .7;
	unequipTime = .7;


	-- NPC values
	NPCMinInaccuracy = math.pi/25;
	NPCMaxInaccuracy = math.pi/20;


	animationEventsSounds = {
		reloadBulletInsert = {
			BulletInsert = Sounds.BulletInsert:GetChildren();
		};
		reloadDown = {
			Pump = Sounds.Pump:GetChildren();
		};
		firePump = {Pump = Sounds.Pump:GetChildren();};
		aimFirePump = {Pump = Sounds.Pump:GetChildren();};
	};

	sounds = {
		fire = Sounds.Fire:GetChildren();
		pump = Sounds.Pump:GetChildren();
	};

	weaponMovement = {
		modifier = 0.05;
		speed = 2.4;
		sway = Vector3.new(1.5,3,0);
		turnFriction = 850;
	};

	crosshair = {
		idleOffset = 20;
		fireOffset = 1;
		maxFiringOffset = 40;
		firstPersonAimingOffset = -20;
		thirdPersonAimingOffset = -10;
		firingCooldown = 0.3;
		fireOffsetTime = 0.2;
	};

	inaccuracyChangePerHipFireShot = 5; -- degrees
	inaccuracyChangePerADSShot = 0.5; -- degrees
	inaccuracyMax = 20;

	walkAnimSpeed = 1;
	sprintAnimSpeed = 1.8;
}

return data;