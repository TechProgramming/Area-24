local queue = {}
queue.__index = queue

function queue.new()
	local self = setmetatable({}, queue)
	self._ops = {}
	return self
end

function queue:push(v)
	table.insert(self._ops, v)
end

function queue:pop()
	local v = table.remove(self._ops, 1)
	return v
end

function queue:isEmpty()
	return #self._ops == 0
end

function queue:emptyAll()
	while not self:isEmpty() do
		self:pop()
	end
end


return queue