local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayersService = game:GetService("Players")
local Signal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local NAMETAG_TEMPLATE = game:GetService("ServerStorage"):WaitForChild("Nametag")

local NametagService = Knit.CreateService({
	Name = "NametagService",
	Players = {},
	Titles = {},

})



--levelService:AddLevel(player, "Class - D", 1)
function NametagService:KnitStart()
	
	--local function onPlayerAdded(player)
		local levelService = Knit.Services.LevelService
		local ProfileService = Knit.Services.ProfileService
		
		ProfileService.CharacterAdded:Connect(function(player, character)
			self:GivePlayerTag(player, player.Team)
		end)
		
		ProfileService.PlayerRemoving:Connect(function(player, character)
			NametagService.Players[player] = nil
		end)
	--end
	
	--PlayersService.PlayerAdded:Connect(onPlayerAdded)
	--for _, player in pairs(PlayersService:GetPlayers()) do coroutine.wrap(function() onPlayerAdded(player) end)() end
	
	local TitlesService = Knit.Services.TitlesService
	self.Titles = TitlesService:GetTitles()
	
	TitlesService.OnTitlesChanged:Connect(function(newTitles)
		self.Titles = newTitles
	end)
end

function NametagService:GivePlayerTag(player, team)
	local team = player.Team

	local RobloxLeaderboardService = Knit.Services.RobloxLeaderboardService

	if not player.Character then
		return
	end
	
	local ProfileService = Knit.Services.ProfileService
	local profile = ProfileService:GetProfile(player)
	local adminLevel = profile.AdminLevel or 0
	
	local GamepassService = Knit.Services.GamepassService
	local hasGamepass = GamepassService:HasGamepass(player, "VIP")
	local rank = player:GetRankInGroup(4889827)
	local highRank = rank > 9
	
	local subTitle = {
		[0] = "",
		[1] = "[Tr. Mod]",
		[2] = "[Mod]",
		[3] = "[Developer]",
		[4] = "[O5 Council]",
		[5] = "[Sr. Mod]",
		[6] = "[O5 Head]",
		[7] = "[Mod Ld.]",
		[8] = "[Developer]",
		[9] = "[Admin]",
	    [10] = "[Owner]",
	}
	
	local titleRank = self:GetPlayerRankInTeam(player, team.Name)
	local faction = player:GetAttribute("Faction") or ""
	local factionTeam = player:GetAttribute("FactionTeam")
	
	local newTag = NametagService.Players[player] or NAMETAG_TEMPLATE:Clone()
	if not newTag:FindFirstChild("Rank") then
		newTag:Destroy()
		newTag = NAMETAG_TEMPLATE:Clone()
	end
	NametagService.Players[player] = newTag
	
	if factionTeam == team.Name then
		newTag.Rank.Text = faction.." | "..titleRank
	else
		newTag.Rank.Text = titleRank
	end
	
	local name = player.Name
	if player.UserId == 194788766 then
		name = player.DisplayName
	end
	
	if adminLevel == 0 then 
		if hasGamepass or highRank then
			newTag.Username.Text = "[VIP] "..name or "[VIP] "..player.Name
		end
	else
		newTag.Username.Text = subTitle[adminLevel].." "..name or subTitle[adminLevel].." "..player.Name
	end
	
	newTag.Status.Text = ""
	newTag.Username.Text = subTitle[adminLevel].." "..name or subTitle[adminLevel].." "..player.Name
	newTag.Username.TextColor3 = team.TeamColor.Color
	newTag.Adornee = player.Character.Head
	newTag.Parent = player.Character.Head
	NametagService.Players[player] = newTag
	--ChatService.OnUpdateTags:Fire(player, {Title = titleRank, Color = team.TeamColor.Color})

	RobloxLeaderboardService:UpdateStat(player, "Title", titleRank)
	--local speaker = ChatService:GetSpeaker(player.Name)
	--local tags = {[player.UserId] = {TagText = titleRank, TagColor = team.TeamColor.Color}, }	
	--speaker:SetExtraData("Tags",{tags[player.UserId]})
	return newTag
end

function NametagService:GetTag(player)
	return NametagService.Players[player] or NametagService:GivePlayerTag(player)
end


function NametagService:UpdateStatus(player, text, color)
	local tag = NametagService:GetTag(player)
	local success, response = pcall(function()
		tag.Status.Text = text
		tag.Status.TextColor3 = color
	end)
	if not success then
		print(response)
	end;
end

function NametagService:UpdateFaction(player, team, faction)
	local RobloxLeaderboardService = Knit.Services.RobloxLeaderboardService
	local tag = NametagService:GetTag(player)
	local titleRank = self:GetPlayerRankInTeam(player, team.Name)
	tag.Rank.Text = faction.." | "..titleRank
	
	RobloxLeaderboardService:UpdateStat(player, "Title", titleRank)
end

function NametagService:GetPlayerRankInTeam(player, teamName)
	local levelService = Knit.Services.LevelService
	local level = levelService:GetLevel(player, teamName)
	
	local rankTitles = self.Titles[teamName]
	if not rankTitles then
		return teamName
	end
	
	local titleToGive = {requiredLevel = 0, title = teamName}
	for _,title in pairs(rankTitles) do
		if level >= title.requiredLevel then
			if title.requiredLevel >= titleToGive.requiredLevel then
				titleToGive = title
			end
		end
	end
	
	return titleToGive.title
end


return NametagService