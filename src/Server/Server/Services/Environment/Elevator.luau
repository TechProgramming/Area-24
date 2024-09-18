local Knit = require(game:GetService("ReplicatedStorage").Knit);
local RemoteSignal = require(Knit.Util.Remote.RemoteSignal);

local elevator = {}

local elevators = game.Workspace:WaitForChild("Scripted").Elevators
local cooldown = 10

local playerHistory = {}

function PassCooldown(player)
	playerHistory[player] = playerHistory[player] or 0
	local playerLastUse = playerHistory[player]
	print(tick() - playerLastUse >= cooldown)
	if tick() - playerLastUse >= cooldown then
		playerHistory[player] = tick()
		return true
	else
		return false
	end
end

for _, group in pairs(elevators.Buttons:GetChildren()) do
	for _, part in pairs(group:GetChildren()) do
		local Prompt = part:FindFirstChild("prompt")
		if Prompt then
			local ParentName = Prompt.Parent.Name
			local TargetBlock = group[ParentName.."Destination"]
			Prompt.Triggered:Connect(function(player)
				if not player.Character then
					return
				end
				
				if not PassCooldown(player) then
					local NotificationService	= Knit.GetService("NotificationService");
					local waitTime = cooldown - (tick() - playerHistory[player])
					NotificationService:ShowNotification(player, 2, "You must wait ".. math.floor(waitTime) .." seconds before you can use this again.", Color3.fromRGB(255, 107, 48))
				else
					player:RequestStreamAroundAsync(TargetBlock.Position)
					player.Character.HumanoidRootPart.CFrame = TargetBlock.CFrame
				end
				
			end)
		end
	end
end

return elevator
