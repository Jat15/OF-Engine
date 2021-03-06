--[[!<
    Various button widgets.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local signal = require("core.events.signal")

--! Module: core
local M = require("core.gui.core")

local emit = signal.emit

-- input event management
local is_clicked, is_hovering, is_focused = M.is_clicked, M.is_hovering,
    M.is_focused
local get_menu = M.get_menu

-- widget types
local register_class = M.register_class

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

-- keys
local key = M.key

local clicked_states = {
    [key.MOUSELEFT   ] = "clicked_left",
    [key.MOUSEMIDDLE ] = "clicked_middle",
    [key.MOUSERIGHT  ] = "clicked_right",
    [key.MOUSEBACK   ] = "clicked_back",
    [key.MOUSEFORWARD] = "clicked_forward"
}

--[[!
    A button has five states, "default", "hovering", "clicked_left",
    "clicked_right" and "clicked_middle". On click it emits the "click" signal
    on itself (which is handled by $Widget, the button itself doesn't do
    anything).
]]
M.Button = register_class("Button", Widget, {
    choose_state = function(self)
        return clicked_states[is_clicked(self)] or
            (is_hovering(self) and "hovering" or "default")
    end,

    --[[!
        Buttons can take be hovered on. Assuming `self:target(cx, cy)` returns
        anything, this returns itself. That means if a child can be targeted,
        the hovered widget will be the button itself.
    ]]
    hover = function(self, cx, cy)
        return self:target(cx, cy) and self
    end,

    --! See $hover.
    click = function(self, cx, cy)
        return self:target(cx, cy) and self
    end
})
local Button = M.Button

--[[!
    Like $Button, but adds a new state, "menu", when a menu is currently
    opened using this button.
]]
M.Menu_Button = register_class("Menu_Button", Button, {
    choose_state = function(self)
        return get_menu(self) != nil and "menu" or Button.choose_state(self)
    end
})

--[[!
    Derived from $Button. The space key serves the same purpose as clicking
    (when focused).

    Properties:
        - condition - a callable object, if it returns something that evaluates
          as true, either the "toggled" or "toggled_hovering" state is used,
          otherwise "default" or "default_hovering" is used. The condition
          is passed the current object as an argument.
]]
M.Toggle = register_class("Toggle", Button, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.condition = kwargs.condition
        return Button.__ctor(self, kwargs)
    end,

    choose_state = function(self)
        local h, f = is_hovering(self), is_focused(self)
        return (self.condition and self:condition() and
            (h and "toggled_hovering" or (f and "toggled_focused"
                or "toggled")) or
            (h and "default_hovering" or (f and "default_focused"
                or "default")))
    end,

    key = function(self, code, isdown)
        if is_focused(self) and code == key.SPACE then
            emit(self, isdown and "clicked" or "released", -1, -1, code)
            return true
        end
        return Widget.key(self, code, isdown)
    end,

    --! Function: set_condition
    set_condition = gen_setter "condition"
})
