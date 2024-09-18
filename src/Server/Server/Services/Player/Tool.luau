local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local ToolService = Knit.CreateService({ 
	Name = "ToolService", 
	Client = {
		OnActivated		= RemoteSignal.new(),
		OnDeactivated	= RemoteSignal.new(),
		OnEquipped		= RemoteSignal.new(),
		OnUnequipped	= RemoteSignal.new(),	
		OnAdded			= RemoteSignal.new(),
		OnRemoved		= RemoteSignal.new(),
	}
})

function ToolService:KnitStart()

	local ProfileService = Knit.Services.ProfileService
	local EmoteService = Knit.Services.EmoteService
	local AuthorizationService = Knit.Services.AuthorizationService
	local MedicKitService = Knit.Services.MedicKitService
	local VentService = Knit.Services.VentService
	local TransactionService = Knit.Services.TransactionService
	local TerminationService = Knit.Services.TerminationService
	local FPSService = Knit.Services.FPSService
	local GamepassService = Knit.Services.GamepassService
	
	local TeamTools = {
		["Chaos Insurgency"] = {
			"AK74",
			--"AK74",--"AK74 Red Dragon",
			--weapon,    skin    ,    stickers
			{"AK74", "Red Dragon", {"Red Dragon"}},
			"M1911",
			--"MP5"
		},
		["Security Department"] = {
			"AK74",
			"Security Cameras",
			"Medic Kit"
		},	
		["Mobile Task Force"] = {
			"AK74",
			"M1911",
			"Medic Kit"
		},	
		["Engineering and Technical"] = {
			"Engineer Task",
			--"M1911"
		},
		["Scientific Department"] = {
			"Authorizer",
			"Medic Kit",
			--"M1911"
		},
		["Site Director"] = {
			"Authorizer",
			"Engineer Task",
			"AK74",
			"SPAS12",
			"Security Cameras",
			"Medic Kit"
		},			
		["O5 Council"] = {
			"Authorizer",
			"Security Cameras",
			"SPAS12",
			{"AK74", "Obsidian"},--"AK74",--"AK74 Obsidian",
			"M1911",
			"Medic Kit",
			"Medic Kit"
		},		
		["Global Occult Coalition"] = {
			"AK74",
			"SPAS12",
			"Medic Kit",
			--"Screwdriver",
			--"Wirecutter",
		},		
		
		["Class - D"] = {
			--"AK74",
			--"M1911",	
		},		
	}
	
	

	ProfileService.CharacterAdded:Connect(function(player, character)
		local team = player.Team
		local teamTools = TeamTools[team.Name]
		if teamTools ~= nil then
			for _, itemId in pairs(teamTools) do
				local args = {}
				if typeof(itemId) == "table" then
					for i,v in ipairs(itemId) do
						if i==1 then continue end
						args[#args+1] = v
					end
					itemId = itemId[1]
				end
				--print(itemId, "ARGS", args)
				TransactionService:Award(player, itemId, unpack(args))
			end
		end
		
		local canHaveGamepassWeapons = team:GetAttribute("GamepassWeapons")
		local rank = player:GetRankInGroup(4889827)
		local highRank = rank > 9 
		if canHaveGamepassWeapons then
			if GamepassService:HasGamepass(player, "VIP") or highRank then
				--TransactionService:Award(player, "AK74 Red Dragon")
				--print("GAVE RED DRAGON")
				FPSService:ChangeWeaponSkin(player, "AK74", "Red Dragon", false, true)
				FPSService:AddWeaponSticker(player, "AK74", "Red Dragon", false, true)
				TransactionService:Award(player, "Medic Kit")
			end
		end
		
		local adminLevel = ProfileService:GetProfile(player).AdminLevel or 0
		if adminLevel > 0 then
			TransactionService:Award(player, "Authorizer")
		end
	end)
	

	ToolService.Process = {
		["Food"] = {
			OnActivated = function(player, tool)
				local actionAnimation = tool:GetAttribute("ActionAnimation")
				local track = EmoteService:Play(player, actionAnimation);
				if track then
					track.Stopped:Connect(function()
						EmoteService:Stop(player);
					end);
				end;
			end,
			OnDeactivated = function(player, tool)

			end,
			OnEquipped = function(player, tool)

			end,
			OnUnequipped = function(player, tool)

			end,
		},
		["Weapon"] = {
			OnActivated = function(player, tool)
				print("WEAPON WAS ACTIVATED!")
			end,
			OnDeactivated = function(player, tool)

			end,
			OnEquipped = function(player, tool)
				if player.Team.Name == "Class - D" then
					TerminationService:Set(player, tool:GetAttribute("MarkForTermination") or false)
				end
			end,
			OnUnequipped = function(player, tool)

			end,
		},		
		["Gear"] = {
			OnActivated = function(player, tool)

			end,
			OnDeactivated = function(player, tool)

			end,
			OnEquipped = function(player, tool)
				
				if tool.Name == "Authorizer" then
					AuthorizationService.Client.OnTogglePrompts:Fire(player, true, AuthorizationService.Prompts)
					--AuthorizationService.Client.OnToggleManager:Fire(player, true)
				elseif tool.Name == "Medic Kit" then
					MedicKitService.Client.OnTogglePrompts:Fire(player, true, MedicKitService.Prompts)
				elseif tool.Name == "Screwdriver" then
					VentService.Client.OnToggle:Fire(player, true)
				end
			end,
			OnUnequipped = function(player, tool)
				if tool.Name == "Authorizer" then
					AuthorizationService.Client.OnTogglePrompts:Fire(player, false, AuthorizationService.Prompts)
					AuthorizationService.Client.OnToggleManager:Fire(player, false)
					VentService.Client.OnToggle:Fire(player, false)
				elseif tool.Name == "Medic Kit" then
					MedicKitService.Client.OnTogglePrompts:Fire(player, false, MedicKitService.Prompts)
				end
			end,
		},		
	}

	ToolService.Client.OnActivated:Connect(function(player, tool)
		if tool == nil then return end
		local toolType = tool:GetAttribute("ToolType")
		--print("ACTIVATE", tool, toolType)

		if toolType ~= nil then
			ToolService.Process[toolType].OnActivated(player, tool)
		end
	end)

	ToolService.Client.OnDeactivated:Connect(function(player, tool)
		if tool == nil then return end
		local toolType = tool:GetAttribute("ToolType")
		if toolType ~= nil then
			ToolService.Process[toolType].OnDeactivated(player, tool)
		end
	end)

	ToolService.Client.OnEquipped:Connect(function(player, tool)
		if tool == nil then return end
		local toolType = tool:GetAttribute("ToolType")
		if toolType ~= nil then
			ToolService.Process[toolType].OnEquipped(player, tool)
		end
	end)

	ToolService.Client.OnUnequipped:Connect(function(player, tool)
		if tool == nil then return end
		local toolType = tool:GetAttribute("ToolType")
		if toolType ~= nil then
			ToolService.Process[toolType].OnUnequipped(player, tool)
		end
	end)

	function ToolService:Add(player, tool, destination, ...)
		--print("LISTENING TO", tool)
		tool.Parent = destination
		ToolService.Client.OnAdded:Fire(player, tool)
		if tool:GetAttribute("ToolType") == "Weapon" then
			local args = {...}
			local skin, stickers
			if #args > 0 then
				skin = args[1]
				stickers = args[2]
			end
			if skin ~= nil then
				tool:SetAttribute("Skin", skin)
			end
			if stickers ~= nil and #stickers > 0 then
				local stickersIds = nil
				for i, v in ipairs(stickers) do
					if stickersIds then
						stickersIds = stickersIds .. "_" .. v
					else
						stickersIds = v
					end
				end
				tool:SetAttribute("Stickers", stickersIds)
			else
				tool:SetAttribute("Stickers", "")
			end
			--print("TOOLSERVICE", skin, stickers, args)
			FPSService:AddWeapon(player, tool:GetAttribute("WeaponName"), tool)
		end
	end

end


return ToolService