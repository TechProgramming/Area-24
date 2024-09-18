local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal	= require(Knit.Util.Remote.RemoteSignal);

local PlayerService = game:GetService("Players");

local PrivateServer = Knit.CreateService({ 
	Name = "PrivateServer", 
	Players = {},
	Client = {
		OnUpdate = RemoteSignal.new(),
	}
})

function PrivateServer:KnitStart()
	self.IsPrivateServer = game.PrivateServerId ~= nil
	self.OwnerId = game.PrivateServerOwnerId
	self.ServerId = game.PrivateServerId

	--[[PrivateServer.PlayerAdded:Connect(function(player)
		
	end)
	
	PrivateServer.CharacterAdded:Connect(function(player, character)

	end)
	
	PrivateServer.PlayerRemoving:Connect(function(player)
		
	end)]]
	
	
end;

return PrivateServer;