local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local PLAYER = game:GetService("Players").LocalPlayer
local AWARD_UI = PLAYER.PlayerGui:WaitForChild("LoginAward")
local MAINMENU_UI = PLAYER.PlayerGui:WaitForChild("MainMenu")
local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")
local InitialVisibilityChanged = false

local LoginAwardController = Knit.CreateController({
	Name = "LoginAwardController",
	VisibilityChanged = KnitSignal.new(),
	InitialStateChanged = KnitSignal.new(),
	HasClosedInitialLogin = false,
})

local AwardDisplays = {
	[1] = AWARD_UI.Container.DayAwards["Day 1"],
	[2] = AWARD_UI.Container.DayAwards["Day 2"],
	[3] = AWARD_UI.Container.DayAwards["Day 3"],
	[4] = AWARD_UI.Container.DayAwards["Day 4"],
	[5] = AWARD_UI.Container.DayAwards["Day 5"],
	[6] = AWARD_UI.Container.DayAwards["Day 6"],
	[7] = AWARD_UI.Container["Day 7"]
}


function LoginAwardController:KnitStart()
	local LoginAwardService = Knit.GetService("LoginAwardService")
	--local ItemService = Knit.GetService("ItemService")
	local ProfileService = Knit.GetService("ProfileService")
	--local profile = ProfileService:GetProfile()
	local redeemMode = false
	local awardEventData = false
	-- { DaysCollected = 2, CurrentDay = 3, NextAwardTime = tick(), AwardAvailable = false }
	
	function LoginAwardController:UpdateDisplay()
		awardEventData = LoginAwardService:DisplayLoginAward()
		local AwardTable = awardEventData.AwardTable
		if awardEventData.AwardAvailable then
			AWARD_UI.Container.Close.CloseButton.DisplayText.Text = "REDEEM"
			AWARD_UI.Container.NextAwardIn.Visible = false
			redeemMode = true
		end
		for day, display in pairs(AwardDisplays) do
			if day <= awardEventData.DaysCollected then
				display.Obtained.Visible = true
			end
			display.ItemName.Text = AwardTable[day].DisplayName
		end
	end
	-------------------------
	
	function LoginAwardController:Show()
		AWARD_UI.Enabled = true
		self.VisibilityChanged:Fire(true)
	end
	
	function LoginAwardController:Hide()
		AWARD_UI.Enabled = false
		self.VisibilityChanged:Fire(false)
		if InitialVisibilityChanged == false then
			self.InitialStateChanged:Fire(false)
			InitialVisibilityChanged = true
		end
	end
	
	AWARD_UI.Container.Close.CloseButton.MouseButton1Down:Connect(function()
		if redeemMode then
			redeemMode = false
			AWARD_UI.Container.Close.CloseButton.DisplayText.Text = "CLOSE"
			local awardData = LoginAwardService:RedeemAward()
			if not awardData then
				
			else
				AWARD_UI.Container.NextAwardIn.Visible = true
			end
			LoginAwardController:UpdateDisplay()
		else
			LoginAwardController:Hide()
		end	
	end)
	
	LoginAwardController:UpdateDisplay()

	spawn(function()
		while true do wait(1)
			if AWARD_UI.Enabled then
				local timeRemaining = awardEventData.NextAwardTime - tick()
				local hours = math.floor(math.fmod(timeRemaining, 86400)/3600)
				local minutes = math.floor(math.fmod(timeRemaining,3600)/60)
				local seconds = math.floor(math.fmod(timeRemaining,60))
				AWARD_UI.Container.NextAwardIn.Text = string.format("%02d:%02d:%02d",hours,minutes,seconds)
			end
		end
	end)
	
	coroutine.wrap(function()
		repeat wait(1) until MAINMENU_UI.Enabled == false
		LoginAwardController:Show()
	end)()
end


return LoginAwardController