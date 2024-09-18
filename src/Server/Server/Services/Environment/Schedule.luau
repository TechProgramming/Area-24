local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local ScheduleService = Knit.CreateService({
	Name = "ScheduleService",
	Client = {
		OnScheduleBegan = RemoteSignal.new(),
		OnScheduleEnded = RemoteSignal.new()
	},
})

ScheduleService.TaskSchedule =
{
	{Time = 6.5, Task = "ROLLCALL"},
	{Time = 8, Task = "WORK"},
	{Time = 12, Task = "LUNCH"},
	{Time = 14, Task = "WORK"},
	{Time = 17, Task = "BREAK"},
	{Time = 19, Task = "ROLLCALL"},
	{Time = 21, Task = "SLEEP"},
}

ScheduleService.CurrentTask = "ROLLCALL"
ScheduleService.NextTaskTime = 8

function ScheduleService.Client:Get(player)
	return ScheduleService.CurrentTask
end

function ScheduleService:KnitStart()
	
	local NotificationService	= Knit.GetService("NotificationService");
	local IntercomService;
	repeat wait();
		IntercomService = Knit.GetService("IntercomService");
	until IntercomService;
	local ProfileService		= Knit.GetService("ProfileService");
	local LightsService			= Knit.GetService("LightsService");
	local EventService			= Knit.GetService("EventService");
	local TimeService			= Knit.GetService("TimeService");
	
	local TeamNotifications = {
		['Chaos Insurgency'] = false,
		['Class - D'] = true,
		['Engineering and Technical'] = true,
		['Scientific Department'] = true,
		['Security Department'] = true,
		["Mobile Task Force"] = true,
		["Site Director"] = true,
		["O5 Council"] = true,
		["Global Occult Coalition"] = true,	
	}
	
	function ScheduleService:sendScheduleMessage(message)
		for _, player in pairs(game.Players:GetPlayers()) do
			local teamName = player.Team.Name
			if TeamNotifications[teamName] then
				NotificationService:ShowServerNotification(5, message, Color3.fromRGB(255, 55, 55))
			end
		end
	end
	
	local ScheduleData = {
		["ROLLCALL"] = {
			Start = function()
				ScheduleService:sendScheduleMessage("ATTENTION! TIME FOR ROLLCALL!")
				IntercomService:PlayWithGroupPriority("Rollcall")
			end,
			End = function()
				
			end,
		},
		["WORK"] = {
			Start = function()
				ScheduleService:sendScheduleMessage("TIME TO WORK!")
				IntercomService:PlayWithGroupPriority("Work")
			end,
			End = function()
				
			end,
		},
		["BREAK"] = {
			Start = function()
				ScheduleService:sendScheduleMessage("BREAK TIME!")
				IntercomService:PlayWithGroupPriority("Break")
			end,
			End = function()
				
			end,
		},	
		["LUNCH"] = {
			Start = function()
				ScheduleService:sendScheduleMessage("TIME TO EAT!")
				IntercomService:PlayWithGroupPriority("Lunch")
			end,
			End = function()
				
			end,
		},	
		["SLEEP"] = {
			Start = function()
				ScheduleService:sendScheduleMessage("LIGHTS OUT! TIME TO SLEEP!")
				IntercomService:PlayWithGroupPriority("Sleep")
			end,
			End = function()
				
			end,
		},	
	}
	
	function ScheduleService:StartEvent(task)
		
		if ScheduleData[task] then
			ScheduleData[task]:Start()
		end
		ScheduleService.Client.OnScheduleBegan:FireAll(task)
	end

	function ScheduleService:EndEvent(task)
		
		if ScheduleData[task] then
			ScheduleData[task]:End()
		end
		ScheduleService.Client.OnScheduleEnded:FireAll(task)
	end
	
	--ScheduleService.TaskSchedule = {
	--	{Time = 6.5, Task = "ROLLCALL"},
	--	{Time = 8, Task = "WORK"},
	--	{Time = 12, Task = "LUNCH"},
	--	{Time = 14, Task = "WORK"},
	--	{Time = 17, Task = "BREAK"},
	--	{Time = 19, Task = "ROLLCALL"},
	--	{Time = 21, Task = "SLEEP"},
	--}
	function ScheduleService:UpdateCurrentTask(hoursAfterMidnight)
		
		for num, taskData in pairs(ScheduleService.TaskSchedule) do
			if taskData.Time <= hoursAfterMidnight then
				ScheduleService.CurrentTask  = taskData.Task
				local nextTaskData = ScheduleService.TaskSchedule[num+1] or ScheduleService.TaskSchedule[1]
				ScheduleService.NextTaskTime = nextTaskData.Time
			end
		end
		ScheduleService:StartEvent(ScheduleService.CurrentTask)
	end
	
	TimeService.TimeChanged:Connect(function(hoursAfterMidnight)
		
		local currentTask = ScheduleService.CurrentTask
		local nextTaskTime = ScheduleService.NextTaskTime

		if currentTask ~= "SLEEP" and hoursAfterMidnight >= nextTaskTime then
			ScheduleService:UpdateCurrentTask(hoursAfterMidnight)
		elseif currentTask == "SLEEP" and hoursAfterMidnight >= nextTaskTime and hoursAfterMidnight <= 7 then
			ScheduleService:UpdateCurrentTask(hoursAfterMidnight)
		end
	end)
	
	ScheduleService:UpdateCurrentTask(game.Lighting:GetMinutesAfterMidnight()/60)
end

return ScheduleService