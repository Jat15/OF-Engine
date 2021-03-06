--[[!<
    Various types of light entities.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local lights = require("core.engine.lights")

local light_add = lights.add

--! Module: lights
local M = {}

local Marker = ents.Marker

--[[! Object: lights.Dynamic_Light
    A generic "dynamic light" entity class. It's not registered by default
    (a Light from the core set is already dynamic), it serves as a base for
    derived dynamic light types. Inherits from {{$ents.Marker}} entity type of
    the core set. Note: even though this type is not registered by default,
    it's fully functional.

    Properties overlap with the core Light entity type (but it lacks flags)
    including newent properties.
]]
local Dynamic_Light = Marker:clone {
    name = "Dynamic_Light",

    __properties = {
        radius = svars.State_Integer(),
        red    = svars.State_Integer(),
        green  = svars.State_Integer(),
        blue   = svars.State_Integer()
    },

    --! Set to true, as <__run> doesn't work on static entities by default.
    __per_frame = true,

    __init_svars = function(self, kwargs, nd)
        Marker.__init_svars(self, kwargs, nd)
        self:set_attr("radius", 100, nd[4])
        self:set_attr("red",    128, nd[1])
        self:set_attr("green",  128, nd[2])
        self:set_attr("blue",   128, nd[3])
    end,

    --[[!
        Overloaded to show the dynamic light. Derived dynamic light types
        need to override this accordingly.
    ]]
    __run = (not SERVER) and function(self, millis)
        Marker.__run(self, millis)
        local pos = self:get_attr("position")
        light_add(pos, self:get_attr("radius"),
            self:get_attr("red") / 255, self:get_attr("green") / 255,
            self:get_attr("blue") / 255)
    end or nil
}
M.Dynamic_Light = Dynamic_Light

local max, random = math.max, math.random
local floor = math.floor
local flash_flag = lights.flags.FLASH

--[[! Object: lights.Flickering_Light
    A flickering light entity type derived from $Dynamic_Light. This one
    is registered. Delays are in milliseconds. It adds probability, min delay
    and max delay to newent properties of its parent.

    Properties:
        - probability - the flicker probability (from 0 to 1, defaults to 0.5).
        - min_delay - the minimal flicker delay (defaults to 100).
        - max_delay - the maximal flicker delay (defaults to 300).
]]
M.Flickering_Light = Dynamic_Light:clone {
    name = "Flickering_Light",

    __properties = {
        probability = svars.State_Float(),
        min_delay   = svars.State_Integer(),
        max_delay   = svars.State_Integer(),
    },

    __init_svars = function(self, kwargs, nd)
        Dynamic_Light.__init_svars(self, kwargs, nd)
        self:set_attr("probability", 0.5, nd[5])
        self:set_attr("min_delay",   100, nd[6])
        self:set_attr("max_delay",   300, nd[7])
    end,

    __activate = (not SERVER) and function(self, kwargs)
        Marker.__activate(self, kwargs)
        self.delay = 0
    end or nil,

    __run = (not SERVER) and function(self, millis)
        local d = self.delay - millis
        if  d <= 0 then
            d = max(floor(random() * self:get_attr("max_delay")),
                self:get_attr("min_delay"))
            if random() < self:get_attr("probability") then
                local pos = self:get_attr("position")
                light_add(pos, self:get_attr("radius"),
                    self:get_attr("red") / 255, self:get_attr("green") / 255,
                    self:get_attr("blue") / 255, d, 0, flash_flag)
            end
        end
        self.delay = d
    end or nil
}

ents.register_class(M.Flickering_Light)

return M
