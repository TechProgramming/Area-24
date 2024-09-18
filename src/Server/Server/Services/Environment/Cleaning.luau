local Knit = require(game:GetService("ReplicatedStorage").Knit)
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

--Vars
--Stain
local STAIN_COOLDOWN = 120 		--How often an attempt to create a stain should happen
local STAIN_CHANCE = 10 		--The chance of a stain spawning every time STAIN_COOLDOWN ends
local STAIN_HOLD_DURATION = 1 	--Stain prompt hold duration
local STAIN_MOP_DURATION = 3 	--How long a player should mop for

--Goo
local GOO_CLEAN_HOLD_DURATION = 1 -- Clean prompt hold duration
local GOO_LOWER_RATE = 120 -- Seconds for goo to fully lower
local GOO_PROMPT_ENABLE_TIME = 50 -- Seconds after goo lowers that clean prompt should be triggered
local GOO_CLEANING_DURATION = 3 -- Amount of time in seconds that the player should show goo clean animation
----

local GOO_GROUPS = CollectionService:GetTagged("GooGroup")
local STAIN_PARTS = CollectionService:GetTagged("Stain")

local CleaningService = Knit.CreateService({
	Name = "CleaningService",
	Client = {},
	Stains = {},
	GooGroups = {},
})


function CleaningService:KnitStart()
	local PropService = Knit.GetService("PropService")
	local EmoteService = Knit.GetService("EmoteService")
	local JobService = Knit.GetService("JobService")
	
	--Initialize parts
	for _, stain in pairs(STAIN_PARTS) do
		local decal = stain.Stain
		decal.Transparency = 1
		
		--Create prompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Prompt"
		prompt.ActionText = "Clean Stain"
		prompt.ObjectText = "Stain"
		prompt.HoldDuration = STAIN_HOLD_DURATION
		prompt.Enabled = false
		prompt.Parent = stain
		
		prompt.Triggered:Connect(function(plr)
			local char = plr.Character
			if not char then
				return
			end
			
			prompt.Enabled = false
			decal.Transparency = 1
			char.HumanoidRootPart.Anchored = true			
			
			local mop = PropService:Add(plr, "Mop")
			EmoteService:Play(plr, "Mop")
			
			task.wait(STAIN_MOP_DURATION)
			EmoteService:Stop(plr)
			
			if mop then
				mop:Destroy()
			end
			
			if char then
				char.HumanoidRootPart.Anchored = false
			end
			
			JobService:Award(plr)
		end)
		
		table.insert(self.Stains, decal)
	end
	
	--Initialize Goo
	for _, gooGroup in pairs(GOO_GROUPS) do
		
		for _, part in pairs(gooGroup:GetChildren()) do
			if part.Name == "goo" then
				part.Anchored = false
			end
		end
		
		--Clean prompt
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Clean Goo"
		prompt.ObjectText = "Goo"
		prompt.HoldDuration = GOO_CLEAN_HOLD_DURATION
		prompt.Parent = gooGroup.PromptContainer
		prompt.Enabled = false
		
		--Register goo
		local gooData = {
			prompt = prompt,
			promptRegistered = false,
			timeSinceStartedLowering = 0,
			tween = nil,
			clean = true,
			gooEndCFrame = gooGroup.GooPrimary.CFrame
		}
		
		gooGroup.GooPrimary.CFrame = gooGroup.GooStart.CFrame
		self.GooGroups[gooGroup] = gooData
	end
	
	
	local stainCooldownCountdown = STAIN_COOLDOWN
	
	while true do
		task.wait(1)
		
		--Stain
		stainCooldownCountdown = stainCooldownCountdown-1
		
		if stainCooldownCountdown >= 0 then
			stainCooldownCountdown = STAIN_COOLDOWN
			
			--test for stain
			local result = math.random(0, 100)
			if result <= STAIN_CHANCE then
				self:SpawnStain()
			end
		end
		
		
		--Goo
		for gooGroup, gooData in pairs(self.GooGroups) do
			if not gooData.promptRegistered then
				gooData.prompt.Triggered:Connect(function(plr)
					if gooData.timeSinceStartedLowering < GOO_PROMPT_ENABLE_TIME then
						return
					end
					gooData.timeSinceStartedLowering = 0
					
					local char = plr.Character
					if not char then
						return
					end
					
					gooData.prompt.Enabled = false
					
					coroutine.wrap(function()
						EmoteService:Play(plr, "Wires")
						char.HumanoidRootPart.CFrame = gooData.prompt.Parent.CFrame
						char.HumanoidRootPart.Anchored = true
						
						
						if gooData.tween then
							gooData.tween:Cancel()
							gooData.tween = nil
						end
						
						task.wait(GOO_CLEANING_DURATION)
						
						char.HumanoidRootPart.Anchored = false
						EmoteService:Stop(plr)
						JobService:Award(plr)
						
						gooGroup.GooPrimary.CFrame = gooGroup.GooStart.CFrame
						gooData.clean = true
					end)()
				end)
				
				gooData.promptRegistered = true
			end
			
			if gooData.timeSinceStartedLowering >= GOO_PROMPT_ENABLE_TIME then
				gooData.prompt.Enabled = true
			else
				gooData.prompt.Enabled = false
			end
			
			--if cleaned, restart tween
			if gooData.clean then
				gooData.timeSinceStartedLowering = 0
				
				local tween = TweenService:Create(gooGroup.GooPrimary, TweenInfo.new(GOO_LOWER_RATE), { CFrame = gooData.gooEndCFrame})
				gooData.tween = tween
				tween:Play()
				
				gooData.clean = false
			end
			
			gooData.timeSinceStartedLowering = gooData.timeSinceStartedLowering+1
		end
	end
end


function CleaningService:SpawnStain()
	local stain = self.Stains[math.random(1, #self.Stains)]
	if stain.Transparency ~= 0 then
		stain.Parent.Prompt.Enabled = true
		stain.Transparency = 0
	end
end


return CleaningService