local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local DebrisService = game:GetService("Debris")
local VentService = Knit.CreateService({
	Name = "VentService",
	Client = {
		OnToggle = RemoteSignal.new(),
	},
	OpenVents = {},
	AnnouncementCooldown = 300,
})


function VentService:KnitStart()
	local NotificationService = Knit.Services.NotificationService
	local LightsService = Knit.Services.LightsService
	local JobService = Knit.Services.JobService
	local TerminationService = Knit.Services.TerminationService
	local IntercomService = Knit.Services.IntercomService

	local vents = CollectionService:GetTagged("Vent")
	
	for _,vent in pairs(vents) do
		local prompt = vent.Config.Prompt.Value
		
		--Check if player did boop
		prompt.Triggered:Connect(function(player)
			if not prompt.Enabled then
				return
			end
			
			--Check if character
			local character = player.Character
			if not character then
				return
			end
			
			if self:IsOpen(vent) then
				
				if player.Team.Name ~= "Engineering and Technical" and player.Team.Name ~= "Site Director" then
					Knit.Services.NotificationService:ShowNotification(player, 5, "Only E&T can repair the vent!", Color3.fromRGB(255, 55, 55))
					return 
				end
				
				self:ShowVent(vent.Config, vent)
				JobService:Award(player, true)
				LightsService:SetEmergencySpinLight(vent.EmergencyLight, false)
				vent.EmergencyLight.Base.Alarm:Stop()
			else
				if player.Team.Name ~= "Class - D" and player.Team.Name ~= "Chaos Insurgency" then
					Knit.Services.NotificationService:ShowNotification(player, 5, "Only Class - D or Chaos Insurgency can unscrew the vent!", Color3.fromRGB(255, 55, 55))
					return 
				end
				
				--Check if player has screwdriver out
				local screwdriver = self:HasScrewdriver(player)
				if not screwdriver then
					Knit.Services.NotificationService:ShowNotification(player, 5, "You require a screwdriver to perform that action!", Color3.fromRGB(255, 55, 55))
					return
				end
			
				if player.Team.Name == "Class - D" then
					TerminationService:Set(player, true)
				end
				--screwdriver:Destroy()
				DebrisService:AddItem(screwdriver, 0)
				LightsService:SetEmergencySpinLight(vent.EmergencyLight, true)
				vent.EmergencyLight.Base.Alarm:Play()
				
				if self.AnnouncementCooldown > 300 then
					self.AnnouncementCooldown = 0
					IntercomService:Play("Vented")
				end
				
				self:HideVent(vent.Config, vent)--.Config.ItemToHide.Value
				
				local players = game:GetService("Teams")["Engineering and Technical"]:GetPlayers()
				for _, plr in pairs(players) do
					Knit.Services.NotificationService:ShowNotification(plr, 5, "Vent '"..vent.Name.."' has been opened!", Color3.fromRGB(255, 55, 55))
				end
				local players = game:GetService("Teams")["Site Director"]:GetPlayers()
				for _, plr in pairs(players) do
					Knit.Services.NotificationService:ShowNotification(plr, 5, "Vent '"..vent.Name.."' has been opened!", Color3.fromRGB(255, 55, 55))
				end				
			end
		end)
	end
	
	while true do
		wait(1)
		self.AnnouncementCooldown = self.AnnouncementCooldown+1
	end
end


function VentService:IsOpen(vent) 
	for _, openVent in pairs(self.OpenVents) do
		if openVent == vent then
			return true
		end
	end	
	
	return false
end


function VentService:RemoveOpen(vent)
	for index, openVent in pairs(self.OpenVents) do
		if openVent == vent then
			table.remove(self.OpenVents, index)
			return
		end
	end	
end


function VentService:ShowVent(config, vent)
	self:RemoveOpen(vent)
	config.Prompt.Value.ActionText = "Unscrew"
	vent.Prompt.Transparency = 0
	vent.Prompt.CanCollide = true
	if vent:IsA("BasePart") then
		vent.Transparency = 0
		vent.CanCollide = true
	end
	
	local ventMesh = vent:FindFirstChild("MeshPart")
	if ventMesh then
		ventMesh.Transparency = 0
		ventMesh.CanCollide = true
	end
	--local items = vent:GetDescendants()
	--for _,item in pairs(items) do
	--	if item:IsA("BasePart") then
	--		item.Transparency = 0
	--		item.CanCollide = true
	--	end
	--end
	config.Prompt.Value.Enabled = true
end


function VentService:HideVent(config, vent)
	table.insert(self.OpenVents, vent)
	config.Prompt.Value.ActionText = "Repair"
	vent.Prompt.Transparency = 1
	vent.Prompt.CanCollide = false
	if vent:IsA("BasePart") then
		vent.Transparency = 1
		vent.CanCollide = false
	end
	local ventMesh = vent:FindFirstChild("MeshPart")
	if ventMesh then
		ventMesh.Transparency = 1
		ventMesh.CanCollide = false
	end
	--local items = vent:GetDescendants()
	--for _,item in pairs(items) do
	--	if item:IsA("BasePart") then
	--		item.Transparency = 1
	--		item.CanCollide = false
	--	end
	--end
end


function VentService:HasScrewdriver(player)
	--Check character
	local character = player.Character

	return character:FindFirstChild("Screwdriver")
end


function VentService.Client:GetVents()
	local vents = {} -- { name, isOpen }

	local tagged = CollectionService:GetTagged("Vent")
	for _, vent in pairs(tagged) do
		local open = VentService:IsOpen(vent)

		table.insert(vents, { 
			name = vent.Name, 
			isOpen = open,
		})
	end

	return vents
end


return VentService