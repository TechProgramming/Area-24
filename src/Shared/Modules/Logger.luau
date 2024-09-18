local logger = {}

function logger.new(script, settings)
	if settings == nil then settings = {} end
	
	local self = {
		settings = settings;
	}
	
	local function updateStates()
		local allOutputDisabled = script:GetAttribute("DisableAllOutput") or settings.disableAllOutput or false
		local printDisabled = not allOutputDisabled and (script:GetAttribute("DisablePrint") or settings.disablePrint) or false
		local warnDisabled = not allOutputDisabled and (script:GetAttribute("DisableWarn") or settings.disableWarn) or false

		self.canOutput = not allOutputDisabled
		self.canPrint = not printDisabled
		self.canWarn = not warnDisabled
	end
	updateStates()
	
	script:GetAttributeChangedSignal("DisableAllOutput"):Connect(updateStates)
	script:GetAttributeChangedSignal("DisablePrint"):Connect(updateStates)
	script:GetAttributeChangedSignal("DisableWarn"):Connect(updateStates)
end

return logger