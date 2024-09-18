local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PLAYER = game:GetService("Players").LocalPlayer
local GUI = PLAYER.PlayerGui:WaitForChild("EngineerTask")
local TITLE = GUI.Manager.Title
local LIST = GUI.Manager.List
local LIST_TEMPLATE = GUI.Manager.Template
local CAMERA_BUTTON = GUI.Manager.Actions.Cameras
local VENT_BUTTON = GUI.Manager.Actions.Vents

--Colors
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
local BACKGROUND_DEFAULT_COLOR = Color3.fromRGB(4, 4, 4)

local WARN_COLOR = Color3.fromRGB(236, 255, 21)
local BACKGROUND_WARN_COLOR = Color3.fromRGB(201, 204, 15)

local ERROR_COLOR = Color3.fromRGB(255, 209, 43)
local BACKGROUND_ERROR_COLOR = Color3.fromRGB(204, 64, 9)

local EngineerTaskController = Knit.CreateController({
	Name = "EngineerTaskController",
	CurrentTab = "Cameras",
	VentsStatus = {},
	CamerasStatus = {},
	UpdatingUI = false,
})


function EngineerTaskController:KnitStart()
	--Clear templates
	self:ClearList()
	
	--Listen for tool equip
	local ToolController = Knit.GetController("ToolController")
	ToolController.OnEquipped:Connect(function(tool)
		if tool.Name == "Engineer Task" then
			self:Show()
		end
	end)
	
	ToolController.OnUnequipped:Connect(function(tool)
		if tool.Name == "Engineer Task" then
			self:Hide()
		end
	end)
	
	--Listen for tab butotn presses
	CAMERA_BUTTON.MouseButton1Down:Connect(function()
		if self.CurrentTab == "Cameras" or self.UpdatingUI then
			return
		end
		self.UpdatingUI = true
		
		self.CurrentTab = "Cameras"
		TITLE.Text = "CAMERAS"
		
		self:ClearList()
		self:UpdateUI()
		self.UpdatingUI = false
	end)
	
	VENT_BUTTON.MouseButton1Down:Connect(function()
		if self.CurrentTab == "Vents" or self.UpdatingUI then
			return
		end
		self.UpdatingUI = true

		self.CurrentTab = "Vents"
		TITLE.Text = "VENTS"
		
		self:ClearList()
		self:UpdateUI()
		self.UpdatingUI = false
	end)
	
	--Start the update loop
	self:StartUpdateLoop()
end


function EngineerTaskController:UpdateUI()
	if self.CurrentTab == "Vents" then
		--Update UI for vents
		
		for _, vent in pairs(self.VentsStatus) do
			local text = vent.name
			if vent.isOpen then
				text = text.." [HELP!]"
			end

			local level = nil
			if vent.isOpen then
				level = "ERROR"
			end

			local currentElem = LIST:FindFirstChild(vent.name)
			if not currentElem then
				currentElem = self:CreateFromTemplate(text)
			else
				currentElem.Reason.Text = text 
			end

			self:SetStyle(currentElem, level)
			currentElem.Name = vent.name
			currentElem.Parent = LIST
			currentElem.Visible = true
		end
		
	elseif self.CurrentTab == "Cameras" then
		--Update UI for cameras
		
		for _, cam in pairs(self.CamerasStatus) do
			local batteryCeil = math.ceil(cam.battery)
			local level = nil

			if batteryCeil <= 60 then
				level = "WARN"
			end

			if batteryCeil <= 20 then
				level = "ERROR"
			end

			local elemText = cam.name.." ["..math.ceil(cam.battery).."%]"

			local currentElem = LIST:FindFirstChild(cam.name)
			if not currentElem then
				currentElem = self:CreateFromTemplate(elemText)
			else
				currentElem.Reason.Text = elemText 
			end

			self:SetStyle(currentElem, level)
			currentElem.Name = cam.name
			currentElem.Parent = LIST
			currentElem.Visible = true
		end
		
	end
end


function EngineerTaskController:CreateFromTemplate(text)
	local newItem = LIST_TEMPLATE:Clone()
	newItem.Reason.Text = text	
	return newItem
end


function EngineerTaskController:SetStyle(elem, styleType)
	if styleType == "ERROR" then
		elem.Reason.TextColor3 = ERROR_COLOR
		elem.BackgroundColor3 = BACKGROUND_ERROR_COLOR
	elseif styleType == "WARN" then
		elem.Reason.TextColor3 = WARN_COLOR
		elem.BackgroundColor3 = BACKGROUND_WARN_COLOR
	else
		elem.Reason.TextColor3 = DEFAULT_COLOR
		elem.BackgroundColor3 = BACKGROUND_DEFAULT_COLOR
	end
end


function EngineerTaskController:ClearList()
	for _, item in pairs(LIST:GetChildren()) do
		if item:IsA("ImageButton") then
			item:Destroy()
		end
	end
end


function EngineerTaskController:RefreshCameras()
	local SecurityCameraService = Knit.GetService("SecurityCameraService")
	self.CamerasStatus = SecurityCameraService:GetCameras()	
end

function EngineerTaskController:RefreshVents()
	local VentService = Knit.GetService("VentService")
	self.VentsStatus = VentService:GetVents()
end


function EngineerTaskController:StartUpdateLoop()
	coroutine.wrap(function()
		while true do
			
			self:RefreshCameras()
			self:RefreshVents()
			self:UpdateUI()
			
			wait(5)
		end
	end)()
end


function EngineerTaskController:Show()
	GUI.Enabled = true
end


function EngineerTaskController:Hide()
	GUI.Enabled = false
end


return EngineerTaskController