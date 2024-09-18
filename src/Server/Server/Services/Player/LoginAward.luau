local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local LoginAwardService = Knit.CreateService({
	Name = "LoginAwardService",
	Client = {
		OnGamepassPurchased = RemoteSignal.new(),
	}
})

function LoginAwardService.Client:DisplayLoginAward(player)
	return LoginAwardService:DisplayLoginAward(player)
end

function LoginAwardService.Client:RedeemAward(player)
	return LoginAwardService:RedeemAward(player)
end

function LoginAwardService:KnitStart()
	local ProfileService = Knit.Services.ProfileService
	local ItemService = Knit.Services.ItemService
	local TransactionService = Knit.Services.TransactionService
	local GamepassService = Knit.Services.GamepassService
	
	local AwardTable = {
		[1] = {
			ItemName = "25 Cash Award",
			DisplayName = "25 Cash",
			ItemType = "GameItem"
		},
		[2] = {
			ItemName = "25 Cash Award",
			DisplayName = "20 Cash",
			ItemType = "GameItem"
		},
		[3] = {
			ItemName = "50 Cash Award",
			DisplayName = "50 Cash",
			ItemType = "GameItem"
		},
		[4] = {
			ItemName = "50 Cash Award",
			DisplayName = "50 Cash",
			ItemType = "GameItem"
		},
		[5] = {
			ItemName = "75 Cash Award",
			DisplayName = "75 Cash",
			ItemType = "GameItem"
		},
		[6] = {
			ItemName = "75 Cash Award",
			DisplayName = "75 Cash",
			ItemType = "GameItem"
		},
		[7] = {
			ItemName = "120 Cash Award",
			DisplayName = "120 Cash",
			ItemType = "GameItem"
		},		
	}
	
	function LoginAwardService:RedeemAward(player)
		local profile = ProfileService:GetProfile(player)
		local awardData = false
		-- VERIFY
		local timeRemaining = profile.LoginAward.NextAwardTime - tick()
		print("TICKTOK", timeRemaining <= 0)
		if timeRemaining <= 0 then
			awardData = AwardTable[profile.LoginAward.CurrentDay]
			print("AWARD!", awardData)
			if awardData.ItemType == "GameItem" then
				TransactionService:Award(player, awardData.ItemName)
				local hasGamepass = GamepassService:HasGamepass(player, "VIP")
				local rank = player:GetRankInGroup(4889827)
				local highRank = rank > 9
				if hasGamepass or highRank then
					TransactionService:Award(player, "50 Cash Award")
				end
			end
		else
			return false
		end
		
		-- INCREMENT
		profile.LoginAward.NextAwardTime = tick() + 86400
		profile.LoginAward.DaysCollected = profile.LoginAward.DaysCollected + 1
		profile.LoginAward.CurrentDay = profile.LoginAward.CurrentDay + 1
		if profile.LoginAward.DaysCollected == 7 then
			profile.LoginAward.DaysCollected = 0
			profile.LoginAward.CurrentDay = 1		
		end
		
		return awardData
	end
	
	
	function LoginAwardService:DisplayLoginAward(player)
		local profile = ProfileService:GetProfile(player)
		local profileLoginAward = profile.LoginAward
		local timeRemaining = profile.LoginAward.NextAwardTime - tick()
		
		local awardData = { 
			DaysCollected = profileLoginAward.DaysCollected, 
			CurrentDay = profile.LoginAward.CurrentDay, 
			NextAwardTime = profile.LoginAward.NextAwardTime, 
			AwardAvailable = timeRemaining <= 0,
			AwardTable = AwardTable
		}

		
		return awardData
	end


end


return LoginAwardService