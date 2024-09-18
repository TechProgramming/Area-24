local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)

local TeamsService = game:GetService("Teams")
local MarketPlaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

local TerminationService

local KillRules = {}

local TeamRulesService = Knit.CreateService({ 
	Name = "TeamRulesService", 
	Client = {
		KillRulesProperty = RemoteProperty.new(KillRules),
	},
	PlayersTeamChanged = KnitSignal.new(),
})

TeamRulesService.KillRules = KillRules

for _, team in pairs(game.Teams:GetTeams()) do
	local canKill = team.CanKill
	TeamRulesService.KillRules[team.Name] = {}
	for _, teamKillable in pairs(canKill:GetChildren()) do
		TeamRulesService.KillRules[team.Name][teamKillable.Name] = true
	end
end

function TeamRulesService:CanKillPlayer(player, target)
	local playerTeam = player.Team.Name
	local targetTeam = target.Team.Name

	if CollectionService:HasTag(target, "Protected") then
		return false
	elseif CollectionService:HasTag(target, "Unprotected") then
		return true
	end
	
	

	local canKillTeam = TeamRulesService.KillRules[playerTeam][targetTeam] or false

	--if canKillTeam and targetTeam == "Class - D" then
	--	return TerminationService:Get(target)
	--end

	return TerminationService:Get(target) or canKillTeam
end

function TeamRulesService:CanKillEntity(player, target)
	print("CHECKING")
	
	if CollectionService:HasTag(target, "Protected") then
		return false
	elseif CollectionService:HasTag(target, "Unprotected") then
		return true
	end

	return true
end

function TeamRulesService.Client:CanKillPlayer(requester, ...)
	return TeamRulesService:CanKillPlayer(...)
end
function TeamRulesService.Client:CanKillEntity(requester, ...)
	return TeamRulesService:CanKillEntity(...)
end

function TeamRulesService:KnitStart()
	TerminationService = Knit.Services.TerminationService
	
	self.Client.KillRulesProperty:Replicate()
end


return TeamRulesService
