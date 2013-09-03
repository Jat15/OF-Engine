--[[! File: lua/core/gui/core_misc.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Misc widgets.
]]

local table2 = require("core.lua.table")

local find = table2.find
local tremove = table.remove

local M = require("core.gui.core")
local world = M.get_world()

-- input event management
local is_clicked, clear_focus = M.is_clicked, M.clear_focus

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- projection
local get_projection = M.get_projection

-- keys
local key = M.key

--[[! Struct: Conditional
    Conditional has two states, "true" and "false". It has a property,
    "condition", which is a function. If that function exists and returns
    a value that can be evaluated as true, the "true" state is set, otherwise
    the "false" state is set.
]]
M.Conditional = register_class("Conditional", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Widget.__init(self, kwargs)
    end,

    choose_state = function(self)
        return (self.condition and self:p_condition()) and "true" or "false"
    end,

    --[[! Function: set_condition ]]
    set_condition = gen_setter "condition"
})

--[[! Struct: Mover
    A widget using which you can move windows. The window must have the
    floating property set to true or it won't move. It doesn't have any
    appearance or states, those are defined by its children.

    If you have multiple movable windows, the mover will take care of
    moving the current window to the top. That means you don't have to care
    about re-stacking them.

    It has one property called "window" which is a reference to the window
    this mover belongs to. Without it, it won't work.
]]
M.Mover = register_class("Mover", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.window = kwargs.window
        return Widget.__init(self, kwargs)
    end,

    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    click = function(self, cx, cy, code)
        if code != key.MOUSELEFT then
            return Widget.click(self, cx, cy, code)
        end
        local  w = self.window
        if not w then return self:target(cx, cy) and self end
        local c = w.parent.children
        local n = find(c, w)
        local l = #c
        if n != l then c[l] = tremove(c, n) end
        return self:target(cx, cy) and self
    end,

    can_move = function(self, cx, cy)
        local win = self.window
        local wp = win.parent

        -- no parent means world; we don't need checking for non-mdi windows
        if not wp.parent then return true end

        local rx, ry, p = self.x, self.y, wp
        while true do
            rx, ry = rx + p.x, ry + py
            local  pp = p.parent
            if not pp then break end
            p    = pp
        end

        if cx < rx or cy < ry or cx > (rx + wp.w) or cy > (ry + wp.h) then
            -- avoid bugs; stop moving when cursor is outside
            clear_focus(self)
            return false
        end

        return true
    end,

    clicked = function(self, cx, cy, code)
        if code == key.MOUSELEFT then
            self.ox, self.oy = cx, cy
        end
    end,

    holding = function(self, cx, cy, code)
        local w = self.window
        if w and w.floating and code == key.MOUSELEFT and self:can_move() then
            local dx, dy = cx - self.ox, cy - self.oy
            w.fx, w.x = w.fx + dx, w.x + dx
            w.fy, w.y = w.fy + dy, w.y + dy
        end
        Widget.holding(self, cx, cy, code)
    end,

    --[[! Function: set_window ]]
    set_window = gen_setter "window"
})
