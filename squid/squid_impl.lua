local SquidImpl = {}

-- Dependencies
local SquidConfig =		require "squid.squid_config"
local SystemHelper =	require "squid.system_helper"
local TableToString =	require "squid.table_to_string"

-- Log Levels
SquidImpl.TRACE =   1
SquidImpl.DEBUG =   2
SquidImpl.INFO =    3
SquidImpl.WARN =    4
SquidImpl.ERROR =   5

--- Localise levels
local TRACE = 	SquidImpl.TRACE
local DEBUG = 	SquidImpl.DEBUG
local INFO = 	SquidImpl.INFO
local WARN = 	SquidImpl.WARN
local ERROR = 	SquidImpl.ERROR

---@type table
local LEVEL_NAME = {}
LEVEL_NAME[TRACE] = "TRACE:  "
LEVEL_NAME[DEBUG] = "DEBUG:  "
LEVEL_NAME[INFO] =  "INFO:   "
LEVEL_NAME[WARN] =  "WARNING:"
LEVEL_NAME[ERROR] = "ERROR:  "
LEVEL_NAME[6] = "CRASH:  "

SquidImpl.ALLOWLIST = {
	none = true,
	squid = true,
	error = true,
	crash = true,
}

---@type boolean
SquidImpl.initialized = false

---@type boolean
local IS_SKIPPING = ((not SquidConfig.is_enabled) or (SquidConfig.is_enabled_in_release and not SystemHelper.is_debug))

---@type boolean
local IS_PRINTING = SquidConfig.is_printing

---@type string
local FILEPATH  = SystemHelper.filepath(SquidConfig.app_catalog,
SquidConfig.log_file_name,
SquidConfig.log_file_extension,
SquidConfig.is_adding_timestamp)

---@type table
local UNSAVED_LOGS_TABLE = {}

--localize globals
local io, print, type, tostring = io, print, type, tostring
local debug_getinfo = debug and debug.getinfo

function SquidImpl.init()
	if SquidImpl.initialized then return end
	SquidImpl.initialized = true
	if not IS_SKIPPING then
		sys.set_error_handler(SquidImpl.error_handler)
		crash.set_file_path(FILEPATH)
	end
	local engine_info = sys.get_engine_info()
	local sys_info = sys.get_sys_info()
	local init_log = "Squid Initialized."
	.. "\n Engine version: "..engine_info.version
	.. "\n Engine SHA1: "..engine_info.version_sha1
	.. "\n Engine is debug?: "..(engine_info.is_debug and "true" or "false")
	.. "\n Device model: "..sys_info.device_model
	.. "\n Device manufacturer: "..sys_info.manufacturer
	.. "\n Device language: "..sys_info.device_language
	.. "\n Device identity: "..sys_info.device_ident
	.. "\n System name: "..sys_info.system_name
	.. "\n System version: "..sys_info.system_version
	.. "\n System API version: "..sys_info.api_version
	.. "\n System language: "..sys_info.language
	.. "\n Territory: "..sys_info.territory
	.. "\n GMT offset: "..sys_info.gmt_offset
	.. "\n HTTP User Agent: "..sys_info.user_agent
	IS_PRINTING = false
	SquidImpl.log(init_log, INFO, nil, "squid")
	IS_PRINTING = SquidConfig.is_printing
end

