--[[!<
    A basic entity set (extends over the base entity).

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local ffi = require("ffi")
local capi = require("capi")
local logging = require("core.logger")
local log = logging.log
local DEBUG = logging.DEBUG

local sound = require("core.engine.sound")
local model = require("core.engine.model")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local msg = require("core.network.msg")
local table2 = require("core.lua.table")
local cs = require("core.engine.cubescript")
local conv = require("core.lua.conv")

local hextorgb = conv.hex_to_rgb

local var_get = cs.var_get

local set_external = require("core.externals").set

local Entity = ents.Entity
local ent_get = ents.get

local assert, unpack, tonumber, tostring = assert, unpack, tonumber, tostring
local connect, emit = signal.connect, signal.emit
local format = string.format
local abs = math.abs
local tconc = table.concat
local min, max = math.min, math.max
local clamp = require("core.lua.math").clamp
local map = table2.map

local set_attachments = capi.set_attachments

-- physics state flags
local MASK_MAT = 0x3
local FLAG_WATER = 1 << 0
local FLAG_LAVA  = 2 << 0
local MASK_LIQUID = 0xC
local FLAG_ABOVELIQUID = 1 << 2
local FLAG_BELOWLIQUID = 2 << 2
local MASK_GROUND = 0x30
local FLAG_ABOVEGROUND = 1 << 4
local FLAG_BELOWGROUND = 2 << 4

local animctl = model.anim_control
local anims = model.anims

local anim_dirs, anim_jump, anim_run
if not SERVER then
    anim_dirs = {
        anims.run_SE, anims.run_S, anims.run_SW,
        anims.run_E,  0,           anims.run_W,
        anims.run_NE, anims.run_N, anims.run_NW
    }

    anim_jump = {
        [anims.jump_N] = true, [anims.jump_NE] = true, [anims.jump_NW] = true,
        [anims.jump_S] = true, [anims.jump_SE] = true, [anims.jump_SW] = true,
        [anims.jump_E] = true, [anims.jump_W ] = true
    }

    anim_run = {
        [anims.run_N] = true, [anims.run_NE] = true, [anims.run_NW] = true,
        [anims.run_S] = true, [anims.run_SE] = true, [anims.run_SW] = true,
        [anims.run_E] = true, [anims.run_W ] = true
    }
end

local mrender = (not SERVER) and model.render

--! Module: ents
local M = ents

--[[!
    Represents the base class for any character (NPC, player etc.). Players
    use the $Player entity class that inherits from this one.
    Inherited property model_name defaults to "player".

    This entity class defines several more properties that do not belong to any
    state variable. These mostly correspond to client_state == {{$State}}.*.
    More will be defined later as needed.

    Non-svar properties:
        - ping - the client ping.
        - plag - the client plag.
        - editing - client_state == EDITING.
        - lagged - client_state == LAGGED.

    Properties:
        - animation [{{$svars.Integer}}] - the entity's current animation.
        - start_time [{{$svars.State_Integer}}] - an internal property used for
          animation timing.
        - model_name [{{$svars.State_String}}] - name of the model associated
          with this entity.
        - attachments [{{$svars.State_Array}}] - an array of model attachments.
          Those are strings in format "tagname,attachmentname".
        - character_name [{{$svars.State_String}}] - name of the character.
        - facing_speed [{{$svars.State_Integer}}] - how fast can the character
          change facing (yaw/pitch) in degrees per second. Defaults to 120.
        - movement_speed [{{$svars.State_Float}}] - how fast the character can
          move. Defaults to 50.
        - yaw [{{$svars.State_Float}}] - the current character yaw in degrees.
        - pitch [{{$svars.State_Float}}] - the current character pitch in
          degrees.
        - roll [{{$svars.State_Float}}] - the current character roll in
          degrees.
        - move [{{$svars.State_Integer}}] - -1 when moving backwards, 0 when
          not moving, 1 when forward.
        - strafe [{{$svars.State_Integer}}] - -1 when strafing left, 0 when not
          strafing, 1 when right.
        - yawing [{{$svars.State_Integer}}] - -1 when turning left, 1 when
          right, 0 when not at all.
        - pitching [{{$svars.State_Integer}}] - -1 when looking down, 1 when
          up, 0 when not.
        - crouching [{{$svars.State_Integer}}] - -1 when crouching down, 1
          when up, 0 when not.
        - jumping [{{$svars.State_Boolean}}] - true when the character has
          jumped, false otherwise.
        - position [{{$svars.State_Vec3}}] - the current position. Defaults to
          { 512, 512, 550 }.
        - velocity [{{$svars.State_Vec3}}] - the current velocity.
        - falling [{{$svars.State_Vec3}}] - the character's gravity falling.
        - radius [{{$svars.State_Float}}] - the character's bounding box
          radius. Defaults to 4.1.
        - above_eye [{{$svars.State_Float}}] - the height of the character
          above its eyes. Defaults to 2.0.
        - eye_height [{{$svars.State_Float}}] - the distance from the ground to
          the eye position. Defaults to 18.0.
        - max_height [{{$svars.State_Float}}] - the maximum distance from the
          ground to the eye position. Defaults to 18.0. Used when crouching.
        - crouch_height [{{$svars.State_Float}}] - the fraction of max_height
          to use when crouched, defaults to 0.75.
        - crouch_speed [{{$svars.State_Float}}] - the fraction of regular
          movement speed to use while crouching, defaults to 0.4.
        - crouch_time [{{$svars.State_Integer}}] - the time in milliseconds
          spent to crouch, adjust to change the speed.
        - jump_velocity [{{$svars.State_Float}}] - the vertical velocity to
          apply when jumping, defaults to 125.
        - gravity [{{$svars.State_Float}}] - a custom character gravity to
          override the global defaults. By default it's -1, which means the
          character will use the global gravity.
        - blocked [{{$svars.State_Boolean}}] - true when the character is
          currently blocked from moving. Floor is not considered an obstacle.
        - can_move [{{$svars.State_Boolean}}] - when false, the character can't
          move. Defaults to true.
        - map_defined_position_data [{{$svars.State_Integer}}] - position
          protocol data specific to the current map, see fpsent (TODO: make
          unsigned).
        - client_state [{{$svars.State_Integer}}] - see $State.
        - physical_state [{{$svars.State_Integer}}] - see $Physical_State.
        - in_liquid [{{$svars.State_Integer}}] - either 0 (in the air) or the
          liquid material id (water, lava).
        - time_in_air [{{$svars.State_Integer}}] - time in milliseconds spent
          in the air (TODO: unsigned).
]]
M.Character = Entity:clone {
    name = "Character",

    -- so that it isn't nonsauer
    sauer_type = -1,

    --[[!
        Defines the "client states". 0 is ALIVE, 1 is DEAD, 2 is SPAWNING,
        3 is LAGGED, 4 is EDITING, 5 is SPECTATOR.
    ]]
    State = {:
        ALIVE = 0, DEAD = 1, SPAWNING = 2, LAGGED = 3, EDITING = 4,
        SPECTATOR = 5
    :},

    --[[!
        Defines the "physical states". 0 is FLOATING, 1 is FALLING,
        2 is SLIDING, 3 is SLOPING, 4 is ON_FLOOR, 5 is STEPPING_UP,
        6 is STEPPING_DOWN, 7 is BOUNCING.
    ]]
    Physical_State = {:
        FLOATING = 0, FALLING = 1, SLIDING = 2, SLOPING = 3,
        ON_FLOOR = 4, STEPPING_UP = 5, STEPPING_DOWN = 6, BOUNCING = 7
    :},

    __properties = {
        animation = svars.State_Integer {
            setter = capi.set_animation, client_set = true
        },
        start_time  = svars.State_Integer { getter = capi.get_start_time },
        model_name  = svars.State_String  { setter = capi.set_model_name },
        attachments = svars.State_Array   {
            setter = function(self, val)
                local arr = ffi.new("const char *[?]", #val + 1)
                for i = 1, #val do arr[i - 1] = val end
                set_attachments(self, arr)
            end
        },

        character_name = svars.State_String(),
        facing_speed   = svars.State_Integer(),

        movement_speed = svars.State_Float {
            getter = capi.get_maxspeed, setter = capi.set_maxspeed
        },
        yaw = svars.State_Float {
            getter = capi.get_yaw, setter = capi.set_yaw,
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = capi.get_pitch, setter = capi.set_pitch,
            custom_sync = true
        },
        roll = svars.State_Float {
            getter = capi.get_roll, setter = capi.set_roll,
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = capi.get_move, setter = capi.set_move,
            custom_sync = true, gui_name = false
        },
        strafe = svars.State_Integer {
            getter = capi.get_strafe, setter = capi.set_strafe,
            custom_sync = true, gui_name = false
        },
        yawing = svars.State_Integer {
            getter = capi.get_yawing, setter = capi.set_yawing,
            custom_sync = true, gui_name = false
        },
        pitching = svars.State_Integer {
            getter = capi.get_pitching, setter = capi.set_pitching,
            custom_sync = true, gui_name = false
        },
        crouching = svars.State_Integer {
            getter = capi.get_crouching, setter = capi.set_crouching,
            custom_sync = true, gui_name = false
        },
        jumping = svars.State_Boolean {
            getter = capi.get_jumping, setter = capi.set_jumping,
            custom_sync = true, gui_name = false
        },
        position = svars.State_Vec3 {
            getter = capi.get_dynent_position,
            setter = capi.set_dynent_position,
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = capi.get_dynent_velocity,
            setter = capi.set_dynent_velocity,
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = capi.get_dynent_falling,
            setter = capi.set_dynent_falling,
            custom_sync = true, gui_name = false
        },
        radius = svars.State_Float {
            getter = capi.get_radius, setter = capi.set_radius
        },
        above_eye = svars.State_Float {
            getter = capi.get_aboveeye, setter = capi.set_aboveeye
        },
        eye_height = svars.State_Float {
            getter = capi.get_eyeheight, setter = capi.set_eyeheight
        },
        max_height = svars.State_Float {
            getter = capi.get_maxheight, setter = capi.set_maxheight
        },
        crouch_height = svars.State_Float {
            getter = capi.get_crouchheight, setter = capi.set_crouchheight
        },
        crouch_speed = svars.State_Float {
            getter = capi.get_crouchspeed, setter = capi.set_crouchspeed
        },
        crouch_time = svars.State_Integer {
            getter = capi.get_crouchtime, setter = capi.set_crouchtime
        },
        jump_velocity = svars.State_Float {
            getter = capi.get_jumpvel, setter = capi.set_jumpvel
        },
        gravity = svars.State_Float {
            getter = capi.get_gravity, setter = capi.set_gravity
        },
        blocked = svars.State_Boolean {
            getter = capi.get_blocked, setter = capi.set_blocked,
            gui_name = false
        },
        can_move = svars.State_Boolean {
            setter = capi.set_can_move, client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = capi.get_mapdefinedposdata,
            setter = capi.set_mapdefinedposdata,
            custom_sync = true, gui_name = false
        },
        client_state = svars.State_Integer {
            getter = capi.get_clientstate, setter = capi.set_clientstate,
            custom_sync = true, gui_name = false
        },
        physical_state = svars.State_Integer {
            getter = capi.get_physstate, setter = capi.set_physstate,
            custom_sync = true, gui_name = false
        },
        in_liquid = svars.State_Integer {
            getter = capi.get_inwater, setter = capi.set_inwater,
            custom_sync = true, gui_name = false
        },
        time_in_air = svars.State_Integer {
            getter = capi.get_timeinair, setter = capi.set_timeinair,
            custom_sync = true, gui_name = false
        },

        physics_trigger = svars.State_Integer { gui_name = false },

        jumping_sound = svars.State_String(),
        landing_sound = svars.State_String()
    },

    --[[!
        A handler called when the character is about to jump. By default sets
        `jumping` to value of its argument.

        Arguments:
            - down - whether the jump key is down.
    ]]
    jump = function(self, down)
        self:set_attr("jumping", down)
    end,

    --[[! Function: crouch
        A handler called when the character is about to crouch. By default
        checks if `down` is true and if it is, sets `crouching` to -1,
        otherwise sets `crouching` to `abs(crouching)`.

        Arguments:
            - down - whether the crouch key is down.
    ]]
    crouch = function(self, down)
        if down then
            self:set_attr("crouching", -1)
        else
            self:set_attr("crouching", abs(self:get_attr("crouching")))
        end
    end,

    get_plag = function(self) return capi.get_plag(self.uid) end,
    get_ping = function(self) return capi.get_ping(self.uid) end,
    get_editing = function(self) return self:get_attr("client_state") == 4 end,
    get_lagged = function(self) return self:get_attr("client_state") == 3 end,

    __init_svars = SERVER and function(self, kwargs)
        Entity.__init_svars(self, kwargs)

        self:set_attr("model_name", "")
        self:set_attr("attachments", {})
        self:set_attr("animation", 3 | (1 << 9))

        self.cn = kwargs and kwargs.cn or -1
        self:set_attr("character_name", "none")
        self:set_attr("model_name", "player")
        self:set_attr("eye_height", 18.0)
        self:set_attr("max_height", 18.0)
        self:set_attr("crouch_height", 0.75)
        self:set_attr("crouch_speed", 0.4)
        self:set_attr("crouch_time", 200)
        self:set_attr("jump_velocity", 125)
        self:set_attr("gravity", -1)
        self:set_attr("above_eye", 2.0)
        self:set_attr("movement_speed", 100.0)
        self:set_attr("facing_speed", 120)
        self:set_attr("position", { 512, 512, 550 })
        self:set_attr("radius", 4.1)
        self:set_attr("can_move", true)

        self:set_attr("physics_trigger", 0)
        self:set_attr("jumping_sound", "gk/jump2.ogg")
        self:set_attr("landing_sound", "olpc/AdamKeshen/kik.wav")
    end or nil,

    __activate = SERVER and function(self, kwargs)
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)
        capi.setup_character(self.uid, self.cn)

        Entity.__activate(self, kwargs)

        self:set_attr("model_name", self:get_attr("model_name"))

        self:flush_queued_svar_changes()
    end or function(self, kwargs)
        Entity.__activate(self, kwargs)

        self.cn = kwargs and kwargs.cn or -1
        capi.setup_character(self.uid, self.cn)

        self.render_args_timestamp = -1

        -- see world.lua for field meanings
        connect(self, "physics_trigger_changed", function(self, val)
            if val == 0 then return end
            self:set_attr("physics_trigger", 0)

            local pos = (self != ents.get_player())
                and self:get_attr("position") or nil

            local lst = val & MASK_LIQUID
            if lst == FLAG_ABOVELIQUID then
                if (val & MASK_MAT) != FLAG_LAVA then
                    sound.play("yo_frankie/amb_waterdrip_2.wav", pos)
                end
            elseif lst == FLAG_BELOWLIQUID then
                sound.play((val & MASK_MAT) == FLAG_LAVA
                    and "yo_frankie/DeathFlash.wav"
                    or "yo_frankie/watersplash2.wav", pos)
            end

            local gst = val & MASK_GROUND
            if gst == FLAG_ABOVEGROUND then
                sound.play(self:get_attr("jumping_sound"), pos)
            elseif gst == FLAG_BELOWGROUND then
                sound.play(self:get_attr("landing_sound"), pos)
            end
        end)
    end,

    __deactivate = function(self)
        capi.destroy_character(self.cn)
        Entity.__deactivate(self)
    end,

    --[[!
        Decides the base time to use for animation rendering of the character.
        By default simply returns `start_time`.
    ]]
    decide_base_time = function(self, anim)
        return self:get_attr("start_time")
    end,

    --[[! Function: __render
        Clientside and run per frame. It renders the character model. Decides
        all the parameters, including animation etc.

        When rendering HUD, the member `hud_model_offset` (vec3) is used to
        offset the HUD model (if available).

        There is one additional argument, fpsshadow - it's true if we're about
        to render a first person shadow (can be true only when needhud is true
        and hudpass is false).

        Arguments:
            - hudpass - a bool, true if we're rendering the HUD pass (whether
              we're rendering a HUD model right now).
            - needhud - true if we're in first person mode.
            - fpsshadow - true if we enabled a FPS player shadow.
    ]]
    __render = (not SERVER) and function(self, hudpass, needhud, fpsshadow)
        if not self.initialized then return end
        if not hudpass and needhud and not fpsshadow then return end

        local state = self:get_attr("client_state")
        -- spawning or spectator
        if state == 5 or state == 2 then return end
        -- editing
        if not hudpass and needhud and state == 4 then return end
        local mdn = (hudpass and needhud)
            and self:get_attr("hud_model_name")
            or  self:get_attr("model_name")

        if mdn == "" then return end

        local yaw, pitch, roll = self:get_attr("yaw"),
            self:get_attr("pitch"),
            self:get_attr("roll")
        local o = self:get_attr("position"):copy()

        if hudpass and needhud and self.hud_model_offset then
            o:add(self.hud_model_offset)
        end

        local pstate = self:get_attr("physical_state")
        local iw = self:get_attr("in_liquid")
        local mv, sf = self:get_attr("move"), self:get_attr("strafe")

        local vel, fall = self:get_attr("velocity"):copy(),
            self:get_attr("falling"):copy()
        local tia = self:get_attr("time_in_air")

        local cr = self:get_attr("crouching")

        local anim = self:decide_animation(state, pstate, mv,
            sf, cr, vel, fall, iw, tia)

        local bt = self:decide_base_time(anim)

        local flags = self:get_render_flags(hudpass, needhud)

        mrender(self, mdn, anim, o, yaw, pitch, roll, flags, bt)
    end or nil,

    --[[! Function: get_render_flags
        Returns the rendering flags used when rendering the character. By
        default, it enables some occlusion stuff. Override as needed.
        Called from $__render. Clientside.

        Arguments:
            - hudpass, needhud - see $__render.
    ]]
    get_render_flags = (not SERVER) and function(self, hudpass, needhud)
        local flags
        if self != ents.get_player() then
            flags = model.render_flags.CULL_VFC
                | model.render_flags.CULL_OCCLUDED
                | model.render_flags.CULL_QUERY
        else
            flags = model.render_flags.FULLBRIGHT
        end
        if needhud then
            if hudpass then
                flags |= model.render_flags.NOBATCH
            else
                flags |= model.render_flags.ONLY_SHADOW
            end
        end
        return flags
    end or nil,

    --[[! Function: get_animation
        Returns the base "action animation" used by $decide_animation. By
        default simply return the `animation` attribute.
    ]]
    get_animation = (not SERVER) and function(self)
        return self:get_attr("animation")
    end or nil,

    --[[! Function: decide_animation
        Decides the current animation for the character. Starts with
        $get_animation, then adjusts it to take things like moving,
        strafing, swimming etc into account. Returns the animation
        (an array) and animation flags (by default 0).

        Arguments:
            - state - client state (see $State).
            - pstate - physical state (see $Physical_State).
            - move, strafe, crouching, vel, falling, unwater, tinair - see
              the appropriate state variables.
    ]]
    decide_animation = (not SERVER) and function(self, state, pstate, move,
    strafe, crouching, vel, falling, inwater, tinair)
        local anim = self:get_animation()

        local mask = anims.INDEX | anims.DIR
        local panim, sanim = anim & mask, (anim >> anims.SECONDARY) & mask

        -- editing or spectator
        if state == 4 or state == 5 then
            panim = anims.edit | animctl.LOOP
        -- lagged
        elseif state == 3 then
            panim = anims.lag | animctl.LOOP
        else
            -- in water and floating or falling
            if inwater != 0 and pstate <= 1 then
                sanim = (((move or strafe) or ((vel.z + falling.z) > 0))
                    and anims.swim or anims.sink) | animctl.LOOP
            -- moving or strafing
            else
                local dir = anim_dirs[(move + 1) * 3 + strafe + 2]
                -- jumping anim
                if tinair > 100 then
                    sanim = ((dir != 0) and (dir + anims.jump_N - anims.run_N)
                        or anims.jump) | animctl.END
                elseif dir != 0 then
                    sanim = dir | animctl.LOOP
                end
            end

            if crouching != 0 then
                local v = sanim & anims.INDEX
                if v == anims.idle then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch
                elseif v == anims.jump then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_jump
                elseif v == anims.swim then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_swim
                elseif v == anims.sink then
                    sanim = sanim & ~anims.INDEX
                    sanim = sanim | anims.crouch_sink
                elseif v == 0 then
                    sanim = anims.crouch | animctl.LOOP
                elseif anim_run[v] then
                    sanim = sanim + anims.crouch_N - anims.run_N
                elseif anim_jump[v] then
                    sanim = sanim + anims.crouch_jump_N - anims.jump_N
                end
            end

            if (panim & anims.INDEX) == anims.idle and
               (sanim & anims.INDEX) != 0 then
                panim = sanim
            end
        end

        if (sanim & anims.INDEX) == 0 then
            sanim = anims.idle | animctl.LOOP
        end
        return panim | (sanim << anims.SECONDARY)
    end or nil,

    --[[!
        Gets the center position of a character, something like gravity center
        (approximate). Useful for e.g. bots (better to aim at this position,
        the actual `position` is feet position). Override if you need this
        non-standard. By default it's 0.75 * eye_height above feet.
    ]]
    get_center = function(self)
        local r = self:get_attr("position"):copy()
        r.z = r.z + self:get_attr("eye_height") * 0.75
        return r
    end,

    --[[!
        Given an origin position (e.g. from an attachment tag), this method
        is supposed to fix it so that it corresponds to where player actually
        targeted from. By default just returns origin.
    ]]
    get_targeting_origin = function(self, origin)
        return origin
    end,

    --[[!
        Sets the `animation` property locally, without notifying the other
        side. Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation = function(self, anim)
        capi.set_animation(self.uid, anim)
        self.svar_values["animation"] = anim
    end,

    --[[!
        Sets the `model_name` property locally, without notifying the other
        side.
    ]]
    set_local_model_name = function(self, mname)
        capi.set_model_name(self.uid, mname)
        self.svar_values["model_name"] = mname
    end
}
local Character = M.Character

--[[! Function: physics_collide_client
    An external called when two clients collide. Takes unique ids of both
    entities. By default emits the "collision" signal on both clients, passing
    the other one as an argument. The client we're testing collisions against
    gets the first emit.
]]
set_external("physics_collide_client", function(cl1, cl2, dx, dy, dz)
    cl1, cl2 = ent_get(cl1), ent_get(cl2)
    emit(cl1, "collision", cl2, dx, dy, dz)
    emit(cl2, "collision", cl1, dx, dy, dz)
end)

set_external("entity_set_local_animation", function(uid, anim)
    ent_get(uid):set_local_animation(anim)
end)

--[[!
    The default entity class for player. Inherits from $Character. Adds
    two new properties.

    Properties:
        - can_edit [false] - if player can edit, it's true (private edit mode).
        - hud_model_name [""] - the first person model to use for the player.
]]
M.Player = Character:clone {
    name = "Player",

    __properties = {
        can_edit = svars.State_Boolean(),
        hud_model_name = svars.State_String()
    },

    __init_svars = SERVER and function(self, kwargs)
        Character.__init_svars(self, kwargs)

        self:set_attr("can_edit", false)
        self:set_attr("hud_model_name", "")
    end or nil
}

ents.register_class(Character)
ents.register_class(M.Player)

local c_get_attr = capi.get_attr
local c_set_attr = capi.set_attr

local gen_attr = function(i, name)
    i = i - 1
    return svars.State_Integer {
        getter = function(ent)      return c_get_attr(ent, i)      end,
        setter = function(ent, val) return c_set_attr(ent, i, val) end,
        gui_name = name, alt_name = name
    }
end

--[[!
    A base for any static entity. Inherits from $Entity. Unlike
    dynamic entities (such as $Character$), static entities usually don't
    invoke their `__run` method per frame. To re-enable that, set the
    `__per_frame` member to true (false by default for efficiency).

    Static entities are persistent by default, so they set the `persistent`
    inherited property to true.

    This entity class is never registered, the inherited ones are.

    Properties:
        position [{{$svars.State_Vec3}}] - the entity position.
]]
M.Static_Entity = Entity:clone {
    name = "Static_Entity",

    --! The icon that'll be displayed in edit mode.
    __edit_icon = "media/interface/icon/edit_generic",

    __per_frame = false,
    sauer_type = 0,
    attr_num   = 0,

    __properties = {
        position = svars.State_Vec3 {
            getter = capi.get_extent_position,
            setter = capi.set_extent_position
        }
    },

    __init_svars = function(self, kwargs)
        debug then log(DEBUG, "Static_Entity.init")

        kwargs = kwargs or {}
        kwargs.persistent = true

        Entity.__init_svars(self, kwargs)
        if not kwargs.position then
            self:set_attr("position", { 511, 512, 513 })
        else
            self:set_attr("position", {
                tonumber(kwargs.position.x),
                tonumber(kwargs.position.y),
                tonumber(kwargs.position.z)
            })
        end

        debug then log(DEBUG, "Static_Entity.init complete")
    end,

    __activate = SERVER and function(self, kwargs)
        kwargs = kwargs or {}

        debug then log(DEBUG, "Static_Entity.__activate")
        Entity.__activate(self, kwargs)

        debug then log(DEBUG, "Static_Entity: extent setup")
        capi.setup_extent(self.uid, self.sauer_type)

        debug then log(DEBUG, "Static_Entity: flush")
        self:flush_queued_svar_changes()

        self:set_attr("position", self:get_attr("position"))
        for i = 1, self.attr_num do
            local an = "attr" .. i
            self:set_attr(an, self:get_attr(an))
        end
    end or function(self, kwargs)
        capi.setup_extent(self.uid, self.sauer_type)
        return Entity.__activate(self, kwargs)
    end,

    __deactivate = function(self)
        capi.destroy_extent(self.uid)
        return Entity.__deactivate(self)
    end,

    send_notification_full = SERVER and function(self, cn)
        local acn = msg.ALL_CLIENTS
        cn = cn or acn

        local cns = (cn == acn) and map(ents.get_players(), function(p)
            return p.cn end) or { cn }

        local uid = self.uid
        debug then log(DEBUG, "Static_Entity.send_notification_full: "
            .. cn .. ", " .. uid)

        local scn, sname = self.cn, self.name
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, capi.extent_notification_complete, uid, sname,
                self:build_sdata({ target_cn = n, compressed = true }))
        end

        debug then log(DEBUG, "Static_Entity.send_notification_full: done")
    end or nil,

    --[[!
        See {{$Character.get_center}}. By default this is the entity position.
        May be overloaded for other entity types.
    ]]
    get_center = function(self)
        return self:get_attr("position"):copy()
    end,

    --[[!
        Returns the color of the entity icon in edit mode. If an invalid
        value is returned, it defaults to 255, 255, 255 (white). This is
        useful for e.g. light entity that is colored.
    ]]
    __get_edit_color = function(self)
        return 255, 255, 255
    end,

    --[[!
        Returns any piece of information displayed in in the edit HUD in
        addition to the entity name. Overload for different entity types.
    ]]
    __get_edit_info = function(self)
        return nil
    end,

    --[[!
        Returns the currently attached entity. Useful mainly for spotlights.
        This refers to the "internally attached" entity that the core engine
        works with.
    ]]
    get_attached_entity = function(self)
        return capi.get_attached_entity(self.uid)
    end,

    --[[!
        Returns the height above the floor to use when dropping the entity
        to the floor. By default returns 4, may be useful to overload (for
        say, mapmodels).
    ]]
    get_edit_drop_height = function(self)
        return 4
    end
}
local Static_Entity = M.Static_Entity

--[[! Function: entity_get_edit_info
    An external. Returns `ent.__edit_icon`,
    `ent:{{$Static_Entity.__get_edit_color|__get_edit_color}}()` where `ent`
    is the entity with unique id `uid`.
]]
set_external("entity_get_edit_icon_info", function(uid)
    local ent = ent_get(uid)
    return ent.__edit_icon, ent:__get_edit_color()
end)

--[[! Function: entity_get_edit_info
    An external. Returns the entity name and the return value of
    {{$Static_Entity.__get_edit_info}}.
]]
set_external("entity_get_edit_info", function(uid)
    local ent = ent_get(uid)
    return ent.name, ent:__get_edit_info()
end)

--[[! Function: entity_get_edit_drop_height
    An external, see {{$Static_Entity.get_edit_drop_height}}. Takes the uid.
]]
set_external("entity_get_edit_drop_height", function(ent)
    return ent_get(ent):get_edit_drop_height()
end)

--[[!
    A generic marker without orientation. It doesn't have any default
    additional properties.
]]
M.Marker = Static_Entity:clone {
    name = "Marker",

    __edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 1,

    --! Places the given entity on this marker's position.
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
    end
}
local Marker = M.Marker

--[[!
    A generic (oriented) marker with a wide variety of uses. Can be used as
    a base for various position markers (e.g. playerstarts).

    An example of world marker usage is a cutscene system. Different marker
    types inherited from this one can represent different nodes.

    Properties:
        - attr1 - aka "yaw".
        - attr2 - aka "pitch".
]]
M.Oriented_Marker = Static_Entity:clone {
    name = "Oriented_Marker",

    __edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 2,
    attr_num   = 2,

    __properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch")
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("yaw", 0, nd[1])
        self:set_attr("pitch", 0, nd[2])
    end,

    --! Places the given entity on this marker's position, using yaw and pitch.
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
        ent:set_attr("yaw", self:get_attr("yaw"))
        ent:set_attr("pitch", self:get_attr("pitch"))
    end,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d", self:get_attr("yaw"),
            self:get_attr("pitch"))
    end
}
local Oriented_Marker = M.Oriented_Marker

local lightflags = setmetatable({
    [0] = "dynamic (0)",
    [1] = "none (1)",
    [2] = "static (2)"
}, {
    __index = function(self, i)
        return ("invalid (%d)"):format(i)
    end
})

--[[!
    A regular point light. In the extension library there are special light
    entity types that are e.g. triggered, flickering and so on. When providing
    properties as extra arguments to newent, you can specify red, green, blue,
    radius and shadow in that order.

    Properties:
        - attr1 - light radius. (0 to N, alias "radius", default 100 - 0 or
          lower means the light is off)
        - attr2 - red value (can be any range, even negative - typical values
          are 0 to 255, negative values make a negative light, alias "red",
          default 128)
        - attr3 - green value (alias "green", default 128)
        - attr4 - blue value (alias "blue", default 128)
        - attr5 - shadow type, 0 means dnyamic, 1 disabled, 2 static (default 0).
]]
M.Light = Static_Entity:clone {
    name = "Light",

    __edit_icon = "media/interface/icon/edit_light",

    sauer_type = 3,
    attr_num   = 5,

    __properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "red"),
        attr3 = gen_attr(3, "green"),
        attr4 = gen_attr(4, "blue"),
        attr5 = gen_attr(5, "shadow")
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("red", 128, nd[1])
        self:set_attr("green", 128, nd[2])
        self:set_attr("blue", 128, nd[3])
        self:set_attr("radius", 100, nd[4])
        self:set_attr("shadow", 0, nd[5])
    end,

    __get_edit_color = function(self)
        return self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
    end,

    __get_edit_info = function(self)
        return format("red :\f2 %d \f7| green :\f2 %d \f7| blue :\f2 %d\n\f7"
            .. "radius :\f2 %d \f7| shadow :\f2 %s",
            self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue"), self:get_attr("radius"),
            lightflags[self:get_attr("shadow")])
    end
}

--[[!
    A spot light. It's attached to the nearest $Light. Properties such as
    color are retrieved from the attached light entity.

    Properties:
        - attr1 - alias "radius", defaults to 90, in degrees (90 is a full
          hemisphere, 0 is a line)
]]
M.Spot_Light = Static_Entity:clone {
    name = "Spot_Light",

    __edit_icon = "media/interface/icon/edit_spotlight",

    sauer_type = 4,
    attr_num   = 1,

    __properties = {
        attr1 = gen_attr(1, "radius")
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("radius", 90, nd[1])
    end,

    __get_edit_color = function(self)
        local ent = self:get_attached_entity()
        if not ent then return 255, 255, 255 end
        return ent:get_attr("red"), ent:get_attr("green"), ent:get_attr("blue")
    end,

    __get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}

--[[!
    An environment map entity class. Things reflecting on their surface using
    environment maps can generate their envmap from the nearest envmap entity
    instead of using skybox and reflect geometry that way (statically). You
    can specify the radius as an extra argument to newent.

    Properties:
        - attr1 - alias "radius", the distance it'll still have effect in,
          defaults to 128.
]]
M.Envmap = Static_Entity:clone {
    name = "Envmap",

    __edit_icon = "media/interface/icon/edit_envmap",

    sauer_type = 5,
    attr_num   = 1,

    __properties = {
        attr1 = gen_attr(1, "radius")
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("radius", 128, nd[1])
    end,

    __get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}

--[[!
    An ambient sound in the world. Repeats the given sound at entity position.
    You can specify the sound name, volume, radius and size as extra arguments
    to newent.

    Properties:
        - attr1 - the sound radius (alias "radius", default 100)
        - attr2 - the sound size, if this is 0, the sound is a point source,
          otherwise the sound volume will always be max until the distance
          specified by this property and then it'll start fading off
          (alias "size", default 0).
        - attr3 - the sound volume, from 0 to 100 (alias "volume",
          default 100).
        - sound_name [{{$svars.State_String}}] - the  path to the sound in
          media/sound (default "").
]]
M.Sound = Static_Entity:clone {
    name = "Sound",

    __edit_icon = "media/interface/icon/edit_sound",

    sauer_type = 6,
    attr_num   = 3,

    __properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "size"),
        attr3 = gen_attr(3, "volume"),
        sound_name = svars.State_String()
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("radius", 100, nd[3])
        self:set_attr("size", 0, nd[4])
        self:set_attr("volume", 100, nd[2])
        self:set_attr("sound_name", "", nd[1])
    end,

    __activate = (not SERVER) and function(self, ...)
        Static_Entity.__activate(self, ...)
        local f = |self| capi.sound_stop_map(self.uid)
        connect(self, "sound_name_changed", f)
        connect(self, "radius_changed", f)
        connect(self, "size_changed", f)
        connect(self, "volume_changed", f)
    end or nil,

    __get_edit_info = function(self)
        return format("radius :\f2 %d \f7| size :\f2 %d \f7| volume :\f2 %d"
            .. "\n\f7name :\f2 %s",
            self:get_attr("radius"), self:get_attr("size"),
            self:get_attr("volume"), self:get_attr("sound_name"))
    end,

    __play_sound = function(self)
        capi.sound_play_map(self.uid, self:get_attr("sound_name"),
            self:get_attr("volume"))
    end
}

set_external("sound_play_map", function(uid)
    ent_get(uid):__play_sound()
end)

--[[!
    A particle effect entity class. You can derive from this to create
    your own effects, but by default this doesn't draw anything and is
    not registered.
]]
M.Particle_Effect = Static_Entity:clone {
    name = "Particle_Effect",

    __edit_icon  = "media/interface/icon/edit_particles",
    sauer_type = 7,

    --! Returns 0.
    get_edit_drop_height = function(self)
        return 0
    end,

    --! This is what you need to override - draw your particles from here.
    __emit_particles = function(self) end
}

set_external("particle_entity_emit", function(uid)
    ent_get(uid):__emit_particles()
end)

--[[!
    A model in the world. All attrs default to 0. On mapmodels and all
    entity types derived from mapmodels, the engine emits the `collision`
    signal with the collider entity passed as an argument when collided.
    You can specify the model name, yaw, pitch, roll and scale as extra
    arguments to newent.

    Properties:
        - animation [{{$svars.State_Integer}}] - the mapmodel's current
          animation. See $Character.
        - start_time [{{$svars.State_Integer}}] - an internal property used for
          animation timing.
        - model_name [{{$svars.State_String}}] - name of the model associated
          with this mapmodel.
        - attachments [{{$svars.State_Array}}] - an array of model attachments.
          Those are strings in format "tagname,attachmentname".
        - attr1 - the model yaw, alias "yaw".
        - attr2 - the model pitch, alias "pitch".
        - attr3 - the model roll, alias "roll".
        - attr4 - the model scale, alias "scale".
]]
M.Mapmodel = Static_Entity:clone {
    name = "Mapmodel",

    __edit_icon = "media/interface/icon/edit_mapmodel",

    sauer_type = 8,
    attr_num   = 4,

    __properties = {
        animation = svars.State_Integer {
            setter = capi.set_animation, client_set = true
        },
        start_time  = svars.State_Integer { getter = capi.get_start_time   },
        model_name  = svars.State_String  { setter = capi.set_model_name   },
        attachments = svars.State_Array   {
            setter = function(self, val)
                return set_attachments(self, map(val, function(str)
                    return str:split(",")
                end))
            end
        },

        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "scale")
    },

    __init_svars = SERVER and function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("model_name", "", nd[1])
        self:set_attr("yaw", 0, nd[2])
        self:set_attr("pitch", 0, nd[3])
        self:set_attr("roll", 0, nd[4])
        self:set_attr("scale", 0, nd[5])
        self:set_attr("attachments", {})
        self:set_attr("animation", 3 | (1 << 9))
    end or nil,

    __activate = SERVER and function(self, kwargs)
        Static_Entity.__activate(self, kwargs)
        self:set_attr("model_name", self:get_attr("model_name"))
    end or nil,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d \f7|"
            .. " scale :\f2 %d\n\f7name :\f2 %s",
            self:get_attr("yaw"), self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("scale"),
            self:get_attr("model_name"))
    end,

    --! Returns 0.
    get_edit_drop_height = function(self)
        return 0
    end,

    --! See {{$Character.set_local_animation}}.
    set_local_animation = Character.set_local_animation,

    --! See {{$Character.set_local_model_name}}.
    set_local_model_name = Character.set_local_model_name
}

