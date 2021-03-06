--[[!<
    Lua string extensions. Contains all the functionality of the original
    string module as well and makes the default __index of the global string
    metatable point to this module so you can use the new functionality more
    conveniently.

    It does not contain string.dump. It contains byte, char, find, format,
    gmatch, gsub, len, lower, match, rep, reverse, sub, upper.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: string
local M = {}

--[[!
    Splits a string using the given parameters.

    Arguments:
        - str - the given string.
        - delim - the delimiter to use (defaults to ",")

    ```
    local a = "abc|def|ghi|jkl"
    local b = split(a, '|')
    assert(table.concat(b) == "abcdefghijkl")
    ```
]]
M.split = function(str, delim)
    delim = delim or ","
    local r = {}
    for ch in str:gmatch("([^" .. delim .. "]+)") do
        r[#r + 1] = ch
    end
    return r
end

--[[!
    Deletes a substring in a string. Returns the new string.

    Arguments:
        - str - the given string.
        - start - the starting index to delete.
        - count - the number of characters to delete.
]]
M.del = function(str, start, count)
    return table.concat { str:sub(1, start - 1), str:sub(start + count) }
end

--[[!
    Inserts a substring into the string. Returns the new string.

    Arguments:
        - str - the given string.
        - idx - the index where to start the inserted substring.
        - new - the string to insert.
]]
M.insert = function(str, idx, new)
    return table.concat { str:sub(1, idx - 1), new, str:sub(idx) }
end

local str_escapes = setmetatable({
    ["\n"] = "\\n", ["\r"] = "\\r",
    ["\a"] = "\\a", ["\b"] = "\\b",
    ["\f"] = "\\f", ["\t"] = "\\t",
    ["\v"] = "\\v", ["\\"] = "\\\\",
    ['"' ] = '\\"', ["'" ] = "\\'"
}, {
    __index = function(self, c) return ("\\%03d"):format(c:byte()) end
})

--[[!
    Escapes a string. Works similarly to the Lua %q format but it tries
    to be more compact (e.g. uses \r instead of \13), doesn't insert newlines
    in the result (\n instead) and automatically decides if to delimit the
    result with ' or " depending on the number of nested ' and " (uses the
    one that needs less escaping).
]]
M.escape = function(s)
    -- a space optimization: decide which string quote to
    -- use as a delimiter (the one that needs less escaping)
    local nsq, ndq = 0, 0
    for c in s:gmatch("'") do nsq = nsq + 1 end
    for c in s:gmatch('"') do ndq = ndq + 1 end
    local sd = (ndq > nsq) and "'" or '"'
    return sd .. s:gsub("[\\"..sd.."%z\001-\031]", str_escapes) .. sd
end

local funmap = {
    "byte" , "char" , "find", "format" , "gmatch", "gsub", "len",
    "lower", "match", "rep" , "reverse", "sub"   , "upper"
}
for i, v in ipairs(funmap) do M[v] = string[v] end

getmetatable("").__index = M

return M
