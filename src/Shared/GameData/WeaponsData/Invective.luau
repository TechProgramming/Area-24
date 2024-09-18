local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local FPSAssets = Assets:WaitForChild("FPS")
local Sounds = SoundService:WaitForChild("Weapons"):WaitForChild(script.Name)

local loadQueue = {}

local function makeAnimation(id)
	local i = Instance.new("Animation")
	i.AnimationId = typeof(id) == "string" and id or ("rbxassetid://" .. id)
	table.insert(loadQueue,i)
	return i
end
local function makeSound(id)
	local i = Instance.new("Sound")
	i.SoundId = typeof(id) == "string" and id or ("rbxassetid://" .. id)
	if not RunService:IsServer() then
		table.insert(loadQueue,i)
	end
	return i
end
local function makeValue(className, defaultValue, parent, name)
    local value = Instance.new(className)
    value.Name = name
    value.Value = defaultValue
    if parent then
        value.Parent = parent
    end
    return value
end

local aimFolder = Instance.new("Folder", script); aimFolder.Name = "aim";
local idleFolder = Instance.new("Folder", script); idleFolder.Name = "idle";
local landFolder = Instance.new("Folder", script); landFolder.Name = "land";
local sprintFolder = Instance.new("Folder", script); sprintFolder.Name = "sprint";

