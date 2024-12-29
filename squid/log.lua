---@class LOG
---LOG - for all logging purposes.
---Fork of Subsoap's Log (https://github.com/subsoap/log)
---CC0 1.0 Universal
---Modified by Pawel Jarosz 2024
local LOG = {}

-- LOG LEVELS
LOG.TRACE = 1
LOG.DEBUG = 2
LOG.INFO = 	3
LOG.WARN = 	4
LOG.ERROR = 5

-- Internal Data
local TRACE = 	LOG.TRACE
local DEBUG = 	LOG.DEBUG
local INFO = 	LOG.INFO
local WARN = 	LOG.WARN
local ERROR = 	LOG.ERROR
local FILE_PATH, IS_LOGGING, IS_PRINTING, IS_SAVING, LOG_LEVEL, IS_LOG_RELEASE
local IS_DEBUG, DEL_AFTER, IS_ALLOWLIST, ALLOWLIST, IS_MOBILE

local log_level_names = {}
log_level_names[TRACE] = "TRACE:  "
log_level_names[DEBUG] = "DEBUG:  "
log_level_names[INFO] =  "INFO:   "
log_level_names[WARN] =  "WARNING:"
log_level_names[ERROR] = "ERROR:  "

---Initializes internal configuration for logger
---@param config table
function LOG.init(config)
	FILE_PATH =		config.log.file_path
	IS_LOGGING =	config.log.is_enabled
	IS_PRINTING =	config.log.is_printing
	IS_SAVING =		config.log.is_saving
	LOG_LEVEL =		config.log.log_level
	DEL_AFTER =		config.log.delete_logs_after_days
	IS_ALLOWLIST =	config.log.is_allowlisting
	ALLOWLIST =		config.log.allowlist
	IS_LOG_RELEASE =config.log.is_enabled_in_release
	IS_DEBUG =		config.system.is_debug
	IS_MOBILE =		config.system.is_mobile
end

-- TRACE
function LOG.trace(message, tag)
	LOG.save_log_line(message, TRACE, tag)
end

-- DEBUG
function LOG.debug(message, tag)
	LOG.save_log_line(message, DEBUG, tag)
end

-- INFO
function LOG.info(message, tag)
	LOG.save_log_line(message, INFO, tag)
end

-- WARNING
function LOG.warn(message, tag)
	LOG.save_log_line(message, WARN, tag)
end

-- ERROR
function LOG.error(message, tag)
	LOG.save_log_line(message, ERROR, tag)
end

--localize globals
local os, io, print, tonumber = os, io, print, tonumber
local lfs_dir = lfs and lfs.dir
local string_gmatch = string and string.gmatch
local debug_getinfo = debug and debug.getinfo

---@param new_level integer 1|2|3|4|5
function LOG.set_level(new_level)
	LOG_LEVEL = new_level
end

function LOG.save_log_line(text, level, tag)
	-- check negative conditions first
	if (not IS_LOGGING)
	or (IS_LOG_RELEASE and not IS_DEBUG)
	or (level < LOG_LEVEL)
	or (IS_ALLOWLIST and (ALLOWLIST[tag or "none"] ~= true)) then
		return false
	end

	local timestamp = os.time()
	local timestamp_string = os.date('%H:%M:%S', timestamp)
	local head = log_level_names[level].."[".. tag .. "]: [" .. timestamp_string .. "]"
	local code_address = ""

	if IS_DEBUG then
		local info = debug_getinfo(3, "Sl") -- https://www.lua.org/pil/23.1.html
		local short_src = info.short_src
		local line_number = info.currentline
		--if debug_getinfo(4, "Sl") then
			--short_src = "/" .. short_src
		--end
		code_address = short_src .. ":" .. line_number
	end

	local complete_line = head .. "\t" .. code_address .. " --> " .. text

	if IS_PRINTING then
		if IS_MOBILE then
			print(complete_line)
		else
			io.stdout:write(complete_line, "\n")
			io.stdout:flush()
		end
	end

	if IS_SAVING then
		local logfile = io.open(FILE_PATH, "a")
		if logfile then
			logfile:write(complete_line, "\n")
			io.close(logfile)
		else
			LOG.error("Log: Can't save to file", "log")
		end
	end
end


-- TODO: Needs refactor:
function LOG.delete_old_logs(days)
	if not lfs_dir then
		LOG.error("Log: LFS is required to delete old logs", "log")
		return false
	end

	local days_to_log_expire = days or DEL_AFTER
	local time_now = os.time()
	local max_time_difference = 86400 * days_to_log_expire
	local directory = LOG.get_LOGGING_dir_path()
	for file in lfs_dir(directory) do
		if file ~= "." and file ~= ".." then
			local delete_file_ok = true
			local it = 0
			local date = ""
			local filetype = ""
			-- break filename of NNNN-NN-NN.log in half at the .
			for i in string_gmatch(file, "[^%.]+") do
				it = it + 1
				if it == 1 then
					date = i
				elseif it == 2 then
					if i == "log" then
						filetype = "log"
					end
				elseif it >= 3 then
					-- mismatch
					delete_file_ok = false
				end
			end
			if filetype == "log" then
				local xyear = 0
				local xmonth = 0
				local xday = 0
				it = 0
				-- break (hopefully) date string NNNN-NN-NN into dates by the -
				for i in string_gmatch(date, "[^%-]+") do
					it = it + 1
					if it == 1 then
						xyear = tonumber(i)
					elseif it == 2 then
						xmonth = tonumber(i)
					elseif it == 3 then
						xday = tonumber(i)
					elseif it >= 4 then
						-- mismatch
						delete_file_ok = false
					end

				end
				local timestamp = os.time({year = xyear, month = xmonth, day = xday, hour = 0, min = 0, sec = 0, isdst=false})
				if timestamp ~= nil and delete_file_ok then
					if time_now - timestamp >= max_time_difference then
						os.remove(directory .. file)
					end
				end
			end
		end
	end
end

return LOG