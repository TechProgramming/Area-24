local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local HelpMenuService = Knit.CreateService({
	Name = "HelpMenuService",
})

function HelpMenuService:KnitStart()
	local ProfileService = Knit.Services.ProfileService
	local TeamingService = Knit.Services.TeamingService
	
	function HelpMenuService:UpdateMenuDisplayedState(player, team)
		local profile = ProfileService:GetProfile(player)
		if profile.HelpMenuDisplayed[team.Name] == false then
			profile.HelpMenuDisplayed[team.Name] = true
		end
	end
	
	TeamingService.PlayersTeamChanged:Connect(function(player, team)
		HelpMenuService:UpdateMenuDisplayedState(player, team)
	end)

end


return HelpMenuService