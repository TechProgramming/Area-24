local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local WorkspaceService = game:GetService("Workspace")
local TeamService = game:GetService("Teams")

local CD_TEAM = TeamService["Class - D"]
local CDC_REGIONS = WorkspaceService:WaitForChild("Scripted").CDCRegions

local CDCRegionService = Knit.CreateService({
	Name = "CDCRegionService",
	PlayersInCDC = {}
})


function CDCRegionService:KnitStart()
	while true do
		
		local whitelistedParts = {}
		for _, plr in pairs(PlayersService:GetChildren()) do
			local char = plr.Character
			if not char then
				continue
			end
			
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if not rootPart then
				continue
			end
			
			table.insert(whitelistedParts, rootPart)
		end
		
		local newPlayersInCDC = {}
		for _, regionPart in pairs(CDC_REGIONS:GetChildren()) do
			
			local region = Region3.new(regionPart.Position - (regionPart.Size/2), regionPart.Position + (regionPart.Size/2))
			local rootPartsInRegion = WorkspaceService:FindPartsInRegion3WithWhiteList(region, whitelistedParts) 
			
			for _, rootPart in pairs(rootPartsInRegion) do
				local char = rootPart.Parent
				local plr = PlayersService:GetPlayerFromCharacter(char)
				if plr then
					table.insert(newPlayersInCDC, plr)
				end
			end
		end
		
		self.PlayersInCDC = newPlayersInCDC
		self:CheckAllCDsForTermination()
		
		wait(2)
	end	
end


function CDCRegionService:IsPlayerInCDC(playerSearchingFor)
	for _, plr in pairs(self.PlayersInCDC) do
		if plr == playerSearchingFor then
			return true
		end
	end
	
	return false
end


function CDCRegionService:CheckAllCDsForTermination()
	local TerminationService = Knit.GetService("TerminationService")
	local AuthorizationService = Knit.GetService("AuthorizationService")
	
	local players = CD_TEAM:GetPlayers()
	for _, plr in pairs(players) do
		if not plr.Character then
			continue
		end
		
		if not self:IsPlayerInCDC(plr) and not TerminationService:Get(plr) and not AuthorizationService:IsAuthorized(plr) then
			--Set for termination
			TerminationService:Set(plr, true)
		end
	end
end


return CDCRegionService