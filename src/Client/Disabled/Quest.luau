local Knit = require(game:GetService("ReplicatedStorage").Knit);

local StarterGui = game:GetService("StarterGui");

local PLAYER = game:GetService("Players").LocalPlayer
local OBJECTIVES_UI = PLAYER.PlayerGui:WaitForChild("Objectives")
local temp = OBJECTIVES_UI.Temps.Quest:Clone()

local QuestController = Knit.CreateController({
	Name = "QuestController"
})

function QuestController:KnitStart()
	
	local QuestService = Knit.GetService("QuestService")
	
	QuestService.OnAssignedQuest:Connect(function(questName, questData, questProfile)
		self:ShowQuest(questName, questData, questProfile)
	end)
	
	QuestService.OnQuestUpdated:Connect(function(questName, questData, questProfile)
		local questUI = OBJECTIVES_UI.Container.Quest:FindFirstChild(questName)
		if questUI then
			questUI.Progress.Text = questProfile.Goal.."/"..questData.Goal.Amount
			if questProfile.Status == "Completed" then
				questUI.Progress.Visible = false
				questUI.Claim.Visible = true
			elseif questProfile.Status == "Done" then
				questUI:Destroy()
			end
		end
	end)
	
	function QuestController:ShowQuest(questName, questData, questProfile)
		--print(questName, questData, questProfile)
		local newQuest = temp:Clone()
		newQuest.Name = questName
		newQuest.Description.Text = questData.Description
		newQuest.Reward.Text = questData.RewardText
		newQuest.Progress.Text = questProfile.Goal.."/"..questData.Goal.Amount
		newQuest.Visible = true
		newQuest.QuestName.Text = questName
		newQuest.Parent = OBJECTIVES_UI.Container.Quest
		newQuest.Claim.MouseButton1Click:Connect(function()
			QuestService.OnClaimReward:Fire(questName)
		end)
		if questProfile.Status == "Completed" then
			newQuest.Progress.Visible = false
			newQuest.Claim.Visible = true
		elseif questProfile.Status == "Done" then
			newQuest:Destroy()
		end
	end
	

	
end

return QuestController