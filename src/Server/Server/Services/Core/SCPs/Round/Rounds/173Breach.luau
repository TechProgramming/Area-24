local PlayersService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)

local TELEPORTS = game.Workspace.Scripted.Teleports:GetChildren()

local Round = {
	Name = "173 Breach",
	Conn2 = nil,
}

local CONTAINER = game.Workspace.Scripted.SCPs["173"]

function Round:Start(endSignal)
	local SCP173 = Knit.GetService("_SCP_173");
	local SCPService = Knit.GetService("SCPService");
	
	local conn = endSignal:Connect(function()
		self:Cleanup()
	end)
	
	self.Conn2 = SCPService.OnContain:Connect(function(container)
		if container == CONTAINER then
			self.Conn2:Disconnect()
			conn:Disconnect()
			endSignal:Fire()
		end
	end)
	
	SCP173:Escape(SCP173.Agent.Container)
end


function Round:Cleanup()
	self.Conn2:Disconnect()
	local SCP173 = Knit.GetService("_SCP_173");
	SCP173:Clear()
end


return Round