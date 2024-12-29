---@class TableToString
local TableToString = {}

local max_depth = 0
---Converts table to one-line string
---@param t					table
---@param depth				integer
---@param result			string|nil @Internal parameter
---@param spaces_in_tab		integer
---@param is_json			boolean
---@return string, boolean @String representation of table, Is max string length reached
function TableToString.convert(t, depth, result, max_length, spaces_in_tab, is_json)
	if not t then
		max_depth = 0
		return "", false
	end

	local tab = ""
	for i = 1, spaces_in_tab do
		tab = tab .. " "
	end

	local assignment = is_json and ": " or " = "

	max_depth = math.max(max_depth, depth)
	depth = depth or 0
	result = result or tab.."{\n"

	if #result > max_length then
		return result:sub(1, max_length) .. "...\n", true
	end

	for key, value in pairs(t) do
		if type(value) == "table" then
			if depth == 0 then
				result = result .. key .. assignment .. "{ ... #" .. #value .. " }"
			else
				print("AAA", max_depth, depth)
				for i = 1, (max_depth - depth) + 2 do
					result = result .. "  "
				end
				result = result .. key .. assignment .. "{\n"
				local convert_result, is_limit = TableToString.convert(value, depth - 1, result, max_length, spaces_in_tab, is_json)
				result = convert_result
				if is_limit then
					break
				end
			end
		else
			for i = 1, (max_depth - depth) + 2 do
				result = result .. tab
			end
			result = result .. key .. assignment .. tostring(value)
		end

		if #result > 2 then
			result = result .. ",\n"
		end
	end

	if #result > max_length then
		max_depth = 0
		return result:sub(1, max_length) .. "\n" .. tab .. tab .. "...\n  }", true
	end

	for i = 1, (max_depth - depth) + 1 do
		result = result .. tab
	end

	--max_depth = 0
	return result .. "}", false
end

return TableToString