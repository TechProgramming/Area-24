local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local BundleService = Knit.CreateService({
	Name = "BundleService",
	Client = {
		OnPrompt = RemoteSignal.new()
	},
})


function BundleService:Prompt(plr, gamepassName)
	local GamepassService = Knit.GetService("GamepassService")
	local hasGamepass = GamepassService:HasGamepass(plr, gamepassName)
	self.Client.OnPrompt:Fire(plr, gamepassName, hasGamepass)
end


return BundleService