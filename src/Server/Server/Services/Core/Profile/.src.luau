local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local TeamsService = game:GetService("Teams")
local MarketPlaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local PlayerService = game:GetService("Players")
local CollectionService = game:GetService("CollectionService");

local Default = require(script.Default)
--local DataStoreProfileService = require(script.DataStoreProfileService)

local DataStoreService = game:GetService("DataStoreService")
local ProfileDataStore = DataStoreService:GetDataStore("PlayerProfile")

local Webhook = ""

local ProfileService = Knit.CreateService({ 
	Name = "ProfileService", 
	CharacterAdded = KnitSignal.new(),
	PlayerAdded = KnitSignal.new(),
	PlayerRemoving = KnitSignal.new(),
	Client = {
		OnCashChanged = RemoteSignal.new(),
	}
})

ProfileService.Collection = {}

function ProfileService.Client:GetProfile(player)
	return ProfileService:GetProfile(player)
end	

function ProfileService:GetProfile(player)
	repeat wait() until ProfileService.Collection[player.UserId] ~= nil
	return ProfileService.Collection[player.UserId]
end

function ProfileService:UpdateProfile(player)
	return ProfileService.Collection[player.UserId]
end

local function CloneTable(obj, seen)
	if type(obj) ~= "table" then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[CloneTable(k, s)] = CloneTable(v, s) end
	return res
end

function ProfileService:SyncWithDefaults(PlayerTable, DefaultTable)
	for key, value in next,DefaultTable do
		if PlayerTable[key] == nil and type(key) ~= "number" then
			--new key added
			if type(value) == "table" then
				PlayerTable[key] = CloneTable(value)
			else
				PlayerTable[key] = value
			end
		elseif type(PlayerTable[key]) == "table" and DefaultTable[key] ~= nil then
			ProfileService:SyncWithDefaults(PlayerTable[key], DefaultTable[key])
		end
	end
	return PlayerTable
end

function ProfileService:DownloadProfile(player)
	--local response = nil
	--pcall(function()
	--	response = HttpService:RequestAsync({
	--		Url = Webhook.."get-profile?userId="..player.UserId,
	--		Method = "GET",
	--		Headers = {["Content-Type"] = "application/json"},
	--	})
	--end)
	--print(response)
	--if response == nil then
	--	return false
	--end
	--if response.Success then
	--	--print("Status code:", response.StatusCode, response.StatusMessage)
	--	--print("Response body:\n", response.Body)
	--	return HttpService:JSONDecode(response.Body)
	--else
	--	return false
	--end
	return {}
end

function ProfileService:UploadProfile(player)
	--print("SAVING PROFILE", player)
	--local profile = ProfileService:GetProfile(player)
	--local response = HttpService:RequestAsync({
	--	Url = Webhook.."update-profile?userId="..player.UserId,
	--	Method = "POST",
	--	Headers = {["Content-Type"] = "application/json"},
	--	Body = HttpService:JSONEncode(profile)
	--})

	--if response.Success then
	--	return true
	--else
	--	return false
	--end
	return false
end

local SAVING_ENABLED = true

--local GameProfileStore = DataStoreProfileService.GetProfileStore(
--	"PlayerData",
--	Default:Get()
--)

