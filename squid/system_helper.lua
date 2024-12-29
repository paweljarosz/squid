---@class SystemHelper	helper class for performing OS specific operations
---@field is_linux		boolean
---@field is_mobile		boolean
---@field is_debug		boolean
local SystemHelper = {}

local system_name = sys.get_sys_info().system_name

SystemHelper.is_linux = system_name == "Linux"
SystemHelper.is_mobile = ( (system_name == "iPhone OS") or (system_name == "Android") )
SystemHelper.is_debug = sys.get_engine_info().is_debug

---Get time stamp string following optional format or default (HH:MM:SS)
---@param format?	string	Optional format following convention as in https://www.lua.org/pil/22.1.html
---@return			string	Formatted time stamp string
function SystemHelper.get_timestamp(format)
	return os.date(format or '%H:%M:%S', os.time()) --[[@as string]]
end

---Get correct system dependent filepath for given file
---@param app_catalog		string	Catalog/folder name
---@param file_name			string	File name
---@param extension?		string	Optional extension to be added at the end (file_name.extension)
---@param add_timestamp?	boolean	True if you want to add current timestamp at end of file_name
---@return string
function SystemHelper.filepath(app_catalog, file_name, extension, add_timestamp)
	if add_timestamp then
		file_name = file_name .. SystemHelper.get_timestamp("_%Y-%m-%d_%H_%M")
	end

	if extension then
		file_name = file_name .. "." .. extension
	end

	if SystemHelper.is_linux then
		-- For Linux we modify the default path to make Linux users happy
		local config_dir = "config/" .. app_catalog
		return sys.get_save_file(config_dir, file_name)
	elseif html5 then
		-- For HTML5 there's no need to get the full path
		return app_catalog .. "_" .. file_name
	end

	return sys.get_save_file(app_catalog, file_name)
end

return SystemHelper