-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)
local Signal = require(Knit.Util.Signal)
local RemoteProperty = require(Knit.Util.Remote.RemoteProperty)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local ROUND_INTERVAL = script:GetAttribute("RoundInterval") or 10
local ROUND_TIME_LIMIT = script:GetAttribute("RoundTimeLimit") or 10

-- SERVICE
local RoundService = Knit.CreateService({
	Name = "RoundService",
	Client = {
		CurrentRound = RemoteProperty.new(""),
		TimeUntilNextRound = RemoteProperty.new(ROUND_INTERVAL),
		TimeUntilRoundEnd = RemoteProperty.new(ROUND_TIME_LIMIT),	
	},
})


function RoundService:KnitStart() 
	--while true do
	--	task.wait(1)
		
	--	local currentTimeUntilNextRound = self.Client.TimeUntilNextRound:Get()
	--	--print(currentTimeUntilNextRound)
	--	if self.Client.TimeUntilNextRound:Get() <= 0 then
	--		self:StartRound()	
	--		currentTimeUntilNextRound = ROUND_INTERVAL+1
	--	end
		
	--	self.Client.TimeUntilNextRound:Set(currentTimeUntilNextRound-1)
	--end
end


function RoundService:StartRound()
	local round = require(self:_GetRandomRound())
	self.Client.CurrentRound:Set(round.Name)
	
	local endSignal = Signal.new()
	endSignal:Connect(function()
		self.Client.TimeUntilRoundEnd:Set(0)
	end)
	
	-- Start the round
	coroutine.wrap(function()
		round:Start(endSignal)
	end)()
	
	-- Setup timer
	self.Client.TimeUntilRoundEnd:Set(ROUND_TIME_LIMIT)
	while self.Client.TimeUntilRoundEnd:Get() > 0 do
		task.wait(1)
		--print(self.TimeUntilRoundEnd:Get())
		self.Client.TimeUntilRoundEnd:Set(self.Client.TimeUntilRoundEnd:Get()-1)
	end
	
	--When time limit ends
	endSignal:Fire()
	self.Client.CurrentRound:Set("")
end


function RoundService:_GetRandomRound()
	local rounds = script.Rounds:GetChildren()
	local selectedRound = rounds[math.random(1, #rounds)]
	return selectedRound
end


return RoundService