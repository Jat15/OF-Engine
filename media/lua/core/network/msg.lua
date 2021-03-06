--[[!<
    Provides an API to the OctaForge message system.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: msg
local M = {}

local type, assert = type, assert

--[[!
    A constant (value -1) used when sending messages. Specifying this constant
    means that the message will be sent to all clients.
]]
M.ALL_CLIENTS = -1

--[[!
    Sends a message. On the client, it simply calls the given message function,
    using the remaining arguments as the call arguments.

    Server:
        On the server the first argument is a client number and the second
        argument is the message function. Using $ALL_CLIENTS as the client
        number, you can send the message to all clients.

    Client:
        The first argument is the message function directly.
]]
M.send = SERVER and function(cn, mf, ...)
    mf(cn, ...)
end or function(mf, ...)
    mf(...)
end

--[[!
    Shows a message on the client, coming from the server (this only works
    serverside). You need to provide a client number or a client entity, a
    message title and a message text.
]]
M.show_client_message = SERVER and function(cn, title, text)
    cn = type(cn) == "table" and cn.cn or cn
    assert(cn)
    send(cn, require("capi").personal_servmsg, title, text)
end or nil

return M
