--[[!<
    Provides streams (file streams and others).

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

local capi = require("capi")

--[[! Module: stream
    The streams some of the functions in this module define have several
    methods.

    Methods:
        - `close()` - closes the stream.
        - `lines()` - returns an iterator function that returns the next line
          every time it's called, until it returns nil.
        - `read(...)` - see the `read` method of a Lua file handle, the only
          difference is that this doesn't support the `*n` format.
        - `seek([whence] [, offset])` - see the `seek` method of a Lua file
          handle.
        - `write(...)` - see the `write` method of a Lua file handle.

    Metamethods:
        - `__gc` - automatically closes the stream when the last variable
          expires, unless the internal refcount is non-zero (in which case
          the stream waits until other streams let it go).
        - `__tostring` - can return two strings, `stream (0xDEADBEEF)` or
          `stream (closed)` depending on its status.
]]
local M = {}

--[[! Function: open
    Opens a file and returns its stream. This first tries to open a file in
    a mounted zip file. If that fails, it tries to open the file directly
    (see $open_raw).

    Arguments:
        - filename - the file path.
        - mode - the mode, identical to modes of the `fopen` C function.

    See also:
        - $open_raw
        - $open_zip
        - $open_gz
        - $open_utf8
]]
M.open = capi.stream_open

--[[! Function: open_raw
    Like $open, but doesn't attempt to read in mounted zip files. It
    first searches in the OctaForge home directory and then in the primary
    directory.

    See also:
        - $open
        - $open_zip
        - $open_gz
        - $open_utf8
]]
M.open_raw = capi.stream_open_raw

--[[! Function: open_zip
    Like $open_raw, but tries to read ONLY in mounted zip files.

    See also:
        - $open
        - $open_raw
        - $open_gz
        - $open_utf8
]]
M.open_zip = capi.stream_open_zip

--[[! Function: open_gz
    Like $open, but treats the file as gzip compressed (zlib). It
    (de)compresses on the fly.

    Arguments:
        - filename, mode - see $open.
        - file - if provided, this should be a previously opened file stream -
          in that case the prior two arguments are ignored and this is used as
          source stream for the gzip stream. It doesn't close the previous
          stream, merely reuses it. An internal refcounting mechanism makes
          sure the original stream is preserved for as long as the child
          stream is alive.
        - level - optional zlib compression level, by default equals to
          `Z_BEST_COMPRESSION`.

    See also:
        - $open
        - $open_raw
        - $open_zip
        - $open_utf8
]]
M.open_gz = capi.stream_open_gz

--[[! Function: open_utf8
    Like $open, but treats the file as UTF-8 input, translating to the
    Cube 2 charset on the fly. This is often what you don't want, as you want
    to read the input source as UTF-8 instead of the Cube encoding, but it
    sometimes comes in handy.

    Arguments:
        - filename, mode - see $open.
        - file - if provided, this should be a previously opened file stream -
          in that case the prior two arguments are ignored and this is used as
          source stream for the gzip stream. It doesn't close the previous
          stream, merely reuses it. An internal refcounting mechanism makes
          sure the original stream is preserved for as long as the child
          stream is alive.

    See also:
        - $open
        - $open_raw
        - $open_zip
        - $open_gz
]]
M.open_utf8 = capi.stream_open_utf8

--[[! Function: type
    Checks if the given value is a file stream. Returns `stream` when it is,
    `closed stream` when it's a closed stream and `nil` when it's not a stream.
]]
M.type = capi.stream_type

return M