local data = {
	name = "Invective";
	displayName = "Invective";

    offsets = {
    	viewmodel = {
    		Camera = {
    			C0 = CFrame.new(0,0,0);
    			C1 = CFrame.new(0,0,0);
    		};
    		MainPart = {
    			C0 = CFrame.new(0.610635519, 0.000468254089, -4.71916008, 1, -9.07904791e-07, 5.72767476e-07, 9.07902859e-07, 1, 1.65019969e-07, -5.72753095e-07, -1.65019443e-07, 1);
    			C1 = CFrame.new(0,0,0);
    		};
    		LeftArm = {
    			C0 = CFrame.new(-1.28243876, -0.24230051, -4.45455074, 2.24438423e-07, 3.8928718e-07, 1, -7.90195198e-09, 1, -3.89288999e-07, -1, -7.90186494e-09, 2.244537e-07);
    			C1 = CFrame.new(2.99999952, 1.49011612e-08, -5.96046448e-07, 1, 0, -1.52766688e-11, 0, 1, -1.82076294e-12, -1.52766688e-11, -1.82076294e-12, 1);
    		};
    		RightArm = {
    			C0 = CFrame.new(1.28769016, -0.242301464, -4.45455074, 2.24438423e-07, 3.8928718e-07, 1, -7.90195198e-09, 1, -3.89288999e-07, -1, -7.90186494e-09, 2.244537e-07);
    			C1 = CFrame.new(3.00000048, 1.49011612e-08, -5.96046448e-07, 1, 0, -1.52766688e-11, 0, 1, -1.82076294e-12, -1.52766688e-11, -1.82076294e-12, 1);
    		};
    	};
        weaponFrame = {
        	MainPart = {
        		C0 = CFrame.new(0.0829762816, -0.181865737, 0.557155132, -5.72738543e-07, 9.0790104e-07, -1, -1.65019443e-07, 1, 9.0790661e-07, 1, 1.65019969e-07, -5.72782028e-07);
        		C1 = CFrame.new(0,0,0);
        	};
            backweld = {
                C0 = CFrame.new(0.909626007, 0.539464951, 0.779060364, 0.766043663, 0.64278698, -0.0014072333, 0.642787576, -0.766044438, 1.51894261e-11, -0.00107800332, -0.000904552289, -0.999998927);
                C1 = CFrame.new(0,0,0);
            };
            weaponHold = {
                C0 = CFrame.new(0,0,0);---0.682041168, -0.395236969, -1.91061211, 1, 0, 4.37113883e-08, 0, 1, 0, -4.37113883e-08, 0, 1
                C1 = CFrame.new(-0.0120000839, 0.900608301, -0.382000148, -0.999998987, 0, 0.00140723342, 0, 1, 0, -0.00140723342, 0, -0.999998987);
            };
		};

		animations = {
			viewmodel = {
				aim = {
					angle = makeValue("Vector3Value", Vector3.new(-0.06, 0, 0), aimFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(-0.65, 0.16, 0.2), aimFolder, "position");
				};
				idle = {
					angle = makeValue("Vector3Value", Vector3.new(0, 0, 0), idleFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.6, 0, -0.6), idleFolder, "position");
				};
				land = {
					angle = makeValue("Vector3Value", Vector3.new(-0.4, 0, 0), landFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0, -0.3, 0), landFolder, "position");
				};
				sprint = {
					angle = makeValue("Vector3Value", Vector3.new(-0.6, 0.4, 0.5), sprintFolder, "angle");
					position = makeValue("Vector3Value", Vector3.new(0.6, 0.35, -0.6), sprintFolder, "position");
				};
			};
		}
    };

	animations = {
		viewmodel = {--
			sprint = {makeAnimation(6261357601)};
			--aim = {makeAnimation(6261357601)};
			idle = {makeAnimation(6283379956)};
			--reload = {
			--	[1] = {
			--		[1] = makeAnimation(6283417470);--shotgun up
			--		[2] = makeAnimation(6283390275);--bullet
			--		[3] = makeAnimation(6283401815);--shotgun down
			--	};
			--};
			reloadUp = {
				[1] = makeAnimation(6283417470);--shotgun up
			};
			reloadDown = {
				[1] = makeAnimation(6283401815);--shotgun down
			};
			reloadBulletInsert = {
				[1] = makeAnimation(6283390275);--bullet insert
			};

			fire = {
				--[1] = {
					[1] = makeAnimation(6283145565);--fire
				--	[2] = makeAnimation(6283329440);--pump
				--};
				--[2] = makeAnimation(6275998042);
			};
			firePump = {
				[1] = makeAnimation(6283329440);--pump
			};
			equip = {
				makeAnimation(6283356876);
			};
			unequip = {
				makeAnimation(6283466719);
			};
			aimFire = {
				--[1] = {
					[1] = makeAnimation(6283488250);--fire
				--	[2] = makeAnimation(6283518364);--pump
				--};
			};
			aimFirePump = {
				[1] = makeAnimation(6283518364);--pump
			};
			--pump = {
			--	[1] = makeAnimation(6283329440);
			--};
			--bulletInsert = {
			--	[1] = makeAnimation(6283390275);
			--};
			--aimFire = {
			--	[1] = makeAnimation(6275987881);
			--};
			--reload = makeAnimation(6275984519);
		};

		player = {
			equip = {makeAnimation(6319479765)};
			unequip = {makeAnimation(6338156147)};

			idle = {makeAnimation(6319489509)};
			aim = {makeAnimation(6338144237)};
			sprint = {makeAnimation(6338152526)};

			fire = {makeAnimation(6338163067)};
			firePump = {makeAnimation(6319503446)};
			aimFirePump = {makeAnimation(6319503446)};

			reloadUp = {makeAnimation(6319516876)};
			reloadDown = {makeAnimation(6319530954)};
			reloadBulletInsert = {makeAnimation(6319525594)};

			--aim = makeAnimation(6148018994);
			--aimFire = makeAnimation(6000260451);
			--idleFire = makeAnimation(6000263346);
			--sprint = makeAnimation(6154515326);
			--reload = makeAnimation(6171841099);
		};

	};

	--firing = {
		firingModes = {
			["semi"] = true;
			--["manual"] = true; -- manual is just one bullet chamber lol
		};
		defaultFiringMode = "semi";
		usesPump = true;

		damage = 50;
		headshot = 75;

		rpm = 60;
		velocity = 1000;--1500
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
	maxPelletSpread = math.pi/15;

	aimSpreadMult = 0.3;


	-- recoil
	recoilStart = Vector3.new(2, 0, 0);
	recoilFinish = Vector3.new(-2, 0, 0);
	recoilWaitTime = 0.15;


	-- animations time
	firingAnimationTime = 0.45;
	pumpTime = 0.55;

	reloadUpTime = 0.5;
	reloadDownTime = 0.5;
	reloadBulletTime = 0.4;
	
	aimTime = 0.5;
	equipTime = .7;
	unequipTime = .7;


	-- NPC values
	NPCMinInaccuracy = math.pi/25;
	NPCMaxInaccuracy = math.pi/20;


	sounds = {
		fire = {makeSound(4670138534)};
	};

	weaponMovement = {
		modifier = 0.05;
		speed = 1.7;
		sway = Vector3.new(5,5,0);
		turnFriction = 800;
	};

	crosshair = {
		idleDistance = 30;
		fireDistance = 30;
	}
};

data.minShootingTime = (60/data.rpm)-- + (data.usesPump and data.pumpTime or 0)

ContentProvider:PreloadAsync(loadQueue)

return data;