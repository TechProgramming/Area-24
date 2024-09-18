local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local CollectionService = game:GetService("CollectionService")

local Photos = CollectionService:GetTagged("Photo")

local PhotoService = Knit.CreateService({
	Name = "PhotoService",
	Client = {
		OnShowPhoto = RemoteSignal.new()
	},
})

function PhotoService:KnitStart()
	
	local NotificationService	= Knit.GetService("NotificationService");
	local ProfileService		= Knit.GetService("ProfileService");
	local LevelService			= Knit.GetService("LevelService");
	
	--[[spawn(function()
		while wait(10) do
			if ActivePhoto == false then
				PhotoService:SpawnPhoto()
			elseif tick() - ActiveSince >= (60 * 5) then
				ActivePhoto.Transparency = 1
				ActivePhoto.PhotoImage.Transparency = 1
				ActivePhoto.ProximityPrompt.Enabled = false
				ActivePhoto = false
				
			end
		end
	end)
	
	function self:SpawnPhoto()
		local randomPhoto = Photos[math.random(1, #Photos)]
		randomPhoto.Transparency = 0
		randomPhoto.PhotoImage.Transparency = 0
		randomPhoto.ProximityPrompt.Enabled = true
		ActivePhoto = randomPhoto
		ActiveSince = tick()
	end]]
	
	function self:ShowPhoto(player, photoObject)
		
		local photoAlreadyExist = ProfileService:SavePhoto(player, photoObject.Name);
		ProfileService:Save(player);
		self.Client.OnShowPhoto:Fire(player, photoObject);
		if not photoAlreadyExist then
			
			NotificationService:ShowNotification(player, 2, "You found a new photo!", Color3.fromRGB(255, 255, 255))
			LevelService:AddXP(player, player.Team.Name, 100);
		end;
	end;
	
	for _, photo in pairs(Photos) do
		photo.ProximityPrompt.Triggered:Connect(function(player)
			self:ShowPhoto(player, photo);
		end);
	end;
end;

return PhotoService;