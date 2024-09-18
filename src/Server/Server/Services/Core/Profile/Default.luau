local WeaponFrameworkData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameData"):WaitForChild("WeaponsData"):WaitForChild("FrameworkData"))

local default = {}

local profile = {
	SaveNumber = 0,
	GameVersion = 1,
	AdminLevel = 0,
	Username = "N/A",
	UserId = 0,
	Cash = 100,
	Access = 1,
	Quest = {},
	NextQuestTime = 0,
	PurchasedCharacterSlots = 0,
	
	PlayTime = {
		["All"] = 0,
		["Class - D"] = 0,
		["Security Department"] = 0,
		["Engineering and Technical"] = 0,
		["Chaos Insurgency"] = 0,
		["Scientific Department"] = 0,
		["Mobile Task Force"] = 0,	
		["Site Director"] = 0,
		["Global Occult Coalition"] = 0,	
		["O5 Council"] = 0,		
	},
	CurrentAvatarSet = {
		["Class - D"] = 1,
		["Security Department"] = 1,
		["Engineering and Technical"] = 1,
		["Chaos Insurgency"] = 1,
		["Scientific Department"] = 1,
		["Mobile Task Force"] = 1,
		["Site Director"] = 1,
		["Global Occult Coalition"] = 1,
		["O5 Council"] = 1,	
	},
	LoginAward = {
		CurrentDay = 1,
		DaysCollected = 0,
		NextAwardTime = 0 -- Store Tick()
	},
	HelpMenuDisplayed = {
		["Class - D"] = false;
		["Engineering and Technical"] = false;
		["Scientific Department"] = false;
		["Security Department"] = false;
		["Mobile Task Force"] = false;
		["Site Director"] = false;
		["Global Occult Coalition"] = false;
		["O5 Council"] = false;
	},
	Gamepasses = {
		["Chaos Insurgency"] = false,
		["Mobile Task Force"] = false,
	},
	DevProducts = {
		
	},
	WeaponCustomisation = {
		--[[ Example:
			["Class - D"] = {AK74 = {Skin = "Default", Charm = "N/A", Stickers = {},}},
		--]]
	},
	AvatarSets = {
		["Class - D"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },	
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },				
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Class - D", Accessories = {} },	
		},
		["Security Department"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },	
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },		
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Security", Accessories = {}, Weapon = "Default" },			
		},	
		["Engineering and Technical"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },		
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },	
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Engineer", Accessories = {} },	
		},		
		["Chaos Insurgency"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },	
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },	
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Chaos Insurgency", Accessories = {}, Weapon = "Default" },	
			
		},		
		["Scientific Department"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Scientist", Accessories = {} },
		},
		["Mobile Task Force"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
		},	
		["Site Director"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "MTF", Accessories = {}, Weapon = "Default"  },
		},
		["O5 Council"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "O5 Council", Accessories = {}, Weapon = "Default"  },
		},
		["Global Occult Coalition"] = {
			[1] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
			[2] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },			
			[3] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
			-- PAID
			[4] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
			[5] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },			
			[6] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
			[7] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
			[8] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },			
			[9] = { Face = "Random", Hair = "Random", SkinTone = "Random", Outfit = "Global Occult Coalition", Accessories = {}, Weapon = "Default"  },
		},
	},
	Documents = {},
	Photos = {},
	SCPData = {
		["173"] = {
			Contained = 0
		}
	},
	Progress = {
		["Class - D"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Scientific Department"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Security Department"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Engineering and Technical"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Chaos Insurgency"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Mobile Task Force"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Site Director"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["Global Occult Coalition"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
		["O5 Council"] = {
			Level = 0, -- For Display Purposes Only
			XP = 0
		},
	},
	PurchasedItems = {
		
	},
}

-- Weapon customisation
for teamName, _ in pairs(profile.CurrentAvatarSet) do
	profile.WeaponCustomisation[teamName] = {}
	for charSlot = 1, 9 do
		profile.WeaponCustomisation[teamName][charSlot] = {}
		for weaponName, _ in pairs(WeaponFrameworkData.weaponsSettings) do
			profile.WeaponCustomisation[teamName][charSlot][weaponName] = {Skin = "Default", Charm = "N/A", Stickers = {}}
		end
	end
end

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function default:Create()
	return deepCopy(profile)
end

function default:Get()
	return profile
end


return default
	
