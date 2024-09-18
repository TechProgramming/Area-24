local NumberFormat = {}

local abbreviations = {
	--K = 4,
	M = 7,
	B = 10,
	Qa = 13
}

function NumberFormat:Abbreviate(number)
	local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = int:reverse():gsub("(%d%d%d)", "%1,")

	-- reverse the int-string back remove an optional comma and put the 
	-- optional minus and fractional part back
	return minus .. int:reverse():gsub("^,", "") .. fraction
	--local text = tostring(math.floor(number))
	--local chosenAbb = false
	--for abbreviation, digits in pairs(abbreviations) do
	--	if #text >= digits and #text < (digits + 3) then
	--		chosenAbb = abbreviation
	--	end
	--end
	
	--if chosenAbb then
	--	local digits = abbreviations[chosenAbb]
	--	local rounded = math.floor(number / 10 ^ (digits - 2)) * 10 ^ (digits - 2)
	--	text = string.format("%.1f", rounded / 10 ^ (digits - 1)) .. chosenAbb
	--else
	--	text = number
	--end
	
	--return text
end

return NumberFormat
