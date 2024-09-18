local Signal = require(script.Parent.Signal)

local module = {}
module.__index = module

function module.new(effects)
	assert(typeof(effects) == "table", "Expected effects to be table instead got "..typeof(effects))
	local self = setmetatable({}, module)
	
	self.SatisfactionChanged = Signal.new()
	self.IsSatisfied = false
	
	self._effects = {}
	for effectName, defaultValue in pairs(effects) do
		assert(typeof(effectName) == "string", tostring(effectName).." is not a string but instead " .. typeof(effectName))
		assert(typeof(defaultValue) == "boolean" or defaultValue == nil, tostring(effectName).."'s default is neither a boolean or nil but instead " .. typeof(defaultValue))
		self._effects[effectName] = defaultValue or false
	end
	
	self:Update()
	
	return self
end

function module:Update()
	local pastValue = self.IsSatisfied
	local isSatisfied = false
	for _, v in pairs(self._effects) do
		if v == true then
			isSatisfied = true
			break
		end
	end
	self.IsSatisfied = isSatisfied
	
	if pastValue ~= isSatisfied then
		self.SatisfactionChanged:Fire(isSatisfied)
	end
end

function module:Set(name, state)
	if self._effects[name] == nil then error(string.format("%s is not a valid EffectName", name), 2) end
	self._effects[name] = state
	
	self:Update()
end

function module:GetIsAllOff()
	return not self.IsSatisfied
end

function module:__tostring()
	local str = ""
	for name, value in ipairs(self._effects) do
		if #str > 0 then
			str = str .. "\n"
		end
		str = str .. tostring(name) .. ": " .. tostring(value)
	end
	return str
end

return module