function ProfileService:KnitStart()
	local LevelService = Knit.Services.LevelService
	local AnalyticsService = Knit.Services.AnalyticsService
	local LeaderboardService = Knit.Services.LeaderboardService
	local JobService = Knit.Services.JobService
	local GamepassService = Knit.Services.GamepassService
	local BundleService = Knit.Services.BundleService
	local TeamingService = Knit.Services.TeamingService
	local NPCService = Knit.Services.NPCService
	
	function ProfileService:DiedEvent(player, character)
		if character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.Anchored = false;
		end;
		if character:FindFirstChild("Humanoid") then
			character.Humanoid.WalkSpeed = 16;
		end;
		CollectionService:AddTag(character, "Dead");
		JobService:StopJob(player)

		if player.Team.Name == "Chaos Insurgency" and not GamepassService:HasGamepass(player, "Chaos Insurgency") then

			TeamingService:TeamPlayer(player, game.Teams["Class - D"])
			BundleService:Prompt(player, "Chaos Insurgency")
		end;
	end;


	function ProfileService:CharacterAddedEvent(player, character)
		local HRP = character:WaitForChild("HumanoidRootPart");
		character.PrimaryPart = HRP;
		ProfileService.CharacterAdded:Fire(player, character)

		character:WaitForChild("Humanoid").Died:Connect(function()
			ProfileService:DiedEvent(player, character)
		end);

		character:WaitForChild("Humanoid").HealthChanged:Connect(function(health)
			print("Died?", health <= 0)
			--NPCService:SpawnPlagueDoctorZombie(player, workspace.SPAWNTEST.CFrame, workspace)
		end)
	end

	function ProfileService:PlayerAddedEvent(player)
		print("PLAYER CONNECTED")
		local teamName = player.Team.Name
		local profileData = self:DownloadProfile(player) or {}
		--ProfileService.Collection[player.UserId] = Default:Create()
		ProfileService.Collection[player.UserId] = ProfileService:SyncWithDefaults(profileData, Default:Get())
		ProfileService.Collection[player.UserId].UserId = player.UserId
		ProfileService.Collection[player.UserId].Username = player.Name
		--ProfileService.Collection[player.UserId].Cash = player.Cash
		ProfileService.Collection[player.UserId].Level = LevelService:GetLevel(player, teamName);

		local success, dataStoreProfile = pcall(function()
			return ProfileDataStore:GetAsync("Player"..player.UserId)
		end)

		if success then
			print("DATASTORE", dataStoreProfile)
			if dataStoreProfile == nil then
				local success, err = pcall(function()
					ProfileDataStore:SetAsync("Player"..player.UserId, ProfileService.Collection[player.UserId])
				end)
				if success then
					print("Save successful")
				else
					print(err)
				end
			else
				local mongoDB_SaveNumber = ProfileService.Collection[player.UserId].SaveNumber
				local dataStore_SaveNumber = dataStoreProfile.SaveNumber
				print("SAVE NUMBERS | MongoDB:", mongoDB_SaveNumber, " | DataStore:", dataStore_SaveNumber)
				local useDataStore = false
				--if mongoDB_SaveNumber < dataStore_SaveNumber then
					print("MONGODB IS BEHIND! USING COPY FROM DATASTORE!")
					ProfileService.Collection[player.UserId] = ProfileService:SyncWithDefaults(dataStoreProfile, Default:Get())
					
				--end
			end
		else
			print("FAILED TO LOAD DATASTORE")
		end


		--local dataStoreProfile = GameProfileStore:LoadProfileAsync(player.UserId, function(place_id, game_job_id)
		--	return "ForceLoad"
		--end)
		--Moved to not use profiles
		--[[if ProfileService.Collection[player.UserId].Ban then
			player:Kick("Access Denied");
		end]]

		ProfileService.PlayerAdded:Fire(player, ProfileService.Collection[player.UserId]);
		
		player.CharacterAdded:Connect(function(character)
			ProfileService:CharacterAddedEvent(player, character)
		end)
		if player.Character then
			ProfileService:CharacterAddedEvent(player, player.Character)
		end
	end

	PlayerService.PlayerAdded:Connect(function(player)
		ProfileService:PlayerAddedEvent(player)
	end)

	function ProfileService:Save(player, force)

		local timePlayed = tick() - AnalyticsService.Players[player].SessionTime;
		local timeTeamed = tick() - AnalyticsService.Players[player].TeamTime;

		local profile = ProfileService.Collection[player.UserId];
		profile.PlayTime["All"] += math.floor(timePlayed);
		profile.PlayTime[AnalyticsService.Players[player].Team] += math.floor(timeTeamed);
		profile.SaveNumber = profile.SaveNumber + 1
		profile.GameVersion = script.GameVersion.Value

		local success, err = pcall(function()
			ProfileDataStore:SetAsync("Player"..player.UserId, profile)
		end)
		if success then
			print("Save successful")
		else
			print(err)
		end
		--local session_progress = AnalyticsService:GetSessionProgress(player)
		--local board_progress = {}

		--for teamName, progressData in pairs(progress) do
		--	board_progress[teamName] = {
		--		XP = {
		--			["$inc"] = {
		--				progressData.XP
		--			}
		--		}
		--	}
		--end

		--LeaderboardService:Save(player, "weekly-progress", {

		--})

		if SAVING_ENABLED or force then
			--DataStoreProfileService.Data = profile
			--ProfileService:UploadProfile(player)
			ProfileService.Collection[player.UserId] = nil
			AnalyticsService.Players[player] = nil
		end
	end


	PlayerService.PlayerRemoving:Connect(function(player)
		ProfileService:Save(player)
		ProfileService.PlayerRemoving:Fire(player)
	end)

	for _, player in pairs(game.Players:GetPlayers()) do
		--local profileData = self:DownloadProfile(player)
		ProfileService:PlayerAddedEvent(player)
	end

end

-- HANDLERS
function ProfileService:SavePhoto(player, newPhotoId)
	local foundPhoto = false
	local profile = ProfileService:GetProfile(player)
	for _, photoId in pairs(profile.Photos) do
		if photoId == newPhotoId then
			foundPhoto = true
			break
		end
	end
	if not foundPhoto then
		table.insert(profile.Photos, newPhotoId);
	end

	return foundPhoto
end

function ProfileService:SaveDocument(player, newDocumentId)
	local foundDocument = false
	local profile = ProfileService:GetProfile(player)
	for _, photoId in pairs(profile.Documents) do
		if photoId == newDocumentId then
			foundDocument = true
			break
		end
	end
	if not foundDocument then
		table.insert(profile.Documents, newDocumentId);
	end

	return foundDocument
end


game:BindToClose(function()
	if SAVING_ENABLED then
		for _, player in pairs(game.Players:GetPlayers()) do
			ProfileService:UploadProfile(player)
		end
	end
end)

return ProfileService