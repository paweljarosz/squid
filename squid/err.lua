-- To Err Is Human
local M = {}

M.appname = "Err"
M.print = false
M.verbose = false
M.initialized = false
M.logging = false
M.logging_filename = "err_log.txt"
M.crash_filename = "engine_crash_log.bin"
M.sysinfo = sys.get_sys_info()
M.callback_function = nil
M.include_timestamp = true
M.use_date_for_filename = false
M.enable_crash_logging = false

function M.error_handler(source, message, traceback)
	if M.verbose then print("Err: err.error_handler has been called.") end
	if M.print then
		pprint(source)
		pprint(message)
		pprint(traceback)
	end
	M.save_log(source, message, traceback)
	if M.callback_function ~= nil then
		M.callback_function(source, message, traceback)
	end
end

function M.init()
	M.initialized = true
	if M.verbose then print("Err: err.init - Err is initialized.") end
	sys.set_error_handler(M.error_handler)
	if M.enable_crash_logging then
		crash.set_file_path(M.get_crash_path())
	end
	M.check_for_crashes()
	
end

function M.check_for_crashes()
	local dump = crash.load_previous()
	if dump == nil then
		print("Err: No crash dump found")
		return false
	else
		print("Err: Crash dump found, writing to log")

		local path = M.get_logging_path()
		local log = io.open(path, "a")

		if not log then return end

		if M.include_timestamp then
			local timestamp = os.time()
			log:write(os.date('%Y-%m-%d %H:%M:%S', timestamp) .. " (" .. timestamp .. ")", "\n")
		end

		log:write("Crash [" .. crash.get_sys_field(dump, crash.SYSFIELD_ENGINE_VERSION) .. "] [" .. crash.get_sys_field(dump, crash.SYSFIELD_ENGINE_HASH) .. "]", "\n")
		log:write("Device Model : " .. crash.get_sys_field(dump, crash.SYSFIELD_DEVICE_MODEL), "\n")
		log:write("Device Language : " .. crash.get_sys_field(dump, crash.SYSFIELD_DEVICE_LANGUAGE), "\n")
		log:write("Device OS : " .. crash.get_sys_field(dump, crash.SYSFIELD_SYSTEM_NAME) .. " " .. crash.get_sys_field(dump, crash.SYSFIELD_SYSTEM_VERSION), "\n")
		log:write("Signum [" .. crash.get_signum(dump) .. "]", "\n")
		log:write("Userdata0 = [" .. crash.get_user_field(dump, 0) .. "]", "\n")
		log:write("Backtrace:", "\n")
		log:write(table.concat(crash.get_backtrace(dump), ","), "\n")
		log:write(crash.get_extra_data(dump), "\n")


		log:write("\n")
		log:write("\n")
		io.close(log)

		crash.release(dump)
	end
end

function M.check_init()
	if M.initialized ~= true then
		M.init()
	end
end



function M.save_log(source, message, traceback)
	M.check_init()
	local path = M.get_logging_path()
	local log = io.open(path, "a")
	if not log then return end

	if M.include_timestamp then
		local timestamp = os.time()
		log:write(os.date('%Y-%m-%d %H:%M:%S', timestamp) .. " (" .. timestamp .. ")", "\n")
	end
	log:write("source: " .. source, "\n")
	log:write("message: " .. message, "\n")
	log:write(traceback, "\n")
	log:write("\n")
	io.close(log)
	if M.verbose then print("Err: err.save_log - Log written to " .. path) end
end


function M.save_log_line(line)
	M.check_init()
	local path = M.get_logging_path()
	local log = io.open(path, "a")
	if not log then return end
	if M.include_timestamp then
		local timestamp = os.time()
		log:write(os.date('%Y-%m-%d %H:%M:%S', timestamp) .. " (" .. timestamp .. ")", "\n")
	end
	log:write(line, "\n")
	log:write("\n")
	io.close(log)
	if M.verbose then print("Err: err.save_log_line - Log written to " .. path) end	
end

function M.set_appname(appname)
	M.check_init()
	-- if you don't want appname filtered then set it directly
	-- err.appname = "whatever"
	appname = appname:gsub('%S%W','')
	M.appname = appname
end

function M.toggle_print()
	if M.print then
		M.print = false
	else
		M.print = true
	end
end

function M.toggle_verbose()
	if M.verbose then
		M.verbose = false
	else
		M.verbose = true
	end
end

function M.toggle_logging()
	if M.logging then
		M.logging = false
	else
		M.logging = true
	end
end

local function appname_check()
	if M.appname == "Err" then
		print("Err: You need to set a custom appname with err.set_appname(appname)")
	end
end

function M.get_logging_path()
	appname_check()
	if M.use_date_for_filename then
		local timestamp = os.time()
		M.logging_filename = "err_log_" .. os.date('%Y-%m-%d', timestamp) .. ".txt"
	end
	if M.sysinfo.system_name == "Linux" then
		-- For Linux we must modify the default path to make Linux users happy
		local appname = "config/" .. tostring(M.appname)
		return sys.get_save_file(appname, M.logging_filename)
	end
	return sys.get_save_file(M.appname, M.logging_filename)
end

function M.get_crash_path()
	appname_check()
	if M.sysinfo.system_name == "Linux" then
		-- For Linux we must modify the default path to make Linux users happy
		local appname = "config/" .. tostring(M.appname)
		return sys.get_save_file(appname, M.crash_filename)
	end
	return sys.get_save_file(M.appname, M.crash_filename)
end

return M