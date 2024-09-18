local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local CollectionService	= game:GetService("CollectionService")

local CameraSeats		= CollectionService:GetTagged("CameraSeat")
local CameraViewModels	= game.Workspace.Scripted.Cameras.Views
local CameraPowerbox	= game.Workspace.Scripted.Cameras.Powerbox;

local SecurityCameraService = Knit.CreateService({
	Name = "SecurityCameraService",
	Client = {
		OnOpenCamera	= RemoteSignal.new(),
		OnCloseCamera	= RemoteSignal.new(),
		OnSwitchCamera	= RemoteSignal.new(),
		NextCamera		= RemoteSignal.new(),
		LastCamera		= RemoteSignal.new(),
	},
})

local CameraIndex = {}
local CameraIndexByName = {}

for _, cameraView in pairs(CameraViewModels:GetChildren()) do
	table.insert(CameraIndex, cameraView.Name)
end

for _, cameraView in pairs(CameraViewModels:GetChildren()) do
	CameraIndexByName[cameraView.Name] = cameraView
end

local CameraIndexMax = #CameraIndex

local PlayersCamera = {}

function SecurityCameraService.Client:OpenCamera(player, cameraName)
	SecurityCameraService:OpenCamera(player, cameraName)
end

function SecurityCameraService:KnitStart()

	local ProfileService = Knit.Services.ProfileService
	local EmoteService = Knit.Services.EmoteService
	local LevelService = Knit.Services.LevelService
	local NotificationService = Knit.Services.NotificationService
	local QuestService = Knit.Services.QuestService
	local JobService = Knit.Services.JobService
	local CashService = Knit.Services.CashService
	local TerminationService = Knit.Services.TerminationService
	--for _, cameraSeat in pairs(CameraSeats) do
	--	cameraSeat.ProximityPrompt.Triggered:Connect(function(player)

	--		cameraSeat:SetAttribute("InUse", true)
	--		cameraSeat.ProximityPrompt.Enabled = false
	--		self:OpenCamera(player, cameraSeat)
	--	end)
	--end


	for _, powerbox in pairs(CameraPowerbox:GetChildren()) do
		local jobCharacter = powerbox.Character
		powerbox.Trigger.ProximityPrompt.Triggered:Connect(function(player)
			local team = player.Team
			local foundation = team:GetAttribute("Foundation")
			local engineer = team:GetAttribute("Engineer")
			local wirecutterTool = player.Character:FindFirstChild("Wirecutter")
			if not engineer and not wirecutterTool then
				return NotificationService:ShowNotification(player, 3, "You must be an Engineer to fix this!",  Color3.fromRGB(255, 42, 0))		
			end
			if wirecutterTool and foundation then
				return NotificationService:ShowNotification(player, 3, "You can not damage facility property!",  Color3.fromRGB(255, 42, 0))	
			end
			powerbox.Trigger.ProximityPrompt.Enabled = false
			local success, errorM = pcall(function()
				player.Character.Humanoid.WalkSpeed = 0
				player.Character.HumanoidRootPart.CFrame = jobCharacter.HumanoidRootPart.CFrame
				JobService:Award(player)
				EmoteService:Play(player, "Wires")
				local actionText = "You finished repairing!"
				wait(3)
				powerbox.Trigger.ProximityPrompt.Enabled = true
				if wirecutterTool then
					wirecutterTool:Destroy()
					CameraViewModels[powerbox.Name]:SetAttribute("Battery", 0);
					actionText = "Camera disabled!"
					if player.Team.Name == "Class - D" then
						TerminationService:Set(player, true)
					end
				else
					CameraViewModels[powerbox.Name]:SetAttribute("Battery", 100);
				end
				EmoteService:Stop(player)
				player.Character.Humanoid.WalkSpeed = 16
				NotificationService:ShowNotification(player, 3, actionText, Color3.fromRGB(41, 255, 141))
			end)
			powerbox.Trigger.ProximityPrompt.Enabled = true
		end);
	end;

	--self.Client.NextCamera:Connect(function(player)

	--	local cameraSeat = PlayersCamera[player]
	--	local currentCamera = cameraSeat:GetAttribute("CurrentCamera")
	--	local nextCamera = currentCamera + 1
	--	if nextCamera >= (CameraIndexMax + 1) then
	--		nextCamera = 1
	--	end
	--	cameraSeat:SetAttribute("CurrentCamera", nextCamera)
	--	self:OpenCamera(player, cameraSeat)
	--end)

	--self.Client.LastCamera:Connect(function(player)

	--	local cameraSeat = PlayersCamera[player]
	--	local currentCamera = cameraSeat:GetAttribute("CurrentCamera")
	--	local nextCamera = currentCamera - 1
	--	if nextCamera == 0 then
	--		nextCamera = CameraIndexMax
	--	end
	--	cameraSeat:SetAttribute("CurrentCamera", nextCamera)
	--	self:OpenCamera(player, cameraSeat)
	--end)

	SecurityCameraService.Client.OnOpenCamera:Connect(function(player)

	end)

	SecurityCameraService.Client.OnCloseCamera:Connect(function(player)

		--if PlayersCamera[player] ~= nil then

		--	local cameraSeat = PlayersCamera[player]
		--	cameraSeat:SetAttribute("InUse", false)
		--	cameraSeat.ProximityPrompt.Enabled = true
		--	player.Character.Humanoid.Jump = true
		--end
	end)

	ProfileService.CharacterAdded:Connect(function(player, character)
		repeat wait() until character:FindFirstChildOfClass("Humanoid")
		self.Client.OnCloseCamera:Fire(player, character, character:FindFirstChildOfClass("Humanoid"))
	end)

	ProfileService.PlayerRemoving:Connect(function(player, character)
		--	self.Client.OnCloseCamera:Fire(player)
	end)

	coroutine.wrap(function()
		for _, cameraView in pairs(CameraViewModels:GetChildren()) do
			cameraView:SetAttribute("Battery", 100);
			cameraView:GetAttributeChangedSignal("Battery"):Connect(function()
				CameraPowerbox[cameraView.Name].Trigger.BillboardGui.DisplayText.Text = math.ceil(cameraView:GetAttribute("Battery")).."%"
				local battery = cameraView:GetAttribute("Battery");
				if battery <= 0 and cameraView.Light.SpotLight.Enabled then
					cameraView.Light.Color = Color3.fromRGB(0, 0, 0)
					cameraView.Light.SpotLight.Enabled = false

					--Send notification
					local players = game:GetService("Teams")["Engineering and Technical"]:GetPlayers()
					for _, plr in pairs(players) do
						Knit.Services.NotificationService:ShowNotification(plr, 5, "Camera '"..cameraView.Name.."' has ran out of energy!", Color3.fromRGB(255, 55, 55))
					end
					local players = game:GetService("Teams")["Site Director"]:GetPlayers()
					for _, plr in pairs(players) do
						Knit.Services.NotificationService:ShowNotification(plr, 5, "Camera '"..cameraView.Name.."' has ran out of energy!", Color3.fromRGB(255, 55, 55))
					end					
				elseif battery > 0 and not cameraView.Light.SpotLight.Enabled then
					cameraView.Light.Color = Color3.fromRGB(15, 255, 91)
					cameraView.Light.SpotLight.Enabled = true							
				end
			end)
		end 	
		while true do wait(3);
			for _, cameraView in pairs(CameraViewModels:GetChildren()) do
				cameraView:SetAttribute("Battery", math.clamp(cameraView:GetAttribute("Battery") - (math.random(1, 2)/10), 0, 100));
			end 
		end;
	end)();
