local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local KnitSignal = require(Knit.Util.Signal)
local Queue = require(Knit.Util.Queue)
local UserInputService = game:GetService("UserInputService")
local PLAYER		= game:GetService("Players").LocalPlayer
local AUTHORIZATION	= PLAYER.PlayerGui:WaitForChild("Authorization")
local MANAGER	= AUTHORIZATION:WaitForChild("Manager")
local LOG	= AUTHORIZATION:WaitForChild("Log")
local LEFT_BAR = PLAYER.PlayerGui:WaitForChild("LeftBar")
local LOG_TEMP = LOG.Template:Clone()
local MANAGER_TEMP = MANAGER.Template:Clone()
local CHARACTERSELECTION_BOX = game.ReplicatedStorage.CharacterSelection.SelectionBox:Clone()
local CHARACTERSELECTION_ATTACHMENT = game.ReplicatedStorage.CharacterSelection.Attachments.HumanoidRootPartAttachment:Clone()
local CHARACTERSELECTION_LINE = game.ReplicatedStorage.CharacterSelection.Line:Clone()

local AuthorizationController = Knit.CreateController({
	Name = "AuthorizationController",
	CacheHistorySizeLimit = 15,
	LogCache = Queue.new(),
	ShowingLog = false,
	LastLog = nil,
	TargetPlayer = nil,
	SelectedReason = "Deauthorize",
	VisibilityChanged = KnitSignal.new(),
})

local logNum = 100000

function AuthorizationController:KnitStart()
	
	local AuthorizationService = Knit.GetService("AuthorizationService")
	local SideBarController = Knit.GetController("SideBarController")
	local SFXController = Knit.GetController("SFXController")
	
	--------------------------------------------------------
	-- MANAGER CODE
	--------------------------------------------------------
	local AuthorizationsOptions = {
		"Testing",
		"Deauthorize"
	}
	
	function AuthorizationController:HighlightReason(obj, set)
		if set then
			obj.BackgroundColor3 = Color3.fromRGB(193, 166, 15)
		else
			obj.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
		end
	end
	
	for _, option in pairs(AuthorizationsOptions) do
		local temp = MANAGER_TEMP:Clone()
		temp.Parent = MANAGER.List
		temp.Reason.Text = option
		temp.Name = option
		temp.Visible = true
		temp.MouseButton1Down:Connect(function()
			local currentReasonObj = MANAGER.List[AuthorizationController.SelectedReason]
			AuthorizationController:HighlightReason(currentReasonObj, false)
			AuthorizationController.SelectedReason = option
			AuthorizationController:HighlightReason(temp, true)
		end)

		temp.MouseEnter:Connect(function()
			SFXController:PlayPrefab("ButtonHover")
		end)
	end
	
	local currentReasonObj = MANAGER.List[AuthorizationController.SelectedReason]
	AuthorizationController:HighlightReason(currentReasonObj, true)

	function AuthorizationController:ShowManager()
		MANAGER.Visible = true
		--self.VisibilityChanged:Fire(true)
	end

	function AuthorizationController:HideManager()
		MANAGER.Visible = false
		--self.VisibilityChanged:Fire(false)
	end
	
	MANAGER.Close.Close.MouseButton1Down:Connect(function()
		AuthorizationController:HideManager()
	end)

	MANAGER.Close.Close.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	MANAGER.Submit.Submit.MouseButton1Down:Connect(function()
		AuthorizationService.OnUpdateAuthorization:Fire(AuthorizationController.TargetPlayer, AuthorizationController.SelectedReason)
	end)

	MANAGER.Submit.Submit.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	AuthorizationService.OnToggleManager:Connect(function(enable, target)
		local TerminationService = Knit.GetService("TerminationService")
		
		if enable then
			local isDesignatedTermination = TerminationService:GetByUserId(target.UserId)
			print(isDesignatedTermination)
			
			if isDesignatedTermination then
				MANAGER.List:FindFirstChild("Deauthorize").Reason.Text = "Remove Termination"
			else
				MANAGER.List:FindFirstChild("Deauthorize").Reason.Text = "Deauthorize"
			end
			
			AuthorizationController.TargetPlayer = target
			MANAGER.Title.Text = "Authorization Manager: "..target.Name
			AuthorizationController:ShowManager()
		else
			AuthorizationController:HideManager()
		end
	end)
	
	AuthorizationService.OnTogglePrompts:Connect(function(enable, prompts)
		for player, prompt in pairs(prompts) do
			prompt.Enabled = enable
		end
		--print(enable, "Updated prompts", prompts)
	end)
	--------------------------------------------------------
	-- AUTH TOOL
	--------------------------------------------------------	
	--function AuthorizationController:HoverOnPlayer(player, tool)
	--	local character = player.Character
	--	CHARACTERSELECTION_BOX.SelectionBox.Parent = character
	--	CHARACTERSELECTION_ATTACHMENT.Parent = character.HumanoidRootPart
	--	CHARACTERSELECTION_LINE.Parent = character.HumanoidRootPart
	--	CHARACTERSELECTION_LINE.Attachment0 = tool.Handle.SelectionAttachment
	--	CHARACTERSELECTION_LINE.Attachment1 = CHARACTERSELECTION_ATTACHMENT
	--end
	
	--function AuthorizationController:HoverOffPlayer()
	--	CHARACTERSELECTION_BOX.SelectionBox.Parent = nil
	--	CHARACTERSELECTION_ATTACHMENT.Parent = nil
	--	CHARACTERSELECTION_LINE.Parent = nil
	--end
	
	--UserInputService.InputBegan:Connect(function(input)
	--	if input.UserInputType == Enum.UserInputType.MouseButton1 then
	--		print("button is down")
	--	end
	--end)

	
	--------------------------------------------------------
	-- LOGGER CODE
	--------------------------------------------------------
	SideBarController.VisibilityChanged:Connect(function(visible)
		if visible and self.ShowingLog then
			LOG.Visible = true
		else
			LOG.Visible = false
		end
	end)

	LEFT_BAR.Container.AuthorizationLog.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		if not LOG.Visible then
			LEFT_BAR.Container.AuthorizationLog.BackgroundColor3 = Color3.new(0.486275, 0.486275, 0.486275)
			AuthorizationController.EnabledUI = true
			LOG.Visible = true
		else
			LEFT_BAR.Container.AuthorizationLog.BackgroundColor3 = Color3.new(0, 0, 0)
			AuthorizationController.EnabledUI = false
			LOG.Visible = false				
		end
	end)
	
	function AuthorizationController:CreateLog(log)
		local temp = LOG_TEMP:Clone()
		temp.Parent = LOG.List
		temp.Visible = true
		temp.Authorizer.Text = log.PlayerName.." ["..log.PlayerTeam.."]"
		temp.Reason.Text = log.TargetName.." for "..log.Reason
		logNum = logNum - 1
		temp.LayoutOrder = logNum
		AuthorizationController.LogCache.Push(temp)
	end
	
	AuthorizationService.OnLogUpdated:Connect(function(log)
		if AuthorizationController.LogCache.Count() >= AuthorizationController.CacheHistorySizeLimit then
			local prev = AuthorizationController.LogCache.Pop()
			if prev then
				prev:Destroy()
			end
		end
		
		AuthorizationController:CreateLog(log)
	end)
	
	
	local currentLogHistory = AuthorizationService:GetLogHistory()
	--print(currentLogHistory)
	--if currentLogHistory ~= nil then
		for _, log in pairs(currentLogHistory) do
			AuthorizationController:CreateLog(log)
		end
	--else
		--print("EMPTY LOG HISTORY", currentLogHistory)
	--end
end

return AuthorizationController