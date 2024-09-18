local EffectsModules = script.Parent
local FXStorage = EffectsModules.FXStorage

local InstanceModule = {}

function InstanceModule.CloneMesh(instanceName, properties) 
	local isCFrame = typeof(properties["Location"]) == "CFrame"
	local findInstance
	for _, object in pairs(FXStorage:GetChildren()) do
		if object.Name == instanceName then
			findInstance = object:Clone()
		end
	end
	if not findInstance then return end
	findInstance.Material = properties["Material"]
	findInstance.Color = properties["Color"]
	findInstance.Transparency = properties["Transparency"]
	findInstance.Size = properties["Size"]
	if isCFrame then
		findInstance.CFrame = properties["Location"]
	else
		findInstance.Position = properties["Location"]
	end
	findInstance.Anchored = true
	findInstance.CanCollide = false
	findInstance.Parent = properties["Parent"]
	game:GetService("Debris"):AddItem(findInstance, properties["DebrisTime"])
	return findInstance
end
function InstanceModule.CloneParticles(instanceName, parent, debrisTime) 
	local findInstance
	for _, object in pairs(FXStorage.Attachments:GetChildren()) do
		if object.Name == instanceName then
			findInstance = object:Clone()
		end
	end
	if not findInstance then return end
	findInstance.Parent = parent
	game:GetService("Debris"):AddItem(findInstance, debrisTime)
	return findInstance
end

return InstanceModule