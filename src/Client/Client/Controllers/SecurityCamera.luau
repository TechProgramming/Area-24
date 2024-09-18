local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui")

local SecurityCameraController = Knit.CreateController({
	Name = "SecurityCameraController",
	VisibilityChanged = KnitSignal.new(),
	CurrentTab = "Cameras",
	VentsStatus = {},
	CamerasStatus = {},
	UpdatingUI = false,
	UsingCams = false,
	CurrentCamera = nil,
})

local PLAYER	= game:GetService("Players").LocalPlayer
local CAMERA_UI	= PLAYER.PlayerGui:WaitForChild("Camera")
local CAMERA	= workspace.CurrentCamera
local GUI = CAMERA_UI
local TITLE = GUI.Manager.Title
local LIST = GUI.Manager.List
local LIST_TEMPLATE = GUI.Manager.Template
local CLOSE_BUTTON = GUI.Manager.Close.Close
local LAST_SWITCH = 0
local DELAY_SWITCH_TIME = 3
--Colors
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
local BACKGROUND_DEFAULT_COLOR = Color3.fromRGB(4, 4, 4)

local WARN_COLOR = Color3.fromRGB(236, 255, 21)
local BACKGROUND_WARN_COLOR = Color3.fromRGB(201, 204, 15)

local ERROR_COLOR = Color3.fromRGB(255, 209, 43)
local BACKGROUND_ERROR_COLOR = Color3.fromRGB(204, 64, 9)

local Connection_Battery;
local ConnectionLog = {}


function SecurityCameraController:KnitStart()

	local SecurityCameraService = Knit.GetService("SecurityCameraService")
	local NotificationController = Knit.GetController("NotificationController")

	SecurityCameraService.OnOpenCamera:Connect(function(cameraObject, cameraName, cameraCFrame)
			self.CurrentCamera = cameraName
			self:ShowCamera(cameraObject, cameraName, cameraCFrame)
	end)

	SecurityCameraService.OnSwitchCamera:Connect(function(cameraObject, cameraName, cameraCFrame)
		--self:ShowCamera(cameraObject, cameraName, cameraCFrame)
	end)

	--CAMERA_UI.CloseCamera.MouseButton1Click:Connect(function(cameraName, cameraCFrame)
	--	SecurityCameraController:Hide()
	--end)

	local ToolController = Knit.GetController("ToolController")
	ToolController.OnEquipped:Connect(function(tool)
		if tool.Name == "Security Cameras" then
			self:Show()
		end
	end)

	ToolController.OnUnequipped:Connect(function(tool)
		if tool.Name == "Security Cameras" then
			self:Hide()
		end
	end)

	function SecurityCameraController:CloseCamera(character, humanoid)
		CAMERA_UI.Camera.Visible = false
		CLOSE_BUTTON.Parent.Visible = false
		SecurityCameraController.UsingCams = false
		if Connection_Battery then
			Connection_Battery:Disconnect();
		end;
		CAMERA.CameraType = Enum.CameraType.Custom
		SecurityCameraService.OnCloseCamera:Fire()
		SecurityCameraController.VisibilityChanged:Fire(false)
		if character then
			if humanoid then
				workspace.CurrentCamera.CameraSubject = humanoid
			end
		end
		--StarterGui:SetCore("Backpack", true)
	end

	CLOSE_BUTTON.MouseButton1Click:Connect(function(cameraName, cameraCFrame)
		SecurityCameraController:CloseCamera()
	end)

	SecurityCameraService.OnCloseCamera:Connect(function(character, humanoid)
		SecurityCameraController:CloseCamera(character, humanoid)
	end)

	--CAMERA_UI.CloseCamera.NextCamera.MouseButton1Click:Connect(function()
	--	SecurityCameraService.NextCamera:Fire()
	--end)

	--CAMERA_UI.CloseCamera.LastCamera.MouseButton1Click:Connect(function()
	--	SecurityCameraService.LastCamera:Fire()
	--end)
end