function SquidImpl.log(message, level, data_or_tag, tag)
	-- Check negative conditions first:
	if IS_SKIPPING
	or (level < SquidConfig.min_log_level)
	then
		return
	end

	if data_or_tag and type(data_or_tag) == "string" then
		tag = tag or data_or_tag
	end

	if (SquidConfig.is_using_allowlist and (SquidImpl.ALLOWLIST[tag or "none"] ~= true)) then
		return
	end

	-- Prepare head prefix of the complete log line:
	local complete_line = LEVEL_NAME[level].."["..(tag or "none").."]: ["..SystemHelper.get_timestamp().."]"

	-- Append code line address:
	local code_address = ""
	if SystemHelper.is_debug then
		local info = debug_getinfo(3, "Sl") -- https://www.lua.org/pil/23.1.html
		info = info or debug_getinfo(2, "Sl")	-- lower level if called Squid.log directly
		local short_src = info.short_src
		local line_number = info.currentline
		code_address = short_src .. ":" .. line_number
	end
	complete_line = complete_line .. " " .. code_address .. ": " .. message

	-- Append optional data:
	if data_or_tag then
		if type(data_or_tag) == "table" then
			data_or_tag = TableToString.convert(data_or_tag, SquidConfig.max_data_depth, nil, SquidConfig.max_log_length, 2, false)
			complete_line = complete_line .. "\n Data:\n" .. data_or_tag
		elseif type(data_or_tag) ~= "string" then
			data_or_tag = tostring(data_or_tag) or ""
			complete_line = complete_line .. "\n Data: " .. data_or_tag
		end
	end

	-- Print log to console:
	if IS_PRINTING then
		if SystemHelper.is_mobile then
			print(complete_line)
		else
			io.stdout:write(complete_line, "\n")
			io.stdout:flush()
		end
	end

	-- Put complete line in Unsaved Logs table:
	UNSAVED_LOGS_TABLE[#UNSAVED_LOGS_TABLE + 1] = complete_line

	-- Save logs if maximum buffer of unsaved logs reached:
	if #UNSAVED_LOGS_TABLE > SquidConfig.unsaved_logs_buffer then
		SquidImpl.save_logs()
	end
end

function SquidImpl.save_logs()
	-- Quit if not configured to save
	if not SquidConfig.is_saving then
		return false
	end

	local logfile, error_message = io.open(FILEPATH, "a")
	if logfile then
		for i = 1, #UNSAVED_LOGS_TABLE do
			logfile:write(UNSAVED_LOGS_TABLE[i], "\n")
		end
		io.close(logfile)
		UNSAVED_LOGS_TABLE = {}
		return true
	else
		SquidImpl.log("Can't save to file.", ERROR, error_message, "squid")
		return false
	end
end


local ERROR_CALLBACK = function(source, message, traceback) end

function SquidImpl.set_error_callback(callback)
	assert(callback, "Squid: Must provide error callback")
	assert(type(callback) == "function", "Squid: error callback must be a function")
	ERROR_CALLBACK = callback
end

function SquidImpl.error_handler(source, message, traceback)
	-- Log error (without printing again) and explicitly save everything
	IS_PRINTING = false
	SquidImpl.log("Error:\n Source: "..source.."\n Message: "..message.."\n Traceback: "..traceback, ERROR, nil, "error")
	IS_PRINTING = SquidConfig.is_printing
	SquidImpl.save_logs()
	ERROR_CALLBACK(source, message, traceback)
end

function SquidImpl.check_for_crashes()
	local dump = crash.load_previous()
	if dump == nil then
		SquidImpl.log("CRASH: No crash dump found", INFO, nil, "crash")
		return
	end

	local crash_log = "\n Engine version: Defold " .. crash.get_sys_field(dump, crash.SYSFIELD_ENGINE_VERSION)
	.. "\n Engine hash: " .. crash.get_sys_field(dump, crash.SYSFIELD_ENGINE_HASH)
	.. "\n Device model: " .. crash.get_sys_field(dump, crash.SYSFIELD_DEVICE_MODEL)
	.. "\n Device language: " .. crash.get_sys_field(dump, crash.SYSFIELD_DEVICE_LANGUAGE)
	.. "\n Device OS: " .. crash.get_sys_field(dump, crash.SYSFIELD_SYSTEM_NAME) .. " " .. crash.get_sys_field(dump, crash.SYSFIELD_SYSTEM_VERSION)
	.. "\n Signum: [\n  " .. crash.get_signum(dump) .. "\n ]"
	.. "\n Userdata0: [\n  " .. crash.get_user_field(dump, 0) .. "\n ]"
	.. "\n Backtrace: [\n  " .. table.concat(crash.get_backtrace(dump), "\n  ") .. "\n ]"
	.. "\n Loaded modules: [\n" .. TableToString.convert(crash.get_modules(dump), SquidConfig.max_data_depth, nil, SquidConfig.max_log_length, 2, false) .. "\n ]"
	.. "\n Extra: [\n  " .. crash.get_extra_data(dump) .. "\n ]"

	-- Log crash (without printing):
	IS_PRINTING = false
	SquidImpl.log("CRASH:" .. crash_log, 6, nil, "crash")
	IS_PRINTING = SquidConfig.is_printing

	crash.release(dump)
end

return SquidImpl