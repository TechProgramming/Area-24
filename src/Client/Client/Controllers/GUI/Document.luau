local Knit = require(game:GetService("ReplicatedStorage").Knit);

local StarterGui = game:GetService("StarterGui");

local PLAYER = game:GetService("Players").LocalPlayer;
local DOCUMENT_UI = PLAYER.PlayerGui:WaitForChild("Document");

local DocumentController = Knit.CreateController({
	Name = "DocumentController",
});

function DocumentController:KnitStart()
	
	local DocumentService		= Knit.GetService("DocumentService")
	
	local ObjectivesController	= Knit.GetController("ObjectivesController");
	
	DocumentService.OnShowDocument:Connect(function(DocumentObject)
		self:ShowDocument(DocumentObject)
	end)

	DOCUMENT_UI.Container.Close.MouseButton1Click:Connect(function()
		DOCUMENT_UI.Enabled = false
	end)
	
	function self:ShowDocument(DocumentObject)
		
		DOCUMENT_UI.Container.DisplayName.Text = DocumentObject:GetAttribute("DisplayName");
		DOCUMENT_UI.Container.DisplayTextContainer.DisplayText.Text = require(DocumentObject.Data).File;
		DOCUMENT_UI.Enabled = true
		DOCUMENT_UI.Container.PickUp:Play()
		
		DocumentObject.Transparency = 1;
		DocumentObject.ProximityPrompt.Enabled = false;
		DocumentObject.Decal.Transparency = 1;
		
		ObjectivesController:DisplayDocument(DocumentObject.Name);
	end
end

return DocumentController