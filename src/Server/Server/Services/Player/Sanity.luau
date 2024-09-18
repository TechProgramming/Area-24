local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local KnitSignal = require(Knit.Util.Signal)
local Players = game:GetService("Players")
local Issues = {
	"Blackout",
	"Whiteout",
	"Redout"
}

local SanityService = Knit.CreateService({
	Name = "SanityService",
	Players = {},
	OnSanityChanged = KnitSignal.new(),
	OnIssueChanged = KnitSignal.new(),	
	Client = {
		OnSanityChanged = RemoteSignal.new(),
		OnIssueChanged = RemoteSignal.new(),
	},
})

function SanityService:ShowNotification(player, displayTime, text, color)
	--self.Client.UpdateSanity:Fire(player, sanityLevel, sanityType)
end


function SanityService:KnitStart()

	local ProfileService		= Knit.Services.ProfileService
	local LightsService			= Knit.Services.LightsService
	local IntercomService		= Knit.Services.IntercomService
	local NotificationService	= Knit.Services.NotificationService
	local EventService			= Knit.Services.EventService
	local TimeService			= Knit.Services.TimeService
	
	--function SanityService:AssignSanity(player)
	--	SanityService.Players[player] = {
	--		Issue = "Blackout"
	--	}
	--end
	
	function SanityService:Pulse(player, amount)
		local currentSanity = player:GetAttribute("Sanity")
		local currentIssue = player:GetAttribute("Issue")
		if not currentIssue or currentSanity then return end
		
		local newSanity = currentSanity + amount
		player:SetAttribute("Sanity", newSanity)
		
		if currentIssue == "None" and newSanity <= 400 then
			local haunt = math.random(1, 5) == 1
			if haunt then
				player:SetAttribute("Issue", "Haunt")
				--Knit.Services.NotificationService:ShowNotification(player, 5, "You need a Sanity Kit!", Color3.fromRGB(255, 55, 55))

				SanityService.OnIssueChanged:Fire(player, "Haunt")
				SanityService.Client.OnIssueChanged:Fire(player, "Haunt")
			end
		end
		
		SanityService.OnSanityChanged:Fire(player, amount)
		SanityService.Client.OnSanityChanged:Fire(player, amount)
		
	end

	ProfileService.PlayerAdded:Connect(function(player)
		player:SetAttribute("Sanity", 1000)
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		--SanityService.Players[player] = nil
	end)
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		player:SetAttribute("Sanity", 1000)
		player:SetAttribute("Issue", "None")
	end)
	
	TimeService.TimeChanged:Connect(function(minutesAfterMidnight)
		--for _, player in pairs(Players:GetPlayers()) do
		--	SanityService:Pulse(player, math.random(-10, 10))
		--	--SanityService:Pulse(player, -10)
		--end
	end)
	
end

return SanityService