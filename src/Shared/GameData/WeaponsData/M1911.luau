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
	displayName = "M1911";
	weaponType = "pistol";
	walkAndSprintAnimType = "pistol";

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
                C0 = CFrame.new(0,0,0);
                C1 = CFrame.new(0,0,0);
            };
		};

		animations = {

			viewmodel = {
				aim = {
					angle = makeValue("Vector3Value", Vector3.new(0, -0.03, 0), aimFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(-0.92, 0.22, 0.5), aimFolder, "position");
				};
				gunUp = {
					angle = makeValue("Vector3Value", Vector3.new(0, 0, 0), gunUpFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(-0.1, -0.3, 0.5), gunUpFolder, "position");
				};
				land = {
					angle = makeValue("Vector3Value", Vector3.new(-0.4, 0, 0), landFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0, -0.3, 0), landFolder, "position");
				};
				sprint = {
					angle = makeValue("Vector3Value", Vector3.new(-0.23, 0.2, 0), sprintFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.1, 0, 0.5), sprintFolder, "position");
				};
				ease = {
					angle = makeValue("Vector3Value", Vector3.new(-0.2, 0.7, 0.1), easeFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.5, 0, 0.5), easeFolder, "position");
				};
			};
		}
    };

	animations = {
		viewmodel = {
			gunUp = {
				makeAnimation(6869725035);
			};
			fire = {
				makeAnimation(6869736382);
			};
			aimFire = {
				makeAnimation(6869715410);
			};
			reload = {
				makeAnimation(6869728869);
			};
			equip = {
				makeAnimation(6869718764);
			};
			unequip = {
				makeAnimation(6869739649);
			};
		};

		player = {
			gunUp = {makeAnimation(6869456330)};
			aim = {makeAnimation(6869445013)};
			fire = {makeAnimation(6869452938)};
			aimFire = {makeAnimation(6921175679)};
			--sprint = {makeAnimation(6455511974)};
			reload = {makeAnimation(6869562264)};
			equip = {makeAnimation(6869461111, "equip")};
			unequip = {makeAnimation(6869675301)};
			atease = {makeAnimation(6893889345)};
		};

	};

	--firing = {
		firingModes = {
			["semi"] = true;
		};
		defaultFiringMode = "semi";
		usesPump = false;

		damage = 37;
		headshot = 60;

		rpm = 350;
		speed = 900;
		range = 4000;

		bulletGravity = -100;

		magCapacity = 15;

		bullet = FPSAssets:WaitForChild("bullet");
		poolNumber = {
			player = 20;
			npc = 20;
		};
	--};

	usesPellets = false;

	recoilStart = Vector3.new(1.8, 0.4, 0);
	recoilFinish = Vector3.new(-1.8, -0.4, 0);
	recoilWaitTime = 0.16;

	firingAnimationTime = 0.16;
	reloadTime = 3.4;
	aimTime = 0.25;
	equipTime = 0.5;
	unequipTime = 0.5;
	
	-- NPC values
	NPCMinInaccuracy = math.pi/10;
	NPCMaxInaccuracy = math.pi/5;
	
	animationEventsSounds = {
		reload = {
			MagRemove = Sounds.MagRemove:GetChildren();
			--MagDrop = Sounds.MagDrop:GetChildren();
			MagInsert = Sounds.MagInsert:GetChildren();
			--BoltOpen = Sounds.BoltOpen:GetChildren();
			--BoltClose = Sounds.BoltClose:GetChildren();
		};
	};

	sounds = {
		fire = Sounds.Fire:GetChildren();
	};

	weaponMovement = {
		modifier = 0.05;
		speed = 1.6;
		sway = Vector3.new(4,4,0);
		turnFriction = 600;
	};

	crosshair = {
		idleOffset = 10;
		fireOffset = 1.5;
		maxFiringOffset = 25;
		firstPersonAimingOffset = -20;
		thirdPersonAimingOffset = -10;
		firingCooldown = 0.4;
		fireOffsetTime = 0.1;
	};

	walkAnimSpeed = 1.4;
	sprintAnimSpeed = 1.8;
}

data.minShootingTime = (60/data.rpm)

return data;