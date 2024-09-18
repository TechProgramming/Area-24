local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal);

local CollectionService = game:GetService("CollectionService");

local Documents = CollectionService:GetTagged("Document");

local DocumentService = Knit.CreateService({
	Name = "DocumentService",
	Client =
	{
		OnShowDocument = RemoteSignal.new(),
	},
});

function DocumentService:KnitStart()
	
	local NotificationService	= Knit.GetService("NotificationService");
	local ProfileService		= Knit.GetService("ProfileService");
	local LevelService			= Knit.GetService("LevelService");
	
	function self:ShowDocument(player, DocumentObject)
		
		local documentAlreadyExist = ProfileService:SaveDocument(player, DocumentObject.Name);
		ProfileService:UploadProfile(player);
		self.Client.OnShowDocument:Fire(player, DocumentObject);
		if not documentAlreadyExist then
			
			NotificationService:ShowNotification(player, 2, "You found a new document!", Color3.fromRGB(255, 255, 255))
			LevelService:AddXP(player, player.Team.Name, 100);
		end;
	end;
	
	for _, document in pairs(Documents) do
		document.ProximityPrompt.Triggered:Connect(function(player)
			self:ShowDocument(player, document);
		end);
	end;
end;

return DocumentService;