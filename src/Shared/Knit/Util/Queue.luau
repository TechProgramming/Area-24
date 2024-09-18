local Queue = {}
Queue.__index = Queue

function Queue.new()
	local newqueue = {}
	setmetatable(newqueue, Queue)
	local first, last = 0, -1
	newqueue.Push = function(item)
		last = last + 1
		newqueue[last] = item
		return item
	end
	newqueue.Pop = function()
		if first <= last then
			local value = newqueue[first]
			newqueue[first] = nil
			first = first + 1
			return value
		end
	end
	newqueue.Iterator = function()
		return function()
			return newqueue.Pop()
		end
	end
	newqueue.Count = function()
		return (last-first+1)
	end
	setmetatable(newqueue, {
		__len = function()
			return (last-first+1)
		end,
	})
	return newqueue
end

return Queue