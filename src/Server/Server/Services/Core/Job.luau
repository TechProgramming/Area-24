local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local EmoteService = false
local JobInteractIcon = script.JobInteractIcon:Clone()

local JobService = Knit.CreateService({
	Name = "JobService",
	LastWorkCache = {},
	Players = {},
	Container = {},
	Client = {
		OnJobStarted = RemoteSignal.new(),
		OnStopJob = RemoteSignal.new(),
	},
})



local JobDurations = 5

function JobService:KnitStart()
	local ProfileService = Knit.Services.ProfileService
	local LevelService = Knit.Services.LevelService
	local NotificationService = Knit.Services.NotificationService
	local QuestService = Knit.Services.QuestService
	local PropService = Knit.Services.PropService
	local CashService = Knit.Services.CashService
	local GamepassService = Knit.Services.GamepassService
	
	EmoteService = Knit.Services.EmoteService
	
	ProfileService.PlayerAdded:Connect(function(player)
		JobService.LastWorkCache[player] = 0
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		JobService.LastWorkCache[player] = nil
		local playerData = JobService.Players[player]
		if playerData and playerData.ActionObject then
			local actionObject = playerData.ActionObject
			actionObject.ProximityPrompt.Enabled = true
			playerData.NewIcon.Enabled = true
		end
		JobService.Players[player] = nil
	end)
	
	local Jobs = {
		-- CLAS D JOBS
		["Pullup"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Pullup")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},
		["Yoga"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Jumping Jack")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},
		["Dumbbells"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Dumbbell")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		["Treadmill"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Treadmill")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		["Deadlift"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Deadlift")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		
		["Microscope"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Microscope")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},
		["Research"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Typing")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		["Monitor"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Typing")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		
		["Check Inventory"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Checkup")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
		
		["Check Systems"] = {
			Work = function(jobData, player, jobObject)
				EmoteService:Play(player, "Checkup")
				--QuestService.ActionEvent.GYM_WORKOUT:Fire(player, 1)
			end,
		},	
	}
	
	local awardPack = {
		["Kill"] = {
			Normal = {
				Cash = 5,
				XP = 2
			},
			VIP = {
				Cash = 15,
				XP = 5
			}
		},
		["Camera"] = {
			Normal = {
				Cash = 5,
				XP = 2
			},
			VIP = {
				Cash = 15,
				XP = 5
			}
		},
		["None"] = {
			Normal = {
				Cash = 10,
				XP = 5
			},
			VIP = {
				Cash = 25,
				XP = 7
			}
		},
	}
	
	function JobService:Award(player, bypassCooldown, disableNotification, awardPackName)
		local disableNotification = disableNotification or false
		local jobWaitTime = 60 * 1
		local lastWorkCache = JobService.LastWorkCache[player]
		local secondsLeft = tick() - lastWorkCache
		awardPackName = awardPackName or "None"
		local xpAward = awardPack[awardPackName].Normal.XP
		if game.VIPServerOwnerId ~= 0 then
			xpAward = 0
		end
		
		local cashAward = awardPack[awardPackName].Normal.Cash
		if secondsLeft >= jobWaitTime or bypassCooldown then
			local hasGamepass = GamepassService:HasGamepass(player, "VIP")
			local rank = player:GetRankInGroup(4889827)
			local highRank = rank > 9
			if hasGamepass or highRank then
				xpAward = awardPack[awardPackName].VIP.XP
				if game.VIPServerOwnerId ~= 0 then
					xpAward = 0
				end
				
				cashAward = awardPack[awardPackName].VIP.Cash
				if not disableNotification then
					if bypassCooldown then
						NotificationService:ShowNotification(player, 3, "+"..xpAward.." XP / +$"..cashAward, Color3.fromRGB(41, 255, 141))
					else
						NotificationService:ShowNotification(player, 3, "+"..xpAward.." XP / +$"..cashAward.." | "..jobWaitTime.." Seconds until you can earn again!", Color3.fromRGB(41, 255, 141))
					end
					
				end
				LevelService:AddXP(player, player.Team.Name, xpAward)
				CashService:Add(player, cashAward)
			else
				if bypassCooldown then
					NotificationService:ShowNotification(player, 3, "+"..xpAward.." XP / +$"..cashAward, Color3.fromRGB(41, 255, 141))
				else
					NotificationService:ShowNotification(player, 3, "+"..xpAward.." XP / +$"..cashAward.." | "..jobWaitTime.." Seconds until you can earn again!", Color3.fromRGB(41, 255, 141))
				end
				LevelService:AddXP(player, player.Team.Name, xpAward)
				CashService:Add(player, cashAward)
			end

			JobService.LastWorkCache[player] = tick()
		else
			if not disableNotification then
				NotificationService:ShowNotification(player, 3, "You have ("..math.ceil(jobWaitTime - secondsLeft)..") seconds left before you can earn from working.", Color3.fromRGB(255, 122, 55))
			end	
		end
	end
	
	JobService.Client.OnStopJob:Connect(function(player)
		JobService:StopJob(player)
	end)
	
	function JobService:StopJob(player)
		pcall(function()
			JobService.Client.OnStopJob:Fire(player)
			
			local playerData = JobService.Players[player]
			--[[if not playerData then
				return
			end
			
			--remove weld if exists
			--[[local weld = player.Character.HumanoidRootPart:FindFirstChild("JobServiceWeld")
			if weld then
				weld:Destroy()
			end]]
			
			local actionObject = playerData.ActionObject
			--player.Character.HumanoidRootPart.Anchored = false
			actionObject.ProximityPrompt.Enabled = true
			player.Character.Humanoid.WalkSpeed = 16
			player.Character.HumanoidRootPart.Anchored = false
			playerData.NewIcon.Enabled = true
			for _, prop in pairs(playerData.Props) do
				prop:Destroy()
			end
			EmoteService:Stop(player)
			JobService.Players[player] = {}
		end)
	end
	
	local jobObjects = CollectionService:GetTagged("Job")
	for _, object in pairs(jobObjects) do
		local jobCharacter = object.Parent.Character
		local jobName = object.Parent.Name
		local propsFolder = object.Parent:FindFirstChild("Props")
		local newIcon = JobInteractIcon:Clone()
		newIcon.Parent = object
		object.Transparency = 1
		object.ProximityPrompt.HoldDuration = 2
		object.ProximityPrompt.ActionText = jobName
		object.ProximityPrompt.ObjectText = "Work"
		object.ProximityPrompt.Triggered:Connect(function(player)
			JobService.Players[player] = {}
			
			local jobData = Jobs[jobName]
			if jobData ~= nil then
				object.ProximityPrompt.Enabled = false
				player.Character.Humanoid:UnequipTools()
				player.Character.Humanoid.WalkSpeed = 0
				
				--Move player into position
				player.Character.HumanoidRootPart.Anchored = true
				player.Character.HumanoidRootPart.CFrame = jobCharacter.HumanoidRootPart.CFrame

				
				--Lock character from moving (disable sprint)
				--[[local weld = Instance.new("WeldConstraint")
				weld.Name = "JobServiceWeld"
				weld.Parent = player.Character.HumanoidRootPart
				weld.Part0 = weld.Parent
				weld.Part1 = jobCharacter.HumanoidRootPart]]
				
				--Add props
				local tempPropAccessories = {}
				if propsFolder then
					for _, prop in pairs(propsFolder:GetChildren()) do
						local propAccessory = PropService:Add(player, prop.Name)
						table.insert(tempPropAccessories, propAccessory)
					end
				end
				
				local team = player.Team
				jobData:Work(player, object)
				newIcon.Enabled = false
				
				JobService.Players[player].Props = tempPropAccessories
				JobService.Players[player].NewIcon = newIcon
				JobService.Players[player].ActionObject = object
				JobService.Client.OnJobStarted:Fire(player)
				
				JobService:Award(player)
			end
		end)
	end
end


return JobService