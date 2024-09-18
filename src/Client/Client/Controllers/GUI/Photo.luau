local Knit = require(game:GetService("ReplicatedStorage").Knit);

local StarterGui = game:GetService("StarterGui");

local PLAYER = game:GetService("Players").LocalPlayer
local PHOTO_UI = PLAYER.PlayerGui:WaitForChild("Photo")

local PhotoController = Knit.CreateController({
	Name = "PhotoController"
})

function PhotoController:KnitStart()
	
	local PhotoService		= Knit.GetService("PhotoService")
	
	local ObjectivesController	= Knit.GetController("ObjectivesController");
	
	PhotoService.OnShowPhoto:Connect(function(photoObject)
		self:ShowPhoto(photoObject)
	end)

	PHOTO_UI.Frame.Close.MouseButton1Click:Connect(function()
		PHOTO_UI.Enabled = false
	end)
	
	function self:ShowPhoto(photoObject)
		
		PHOTO_UI.Frame.DisplayName.Text = photoObject:GetAttribute("DisplayName");
		PHOTO_UI.Frame.DisplayImage.Image = photoObject.BillboardGui.Thumbnail.Image;
		PHOTO_UI.Enabled = true
		PHOTO_UI.Frame.PickUp:Play()
		
		photoObject.Transparency = 1;
		photoObject.ProximityPrompt.Enabled = false;
		photoObject.PhotoImage.Transparency = 1;
		photoObject.BillboardGui.Enabled = false;
		
		ObjectivesController:DisplayPhoto(photoObject.Name);
	end
end

return PhotoController