local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)

local MIN_ZOMBIES = script:GetAttribute("MinZombies") or 1
local MAX_ZOMBIES = script:GetAttribute("MaxZombies") or 10
local TELEPORTS = game.Workspace.Scripted.Teleports:GetChildren()

local Round = {
	Name = "Zombie Outbreak",
	Zombies = {},
	Run = true,
}

function Round:Start(endSignal)
	local ZombieService	= Knit.GetService("SCP-049-02");
	local zombieAmount = math.random(MIN_ZOMBIES, MAX_ZOMBIES)
	
	--end zombie spawning on event end
	self.Run = true
	endSignal:Connect(function()
		self.Run = false
	end)
	
	while self.Run do
		
		if #self.Zombies < zombieAmount then
			
			--spawn zombie and add to table
			local plrs = PlayersService:GetPlayers()
			local zombo = ZombieService:SpawnZombie(plrs[math.random(1, #plrs)], TELEPORTS[math.random(1, #TELEPORTS)].CFrame)
			table.insert(self.Zombies, zombo)
			zombo.Humanoid.Died:Connect(function()
				--remove zombie
				for index, zombie in ipairs(self.Zombies) do
					if zombie == zombo then
						table.remove(self.Zombies, index)
					end
				end
			end)
		end
				
		task.wait(.5)
	end
	
	self:Cleanup()
end


function Round:Cleanup()
	-- clear zombies
	local ZombieService	= Knit.GetService("SCP-049-02");
	ZombieService:ClearZombies()
	self.Zombies = {}
end


return Round