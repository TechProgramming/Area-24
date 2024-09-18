local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local NotificationService = Knit.CreateService({
	Name = "NotificationService",
	Client = {
		OnNotification = RemoteSignal.new()
	},
})

function NotificationService:ShowNotification(player, displayTime, text, color)
	self.Client.OnNotification:Fire(player, displayTime, text, color)
end

function NotificationService:ShowServerNotification(displayTime, text, color)
	self.Client.OnNotification:FireAll(displayTime, text, color)
end


return NotificationService