--[[! Function: physics_collide_mapmodel
    An external called when a client collides with a mapmodel. Takes the
    collider entity uid (the client) and the mapmodel entity uid. By default
    emits the `collision` signal on both entities, passing the other one as an
    argument. The mapmodel takes precedence.
]]
set_external("physics_collide_mapmodel", function(collider, entity)
    collider, entity = ent_get(collider), ent_get(entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

--[[!
    An entity class that emits a `collision` signal on itself when a client
    (player, NPC...) collides with it. You can specify the properties as extra
    arguments to newent.

    Properties:
        - attr1, attr2, attr3 - alias "yaw", "pitch", "roll", all 0.
        - attr4, attr5, attr6 - alias "a", "b", "c" (the dimensions,
          10, 10, 10 by default).
        - attr7 - alias "solid", makes the obstacle solid when not 0 (0
          by default).
]]
M.Obstacle = Static_Entity:clone {
    name = "Obstacle",

    sauer_type = 9,
    attr_num   = 7,

    __properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "a"),
        attr5 = gen_attr(5, "b"),
        attr6 = gen_attr(6, "c"),
        attr7 = gen_attr(7, "solid")
    },

    __init_svars = function(self, kwargs, nd)
        Static_Entity.__init_svars(self, kwargs, nd)
        self:set_attr("yaw", 0, nd[4])
        self:set_attr("pitch", 0, nd[5])
        self:set_attr("roll", 0, nd[6])
        self:set_attr("a", 10, nd[1])
        self:set_attr("b", 10, nd[2])
        self:set_attr("c", 10, nd[3])
        self:set_attr("solid", 0, nd[7])
    end,

    __get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d\n\f7"
            .. "a :\f2 %d \f7| b :\f2 %d \f7| c :\f2 %d \f7| solid :\f2 %d",
            self:get_attr("yaw"),  self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("a"),
            self:get_attr("b"),    self:get_attr("c"), self:get_attr("solid"))
    end,

    --! Returns 0.
    get_edit_drop_height = function(self)
        return 0
    end
}

--[[! Function: physics_collide_area
    An external called when a client collides with an area. Takes the
    collider entity uid (the client) and the area entity uid. By default emits
    the `collision` signal on both entities, passing the other one as an
    argument. The obstacle takes precedence.
]]
set_external("physics_collide_area", function(collider, entity)
    collider, entity = ent_get(collider), ent_get(entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

ents.register_class(M.Marker)
ents.register_class(M.Oriented_Marker)
ents.register_class(M.Light)
ents.register_class(M.Spot_Light)
ents.register_class(M.Envmap)
ents.register_class(M.Sound)
ents.register_class(M.Mapmodel)
ents.register_class(M.Obstacle)
