
local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local LightingService = game:GetService("Lighting")

local TIME_SHIFT = 1
local TIME_WAIT = 1 -- How many minutes it should take for a single hour.

local TimeService = Knit.CreateService({
	Name = "TimeService",
	TimeChanged = KnitSignal.new(),
	minutesAfterMidnight = nil,
})


--Start the day/night cycle
function TimeService:KnitStart()
	while true do wait(TIME_WAIT)
		--Increment time
		self.minutesAfterMidnight = LightingService:GetMinutesAfterMidnight() + TIME_SHIFT
		LightingService:SetMinutesAfterMidnight(self.minutesAfterMidnight)
		self.minutesAfterMidnight = self.minutesAfterMidnight/60
		
		--Fire events
		self.TimeChanged:Fire(self.minutesAfterMidnight);
		if script:GetAttribute("Paused") then
			self:GetAttributeChangedSignal("Paused"):Wait();
		end;
	end
end

function TimeService:Pause(doPause)
	script:SetAttribute("Paused", doPause);
end;

--Return the current time
function TimeService:GetTime()
	return self.CurrentTime
end


--Proxy our gettime function
function TimeService.Client:GetTime()
	return self:GetTime()
end

return TimeService