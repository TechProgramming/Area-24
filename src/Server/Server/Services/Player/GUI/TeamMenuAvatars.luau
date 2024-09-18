local Knit = require(game:GetService("ReplicatedStorage").Knit)

local TeamMenuAvatars = Knit.CreateService({ 
	Name = "TeamMenuAvatars", 
})

local TEMP = script.Temp

local Avatars = {
	["Class - D"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} 
	},
	["Security Department"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" 
	},	
	["Engineering and Technical"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} 
	},
	["Chaos Insurgency"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" 
	},
	["Scientific Department"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} 
	},
	["Mobile Task Force"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  
	},
	["Site Director"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Site Director", Accessories = {}, Weapon = "Default"  
	},
	["Global Occult Coalition"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  
	},
	["O5 Council"] = { 
		Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council 7", Accessories = {}, Weapon = "Default"  
	},
}

function TeamMenuAvatars:KnitStart()

	local CharacterEditorService = Knit.Services.CharacterEditorService
	for team, avatarSetData in pairs(Avatars) do
		local temp = TEMP:Clone()
		temp.Name = team
		temp.Parent = game.ReplicatedStorage.TeamMenuAvatars
		CharacterEditorService.LoadMenuAvatar:Fire(temp, avatarSetData)
	end
	
end


return TeamMenuAvatars
