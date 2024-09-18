local Knit = require(game:GetService("ReplicatedStorage").Knit);
local ErrorLoggerService = Knit.GetService("ErrorLoggerService")

local RunService = game:GetService("RunService")
local ScriptContextService = game:GetService("ScriptContext")

local IS_STUDIO = RunService:IsStudio()

local ErrorLoggerController = Knit.CreateController({
	Name = "ErrorLoggerController"
})


function ErrorLoggerController:KnitStart()

	--Gather messages
	ScriptContextService.Error:Connect(function(message, trace, _erroredScript)
		if IS_STUDIO then
			return
		end
		
		if string.match(message, "Core") ~= nil then
			return
		end

		ErrorLoggerService.OnLog:Fire(message, trace)
	end)
end


return ErrorLoggerController