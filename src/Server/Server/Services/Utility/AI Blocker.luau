local CollectionService = game:GetService("CollectionService")
local items = CollectionService:GetTagged("AI Blocker")
--local DebrisService = game:GetService("Debris")

function ApplyTo(part)
	if part:IsA("Decal") then
		part:Destroy()
		--DebrisService:AddItem(part, 0)
		return
	end

	if part:IsA("BasePart") then
		--Prevent falling through unloaded terrain
		if part.Parent.Name ~= "Spawns" and part.Parent.Name ~= "Walls" then
			part.CanCollide = false
		end
		part.Transparency = 1
	end

end

for _,item in pairs(items) do
	ApplyTo(item)

	local descendants = item:GetDescendants()
	for _,descendant in pairs(descendants) do
		ApplyTo(descendant)
	end
end

return {}