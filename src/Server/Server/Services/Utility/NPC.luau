local CollectionService = game:GetService("CollectionService");
local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local RunService		= game:GetService("RunService");
local PlayerService		= game:GetService("Players");

local Knit = require(ReplicatedStorage.Knit);

local NPCService = Knit.CreateService({
	Name = "NPCService",
	Client = {},
	Spawns = {},
});

local SPAWNS	= CollectionService:GetTagged("Spawn");
local TEMPLATES	= game.Workspace.Scripted.NPCTemplates;

function NPCService:KnitStart()
	--Listen to player added
	local CharacterEditorService	= Knit.GetService("CharacterEditorService");
	local ProfileService			= Knit.GetService("ProfileService");
	
	function NPCService:Create(name, templateCharacter, avatarSetData, spawnLocation, storageLocation)
		
		local character = templateCharacter:Clone();
		if avatarSetData then
			CharacterEditorService:LoadNPCSet(character, avatarSetData);
		end;
		character.Name = name
		character.Parent = storageLocation or workspace
		character.HumanoidRootPart.CFrame = spawnLocation + Vector3.new(0, character.Humanoid.HipHeight, 0);
		return character;
	end;
end;

--[[function NPCService:SpawnPlagueDoctorZombie(player, spawnLocation, storageLocation)
		
		local avatarSetData = CharacterEditorService:GetAvatarData(player).AvatarSetData;
		
		local character = NPCService:Create(player.Name.."_049-2", TEMPLATES["Zombie"], avatarSetData, spawnLocation, storageLocation);
		CollectionService:AddTag(character, "049_2");
	end;
	
	for _, ai in pairs(script.Entities:GetChildren()) do
		require(ai):Begin();
	end;
	
	]]

return NPCService;