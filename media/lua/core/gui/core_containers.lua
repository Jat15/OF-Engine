--[[! File: lua/core/gui/core_containers.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Features container widgets for the OF GUI.
]]

local max = math.max
local min = math.min

local createtable = require("capi").table_create

local M = require("core.gui.core")

-- consts
local gl, key = M.gl, M.key

-- widget types
local register_class = M.register_class

-- children iteration
local loop_children, loop_children_r = M.loop_children, M.loop_children_r

-- scissoring
local clip_push, clip_pop = M.clip_push, M.clip_pop

-- base widgets
local Widget = M.get_class("Widget")

-- setters
local gen_setter = M.gen_setter

--[[! Struct: H_Box
    A horizontal box. Boxes are containers that hold multiple widgets that
    do not cover each other. It has one extra property, padding, specifying
    the padding between the items (the actual width is width of items
    extended by (nitems-1)*padding).
]]
M.H_Box = register_class("H_Box", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding = kwargs.padding or 0
        return Widget.__init(self, kwargs)
    end,

    layout = function(self)
        self.w, self.h = 0, 0
        local subw = 0
        loop_children(self, function(o)
            o.x = subw
            o.y = 0
            o:layout()
            subw += o.w
            self.h = max(self.h, o.y + o.h)
        end)
        local vstates = self.vstates
        self.w = subw + self.padding * max((vstates and #vstates or 0) +
            #self.children - 1, 0)
        self.subw = subw
    end,

    adjust_children = function(self)
        local vstates = self.vstates
        local nchildren, nvstates = #self.children, (vstates and #vstates or 0)
        if nchildren == 0 and nvstates == 0 then return end
        local offset, space = 0, (self.w - self.subw) / max(nvstates +
            nchildren - 1, 1)
        loop_children(self, function(o)
            o.x = offset
            offset += o.w
            o:adjust_layout(o.x, 0, o.w, self.h)
            offset += space
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding"
})

--[[! Struct: V_Box
    See <H_Box>. This is a vertical variant.
]]
M.V_Box = register_class("V_Box", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding = kwargs.padding or 0
        return Widget.__init(self, kwargs)
    end,

    layout = function(self)
        self.w, self.h = 0, 0
        local subh = 0
        loop_children(self, function(o)
            o.x = 0
            o.y = subh
            o:layout()
            subh += o.h
            self.w = max(self.w, o.x + o.w)
        end)
        local vstates = self.vstates
        self.h = subh + self.padding * max((vstates and #vstates or 0) +
            #self.children - 1, 0)
        self.subh = subh
    end,

    adjust_children = function(self)
        local vstates = self.vstates
        local nchildren, nvstates = #self.children, (vstates and #vstates or 0)
        if nchildren == 0 and nvstates == 0 then return end
        local offset, space = 0, (self.h - self.subh) / max(nvstates +
            nchildren - 1, 1)
        loop_children(self, function(o)
            o.y = offset
            offset += o.h
            o:adjust_layout(0, o.y, self.w, o.h)
            offset += space
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding"
}, M.H_Box.type)

--[[! Struct: Grid
    A grid of elements. It has two properties, columns (specifies the number
    of columns the table will have at max) and again padding (which has the
    same meaning as in boxes). As you append, the children will automatically
    position themselves according to the max number of columns.
]]
M.Grid = register_class("Grid", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.columns = kwargs.columns or 0
        self.padding = kwargs.padding or 0
        return Widget.__init(self, kwargs)
    end,

    layout = function(self)
        local widths, heights = createtable(4), createtable(4)
        self.widths, self.heights = widths, heights

        local column, row = 1, 1
        local columns, padding = self.columns, self.padding

        loop_children(self, function(o)
            o:layout()

            if #widths <= column then
                widths[#widths + 1] = o.w
            elseif o.w > widths[column] then
                widths[column] = o.w
            end

            if #heights <= row then
                heights[#heights + 1] = o.h
            elseif o.h > heights[row] then
                heights[row] = o.h
            end

            column = (column % columns) + 1
            if column == 1 then
                row = row + 1
            end
        end)

        local subw, subh = 0, 0
        for i = 1, #widths  do subw +=  widths[i] end
        for i = 1, #heights do subh += heights[i] end
        self.w = subw + padding * max(#widths  - 1, 0)
        self.h = subh + padding * max(#heights - 1, 0)
        self.subw, self.subh = subw, subh
    end,

    adjust_children = function(self)
        local vstates = self.vstates
        if #self.children == 0 and (not vstates or #vstates == 0) then
            return
        end
        local widths, heights = self.widths, self.heights
        local column , row     = 1, 1
        local offsetx, offsety = 0, 0
        local cspace = (self.w - self.subw) / max(#widths  - 1, 1)
        local rspace = (self.h - self.subh) / max(#heights - 1, 1)
        local columns = self.columns

        loop_children(self, function(o)
            o.x = offsetx
            o.y = offsety

            local wc, hr = widths[column], heights[row]
            o.adjust_layout(o, offsetx, offsety, wc, hr)

            offsetx = offsetx + wc + cspace
            column = (column % columns) + 1

            if column == 1 then
                offsetx = 0
                offsety = offsety + hr + rspace
                row = row + 1
            end
        end)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding",

    --[[! Function: set_columns ]]
    set_columns = gen_setter "columns"
})

--[[! Struct: Clipper
    Clips the children inside of it by clip_w and clip_h.
]]
M.Clipper = register_class("Clipper", Widget, {
    __init = function(self, kwargs)
        kwargs = kwargs or {}
        self.clip_w = kwargs.clip_w or 0
        self.clip_h = kwargs.clip_h or 0
        self.virt_w = 0
        self.virt_h = 0

        return Widget.__init(self, kwargs)
    end,

    layout = function(self)
        Widget.layout(self)
    
        self.virt_w = self.w
        self.virt_h = self.h

        local cw, ch = self.clip_w, self.clip_h

        if cw != 0 then self.w = min(self.w, cw) end
        if ch != 0 then self.h = min(self.h, ch) end
    end,

    adjust_children = function(self)
        Widget.adjust_children(self, 0, 0, self.virt_w, self.virt_h)
    end,

    draw = function(self, sx, sy)
        local cw, ch = self.clip_w, self.clip_h

        if (cw != 0 and self.virt_w > cw) or (ch != 0 and self.virt_h > ch)
        then
            clip_push(sx, sy, self.w, self.h)
            Widget.draw(self, sx, sy)
            clip_pop()
        else
            return Widget.draw(self, sx, sy)
        end
    end,

    --[[! Function: set_clip_w ]]
    set_clip_w = gen_setter "clip_w",

    --[[! Function: set_clip_h ]]
    set_clip_h = gen_setter "clip_h"
})