function SecurityCameraController:ShowCamera(cameraObject, cameraName, cameraCFrame)
	if Connection_Battery then
		Connection_Battery:Disconnect();
	end;
	local currentConnection = nil;
	CAMERA_UI.Camera.Visible = true
	CAMERA.CameraType = Enum.CameraType.Scriptable
	CAMERA_UI.Camera.NameDisplay.Text = cameraName
	SecurityCameraController.VisibilityChanged:Fire(true)
	wait()
	StarterGui:SetCoreGuiEnabled("All", false)
	wait()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	currentConnection = cameraObject:GetAttributeChangedSignal("Battery"):Connect(function()
		if SecurityCameraController.UsingCams then
			CAMERA_UI.Camera["Battery Life"].Text = string.format("%s%%", tostring(math.ceil(cameraObject:GetAttribute("Battery"))));
			CAMERA_UI.Camera.Blackout.Visible = CAMERA_UI.Camera["Battery Life"].Text == "0%"
			if CAMERA_UI.Camera.Blackout.Visible then
				CAMERA.CFrame = CFrame.new(Vector3.new(1000, 1000, 1000))
			else
				CAMERA.CFrame = cameraCFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, -1.2)
			end
		else
			if currentConnection ~= nil then
				currentConnection:Disconnect()
			end
		end
	end)
	Connection_Battery = currentConnection
	CAMERA_UI.Camera["Battery Life"].Text = string.format("%s%%", tostring(math.ceil(cameraObject:GetAttribute("Battery"))));
	CAMERA_UI.Camera.Blackout.Visible = CAMERA_UI.Camera["Battery Life"].Text == "0%"
	if CAMERA_UI.Camera.Blackout.Visible then
		CAMERA.CFrame = CFrame.new(Vector3.new(1000, 1000, 1000))
	else
		CAMERA.CFrame = cameraCFrame * CFrame.Angles(0, math.rad(180), 0) * CFrame.new(0, 0, -1.2)
	end
end

function SecurityCameraController:UpdateUI()

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
			currentElem = self:CreateFromTemplate(cam.name, elemText)
		else
			currentElem.Reason.Text = elemText 
		end

		self:SetStyle(currentElem, level)
		currentElem.Name = cam.name
		currentElem.Parent = LIST
		currentElem.Visible = true
	end
end


function SecurityCameraController:CreateFromTemplate(cameraName, text)
	local SecurityCameraService = Knit.GetService("SecurityCameraService")
	
	local NotificationController;
	repeat task.wait();
		NotificationController = Knit.GetController("NotificationController");
	until NotificationController;

	local newItem = LIST_TEMPLATE:Clone()
	newItem.Reason.Text = text
	newItem.MouseButton1Click:Connect(function()
		if cameraName == self.CurrentCamera then
			print("NOT OPENING CAM")
			return
		end

		local secondsLeft = tick() - LAST_SWITCH
		print(secondsLeft)
		if secondsLeft >= DELAY_SWITCH_TIME then
			CLOSE_BUTTON.Parent.Visible = true
			SecurityCameraController.UsingCams = true
			LAST_SWITCH = tick()
			SecurityCameraService:OpenCamera(cameraName)
		else
			NotificationController:ShowNotification(3, "You must wait "..math.round(DELAY_SWITCH_TIME - secondsLeft).." seconds.", Color3.fromRGB(255, 0, 0))
		end
		--prevent ddosing server and xp farming
	end)
	return newItem
end

function SecurityCameraController:SetStyle(elem, styleType)
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

function SecurityCameraController:RefreshCameras()
	local SecurityCameraService = Knit.GetService("SecurityCameraService")
	self.CamerasStatus = SecurityCameraService:GetCameras()	
end

function SecurityCameraController:StartUpdateLoop()
	coroutine.wrap(function()
		while true do

			self:RefreshCameras()
			self:UpdateUI()

			wait(5)
		end
	end)()
end

SecurityCameraController:StartUpdateLoop()

function SecurityCameraController:Show()
	GUI.Manager.Visible = true
end


function SecurityCameraController:Hide()
	GUI.Manager.Visible = false	
end


return SecurityCameraController