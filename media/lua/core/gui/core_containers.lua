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

-- adjustment
local adjust = M.adjust

local CLAMP_LEFT, CLAMP_RIGHT, CLAMP_TOP, CLAMP_BOTTOM in adjust

--[[! Struct: H_Box
    A horizontal box. Boxes are containers that hold multiple widgets that
    do not cover each other. It has three extra properties.

    The first property, padding, specifies the padding between the items
    (the actual width is width of items extended by (nitems-1)*padding).

    The second property is "expand" and it's a boolean value (defaults to
    false). If you set it to true, items clamped from both left and right
    will divide the remaining space the other items didn't fill between
    themselves, in the other case clamping will have no effect and the
    items will be aligned evenly through the list.

    The third property is "homogenous" and it attempts to reserve an equal
    amount of space for every item. Items that clamp will be clamped inside
    their space and the other items will be aligned depending on their own
    alignment.

    The property "homogenous" takes precedence over "expand". Only one can
    be in effect (or none of them).
]]
M.H_Box = register_class("H_Box", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding    = kwargs.padding    or 0
        self.expand     = kwargs.expand     or false
        self.homogenous = kwargs.homogenous or false
        return Widget.__ctor(self, kwargs)
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
        self.w = subw + self.padding * max(#self.vstates + 
            #self.children - 1, 0)
        self.subw = subw
    end,

    adjust_children_regular = function(self, nch, nvs, hmg)
        local offset, space = 0, (self.w - self.subw) / max(nvs + nch - 1, 1)
        loop_children(self, function(o)
            o.x = offset
            offset += o.w + space
            o:adjust_layout(o.x, 0, o.w, self.h)
        end)
    end,

    adjust_children_homogenous = function(self, nch, nvs)
        local pad = self.padding
        local offset, space = 0, (self.w - self.subw - (nvs + nch - 1) * pad)
            / max(nvs + nch, 1)
        loop_children(self, function(o)
            o.x = offset
            offset += o.w + space + pad
            o:adjust_layout(o.x, 0, o.w + space, self.h)
        end)
    end,

    adjust_children_expand = function(self, nch, nvs, ncl, cl)
        local pad = self.padding
        local dpad = pad * max(nch + nvs - 1, 0)
        local offset, space = 0, ((self.w - self.subw) / ncl - dpad)
        loop_children(self, function(o)
            o.x = offset
            local add = (cl[o] != nil) and space or 0
            o:adjust_layout(o.x, 0, o.w + add, self.h)
            offset += o.w + pad
        end)
    end,

    adjust_children = function(self)
        local nch, nvs = #self.children, #self.vstates
        if nch == 0 and nvs == 0 then return end
        if self.homogenous then
            return self:adjust_children_homogenous(nch, nvs)
        elseif self.expand then
            local ncl, cl = 0, {}
            loop_children(self, function(o)
                local a = o.adjust
                if  ((a & CLAMP_LEFT) != 0) and ((a & CLAMP_RIGHT) != 0) then
                    ncl += 1
                    cl[o] = true
                end
            end)
            if ncl != 0 then
                return self:adjust_children_expand(nch, nvs, ncl, cl)
            end
        end
        return self:adjust_children_regular(nch, nvs)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding",

    --[[! Function: set_expand ]]
    set_expand = gen_setter "expand",

    --[[! Function: set_homogenous ]]
    set_homogenous = gen_setter "homogenous"
})

--[[! Struct: V_Box
    See <H_Box>. This is a vertical variant. For "expand" and "homogenous",
    top/bottom clamping applies.
]]
M.V_Box = register_class("V_Box", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.padding    = kwargs.padding    or 0
        self.expand     = kwargs.expand     or false
        self.homogenous = kwargs.homogenous or false
        return Widget.__ctor(self, kwargs)
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
        self.h = subh + self.padding * max(#self.vstates +
            #self.children - 1, 0)
        self.subh = subh
    end,

    adjust_children_regular = function(self, nch, nvs)
        local offset, space = 0, (self.h - self.subh) / max(nvs + nch - 1, 1)
        loop_children(self, function(o)
            o.y = offset
            offset += o.h + space
            o:adjust_layout(0, o.y, self.w, o.h)
        end)
    end,

    adjust_children_homogenous = function(self, nch, nvs)
        local pad = self.padding
        local offset, space = 0, (self.h - self.subh - (nvs + nch - 1) * pad)
            / max(nvs + nch, 1)
        loop_children(self, function(o)
            o.y = offset
            offset += o.h + space + pad
            o:adjust_layout(0, o.y, self.w, o.h + space)
        end)
    end,

    adjust_children_expand = function(self, nch, nvs, ncl, cl)
        local pad = self.padding
        local dpad = pad * max(nch + nvs - 1, 0)
        local offset, space = 0, ((self.h - self.subh) / ncl - dpad)
        loop_children(self, function(o)
            o.y = offset
            local add = (cl[o] != nil) and space or 0
            o:adjust_layout(0, o.y, self.w, o.h + add)
            offset += o.h + pad
        end)
    end,

    adjust_children = function(self)
        local nch, nvs = #self.children, #self.vstates
        if nch == 0 and nvs == 0 then return end
        if self.homogenous then
            return self:adjust_children_homogenous(nch, nvs)
        elseif self.expand then
            local ncl, cl = 0, {}
            loop_children(self, function(o)
                local a = o.adjust
                if  ((a & CLAMP_TOP) != 0) and ((a & CLAMP_BOTTOM) != 0) then
                    ncl += 1
                    cl[o] = true
                end
            end)
            if ncl != 0 then
                return self:adjust_children_expand(nch, nvs, ncl, cl)
            end
        end
        return self:adjust_children_regular(nch, nvs)
    end,

    --[[! Function: set_padding ]]
    set_padding = gen_setter "padding",

    --[[! Function: set_expand ]]
    set_expand = gen_setter "expand",

    --[[! Function: set_homogenous ]]
    set_homogenous = gen_setter "homogenous"
}, M.H_Box.type)

--[[! Struct: Grid
    A grid of elements. It has two properties, columns (specifies the number
    of columns the table will have at max) and again padding (which has the
    same meaning as in boxes). As you append, the children will automatically
    position themselves according to the max number of columns.
]]
M.Grid = register_class("Grid", Widget, {
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.columns = kwargs.columns or 0
        self.padding = kwargs.padding or 0
        return Widget.__ctor(self, kwargs)
    end,

    layout = function(self)
        local widths, heights = createtable(4), createtable(4)
        self.widths, self.heights = widths, heights

        local column, row = 1, 1
        local columns, padding = self.columns, self.padding

        loop_children(self, function(o)
            o:layout()

            if #widths < column then
                widths[#widths + 1] = o.w
            elseif o.w > widths[column] then
                widths[column] = o.w
            end

            if #heights < row then
                heights[#heights + 1] = o.h
            elseif o.h > heights[row] then
                heights[row] = o.h
            end

            column = (column % columns) + 1
            if column == 1 then
                row += 1
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
        if #self.children == 0 and #self.vstates == 0 then return end
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
            o:adjust_layout(offsetx, offsety, wc, hr)

            offsetx += wc + cspace
            column = (column % columns) + 1

            if column == 1 then
                offsetx = 0
                offsety += hr + rspace
                row += 1
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
    __ctor = function(self, kwargs)
        kwargs = kwargs or {}
        self.clip_w = kwargs.clip_w or 0
        self.clip_h = kwargs.clip_h or 0
        self.virt_w = 0
        self.virt_h = 0

        return Widget.__ctor(self, kwargs)
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
