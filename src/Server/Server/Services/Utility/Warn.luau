local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal);
local PlayerService	= game:GetService("Players");

local WarnService = Knit.CreateService({ 
	Name = "WarnService",
	Client = {
		OnWarn = RemoteSignal.new(),
	},
});

function WarnService:KnitStart()
	
end;

function WarnService:Warn(warner, target, description)
	WarnService.Client.OnWarn:Fire(target, description);
end;

return WarnService;