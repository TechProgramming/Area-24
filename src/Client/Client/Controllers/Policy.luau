local Knit				= require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat		= require(Knit.Util.NumberFormat)
local CollectionService	= game:GetService("CollectionService")
local StarterGui		= game:GetService("StarterGui")
local PolicyAPI			= game:GetService("PolicyService")

local PLAYER	= game:GetService("Players").LocalPlayer

local SCHEDULE	= PLAYER.PlayerGui:WaitForChild("Schedule")

local PolicyService = Knit.CreateController({
	Name = "PolicyService",
	policyInfo = nil
})

function PolicyService:KnitStart()
	local player = game.Players.LocalPlayer

	local result, policyInfo = pcall(function()
		return PolicyAPI:GetPolicyInfoForPlayerAsync(player)
	end)

	if result then
		if policyInfo.AllowedExternalLinkReferences ~= nil then
			local allowed = false
			for _, v in pairs(policyInfo.AllowedExternalLinkReferences) do
				if v == "Discord" then
					allowed = true
				end
			end
			
			if not allowed then
				for _, v in pairs(CollectionService:GetTagged("Policy_AllowedExternalLinkReferences")) do
					v:Destroy()
				end
			end
		else
			for _, v in pairs(CollectionService:GetTagged("Policy_AllowedExternalLinkReferences")) do
				v:Destroy()
			end
		end
	elseif policyInfo.ArePaidRandomItemsRestricted then
		warn("Player cannot interact with paid random item generators")
	end
	
end

return PolicyService