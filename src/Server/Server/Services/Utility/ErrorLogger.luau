local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local ScriptContext		= game:GetService("ScriptContext");
local HTTPService		= game:GetService("HttpService");
local RunService		= game:GetService("RunService");

local Knit			= require(ReplicatedStorage.Knit);
local RemoteSignal	= require(Knit.Util.Remote.RemoteSignal);

local DEBUG = false
local IS_STUDIO = RunService:IsStudio()
local DISCORD_WEBHOOK_URL = ""

local ErrorLoggerService = Knit.CreateService({ 
	Name = "ErrorLoggerService", 
	Client = {
		OnLog = RemoteSignal.new(),
	}
});

function ErrorLoggerService:KnitStart()

	--Gather messages
	ScriptContext.Error:Connect(function(message, stack, _erroredScript)
		if string.match(message, "Core") ~= nil then
			return
		end
		
		self:HandleError(message, stack, "false", nil)
	end)

	--Gather messages from client
	self.Client.OnLog:Connect(function(plr, message, stack)
		self:HandleError(message, stack, plr.Name.." ("..tostring(plr.UserId)..")", plr)
	end)
	

end


function ErrorLoggerService:HandleError(message, stack, playerDetails, plr)	
	if IS_STUDIO and not DEBUG then
		return
	end	

	local formattedStack, _ = string.gsub(stack, "\n", "\n+ ")
	formattedStack, _ = string.gsub(formattedStack, "\r", "\n+ ")
	
	--players script is non existance, most likely injected script
	if plr and string.match(formattedStack, " , line") then
		local BanService = Knit.GetService("BanService")
		BanService:CreateBan(plr, "Suspected Exploiting (E001)", nil)
	end

	--Setup data
	local serverId = game.JobId
	local discordData = {
		username = "Error Logger",
		content = "```diff\n- "..message.."\n+ "..formattedStack.."\n# CLIENT-SIDE: "..playerDetails.."\n# VER: "..ReplicatedStorage.Version.Value
	}



	--Final formatting and send to discord
	discordData.content = discordData.content.."\n# "..serverId.."\n```"
	self:SendToDiscord(discordData)
end

function ErrorLoggerService:SendToDiscord(dataToEncode)
	--Encode
	local encodedData = HTTPService:JSONEncode(dataToEncode)

	--Send http request
	pcall(function()
		HTTPService:PostAsync(DISCORD_WEBHOOK_URL, encodedData)
	end)
end


return ErrorLoggerService