end

--function SecurityCameraService:OpenCamera(player, cameraSeat)
--	local JobService = Knit.Services.JobService
--	local cameraNum		= cameraSeat:GetAttribute("CurrentCamera")
--	local cameraName	= CameraIndex[cameraNum]
--	local cameraObject	= CameraViewModels[cameraName]
--	PlayersCamera[player] = cameraSeat
--	local seat = cameraSeat.Seat
--	seat:Sit(player.Character.Humanoid)
--	JobService:Award(player)
--	player:RequestStreamAroundAsync(cameraObject.CameraBody.Position)
--	self.Client.OnOpenCamera:Fire(player, cameraObject, cameraName, cameraObject.CameraBody.CFrame)
--end

function SecurityCameraService:OpenCamera(player, cameraName)
	print(player, cameraName)
	local cameraObject	= CameraViewModels[cameraName]
	player:RequestStreamAroundAsync(cameraObject.CameraBody.Position)
	self.Client.OnOpenCamera:Fire(player, cameraObject, cameraName, cameraObject.CameraBody.CFrame)
	local JobService = Knit.Services.JobService
	JobService:Award(player, false, false, "Camera")
end

function SecurityCameraService.Client:GetCameras()
	local cams = {} -- {name, battery}

	for _, camera in pairs(CameraViewModels:GetChildren()) do
		local data = { 
			name = camera.Name,
			battery = camera:GetAttribute("Battery")
		}

		table.insert(cams, data)
	end

	return cams
end


return SecurityCameraService