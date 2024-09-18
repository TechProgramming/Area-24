local Knit = require(game:GetService("ReplicatedStorage").Knit)

local SOCCER_STUFF = game.Workspace:WaitForChild("Scripted").Soccer

local SoccerService = Knit.CreateService({
	Name = "SoccerService",
	Client = {},
})


function SoccerService:KnitStart()
	SOCCER_STUFF._Ball:SetNetworkOwner(nil)
	
	for _, item in pairs(SOCCER_STUFF:GetChildren()) do
		if item.Name == "GoalTrigger" then
			item.Touched:Connect(function(hit)
				if hit.Name ~= "_Ball" then
					return
				end
				
				--respawn ball and play epic sound
				hit.Velocity = Vector3.new(0,0,0)
				hit.RotVelocity = Vector3.new(0,0,0)
				hit.CFrame = SOCCER_STUFF.BallSpawner.CFrame
				SOCCER_STUFF.BallSpawner.Goal:Play()
			end)
		end
	end
end


return SoccerService