--[[!<
    Loads all required core modules, sets up logging, loads the FFI
    and sets up the default environment.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--[[! Object: _G
    Sets up the default _G metatable in that way it won't allow creation
    of global variables and usage of non-existent global variables.
]]
setmetatable(_G, {
    __newindex = function(self, n)
        error("attempt to create a global variable '" .. n .. "'", 2)
    end,
    __index = function(self, n)
        error("attempt to use a global variable '" .. n .. "'", 2)
    end
})

-- init a random seed
math.randomseed(os.time())

--[[!
    Traces what Lua does and logs it into the console. Not in use by
    default. Very verbose. Use only when absolutely required. Uncomment
    the sethook line to use it. Takes two arguments, the caught event and
    the line on which the event was caught.

    Does not get logged, just printed into the console.

    ```
    debug.sethook(trace, "c")
    ```
]]
local trace = function(event, line)
    local s = debug.getinfo(2, "nSl")
    print("DEBUG:")
    print("    " .. tostring(s.name))
    print("    " .. tostring(s.namewhat))
    print("    " .. tostring(s.source))
    print("    " .. tostring(s.short_src))
    print("    " .. tostring(s.linedefined))
    print("    " .. tostring(s.lastlinedefined))
    print("    " .. tostring(s.what))
    print("    " .. tostring(s.currentline))
end

--debug.sethook(trace, "c")

local capi = require("capi")

-- patch capi
require("core.capi")

capi.log(1, "Initializing logging.")

local log = require("core.logger")

require("core.externals")

log.log(log.DEBUG, "Initializing the core library.")

log.log(log.DEBUG, ":: Lua extensions.")
require("core.lua")

log.log(log.DEBUG, ":: Network system.")
require("core.network")

log.log(log.DEBUG, ":: Event system.")
require("core.events")

log.log(log.DEBUG, ":: Engine system.")
require("core.engine")

log.log(log.DEBUG, ":: Entity system.")
require("core.entities")

log.log(log.DEBUG, ":: GUI.")
require("core.gui")

log.log(log.DEBUG, "Core scripting initialization complete.")
