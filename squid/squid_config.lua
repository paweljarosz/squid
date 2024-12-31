---@class SquidConfig  configuration of the Squid logging system
---@field app_catalog			string
---@field log_file_name			string
---@field log_file_extension	string
---@field is_enabled			boolean
---@field is_enabled_in_release	boolean
---@field is_printing			boolean
---@field is_saving				boolean
---@field is_adding_timestamp	boolean
---@field is_using_allowlist	boolean
---@field days_to_delete_logs	integer
---@field min_log_level			integer 1|2|3|4|5
---@field unsaved_logs_buffer	integer
---@field max_data_length		integer
---@field max_data_depth		integer
---@field is_printing_crashes	boolean
---@field is_saving_crashes		boolean
---@field crash_file_name		string
---@field crash_file_extension	string

---@type SquidConfig
local SquidConfig = {
	app_catalog =			sys.get_config_string("squid.app_catalog", "squid_app_catalog"),
	log_file_name =			sys.get_config_string("squid.log_file_name", "squid_log_file"),
	log_file_extension =	sys.get_config_string("squid.log_file_extension", "log"),
	is_enabled =			sys.get_config_int("squid.is_enabled", 1) == 1 and true or false,
	is_enabled_in_release =	sys.get_config_int("squid.is_enabled_in_release", 1) == 1 and true or false,
	is_printing =			sys.get_config_int("squid.is_printing", 1) == 1 and true or false,
	is_saving =				sys.get_config_int("squid.is_saving", 1) == 1 and true or false,
	is_adding_timestamp =	sys.get_config_int("squid.is_adding_timestamp", 1) == 1 and true or false,
	is_using_allowlist =	sys.get_config_int("squid.is_using_allowlist", 1) == 1 and true or false,
	days_to_delete_logs =	sys.get_config_int("squid.days_to_delete_logs", 7),
	min_log_level =			sys.get_config_int("squid.min_log_level", 2),
	unsaved_logs_buffer =	sys.get_config_int("squid.unsaved_logs_buffer", 30),
	max_data_length =		sys.get_config_int("squid.max_data_length", 500),
	max_data_depth =		sys.get_config_int("squid.max_data_depth", 5),
	is_printing_crashes =	sys.get_config_int("squid.is_printing_crashes", 1) == 1 and true or false,
	is_saving_crashes =		sys.get_config_int("squid.is_saving_crashes", 1) == 1 and true or false,
	crash_file_name =		sys.get_config_string("squid.crash_file_name", "squid_crash_file"),
	crash_file_extension =	sys.get_config_string("squid.crash_file_extension", "bin"),
}

return SquidConfig