local Knit = require(game:GetService("ReplicatedStorage").Knit)
local PlayerService = game:GetService("Players")
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal)

local EmoteService = Knit.CreateService({ 
	Name = "EmoteService", 
	Client = {
		OnEmote = RemoteSignal.new();
	},
	AnimationData = {},
	LiveTracks = {},
	LiveConnections = {}
})

local Animations = game.ReplicatedStorage.Animations

function EmoteService:KnitStart()
	local ProfileService = Knit.Services.ProfileService

	ProfileService.PlayerRemoving:Connect(function(player, character)
		self.LiveTracks[player] = nil
		if self.LiveConnections[player] ~= nil then
			self.LiveConnections[player]:Disconnect()		
		end
		self.LiveConnections[player] = nil
	end)

	for _, category in pairs(Animations.Emotes:GetChildren()) do
		for _, anim in pairs(category:GetChildren()) do
			self.AnimationData[anim.Name] = {
				Category = category.Name,
				Name = anim.Name,
				Animation = anim,
				StopWhenMoving = anim:GetAttribute("StopWhenMoving"),
				Tracks = {}
			}
		end
	end
	
	function EmoteService:Stop(player)
		local character = player.Character
		if character then
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.AutoRotate = true
		end
		
		if self.LiveTracks[player] ~= nil then
			self.LiveTracks[player]:Stop()
			self.LiveTracks[player]:Destroy()
			if self.LiveConnections[player] ~= nil then
				self.LiveConnections[player]:Disconnect()		
			end
		end
	end
	
	function EmoteService:Play(player, emoteName)
		
		local character = player.Character
		if character then
			local humanoid = character:WaitForChild("Humanoid")
			local animator = humanoid:WaitForChild("Animator")
			local animationData = self.AnimationData[emoteName]
			if animationData ~= nil then
				--local Track = animationData.Tracks[player]

				--if Track == nil then
				if self.LiveTracks[player] ~= nil then
					self.LiveTracks[player]:Stop()
					self.LiveTracks[player]:Destroy()
				end
				
				local Track = animator:LoadAnimation(animationData.Animation)
				self.LiveTracks[player] = Track
				--animationData.Tracks[player] = Track
				local connection = nil	

				local function disableAnimation()
					humanoid.AutoRotate = true
					
					if self.LiveTracks[player] ~= nil then
						self.LiveTracks[player]:Stop()
						self.LiveTracks[player]:Destroy()
						if self.LiveConnections[player] ~= nil then
							self.LiveConnections[player]:Disconnect()		
						end
					end
				end

				if animationData.StopWhenMoving then
					connection = humanoid.Running:Connect(disableAnimation)
					self.LiveConnections[player] = connection
				end
				--end
				Track:Play()
				--humanoid.AutoRotate = false
				--humanoid.WalkSpeed = 0
				return Track;
			else
				print("No emote found.")
			end
		else
			print("No character found.")
		end		
	end
	
	EmoteService.Client.OnEmote:Connect(function(player, emoteName)
		EmoteService:Play(player, emoteName)
	end)

end


return EmoteService
