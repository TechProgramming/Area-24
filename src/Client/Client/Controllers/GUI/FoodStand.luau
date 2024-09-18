local Knit			= require(game:GetService("ReplicatedStorage").Knit)
local KnitSignal	= require(Knit.Util.Signal)

local StarterGui = game:GetService("StarterGui");

local PLAYER = game:GetService("Players").LocalPlayer
local FOODSTAND_UI = PLAYER.PlayerGui:WaitForChild("FoodStand")
--local SOUNDS = game:GetService("SoundService"):WaitForChild("MainMenu")

local FoodStandController = Knit.CreateController({
	Name = "FoodStandController",
	VisibilityChanged = KnitSignal.new(),
})

local ViewCoordinates = script.ViewCoordinates
local function prepareViewportFrame(viewport, model, category)
	
	local CFrameLook = CFrame.new(Vector3.new(0, 0, 2.5), Vector3.new(0,0,0))
	
	local coords = ViewCoordinates:FindFirstChild(category)
	if coords then
		CFrameLook = CFrame.new(coords.Value, Vector3.new(0,0,0))
	end
	
	if not viewport.CurrentCamera then
		
		local camera = Instance.new("Camera", viewport)
		viewport.CurrentCamera = camera
	end
	viewport.CurrentCamera.CFrame = CFrameLook
	
	if viewport:FindFirstChild("Object") then
		viewport.Object:Destroy()
	end
	
	local copyModel = model:Clone();
	
	copyModel.Name = "Object"
	copyModel.PrimaryPart = model.Handle;
	copyModel:PivotTo(CFrame.new());
	copyModel.Parent = viewport;
end

local CurrentDesiredFood = ""

function FoodStandController:KnitStart()
	local FoodStandService = Knit.GetService("FoodStandService")
	local ItemService = Knit.GetService("ItemService")
	local SFXController = Knit.GetController("SFXController")
	
	local currentShop = ""
	
	function FoodStandController:DisplayShop(shop)
		FOODSTAND_UI.Container.Title.Text = shop
		
		local displayListTemp = FOODSTAND_UI.Container.Template:Clone()
		for _, item in pairs(FOODSTAND_UI.Container.Items:GetChildren()) do
			if item:IsA("ImageButton") then
				item:Destroy()
			end
		end

		local foodData = ItemService:GetFoods(shop)
		--print("FOOD", shop, foodData)
		for name, data in pairs(foodData) do
			
			data.Name = name
			data.Model = game.ReplicatedStorage.Food[data.Category][data.SubCategory][name]
			local newButton = displayListTemp:Clone()
			--newButton.Icon.Image = data.Icon
			newButton.FoodName.Text = name
			--newButton.FoodName.UIGradient.Color = data.TextGradient
			newButton.Visible = true
			newButton.Parent = FOODSTAND_UI.Container.Items
			newButton.MouseButton1Down:Connect(function()
				
				SFXController:PlayPrefab("ButtonClick")
				prepareViewportFrame(FOODSTAND_UI.Container.Display.Thumbnail, data.Model, data.Category)
				FOODSTAND_UI.Container.Display.Explanation.Text = "Test"--data.Explanation
				FOODSTAND_UI.Container.Display.Purchase.Text = "Purchase ($"..data.Price..")"
				CurrentDesiredFood = data
			end)

			newButton.MouseEnter:Connect(function()
				SFXController:PlayPrefab("ButtonHover")
			end)

			CurrentDesiredFood = data
		end;
		prepareViewportFrame(FOODSTAND_UI.Container.Display.Thumbnail, CurrentDesiredFood.Model, CurrentDesiredFood.Category)
		FOODSTAND_UI.Container.Display.Explanation.Text = "Test"--data.Explanation
		FOODSTAND_UI.Container.Display.Purchase.Text = "Purchase ($"..CurrentDesiredFood.Price..")"
	end
	
	FOODSTAND_UI.Container.Display.Purchase.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		if FOODSTAND_UI.Container.Items.Visible then
			FoodStandService:Purchase(CurrentDesiredFood.Name)
		end
	end)
	
	FOODSTAND_UI.Container.Display.Purchase.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
	
	FoodStandService.OnFoodStandOpen:Connect(function(shopName)
		currentShop = shopName
		self:DisplayShop(currentShop)
		FOODSTAND_UI.Enabled = true
		self.VisibilityChanged:Fire(true)
	end)
	
	
	function FoodStandController:Show()
		FOODSTAND_UI.Enabled = true
		self.VisibilityChanged:Fire(true)
	end
	
	function FoodStandController:Hide()
		FOODSTAND_UI.Enabled = false
		self.VisibilityChanged:Fire(false)
	end
	
	FOODSTAND_UI.Container.Close.Close.MouseButton1Down:Connect(function()
		FoodStandController:Hide()
	end)
	
	FOODSTAND_UI.Container.Close.Close.MouseEnter:Connect(function()
		SFXController:PlayPrefab("ButtonHover")
	end)
end


return FoodStandController