local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local CashService = Knit.CreateService({ 
	Name = "CashService", 
	Client = {
		OnCashAdded = RemoteSignal.new(),
		OnCashRemoved = RemoteSignal.new()
	}
})

function CashService.Client:Get(player)
	return CashService:Get(player)
end

function CashService:KnitStart()

	local ProfileService = Knit.Services.ProfileService

	function CashService:Get(player)
		local profile = ProfileService:GetProfile(player)
		return profile.Cash
	end

	function CashService:Add(player, amount)
		
		local profile = ProfileService:GetProfile(player)
		profile.Cash = profile.Cash + amount
		CashService.Client.OnCashAdded:Fire(player, profile.Cash, amount)
		ProfileService:UploadProfile(player)
	end
	
	function CashService:Remove(player, amount)
		
		local profile = ProfileService:GetProfile(player)
		profile.Cash = profile.Cash - amount
		CashService.Client.OnCashRemoved:Fire(player, profile.Cash, amount)
		ProfileService:UploadProfile(player)
	end
	
	function CashService:Set(player, amount)
		
		local profile = ProfileService:GetProfile(player);
		if profile.Cash < amount then
			
			CashService.Client.OnCashAdded:Fire(player, profile.Cash, amount - profile.Cash);
			profile.Cash = amount;
			ProfileService:UploadProfile(player);
		elseif profile.Cash > amount then
			
			CashService.Client.OnCashRemoved:Fire(player, profile.Cash, profile.Cash - amount);
			profile.Cash = amount;
			ProfileService:UploadProfile(player);
		end;
	end;
end


return CashService
