---@class SystemHelper	helper class for performing OS specific operations
---@field is_linux		boolean
---@field is_mobile		boolean
---@field is_debug		boolean
local SystemHelper = {}

-- localize
local sys, io, os, tonumber, ipairs = sys, io, os, tonumber, ipairs

local system_name = sys.get_sys_info().system_name

SystemHelper.is_linux = system_name == "Linux"
SystemHelper.is_windows = system_name == "Windows"
SystemHelper.is_linux_or_mac = SystemHelper.is_linux or system_name == "Darwin"
SystemHelper.is_mobile = ( (system_name == "iPhone OS") or (system_name == "Android") )
SystemHelper.is_debug = sys.get_engine_info().is_debug

---Get time stamp string following optional format or default (HH:MM:SS)
---@param format?	string	Optional format following convention as in https://www.lua.org/pil/22.1.html
---@return			string	Formatted time stamp string
function SystemHelper.get_timestamp(format)
	return os.date(format or '%H:%M:%S', os.time()) --[[@as string]]
end

---Get correct system dependent filepath for given catalog
---@param app_catalog		string	Catalog/folder name
---@return string
function SystemHelper.directory(app_catalog)
	if SystemHelper.is_linux then
		-- For Linux we modify the default path to make Linux users happy
		local config_dir = "config/" .. app_catalog
		return sys.get_save_file(config_dir, "")
	elseif html5 then
		-- For HTML5 there's no need to get the full path
		return app_catalog
	end

	return sys.get_save_file(app_catalog, "")
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

---Get a list of all saved files in the specified catalog
---@param app_catalog	string	Catalog/folder name
---@return				table	List of saved file paths
---@return				string	Error message if somethings goes wrong, OK string otherwise
function SystemHelper.get_all_files_in_catalog(app_catalog)
	-- Get the base path for the app catalog
	local base_file_path
	if SystemHelper.is_linux then
		local config_dir = "config/" .. app_catalog
		base_file_path = sys.get_save_file(config_dir, "")
	elseif html5 then
		return {}, "HTML5 does not support directory operations."
	else
		base_file_path = sys.get_save_file(app_catalog, "")
	end

	-- Extract directory from the file path
	local directory = base_file_path:match("^(.*)[/\\]") -- Handles both / and \ separators
	if not directory then
		return {}, "Unable to determine directory path from ".. base_file_path
	end

	-- Platform-specific file listing command
	local list_files_cmd
	if SystemHelper.is_linux_or_mac then
		-- Linux/MacOS specific: using `ls` command
		list_files_cmd = "ls -1 \"" .. directory .. "\""
	elseif SystemHelper.is_windows then
		-- Windows specific: using `dir` command
		list_files_cmd = "dir /b \"" .. directory .. "\""
	else
		return {}, "Unsupported platform for directory operations."
	end

	-- Capture the output of the command
	local files = {}
	local handle = io.popen(list_files_cmd)
	if handle then
		for file in handle:lines() do
			if file ~= "." and file ~= ".." then
				table.insert(files, file)
			end
		end
		handle:close()
	else
		return {}, "Error: Unable to execute directory listing command."
	end

	if #files == 0 then
		return files, "No files found in directory."
	end

	return files, "OK"
end


---Extract timestamp from a filename with the format "squid_log_file_YYYY-MM-DD_HH_MM.txt"
---@param file_name string Filename to extract the timestamp from
---@return number|nil The Unix timestamp of the file, or nil if parsing fails
local function extract_timestamp_from_filename(file_name)
	local year, month, day, hour, min = file_name:match("_(%d%d%d%d)%-(%d%d)%-(%d%d)_(%d%d)_(%d%d)%.")
	if year and month and day and hour and min then
		return os.time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), 
		hour = tonumber(hour), min = tonumber(min), sec = 0 })
	end
	return nil
end

---Remove files older than a specified number of days based on their filename timestamp
---@param files_table table Table containing file names
---@param directory string Directory where the files are located
---@param days_threshold number Number of days before current date to consider files as old
function SystemHelper.remove_old_files_by_filename(files_table, directory, days_threshold)
	-- Get current time
	local current_time = os.time()

	for _, file_name in ipairs(files_table) do
		local file_path = directory .. "/" .. file_name -- Adjust path separator if needed

		-- Extract the timestamp from the filename
		local file_timestamp = extract_timestamp_from_filename(file_name)
		if file_timestamp then
			-- Calculate file age in days
			local file_age_days = os.difftime(current_time, file_timestamp) / (60 * 60 * 24)
			if file_age_days > days_threshold then
				-- Remove the file if it's older than the threshold
				os.remove(file_path)
			end
		end
	end
end

return SystemHelper