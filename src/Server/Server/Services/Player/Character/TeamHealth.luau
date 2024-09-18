local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")

local TeamHealthService = Knit.CreateService({
	Name = "TeamHealthService",
})

local TeamHealth = {
	["Chaos Insurgency"] = 120,
	["Security Department"] = 100,
	["Mobile Task Force"] = 120,
	["Engineering and Technical"] = 100,
	["Scientific Department"] = 100,
	["Class - D"] = 100	,
	["Site Director"] = 140,
	["Global Occult Coalition"] = 140,
	["O5 Council"] = 180,	
}



--levelService:AddLevel(player, "Class - D", 1)
function TeamHealthService:KnitStart()
	local ProfileService		= Knit.GetService("ProfileService");
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		local team = player.Team
		local teamHealth = TeamHealth[team.Name]
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.MaxHealth = teamHealth
		humanoid.Health = teamHealth
	end)
end


function TeamHealthService:GetPlayerRankInTeam(player, teamName)
	
end


return TeamHealthService