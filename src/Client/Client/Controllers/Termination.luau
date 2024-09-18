local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Thread = require(Knit.Util.Thread)
local PlayerService = game:GetService("Players")

local TerminationService = Knit.GetService("TerminationService")
local Players = {}

local TerminationController = Knit.CreateController({ 
	Name = "TerminationController", 
})


function TerminationController:KnitStart()
	function TerminationController:Get(player)
		return Players[player.Name]
	end
	
	function TerminationController:GetByUserId(_, userId)
		local target = PlayerService:GetPlayerByUserId(userId)
		return TerminationController:Get(target)
	end
	
	TerminationService.OnUpdate:Connect(function(player, status)
		Players[player.Name] = status
	end)
	
	Thread.Spawn(function()
		for _, player in pairs(PlayerService:GetPlayers()) do
			Players[player.Name] = TerminationService:Get(player)
		end
	end)
end


return TerminationController
