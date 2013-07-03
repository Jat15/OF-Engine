--[[! File: lua/core/engine/model.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Lua model API.
]]

local bit = require("bit")

local M = {}

local ran = _C.model_register_anim

--[[! Variable: anims
    An enumeration of all basic (pre-defined) animations available in the
    engine. Possible values are IDLE, FORWARD, BACKWARD, LEFT, RIGHT, CROUCH,
    CROUCH_FORAWRD, CROUCH_BACKWARD, CROUCH_LEFT, CROUCH_RIGHT, JUMP, SINK,
    SWIM, EDIT, LAG, MAPMODEL.

    There are also modifiers, INDEX, LOOP, START, END and REVERSE. You can
    use them with bitwise OR to control the animation.
]]
M.anims = {
    IDLE = ran "idle", FORWARD = ran "forward", BACKWARD = ran "backward",
    LEFT = ran "left", RIGHT = ran "right", CROUCH = ran "crouch",
    CROUCH_FORWARD = ran "crouch_forward",
    CROUCH_BACKWARD = ran "crouch_backward",
    CROUCH_LEFT = ran "crouch_left", CROUCH_RIGHT = ran "crouch_right",
    JUMP = ran "jump", SINK = ran "sink", SWIM = ran "swim",
    CROUCH_JUMP = ran "crouch_jump", CROUCH_SINK = ran "crouch_sink",
    CROUCH_SWIM = ran "crouch_swim", EDIT = ran "edit", LAG = ran "lag",
    MAPMODEL = ran "mapmodel",

    INDEX = 0x1FF,
    LOOP = bit.lshift(1, 9),
    CLAMP = bit.lshift(1, 10),
    REVERSE = bit.lshift(1, 11),
    START = bit.bor(bit.lshift(1, 9), bit.lshift(1, 10)),
    END = bit.bor(bit.lshift(1, 9), bit.lshift(1, 10), bit.lshift(1, 11))
}

--[[! Variable: render_flags
    Contains flags for model rendering. CULL_VFC is a view frustrum culling
    flag, CULL_DIST is a distance culling flag, CULL_OCCLUDED is an occlusion
    culling flag, CULL_QUERY is hw occlusion queries flag, FULLBRIGHT makes
    the model fullbright, NORENDER disables rendering, MAPMODEL is a mapmodel
    flag, NOBATCH disables batching on the model.
]]
M.render_flags = {
    CULL_VFC = bit.lshift(1, 0), CULL_DIST = bit.lshift(1, 1),
    CULL_OCCLUDED = bit.lshift(1, 2), CULL_QUERY = bit.lshift(1, 3),
    FULLBRIGHT = bit.lshift(1, 4), NORENDER = bit.lshift(1, 5),
    MAPMODEL = bit.lshift(1, 6), NOBATCH = bit.lshift(1, 7)
}

--[[! Function: register_anim
    Registers an animation of the given name. Returns the animation number
    that you can then use. If an animation of the same name already exists,
    it just returns its number. It also returns a second boolean value that
    is true when the animation was actually newly registered and false when
    it just re-returned an already existing animation.
]]
M.register_anim = ran

--[[! Function: get_anim
    Returns the animation number for the given animation name. If no such
    animation exists, returns nil.
]]
M.get_anim = _C.model_get_anim

--[[! Function: find_anims
    Finds animations whose names match the given pattern. It's a regular
    Lua pattern. It also accepts integers (as in animation numbers). It
    returns an array of all animation numbers that match the input. The
    result is sorted.
]]
local find_anims = _C.model_find_anims

--[[! Function: clear
    Clears a model with a name given by the argument (which is relative
    to media/model) and reloads.
]]
M.clear = _C.model_clear

--[[! Function: preload
    Adds a model into the preload queue for faster loading. Name is
    again relative to media/model.
]]
M.preload = _C.model_preload

local mrender = _C.model_render

--[[! Function: render
    Renders a model. Takes the entity which owns the model, the model name
    (relative to media/model), animation (see above), animation flags,
    position (vec3), yaw, pitch, roll, flags (see render_flags), basetime
    (start_time) and trans (which is model transparency that ranges from 0
    to 1 and defaults to 1).
]]
M.render = function(ent, mdl, anim, animflags, pos, yaw, pitch, roll, flags,
btime, trans)
    mrender(ent, mdl, anim, animflags, pos.x, pos.y, pos.z, yaw, pitch, roll,
        flags, btime, trans)
end

--[[! Function: get_bounding_box
    Returns the bounding box of the given model as two vec3, center and
    radius.
]]
M.get_bounding_box = _C.model_get_boundbox

--[[! Function: get_collision_box
    Returns the collision box of the given model as two vec3, center and
    radius.
]]
M.get_collision_box = _C.model_get_collisionbox

--[[! Function: get_mesh
    Returns the mesh information about the given model as a table.
    It contains information about each triangle. The return value
    is a table (an array) which contains tables (representing triangles).
    The triangles are associative arrays with members a, b, c where a,
    b, c are vec3.
]]
M.get_mesh = _C.model_get_mesh

return M
