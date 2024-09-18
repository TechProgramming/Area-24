local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Systems = script.Parent.Controllers

local AllModules = {}

--Init all module scripts
local function addModules(inst)
	if inst:IsA("Folder") then
		for _, module in pairs(inst:GetChildren()) do
			if module:IsA("Folder") then
				addModules(module)
			elseif module:GetAttribute("Disabled") then
				local name = module:GetFullName()
				warn("Controller ["..name.."] is disabled!")
				continue
			elseif module:IsA("ModuleScript") then
				table.insert(AllModules, {module, module:GetAttribute("Priority") or 1000})
			end
		end
	end
end
addModules(Systems)
--for _,module in pairs(Systems:GetDescendants()) do
--end

table.sort(AllModules, function(p1, p2) return p1[2] < p2[2] end)

for _, data in ipairs(AllModules) do
	-- require modules
	local success, result = pcall(require, data[1])
	if not success then
		warn("Failed to load module ["..data[1]:GetFullName().."]: "..result)
	end
end

Knit.Start():Catch(warn)