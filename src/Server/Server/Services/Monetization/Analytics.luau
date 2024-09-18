local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local Queue = require(Knit.Util.Queue)
local Webhook = ""

local AnalyticsService = Knit.CreateService({ 
	Name = "AnalyticsService", 
	Players = {},
	SessionTime = {},
	Client = {
		Log = RemoteSignal.new(),
	}
})


function disp_time(time)
	local days = math.floor(time/86400)
	local hours =  math.floor((math.fmod(time, 86400)/3600))
	local minutes =  math.floor((math.fmod(time,3600)/60))
	local seconds =  math.floor((math.fmod(time,60)))
	return {Hours = hours, Minutes = minutes, Seconds = seconds}
end

function AnalyticsService:GetPlayTimes(player)
	return {
		["All"] = math.floor(tick() - AnalyticsService.Players[player].SessionTime)
	}
end

function AnalyticsService:KnitStart()

	local NotificationService	= Knit.GetService("NotificationService");
	local TransactionService	= Knit.GetService("TransactionService");
	local NametagService		= Knit.GetService("NametagService");
	local ProfileService		= Knit.GetService("ProfileService");
	local TeamingService		= Knit.GetService("TeamingService");
	local ToolService			= Knit.GetService("ToolService");
	
	self.Client.Log:Connect(function(player, event, data)
		AnalyticsService:Log(event, player, data)
	end)
	
	TeamingService.PlayersTeamChanged:Connect(function(player, new, old)
		
		local profile = ProfileService:GetProfile(player);
		local timeTeamed = tick() - self.Players[player].TeamTime;
		profile.PlayTime[old.Name] += math.floor(timeTeamed);
		self.Players[player].TeamTime = tick();
		self.Players[player].Team = new.Name;
	end);
	
	ProfileService.CharacterAdded:Connect(function(player)
		local team = player.Team
		--AnalyticsService.SessionTime[player] = nil
	end)
	
	ProfileService.PlayerAdded:Connect(function(player)
		
		self.Players[player] =
		{
			SessionTime	= tick(),
			TeamTime	= tick(),
			Team		= "Class - D",
			SessionProgress =
			{
				["Class - D"] 					= {XP = 0},
				["Scientific Department"] 		= {XP = 0},
				["Security Department"] 		= {XP = 0},
				["Engineering and Technical"] 	= {XP = 0},
				["Chaos Insurgency"] 			= {XP = 0},
				["Mobile Task Force"] 			= {XP = 0},
			}
		}
		
		self:Log("player-added", player, {})
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		if self.Players[player] then
			local timePlayed = tick() - self.Players[player].SessionTime;
			--[[ Moved to Profile since saving here is inconsistent
			local timeTeamed = tick() - self.Players[player].TeamTime;
			
			local profile = ProfileService:GetProfile(player);
			profile.PlayTime["All"] += math.floor(timePlayed);
			profile.PlayTime[player.Teams.Name] += math.floor(timeTeamed);
			
			ProfileService:Save(player);
			]]
			
			local second	= math.floor(timePlayed);
			local minute	= math.floor(second/60);
			local hour		= math.floor(minute/60);
			self:Log(
				"player-left",
				player,
				{
					TimePlayed =
					{
						Hours	= hour,
						Minutes	= minute,
						Seconds	= second
					}
				}
			);
		end
		self.Players[player] = nil;
	end);
end;

function AnalyticsService:Log(event, player, data)
	
	--data.Event = event
	--if player then
	--	data.Username	= player.Name
	--	data.UserId		= player.UserId
	--	data.Premium	= player.MembershipType == Enum.MembershipType.Premium or false
	--	data.AccountAge	= player.AccountAge
	--end;
	--local response = HttpService:RequestAsync(
	--	{
	--		Url = Webhook,
	--		Method = "POST",
	--		Headers = {["Content-Type"] = "application/json"},
	--		Body = HttpService:JSONEncode(data)
	--	}
	--);
	
	--if response.Success then
	--	return true
	--else
	--	return false
	--end
	return true
end;

return AnalyticsService