local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)


local FactionService = Knit.CreateService({
	Name = "FactionService",
	Client = {
		OnFactionChanged = RemoteSignal.new(),
	},
	OnFactionChanged = Signal.new(),

})


FactionService.Client.OnFactionChanged:Connect(function(player, factionName)
	local NametagService = Knit.Services.NametagService
	player:SetAttribute("Faction", factionName)
	player:SetAttribute("FactionTeam", player.Team.Name)
	NametagService:UpdateFaction(player, player.Team, factionName)
end)

--Set the ranks and get initial data
function FactionService:KnitStart()
	
end


return FactionService