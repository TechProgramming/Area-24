local ReplicatedStorage	= game:GetService("ReplicatedStorage");

local PLAYER = game.Players.LocalPlayer;
local VER = PLAYER.PlayerGui:WaitForChild("Version");

VER:WaitForChild("Ver").Text = string.format("PBT - %s", ReplicatedStorage:WaitForChild("Version").Value);