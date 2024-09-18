--[[
	Copied from Service to a Controller for instantenious replies instead of sending a request each function call
]]

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local TeamsService = game:GetService("Teams")
local MarketPlaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

local TeamRulesService = Knit.GetService("TeamRulesService")

local TerminationController

local KillRules = TeamRulesService.KillRulesProperty

local TeamRulesController = Knit.CreateController({ 
	Name = "TeamRulesController",
})

function TeamRulesController:CanKillPlayer(player, target)
	local playerTeam = player.Team.Name
	local targetTeam = target.Team.Name

	if CollectionService:HasTag(target, "Protected") then
		return false
	elseif CollectionService:HasTag(target, "Unprotected") then
		return true
	end
	
	local canKillTeam = KillRules:Get()[playerTeam][targetTeam] or false

	if canKillTeam and targetTeam == "Class - D" then
		return TerminationController:Get(target)
	end

	return canKillTeam
end

function TeamRulesController:CanKillEntity(player, target)

	if CollectionService:HasTag(target, "Protected") then
		return false
	elseif CollectionService:HasTag(target, "Unprotected") then
		return true
	end

	return true
end

function TeamRulesController:KnitStart()
	TerminationController = Knit.Controllers["TerminationController"]

end


return TeamRulesController
