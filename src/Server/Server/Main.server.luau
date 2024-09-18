local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Systems = script.Parent.Services

local AllModules = {}

if game.PlaceId == 7027296354 then
	print("GAME IS LIVE VERSION");
else
	print("GAME IS PTS VERSION");
end;
--Init all module scripts
local function addModules(inst)
	if inst:IsA("Folder") then
		for _, module in pairs(inst:GetDescendants()) do
			if module:GetAttribute("Disabled") then
				local name = module:GetFullName()
				warn("Service ["..name.."] is disabled!")
				continue
			end
			
			if module:GetAttribute("Debug") or module:GetAttribute("Debug_Print") or module:GetAttribute("Debug_Pathfinding") then
				warn(string.format("%s HAVE DEBUG ENABLED", module:GetFullName()));
				if game.PlaceId == 7027296354 then
					module:SetAttribute("Debug", false);
					module:SetAttribute("Debug_Print", false);
					module:SetAttribute("Debug_Pathfinding", false);
				end;
			end;
			
			if module:IsA("ModuleScript") then
				table.insert(AllModules, {module, module:GetAttribute("Priority") or 1000})
			end
		end
	end
end;
addModules(Systems)

table.sort(AllModules, function(p1, p2) return p1[2] < p2[2] end)

for order, data in ipairs(AllModules) do
	-- require modules
	local success, result = pcall(require, data[1])
	if not success then
		warn("Failed to load module ["..data[1]:GetFullName().."]: "..result);
	else
		print(string.format("%s Loaded Service: %s", tostring(order), data[1].Name));
	end;
end;

Knit.Start():Catch(warn)