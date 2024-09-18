local Knit = require(game:GetService("ReplicatedStorage").Knit)
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local PlayerService = game:GetService("Players")
local DebrisService = game:GetService("Debris")

local HOLD_DURATION = 10
local PROMPT_MAX_DISTANCE = 8


local MedicKitService = Knit.CreateService({ 
	Name = "MedicKitService", 
	Client = {
		OnTogglePrompts = RemoteSignal.new(),
	},
	Prompts = {}
})

function MedicKitService:HasMedicalKit(player)
	--Check character
	local character = player.Character

	return character:FindFirstChild("Medic Kit")
end

function MedicKitService:KnitStart()

	local ProfileService = Knit.GetService("ProfileService");
	local ToolService = Knit.GetService("ToolService")
	local EmoteService = Knit.GetService("EmoteService")
	
	
	ProfileService.CharacterAdded:Connect(function(player, character)
		local healScript = character:WaitForChild("Health", 3)
		if healScript then
			healScript:Destroy()
		end
		
		character:WaitForChild("Humanoid").Died:Connect(function()
			self.Prompts[player.UserId] = nil
		end)
		
		--Create prompt on character
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Medic Kit Prompt"
		prompt.ActionText = "Heal"
		prompt.ObjectText = player.DisplayName
		prompt.HoldDuration = HOLD_DURATION
		prompt.MaxActivationDistance = PROMPT_MAX_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = character.HumanoidRootPart
		
		prompt.Triggered:Connect(function(plr)
			self:Heal(plr, player)
		end)
		
		prompt.PromptButtonHoldBegan:Connect(function(plr)
			if not plr.Character then 
				return 
			end
			
			local targetPlr = PlayerService:GetPlayerFromCharacter(prompt.Parent.Parent)
			if not targetPlr then
				return
			end
			
			if targetPlr.UserId ~= plr.UserId then
				plr.Character.HumanoidRootPart.CFrame = CFrame.new(plr.Character.HumanoidRootPart.Position, character.HumanoidRootPart.Position)	
			end
			plr.Character.HumanoidRootPart.Anchored = true
			--plr.Character.Humanoid.WalkSpeed = 0
			EmoteService:Play(plr, "Wires")
		end)
		
		prompt.PromptButtonHoldEnded:Connect(function(plr)
			if not plr.Character then 
				return 
			end
			
			plr.Character.HumanoidRootPart.Anchored = false
			--plr.Character.Humanoid.WalkSpeed = 16
			
			EmoteService:Stop(plr)

		end)
		
		self.Prompts[player.UserId] = prompt
	end)
	
	ProfileService.PlayerRemoving:Connect(function(player)
		self.Prompts[player.UserId] = nil
	end)
end


function MedicKitService:Heal(plr, targetPlr)
	--Exploit checks
	--if plr.Team.Name ~= "Scientific Department" and plr.Team.Name ~= "Site Director" then
	--	return
	--end
	
	if not targetPlr.Character or not plr.Character then
		return
	end
	
	local distance = plr:DistanceFromCharacter(targetPlr.Character.HumanoidRootPart.Position)
	if distance > PROMPT_MAX_DISTANCE then
		return
	end
	
	--Award and play emote
	local JobService = Knit.GetService("JobService")
	JobService:Award(plr)
	
	local kit = MedicKitService:HasMedicalKit(plr)
	if kit then --you're already checking if nil, no need for debris service
		kit:Destroy()
	end
	--Heal
	targetPlr.Character.Humanoid.Health = targetPlr.Character.Humanoid.MaxHealth
	
	--Tell plr to hide prompts
	self.Client.OnTogglePrompts:Fire(plr, false, self.Prompts)
end


return MedicKitService