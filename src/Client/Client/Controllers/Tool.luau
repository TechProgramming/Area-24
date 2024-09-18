local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

local Signal = require(Knit.Util.Signal)

local PLAYER = game:GetService("Players").LocalPlayer

local CurrentlyEquippedTool = nil

local ToolController = Knit.CreateController({
	Name = "ToolController",

	OnActivated = Signal.new();
	OnDeactivated = Signal.new();
	OnEquipped = Signal.new();
	OnUnequipped = Signal.new();
	OnDestroyed = Signal.new();
})

function ToolController:GetIsToolEquipped(tool)
	return tool == CurrentlyEquippedTool
end

function ToolController:KnitStart()
	local ToolService = Knit.GetService("ToolService")

	ToolService.OnAdded:Connect(function(tool)
		tool.Activated:Connect(function()
			self.OnActivated:Fire(tool)
			ToolService.OnActivated:Fire(tool)
		end)
		tool.Deactivated:Connect(function()
			self.OnDeactivated:Fire(tool)
			ToolService.OnDeactivated:Fire(tool)
		end)
		tool.Equipped:Connect(function()
			CurrentlyEquippedTool = tool

			self.OnEquipped:Fire(tool)
			ToolService.OnEquipped:Fire(tool)
		end)
		tool.Unequipped:Connect(function()
			if CurrentlyEquippedTool == tool then
				CurrentlyEquippedTool = nil
			end

			self.OnUnequipped:Fire(tool)
			ToolService.OnUnequipped:Fire(tool)
		end)

		tool.Changed:Connect(function(property)
			if property == "Parent" then
				if tool.Parent == nil then
					self.OnDestroyed:Fire(tool)
				end
			end
		end)
	end)


end


return ToolController