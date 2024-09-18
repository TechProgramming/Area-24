local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local CollectionService = game:GetService("CollectionService");

local EventService = Knit.CreateService({
	Name = "EventService",
	Client = {
		OnEventBegan = RemoteSignal.new(),
		OnEventEnded = RemoteSignal.new(),
		OnRiotPrompt = RemoteSignal.new(),
	},
	Cooldown = {},
})

EventService.EventStartedAt = 0
EventService.EventEndedAt = 0

function EventService:KnitStart()
	
	local TransactionService	= Knit.GetService("TransactionService");
	local IntercomService		= Knit.GetService("IntercomService");
	local ProfileService		= Knit.GetService("ProfileService");
	local LightsService			= Knit.GetService("LightsService");
	
	local EventData = {
		["Emergency"] = {
			DisplayName = "Emergency",
			Start = function()
				IntercomService:Play("Lockdown")
				LightsService:SetFacilityEmergencyLights(true)
				IntercomService:StartAlarm()
			end,
			End = function()
				LightsService:SetFacilityEmergencyLights(false)
				IntercomService:StopAlarm()
			end,
		},
		["Riot"] = {
			DisplayName = "Riot",
			Start = function()
				self.Cooldown["Riot"] = tick() + 600;
				for _, player in pairs(game.Players:GetPlayers()) do
					if player.Team.Name == "Class - D" then
						if player.Character then
							CollectionService:AddTag(player.Character, "Riot Prompt");
						end;
					end;
				end;
			end,
		},
		["Generators Down"] = {
			DisplayName = "Generators Down",
			Start = function()
				LightsService:SetFacilityPower(true)
			end,
			End = function()
				LightsService:SetFacilityPower(false)
			end,
		},
	}
	
	function EventService:StartEvent(event)
		EventData[event]:Start()
		EventService.Client.OnEventBegan:FireAll(event)
	end
	
	function EventService:EndEvent(event)
		EventData[event]:End()
		EventService.Client.OnEventEnded:FireAll(event)
	end
	
	for _, event in pairs(script.Event:GetChildren()) do
		require(event):Init();
	end;
end

return EventService