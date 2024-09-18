local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local UPDATE_WAIT_TIME_SECONDS = 60
local DEFAULT_RANKS = require(script.DefaultTitles)
local Boards = game.Workspace.Scripted.Titleboards

local TitlesService = Knit.CreateService({
	Name = "TitlesService",
	Client = {
		OnTitlesChanged = RemoteSignal.new(),
	},
	OnTitlesChanged = Signal.new(),
	
	Ranks = {},
})


--Set the ranks and get initial data
function TitlesService:KnitStart()
	self.Ranks = DEFAULT_RANKS
	
	local teamDisplay = Boards["Class - D"].Team.Display:Clone()
	local titlesDisplay = Boards["Class - D"].Board.List:Clone()
	local titlesDisplayTemp = titlesDisplay.Container.DisplayList.Temp:Clone()
	
	Boards["Class - D"].Team.Display.Parent = nil
	Boards["Class - D"].Board.List.Parent = nil
	
	for _, board in pairs(Boards:GetChildren()) do
		if board:GetAttribute("Enabled") then
			local newTeamDisplay = teamDisplay:Clone()
			local newTitlesDisplay = titlesDisplay:Clone()
			
			newTeamDisplay.Parent = board.Team
			newTeamDisplay.NameDisplay.Text = board.Name
			
			newTitlesDisplay.Parent = board.Board
			local titles = self.Ranks[board.Name]
			for _, titleData in ipairs(titles) do
				local tempTitleFrame = titlesDisplayTemp:Clone()
				tempTitleFrame.Parent = newTitlesDisplay.Container.DisplayList
				tempTitleFrame.Level.Text = titleData.requiredLevel
				tempTitleFrame.Title.Text = titleData.title
				tempTitleFrame.Rewards.Text = titleData.rewards or "" 
				tempTitleFrame.Visible = true
			end
		end
	end
	
	while true do
		self:GetRanksFromLiveOps()
		wait(UPDATE_WAIT_TIME_SECONDS)
	end
end


--Return titles
function TitlesService:GetTitles()
	return self.Ranks
end


--Expose GetTitles function for client
function TitlesService.Client:GetTitles()
	return TitlesService:GetTitles()
end

--Update ranks TODO: Add http liveops call
function TitlesService:GetRanksFromLiveOps() 
	self.Ranks = DEFAULT_RANKS
	
	
	self.OnTitlesChanged:Fire(self.Ranks)
	self.Client.OnTitlesChanged:FireAll(self.Ranks)
	
	return self.Ranks
end


return TitlesService