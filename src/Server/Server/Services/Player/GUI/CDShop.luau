local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")

local CDShopService = Knit.CreateService({
	Name = "CDShopService",
	Client = {
		OnPromptTriggered = RemoteSignal.new();
	},
});

function CDShopService:KnitStart()
	for _, part in pairs(CollectionService:GetTagged("Shop")) do
		part.ProximityPrompt.Triggered:Connect(function(player)
			self.Client.OnPromptTriggered:Fire(player);
		end);
	end
end;

return CDShopService;