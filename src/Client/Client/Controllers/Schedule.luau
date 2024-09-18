local Knit				= require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat		= require(Knit.Util.NumberFormat)
local CollectionService	= game:GetService("CollectionService")
local StarterGui		= game:GetService("StarterGui")

local PLAYER	= game:GetService("Players").LocalPlayer

local SCHEDULE	= PLAYER.PlayerGui:WaitForChild("Schedule")

local ScheduleController = Knit.CreateController({
	Name = "ScheduleController",
})

function ScheduleController:KnitStart()
	
	local ScheduleService = Knit.GetService("ScheduleService")
	local currentTask = ScheduleService:Get()
	
	function ScheduleController:Update(task)
		SCHEDULE.Display.Text = task
	end
	
	ScheduleService.OnScheduleBegan:Connect(function(task)
		ScheduleController:Update(task)
	end)
	
	ScheduleController:Update(currentTask)
end

return ScheduleController