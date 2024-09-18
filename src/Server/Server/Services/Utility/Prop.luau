local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Props = game.Workspace.Scripted.Props

local PropService = Knit.CreateService({
	Name = "PropService",
	Props = {}
})


function PropService:KnitStart()
	
	for _, prop in pairs(Props:GetChildren()) do
		PropService.Props[prop.Name] = prop:Clone()
	end
	
	function PropService:Add(player, propName)
		local prop = PropService.Props[propName]:Clone()
		player.Character.Humanoid:AddAccessory(prop)
		return prop
	end
	
	
end


return PropService