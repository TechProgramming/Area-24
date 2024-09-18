local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")

local GamepassService = Knit.CreateService({
	Name = "GamepassService",
	Ready = false,
	BindsByProductId = {},
	Client = {
		OnUpdate = RemoteSignal.new(),
		OnRequestItems = RemoteSignal.new()
	}
})


function GamepassService.Client:GetGamepassByRobloxId(gamepassId)
	return GamepassService:GetGamepassByRobloxId(gamepassId)
end

function GamepassService.Client:GetGamepass(player, gamepassName)
	return GamepassService:GetGamepass(player, gamepassName)
end

function GamepassService.Client:GetGamepasses(player)
	return GamepassService:GetGamepasses(player)
end

function GamepassService.Client:HasGamepass(player, gamepassName)
	return GamepassService:HasGamepass(player, gamepassName)
end

function GamepassService.Client:Prompt(player, gamepassName)
	return GamepassService:Prompt(player, gamepassName)
end

function GamepassService:KnitStart()
	local ProfileService = Knit.Services.ProfileService
	local BundleService = Knit.Services.BundleService
	-----------------------------------------------------
	GamepassService.Gamepasses = {

		["Chaos Insurgency"] = {
			TargetId = 20017644,
			OriginalId = 7831180,
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Chaos Insurgency"] = true
				--print("PURCHASE WORKED!")
			end,
		},

		["Mobile Task Force"] = {
			TargetId = 20017658,
			OriginalId = 7831163,
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Mobile Task Force"] = true
			end,
		},

		["Radio"] = {
			TargetId = 20070433,
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Radio"] = true
			end,
		},

		["Night Vision"] = {
			TargetId = 20179515,
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Night Vision"] = true
			end,
		},

		["Site Director"] = {
			TargetId = 20180602,
			OriginalId = 7858899,
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Site Director"] = true
			end,
		},

		["VIP"] = {
			TargetId = 20310730,
			OriginalId = 7865045, -- L5 Keycard
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["VIP"] = true
			end,
		},
		["Global Occult Coalition"] = {
			TargetId = 20403135,
			OriginalId = 7853693, 
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["Global Occult Coalition"] = true
			end,
		},
		["O5 Council"] = {
			TargetId = 20403044,
			OriginalId = 7831171, -- L5 Keycard
			Process = function(gamepassData, player, profile)
				profile.Gamepasses["O5 Council"] = true
			end,
		},
	}


	function GamepassService:UpdateOwnership(player)
		local profile = ProfileService:GetProfile(player)
		for gamepassName, gamepassData in pairs(GamepassService.Gamepasses) do
			if MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.TargetId) then
				profile.Gamepasses[gamepassName] = true
			end
		end
	end

	function GamepassService:GetGamepassByRobloxId(gamepassId)
		return GamepassService.BindsByProductId[gamepassId]
	end

	function GamepassService:GetGamepass(player, gamepassName)
		return GamepassService.Gamepasses[gamepassName]
	end

	function GamepassService:GetGamepasses(player)
		return GamepassService.Gamepasses
	end

	function GamepassService:HasGamepass(player, gamepassName)
		local gamepassData = GamepassService.Gamepasses[gamepassName]

		local success, result = pcall(function()
			--print(gamepassData)
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.TargetId)
		end)

		if not success then
			warn(result)
			return false
		end

		if result == false and gamepassData.OriginalId ~= nil then
			success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.OriginalId)
			end)
			--print(success, result)
		end

		return result
	end

	function GamepassService:Prompt(player, gamepassName)
		local profile = ProfileService:GetProfile(player)
		if GamepassService.Gamepasses[gamepassName] and not profile.Gamepasses[gamepassName] then
			MarketplaceService:PromptGamePassPurchase(player, GamepassService.Gamepasses[gamepassName].TargetId)
			return true
		end
		return false
	end

	function GamepassService:UpdateGamepasses()
		for gamepassName, gamepassData in pairs(GamepassService.Gamepasses) do
			local productData = MarketplaceService:GetProductInfo(gamepassData.TargetId, Enum.InfoType.GamePass)
			for key, value in pairs(productData) do
				GamepassService.Gamepasses[gamepassName][key] = value
			end
		end
		GamepassService.Ready = true
		GamepassService.Client.OnUpdate:FireAll(GamepassService.Gamepasses)
	end

	GamepassService.Client.OnRequestItems:Connect(function(player)
		repeat wait() until GamepassService.Ready == true
		GamepassService.Client.OnUpdate:Fire(player, GamepassService.Gamepasses)
	end)

	function GamepassService:Process(player, gamepassName)
		local profile = ProfileService:GetProfile(player)
		GamepassService.Gamepasses[gamepassName]:Process(player, profile)
	end

	---------------------------------------------------------------
	GamepassService:UpdateGamepasses()

	-- Setup Binds
	for gamepassName, gamepassData in pairs(GamepassService.Gamepasses) do
		GamepassService.BindsByProductId[gamepassData.TargetId] = gamepassName
	end

	ProfileService.CharacterAdded:Connect(function(player, character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		humanoidRootPart.Touched:Connect(function(hit)
			if CollectionService:HasTag(hit, "Gamepass") then

				if GamepassService.Gamepasses[hit.Name] then
					BundleService:Prompt(player, hit.Name)
					--GamepassService:Prompt(player, hit.Name)
				end
			end
		end)
	end)

end


return GamepassService