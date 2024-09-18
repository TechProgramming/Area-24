local Knit = require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal = require(Knit.Util.Signal)

local CollectionService = game:GetService("CollectionService");
local StarterGui = game:GetService("StarterGui")

local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")
local PLAYER = game:GetService("Players").LocalPlayer
local OBJECTIVES_UI = PLAYER.PlayerGui:WaitForChild("Objectives");
local DOCUMENT_UI = PLAYER.PlayerGui:WaitForChild("Document");

local Photos = CollectionService:GetTagged("Photo");
local PhotoContainer = game.Workspace.Scripted.Photo;

local Documents = CollectionService:GetTagged("Document");
local DocumentContainer = game.Workspace.Scripted.Document;

local TabsSystem = require(script.TabsSystem)

local ObjectivesController = Knit.CreateController({
	Name = "ObjectivesController",
	VisibilityChanged = KnitSignal.new(),
})

function ObjectivesController:KnitStart()
	
	local ProfileService	= Knit.GetService("ProfileService")
	
	local profile = ProfileService:GetProfile()
	local photoDictionary = {}
	
	local photoTemp		= OBJECTIVES_UI.Temps.Photo;
	local documentTemp	= OBJECTIVES_UI.Temps.Document;
	
	function self:DisplayPhoto(photoId)
		
		local object = OBJECTIVES_UI.Container.Photos:FindFirstChild(photoId);
		if not object then
			object = photoTemp:Clone();
			object.Visible = true;
			object.Name = photoId;
			object.Parent = OBJECTIVES_UI.Container.Photos;
		end;
		object.Missing.Visible = false;
		object.PhotoName.Text = PhotoContainer[photoId]:GetAttribute("DisplayName");
		object.Photo.Image = PhotoContainer[photoId].BillboardGui.Thumbnail.Image;
	end
	
	function self:DisplayDocument(documentId)
		
		local object = OBJECTIVES_UI.Container.Files:FindFirstChild(documentId);
		if not object then
			object = documentTemp:Clone();
			object.Visible = true;
			object.Name = documentId;
			object.Parent = OBJECTIVES_UI.Container.Files;
		end;
		object.FileName.TextColor3 = Color3.fromRGB(255, 255, 255);
		object.FileName.Text = DocumentContainer[documentId]:GetAttribute("DisplayName");
		object.MouseButton1Click:Connect(function()
			
			DOCUMENT_UI.Container.DisplayName.Text = DocumentContainer[documentId]:GetAttribute("DisplayName");
			DOCUMENT_UI.Container.DisplayTextContainer.DisplayText.Text = require(DocumentContainer[documentId].Data).File;
			DOCUMENT_UI.Enabled = true
		end);
	end
	
	for _, photo in pairs(Photos) do
		
		local photoObject = photoTemp:Clone();
		photoObject.Visible = true;
		photoObject.Name = photo.Name;
		photoObject.Parent = OBJECTIVES_UI.Container.Photos;
	end;
	
	for _, photoId in pairs(profile.Photos) do
		
		local targetObject = PhotoContainer:FindFirstChild(photoId);
		if targetObject then
			
			self:DisplayPhoto(photoId);
			targetObject.Transparency = 1;
			targetObject.ProximityPrompt.Enabled = false;
			targetObject.PhotoImage.Transparency = 1;
			targetObject.BillboardGui.Enabled = false;
		end;
	end;
	
	for _, document in pairs(Documents) do
		
		local documentObject = documentTemp:Clone();
		documentObject.Visible = true;
		documentObject.Name = document.Name;
		documentObject.Parent = OBJECTIVES_UI.Container.Files;
	end;
	
	for _, documentId in pairs(profile.Documents) do
		
		local targetObject = DocumentContainer:FindFirstChild(documentId);
		if targetObject then
			
			self:DisplayDocument(documentId);
			targetObject.Transparency = 1;
			targetObject.ProximityPrompt.Enabled = false;
			targetObject.Decal.Transparency = 1;
		end;
	end;
	
	--local currentCategory = 
	--Register all button click events
	local MenuButtons = OBJECTIVES_UI.Container.MenuButtons
	for _, menuButton in pairs(MenuButtons:GetChildren()) do
		if menuButton:IsA("TextButton") then
			menuButton.MouseButton1Down:Connect(function()
				SOUNDS.Click:Play()
				if menuButton.Name ~= "Four" then
					TabsSystem:SwitchTab(menuButton.Name)
				else
					self:Hide()
				end
			end)
		end
	end
	
	function self:Show()
		OBJECTIVES_UI.Enabled = true
		TabsSystem:SwitchTab("One")
		self.VisibilityChanged:Fire(true)
	end
	
	function self:Hide()
		OBJECTIVES_UI.Enabled = false
		self.VisibilityChanged:Fire(false)
	end
	
	--EDITOR_UI.Done.MouseButton1Down:Connect(function()
	--	CharacterEditorController:Hide()
	--end)

	--CharacterEditorController:DisplayCategory(currentCategory)
end


return ObjectivesController