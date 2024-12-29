![](media/Squid-hero.png)

# SQUID 🦑

**Squid** is a standalone injectable system for saveable logging of user logs, errors and crashes for Defold.

License: MIT

Copyright 2024-2025 Paweł Jarosz

---

## Defold dependency:

You can add Squid as a dependency to Defold. Open your `game.project` file and add the following link as an entry in the `Dependencies` under the `Project` section. Current version is 1.0: 

`https://github.com/paweljarosz/squid/archive/refs/tags/1.0.zip`

Squid uses also immutable configuration, so add dependency to newest Immutable too. Current is 1.1:

`https://github.com/paweljarosz/lua-immutable/archive/refs/tags/v1.1.zip`

## Usage:

Squid offers simple static API, check examples:

```lua
	-- If squid is initialized with init() it will handle errors and crashes automatically too
	squid.init()

	-- Define new tag strings and enable/disable them:
	squid.set_allowed("main", true)

	-- Use static logging functions with or without optional non-string data and/or tag string:
	squid.trace("My Trace Message")								-- no data and no tag, uses default tag ("none")
	squid.debug("My Debug Message  ", { my_test_data = 1 })		-- with optional non-string data (default tag used)
	squid.info( "My Info Message   ", "main")					-- with string data only (used as tag too)
	squid.warn( "My Warning Message", "Hello World", "main")	-- with string data and tag ("main" tag is used as tag here)
	squid.error("My Error Message  ", vmath.vector3(1), "main")	-- with non-string data and tag

	-- Or generic logging function with own logging level:
	squid.log("My Other Message", squid.DEBUG)

    -- You can explicitly save any unsaved buffered logs to a file at any time:
	--(logs are saved automatically anyway, in batch, every X logs if configured in game.project)
	squid.save_logs()

	-- If squid.final() is called (in final() preferably) it checks for crash dumps and saves all unsaved buffered logs
	squid.final()
```

### Instancing

Squid can be conveniently used as internal logger module for various other Defold modules, e.g.:
* [Pigeon](https://github.com/paweljarosz/pigeon) by Paweł Jarosz
* [Defold Saver](https://github.com/Insality/defold-saver) by Insality
* [Defold Event](https://github.com/Insality/defold-event) by Insality

```lua
	-- Create new instance with optional tag assigned (`none` by default) initially allowed or not:
	local is_allowed = true
	self.player_logger = squid.new("player", is_allowed)

	-- Use all API function with the created instance:
	self.player_logger:info("Logger with 'player' tag")
```

Above prints in console and writes to a log file:
```lua
TRACE:  [none]: [16:05:06] main/main.script:13: My Trace Message
DEBUG:  [none]: [16:05:06] main/main.script:14: My Debug Message  
 Data:
  {
    my_test_data = 1,
  }
INFO:   [main]: [16:05:06] main/main.script:15: My Info Message   
WARNING:[main]: [16:05:06] main/main.script:16: My Warning Message
ERROR:  [main]: [16:05:06] main/main.script:17: My Error Message  
 Data: vmath.vector3(1, 1, 1)
DEBUG:  [none]: [16:05:06] main/main.script:19: My Other Message
```

Additionally, the different log level messages are colored in Defold console:

![](media/console.png)

### Configuration

Squid can be configured in Defold's `game.project` file. Add squid configuration at the end of the file:

```
[squid]
app_catalog = squid_app_catalog
log_file_name = squid_log_file
log_file_extension = log
is_enabled = 1
is_enabled_in_release = 1
is_printing = 1
is_saving = 1
is_adding_timestamp = 1
is_using_allowlist = 1
days_to_delete_logs = 7
min_log_level = 1
unsaved_logs_buffer = 30
max_log_length = 50
max_data_depth = 5
```

### Thanks

Squid is heavily inspired by [Log](https://github.com/subsoap/log) and [Err](https://github.com/subsoap/err) by Subsoap and [Defold Log](https://github.com/Insality/defold-log) by Insality and uses and iterates over some of their solutions. Squid tries to be compatible with both APIs for easier replacements.

---

### Changelog

#### 1.0
First public version release.

---

### License

MIT

Copyright 2024-2025 Paweł Jarosz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.