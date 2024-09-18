local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local LightingService = game:GetService("Lighting")
local PlayerService = game:GetService("Players")
local RunService = game:GetService("RunService")

local TAG = "Vehicle"
local TIMEOUT_TIME_SECONDS = 60
local TIMEOUT_UI = script:WaitForChild("Timeout")
local LIGHT_ATTACHEMENT = script:WaitForChild("VehicleLightContainer").Attachment

local VehicleService = Knit.CreateService({
	Name = "VehicleService",
	Client = {},
	Vehicles = {},
	HeadlightsEnabled = false,
})


function VehicleService:KnitStart()
	local vehicles = CollectionService:GetTagged(TAG)
	
	--Register event handlers for vehicles
	for _, vehicle in pairs(vehicles) do
		self.RegisterVehicle(vehicle)
	end
	
	--Listen for new tagged vehicles
	CollectionService:GetInstanceAddedSignal(TAG):Connect(self.RegisterVehicle)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(vehicle)
		--Remove from registered vehicles
		for index, vehicle in pairs(self.Vehicles) do
			if vehicle.instance == vehicle then
				table.remove(self.Vehicles, index)
				break
			end
		end
	end)
	
	
	--Listen to lighting time of day
	LightingService:GetPropertyChangedSignal("ClockTime"):Connect(function()
		local newTime = LightingService.ClockTime
		
		--17.5 after
		--6.4 before
		local nightTime = false
		
		if newTime <= 6.4 then
			nightTime = true
		end
		
		if newTime >= 17.5 then
			nightTime = true
		end
		
		--Change headlights accordingly
		if not nightTime and self.HeadlightsEnabled then
			--Turn off headlights
			self.HeadlightsEnabled = false
			self:ToggleHeadlights()
		elseif nightTime and not self.HeadlightsEnabled then
			--Turn on headlights
			self.HeadlightsEnabled = true
			self:ToggleHeadlights()
		end
	end)
	
	--BLOCKING - failsafe
	while true do
		pcall(function()
			self:StartUpdateLoop()
		end)
		wait(1)
	end
end


function VehicleService.RegisterVehicle(vehicle)
	--Create timeout UI
	local timeoutUI = TIMEOUT_UI:Clone()
	timeoutUI.Counter.Text = TIMEOUT_TIME_SECONDS.."s"
	timeoutUI.Parent = vehicle
	
	--Create night light
	local lightAttachment = LIGHT_ATTACHEMENT:Clone()
	lightAttachment.Parent = vehicle.PrimaryPart
	
	--add vehicle data to list
	local data = {
		timeout = 25,
		timeoutDebounce = false,
		timeoutEnabled = false,
		timeoutUI = timeoutUI,
		instance = vehicle,
		spawnCFrame = vehicle.PrimaryPart.CFrame,
		headlight = lightAttachment.Light,
		vehicleType = vehicle:GetAttribute("VehicleType"),
		
	}
	table.insert(VehicleService.Vehicles, data)

	--Listen to occupant events
	local vehicleSeat = vehicle.Chassis.VehicleSeat
	vehicleSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		--print(vehicleSeat.Occupant)
		if vehicleSeat.Occupant ~= nil then
			--Player is using vehicle, stop timeout
			local plr = PlayerService:GetPlayerFromCharacter(vehicleSeat.Occupant.Parent)
			--print(plr)
			if not plr then
				return
			end
			
			local vehicleData = VehicleService:GetVehicle(vehicle)
			if vehicleData.vehicleType == "Jeep" then
				local hasAccess = plr.Team:GetAttribute("JeepAccess")
				if not hasAccess then
					vehicle:SetAttribute("MaxSpeed", 0)
					vehicle:SetAttribute("ReverseSpeed", 0)
					local lastCFrame = plr.Character.HumanoidRootPart.CFrame
					--boot from seat
					vehicleData.timeoutDebounce = true
					local weld = vehicleSeat:WaitForChild("SeatWeld")
					
					if weld.Parent ~= vehicleSeat then
						repeat wait(0.1) until weld.Parent == vehicleSeat
					end
					
					weld:Destroy()
					plr.Character.HumanoidRootPart.CFrame  = lastCFrame
					
					local NotificationService = Knit.GetService("NotificationService")
					NotificationService:ShowNotification(plr, 3, "You aren't allowed in that vehicle!", Color3.fromRGB(255, 123, 123))
					
					return
				else
					vehicle:SetAttribute("MaxSpeed", 30)
					vehicle:SetAttribute("ReverseSpeed", 15)
				end
			end
			
			VehicleService:SetTimeout(vehicleData, false)

		else
			--Player stopped using vehicle
			local vehicleData = VehicleService:GetVehicle(vehicle)
			if vehicleData.timeoutDebounce then
				vehicleData.timeoutDebounce = false
				return
			end

			VehicleService:SetTimeout(vehicleData, true)
		end
	end)
end


function VehicleService:ToggleHeadlights()
	for _, vehicle in pairs(self.Vehicles) do
		local light = vehicle.headlight
		light.Enabled = not light.Enabled
	end
end


function VehicleService:SetTimeout(vehicleData, value) 
	vehicleData.timeoutEnabled = value
	vehicleData.timeout = TIMEOUT_TIME_SECONDS
	vehicleData.timeoutUI.Enabled = value
	vehicleData.timeoutUI.Counter.Text = TIMEOUT_TIME_SECONDS.."s"
end


function VehicleService:RespawnVehicle(vehicleData)
	vehicleData.instance:SetPrimaryPartCFrame(vehicleData.spawnCFrame)
end


function VehicleService:GetVehicle(targetVehicle)
	for _, vehicle in pairs(self.Vehicles) do
		if vehicle.instance == targetVehicle then
			return vehicle
		end
	end
	
	return nil
end


function VehicleService:StartUpdateLoop()
	while true do
		
		--Update timeouts
		for index, vehicleData in pairs(self.Vehicles) do
			--check if timeout enabled
			if vehicleData.timeoutEnabled == false then
				continue
			end
			
			--get new timeout and check if timeout over, if over respawn vehicle and reset timeout
			local newTimeLeft = vehicleData.timeout-1
			if newTimeLeft <= 0 then
				self:SetTimeout(vehicleData, false)
				self:RespawnVehicle(vehicleData)
				continue
			end
			
			vehicleData.timeout = newTimeLeft
			vehicleData.timeoutUI.Counter.Text = newTimeLeft.."s"
			
		end
		
		wait(1)
	end
end


return VehicleService