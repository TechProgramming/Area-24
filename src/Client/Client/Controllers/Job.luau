local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local KnitSignal = require(Knit.Util.Signal)

local PLAYER = game:GetService("Players").LocalPlayer
local ACTION = PLAYER.PlayerGui:WaitForChild("Job")

local JobController = Knit.CreateController({
	Name = "JobController",
	VisibilityChanged = KnitSignal.new(),
	InJob = false,
})

function JobController:KnitStart()
	local JobService = Knit.GetService("JobService")
	local SFXController = Knit.GetController("SFXController")
	
	JobService.OnStopJob:Connect(function()
		JobController.InJob = false
		JobController:Hide()
	end)
	
	
	function JobController:Show()
		ACTION.Enabled = true
		self.VisibilityChanged:Fire(true)
	end

	function JobController:Hide()
		ACTION.Enabled = false
		self.VisibilityChanged:Fire(false)
	end

	ACTION.Close.CloseButton.MouseButton1Down:Connect(function()
		JobController.InJob = false
		JobService.OnStopJob:Fire()
		JobController:Hide()
	end)

	ACTION.Close.CloseButton.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)

	JobService.OnJobStarted:Connect(function()
		JobController.InJob = true
		JobController:Show()
	end)
	
	function JobController:IsInJob() 
		return self.InJob
	end

end


return JobController