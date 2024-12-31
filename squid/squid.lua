---SQUID
---version: 1.1
---Squid is a standalone injectable system for saveable logging of user logs, errors and crashes for Defold
---License: MIT
---Copyright Paweł Jarosz 2024-2025

---@class Squid
---@field TRACE		integer	@(1) trace logging level constant
---@field DEBUG		integer	@(2) debug logging level constant
---@field INFO		integer	@(3) info logging level constant
---@field WARN		integer	@(4) warning logging level constant
---@field ERROR		integer	@(5) error logging level constant
---@field ALLOWLIST	table	@Public list of allowed tags (pairs tag[string] - is_allowed[boolean])
local Squid = {}

-- Dependencies
local SquidImpl =	require "squid.squid_impl"

---------
-- Public members
---------
Squid.TRACE =		SquidImpl.TRACE
Squid.DEBUG =		SquidImpl.DEBUG
Squid.INFO =		SquidImpl.INFO
Squid.WARN =		SquidImpl.WARN
Squid.ERROR =		SquidImpl.ERROR
Squid.ALLOWLIST =	SquidImpl.ALLOWLIST

---------
-- API
---------

---Initialize Squid for error and crash handling and logging
---@static
function Squid.init()
	SquidImpl.init()
end


---Set if logs should be saved to file
---@static
---@param   tag?        string  @Tag to change
---@param   is_allowed  boolean @True if tag should be logged, false otherwise
function Squid.set_allowed(tag, is_allowed)
	assert(tag, "Tag must be specified")
	Squid.ALLOWLIST[tag] = is_allowed
end

---Log TRACE level message with optional data and tag
---@static
---@param message		string	@Message to log
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.trace(message, data_or_tag, tag)
	SquidImpl.log(message, Squid.TRACE, data_or_tag, tag)
end

---Log DEBUG level message with optional data and tag
---@static
---@param message		string	@Message to log
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.debug(message, data_or_tag, tag)
	SquidImpl.log(message, Squid.DEBUG, data_or_tag, tag)
end

---Log INFO level message with optional data and tag
---@static
---@param message		string	@Message to log
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.info(message, data_or_tag, tag)
	SquidImpl.log(message, Squid.INFO, data_or_tag, tag)
end

---Log WARNING level message with optional data and tag
---@static
---@param message		string	@Message to log
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.warn(message, data_or_tag, tag)
	SquidImpl.log(message, Squid.WARN, data_or_tag, tag)
end

---Log ERROR level message with optional data and tag
---@static
---@param message		string	@Message to log
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.error(message, data_or_tag, tag)
	SquidImpl.log(message, Squid.ERROR, data_or_tag, tag)
end


---Log message with provided level, message, data and tag
---@static
---@param message		string	@Message to log
---@param level			integer	@Log level
---@param data_or_tag?	any		@Optional non-string data to log or tag if string provided
---@param tag?			string	@Optional tag string, if provided, used instead of data_or_tag string as a matter of priority
function Squid.log(message, level, data_or_tag, tag)
	SquidImpl.log(message, level, data_or_tag, tag)
end

---Explicitly save buffer of unsaved logs to a file
---@static
---@return boolean @True if saved logs succesfully, false otherwise
function Squid.save_logs()
	return SquidImpl.save_logs()
end

---Set error callback function that will be called on error after logging it
---@static
---@param callback fun(source: string, message: string, traceback: string)
function Squid.set_error_callback(callback)
	SquidImpl.set_error_callback(callback)
end

---Finalize Squid logging - check for crashes and saved all unsaved buffered logs
---@static
function Squid.final()
	SquidImpl.check_for_crashes()
	SquidImpl.save_logs()
end

---Create a new instance of the Squid logger
---@param tag?  		string	@Optional tag used for all logs when invoked within this instance
---@param is_allowed?	boolean	@Optional flag to set if instance's tag is allowed to be logged initially
function Squid.new(tag, is_allowed)
	tag = tag or "none"
	Squid.set_allowed(tag, is_allowed or false)
	local instance = {
		tag = tag,
		log = function(self, message, data, level) Squid.log(message, data, level, self.tag) end,
		trace = function(self, message, data) Squid.trace(message, data, self.tag) end,
		debug = function(self, message, data) Squid.debug(message, data, self.tag) end,
		info = function(self, message, data) Squid.info(message, data, self.tag) end,
		warn = function(self, message, data) Squid.warn(message, data, self.tag) end,
		error = function(self, message, data) Squid.error(message, data, self.tag) end,
		set_allowed = function(self, tag, is_allowed) Squid.set_allowed(tag or self.tag, is_allowed) end,
		save_logs = function() Squid.save_logs() end,
		init = function() Squid.init() end,
		final = function() Squid.final() end,
		ALLOWLIST = Squid.ALLOWLIST
	}
	return instance
end

---Get Squid configuration
---@return SquidConfig @User configuration table compatible with SquidConfig
function Squid.get_config()
	return SquidImpl.get_config()
end

---Set and use user configuration
---@param config SquidConfig @user configuration table compatible with SquidConfig
function Squid.set_config(config)
	SquidImpl.set_config(config)
end

return Squid