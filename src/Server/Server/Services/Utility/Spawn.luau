local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local SPAWNS = CollectionService:GetTagged("Spawn")

local SpawnService = Knit.CreateService({
	Name = "SpawnService",
	Client = {},
	Spawns = {},
})


function SpawnService:KnitStart()
	local JobService = Knit.Services.JobService
	
	--Setup Spawns
	for _, spawnPoint in pairs(SPAWNS) do
		if not self.Spawns[spawnPoint.Name] then
			self.Spawns[spawnPoint.Name] = {}
		end
		
		table.insert(self.Spawns[spawnPoint.Name], spawnPoint)
	end
	
	--Listen to player added
	local ProfileService = Knit.GetService("ProfileService")
	ProfileService.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			
			--Connect death
			char.Humanoid.Died:Connect(function()

				print("character died")
				
				--ensure the job stops if there is any
				JobService:StopJob(plr)
				
				--Wait duration
				task.wait(PlayerService.RespawnTime)
				
				--Check if player still in game
				if not PlayerService:FindFirstChild(plr.Name) then
					return
				end
				
				--Respawn character
				plr:LoadCharacter()
			end)
			
			--Spawn Character
			local team = plr.Team
			
			local spawnPoints = self.Spawns[team.Name]
			if not spawnPoints then
				warn(team.Name.." has no spawn point!")
				return
			end
			
			--choose random spawn point and random cframe position on that spawn point
			local chosenSpawnPoint = spawnPoints[math.random(1, #spawnPoints)]
			
			--stream area before tping
			plr:RequestStreamAroundAsync(chosenSpawnPoint.Position)
			
			--get spawn cframe from spawn point
			local randomSpawnPosition = chosenSpawnPoint.CFrame * CFrame.new(
				math.random(-chosenSpawnPoint.Size.X/2, chosenSpawnPoint.Size.X/2),
				3,
				math.random(-chosenSpawnPoint.Size.Z/2, chosenSpawnPoint.Size.Z/2)
				
			)
			
			--Wait for robloxs spawning and set position and orientation
			RunService.Stepped:Wait()
			
			local rootPart = char:WaitForChild("HumanoidRootPart")
			rootPart.CFrame = randomSpawnPosition	
			
		end)
		
		plr:LoadCharacter()
	end)	
end


return SpawnService