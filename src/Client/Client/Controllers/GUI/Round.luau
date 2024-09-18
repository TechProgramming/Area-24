local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RoundService = Knit.GetService("RoundService")

local PLAYER = game:GetService("Players").LocalPlayer
local ROUND_UI = PLAYER.PlayerGui:WaitForChild("RoundUI")

local RoundUIController = Knit.CreateController({
	Name = "RoundUIController",
})


local function decimalsToMinutes(dec)
	local ms = tonumber(dec)
	local finalSeconds = ms % 60
	if finalSeconds < 10 then
		finalSeconds = "0"..finalSeconds
	end
	
	return math.floor(ms / 60)..":"..finalSeconds
end


function RoundUIController:KnitStart()
	local currentRound = RoundService.CurrentRound:Get()
	local currentTimeUntilNextRound = RoundService.TimeUntilNextRound:Get()
	local timeUntilRoundEnd = RoundService.TimeUntilRoundEnd:Get()
	
	if currentRound ~= "" then
		--Round is ongoing
		local msg = currentRound.." ends in "..decimalsToMinutes(timeUntilRoundEnd)
		ROUND_UI.Status.Text = msg
	else
		--Round isn't going, tell time until next round
		local msg = "Next event in "..decimalsToMinutes(currentTimeUntilNextRound)
		ROUND_UI.Status.Text = msg
	end
	
	RoundService.TimeUntilNextRound.Changed:Connect(function(newTime)
		local msg = "Next event in "..decimalsToMinutes(newTime)
		ROUND_UI.Status.Text = msg
	end)
	
	RoundService.TimeUntilRoundEnd.Changed:Connect(function(newValue)
		local currentRound = RoundService.CurrentRound:Get()
		local msg = currentRound.." ends in "..decimalsToMinutes(newValue)
		ROUND_UI.Status.Text = msg
	end)
end


return RoundUIController