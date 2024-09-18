local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PhysicsService = game:GetService("PhysicsService")
--PhysicsService:CreateCollisionGroup("Player")


local CollisionService = Knit.CreateService({
	Name = "CollisionService",
	Titles = {},
})

local function Collisions(Part)
	if Part:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(Part, "Player")
	end
end



--levelService:AddLevel(player, "Class - D", 1)
function CollisionService:KnitStart()
	local ProfileService        = Knit.GetService("ProfileService");

	ProfileService.CharacterAdded:Connect(function(player, character)
		for i, v in pairs(character:GetChildren()) do
			Collisions(v)
		end

	end)
end


function CollisionService:GetPlayerRankInTeam(player, teamName)

end

return CollisionService