--[[! File: lua/core/gui/constants.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Some constants used in the GUI. Non-global, used by the primary GUI
        module and forwarded.
]]

local M = {}

--[[! Variable: gl
    Contains a list of OpenGL constants used by (and useful in) the GUI.
    Their meaning matches the one in OpenGL (with the GL_ prefix). This table
    contains ALPHA, ALWAYS, BLUE, CLAMP_TO_BORDER, CLAMP_TO_EDGE,
    COMPARE_REF_TO_TEXTURE, CONSTANT_ALPHA, CONSTANT_COLOR, DST_ALPHA,
    DST_COLOR, EQUAL, GEQUAL, GREATER, GREEN, LEQUAL, LESS, LINEAR,
    LINEAR_MIPMAP_LINEAR, LINEAR_MIPMAP_NEAREST, LINES, LINE_LOOP,
    LINE_STRIP, MAX_TEXTURE_LOD_BIAS, MIRRORED_REPEAT, NEAREST,
    NEAREST_MIPMAP_LINEAR, NEAREST_MIPMAP_NEAREST, NEVER, NONE, NOTEQUAL, ONE,
    ONE_MINUS_CONSTANT_ALPHA, ONE_MINUS_CONSTANT_COLOR, ONE_MINUS_DST_ALPHA,
    ONE_MINUS_DST_COLOR, ONE_MINUS_SRC1_ALPHA, ONE_MINUS_SRC1_COLOR,
    ONE_MINUS_SRC_ALPHA, ONE_MINUS_SRC_COLOR, POINTS, POLYGON, QUADS,
    QUAD_STRIP, RED, REPEAT, SRC1_ALPHA, SRC1_COLOR, SRC_ALPHA,
    SRC_ALPHA_SATURATE, SRC_COLOR, TEXTURE_BASE_LEVEL, TEXTURE_COMPARE_FUNC,
    TEXTURE_COMPARE_MODE, TEXTURE_LAOD_BIAS, TEXTURE_MAG_FILTER,
    TEXTURE_MAX_LEVEL, TEXTURE_MAX_LOD, TEXTURE_MIN_FILTER, TEXTURE_MIN_LOD,
    TEXTURE_SWIZZLE_A, TEXTURE_SWIZZLE_B, TEXTURE_SWIZZLE_G,
    TEXTURE_SWIZZLE_R, TEXTURE_WRAP_R, TEXTURE_WRAP_S, TEXTURE_WRAP_T,
    TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP, ZERO.
]]
local gl = {
    ALPHA = 0x1906,
    ALWAYS = 0x0207,
    BLUE = 0x1905,
    CLAMP_TO_BORDER = 0x812D,
    CLAMP_TO_EDGE = 0x812F,
    COMPARE_REF_TO_TEXTURE = 0x884E,
    CONSTANT_ALPHA = 0x8003,
    CONSTANT_COLOR = 0x8001,
    DST_ALPHA = 0x0304,
    DST_COLOR = 0x0306,
    EQUAL = 0x0202,
    GEQUAL = 0x0206,
    GREATER = 0x0204,
    GREEN = 0x1904,
    LEQUAL = 0x0203,
    LESS = 0x0201,
    LINEAR = 0x2601,
    LINEAR_MIPMAP_LINEAR = 0x2703,
    LINEAR_MIPMAP_NEAREST = 0x2701,
    LINES = 0x0001,
    LINE_LOOP = 0x0002,
    LINE_STRIP = 0x0003,
    MAX_TEXTURE_LOD_BIAS = 0x84FD,
    MIRRORED_REPEAT = 0x8370,
    NEAREST = 0x2600,
    NEAREST_MIPMAP_LINEAR = 0x2702,
    NEAREST_MIPMAP_NEAREST = 0x2700,
    NEVER = 0x0200,
    NONE = 0x0,
    NOTEQUAL = 0x0205,
    ONE = 0x1,
    ONE_MINUS_CONSTANT_ALPHA = 0x8004,
    ONE_MINUS_CONSTANT_COLOR = 0x8002,
    ONE_MINUS_DST_ALPHA = 0x0305,
    ONE_MINUS_DST_COLOR = 0x0307,
    ONE_MINUS_SRC1_ALPHA = 0x88FB,
    ONE_MINUS_SRC1_COLOR = 0x88FA,
    ONE_MINUS_SRC_ALPHA = 0x0303,
    ONE_MINUS_SRC_COLOR = 0x0301,
    POINTS = 0x0000,
    POLYGON = 0x0009,
    QUADS = 0x0007,
    QUAD_STRIP = 0x0008,
    RED = 0x1903,
    REPEAT = 0x2901,
    SRC1_ALPHA = 0x8589,
    SRC1_COLOR = 0x88F9,
    SRC_ALPHA = 0x0302,
    SRC_ALPHA_SATURATE = 0x0308,
    SRC_COLOR = 0x0300,
    TEXTURE_BASE_LEVEL = 0x813C,
    TEXTURE_COMPARE_FUNC = 0x884D,
    TEXTURE_COMPARE_MODE = 0x884C,
    TEXTURE_LOD_BIAS = 0x8501,
    TEXTURE_MAG_FILTER = 0x2800,
    TEXTURE_MAX_LEVEL = 0x813D,
    TEXTURE_MAX_LOD = 0x813B,
    TEXTURE_MIN_FILTER = 0x2801,
    TEXTURE_MIN_LOD = 0x813A,
    TEXTURE_SWIZZLE_A = 0x8E45,
    TEXTURE_SWIZZLE_B = 0x8E44,
    TEXTURE_SWIZZLE_G = 0x8E43,
    TEXTURE_SWIZZLE_R = 0x8E42,
    TEXTURE_WRAP_R = 0x8072,
    TEXTURE_WRAP_S = 0x2802,
    TEXTURE_WRAP_T = 0x2803,
    TRIANGLES = 0x0004,
    TRIANGLE_FAN = 0x0006,
    TRIANGLE_STRIP = 0x0005,
    ZERO = 0x0
}
M.gl = gl

local scancode_to_keycode = function(x) return (x | (1 << 30)) end
local char_to_byte = string.byte

--[[! Variable: scancode
    Contains a list of key scan codes. Not meant for direct use. Use <key>.
]]
local scancode = {
    UNKNOWN = 0,
    A = 4,
    B = 5,
    C = 6,
    D = 7,
    E = 8,
    F = 9,
    G = 10,
    H = 11,
    I = 12,
    J = 13,
    K = 14,
    L = 15,
    M = 16,
    N = 17,
    O = 18,
    P = 19,
    Q = 20,
    R = 21,
    S = 22,
    T = 23,
    U = 24,
    V = 25,
    W = 26,
    X = 27,
    Y = 28,
    Z = 29,

    [1] = 30,
    [2] = 31,
    [3] = 32,
    [4] = 33,
    [5] = 34,
    [6] = 35,
    [7] = 36,
    [8] = 37,
    [9] = 38,
    [0] = 39,

    RETURN = 40,
    ESCAPE = 41,
    BACKSPACE = 42,
    TAB = 43,
    SPACE = 44,

    MINUS = 45,
    EQUALS = 46,
    LEFTBRACKET = 47,
    RIGHTBRACKET = 48,
    BACKSLASH = 49,
    NONUSHASH = 50,
    SEMICOLON = 51,
    APOSTROPHE = 52,
    GRAVE = 53,
    COMMA = 54,
    PERIOD = 55,
    SLASH = 56,
    CAPSLOCK = 57,
    F1 = 58,
    F2 = 59,
    F3 = 60,
    F4 = 61,
    F5 = 62,
    F6 = 63,
    F7 = 64,
    F8 = 65,
    F9 = 66,
    F10 = 67,
    F11 = 68,
    F12 = 69,
    PRINTSCREEN = 70,
    SCROLLLOCK = 71,
    PAUSE = 72,
    INSERT = 73,
    HOME = 74,
    PAGEUP = 75,
    DELETE = 76,
    END = 77,
    PAGEDOWN = 78,
    RIGHT = 79,
    LEFT = 80,
    DOWN = 81,
    UP = 82,

    NUMLOCKCLEAR = 83,
    KP_DIVIDE = 84,
    KP_MULTIPLY = 85,
    KP_MINUS = 86,
    KP_PLUS = 87,
    KP_ENTER = 88,
    KP_1 = 89,
    KP_2 = 90,
    KP_3 = 91,
    KP_4 = 92,
    KP_5 = 93,
    KP_6 = 94,
    KP_7 = 95,
    KP_8 = 96,
    KP_9 = 97,
    KP_0 = 98,
    KP_PERIOD = 99,

    NONUSBACKSLASH = 100,
    APPLICATION = 101,
    POWER = 102,
    KP_EQUALS = 103,
    F13 = 104,
    F14 = 105,
    F15 = 106,
    F16 = 107,
    F17 = 108,
    F18 = 109,
    F19 = 110,
    F20 = 111,
    F21 = 112,
    F22 = 113,
    F23 = 114,
    F24 = 115,
    EXECUTE = 116,
    HELP = 117,
    MENU = 118,
    SELECT = 119,
    STOP = 120,
    AGAIN = 121,
    UNDO = 122,
    CUT = 123,
    COPY = 124,
    PASTE = 125,
    FIND = 126,
    MUTE = 127,
    VOLUMEUP = 128,
    VOLUMEDOWN = 129,
    KP_COMMA = 133,
    KP_EQUALSAS400 = 134,
    INTERNATIONAL1 = 135,
    INTERNATIONAL2 = 136,
    INTERNATIONAL3 = 137,
    INTERNATIONAL4 = 138,
    INTERNATIONAL5 = 139,
    INTERNATIONAL6 = 140,
    INTERNATIONAL7 = 141,
    INTERNATIONAL8 = 142,
    INTERNATIONAL9 = 143,
    LANG1 = 144,
    LANG2 = 145,
    LANG3 = 146,
    LANG4 = 147,
    LANG5 = 148,
    LANG6 = 149,
    LANG7 = 150,
    LANG8 = 151,
    LANG9 = 152,

    ALTERASE = 153,
    SYSREQ = 154,
    CANCEL = 155,
    CLEAR = 156,
    PRIOR = 157,
    RETURN2 = 158,
    SEPARATOR = 159,
    OUT = 160,
    OPER = 161,
    CLEARAGAIN = 162,
    CRSEL = 163,
    EXSEL = 164,

    KP_00 = 176,
    KP_000 = 177,
    THOUSANDSSEPARATOR = 178,
    DECIMALSEPARATOR = 179,
    CURRENCYUNIT = 180,
    CURRENCYSUBUNIT = 181,
    KP_LEFTPAREN = 182,
    KP_RIGHTPAREN = 183,
    KP_LEFTBRACE = 184,
    KP_RIGHTBRACE = 185,
    KP_TAB = 186,
    KP_BACKSPACE = 187,
    KP_A = 188,
    KP_B = 189,
    KP_C = 190,
    KP_D = 191,
    KP_E = 192,
    KP_F = 193,
    KP_XOR = 194,
    KP_POWER = 195,
    KP_PERCENT = 196,
    KP_LESS = 197,
    KP_GREATER = 198,
    KP_AMPERSAND = 199,
    KP_DBLAMPERSAND = 200,
    KP_VERTICALBAR = 201,
    KP_DBLVERTICALBAR = 202,
    KP_COLON = 203,
    KP_HASH = 204,
    KP_SPACE = 205,
    KP_AT = 206,
    KP_EXCLAM = 207,
    KP_MEMSTORE = 208,
    KP_MEMRECALL = 209,
    KP_MEMCLEAR = 210,
    KP_MEMADD = 211,
    KP_MEMSUBTRACT = 212,
    KP_MEMMULTIPLY = 213,
    KP_MEMDIVIDE = 214,
    KP_PLUSMINUS = 215,
    KP_CLEAR = 216,
    KP_CLEARENTRY = 217,
    KP_BINARY = 218,
    KP_OCTAL = 219,
    KP_DECIMAL = 220,
    KP_HEXADECIMAL = 221,

    LCTRL = 224,
    LSHIFT = 225,
    LALT = 226,
    LGUI = 227,
    RCTRL = 228,
    RSHIFT = 229,
    RALT = 230,
    RGUI = 231,

    MODE = 257,

    AUDIONEXT = 258,
    AUDIOPREV = 259,
    AUDIOSTOP = 260,
    AUDIOPLAY = 261,
    AUDIOMUTE = 262,
    MEDIASELECT = 263,
    WWW = 264,
    MAIL = 265,
    CALCULATOR = 266,
    COMPUTER = 267,
    AC_SEARCH = 268,
    AC_HOME = 269,
    AC_BACK = 270,
    AC_FORWARD = 271,
    AC_STOP = 272,
    AC_REFRESH = 273,
    AC_BOOKMARKS = 274,

    BRIGHTNESSDOWN = 275,
    BRIGHTNESSUP = 276,
    DISPLAYSWITCH = 277,
    KBDILLUMTOGGLE = 278,
    KBDILLUMDOWN = 279,
    KBDILLUMUP = 280,
    EJECT = 281,
    SLEEP = 282,

    APP1 = 283,
    APP2 = 284,
}
M.scancode = scancode

--[[! Variable: key
    Contains a list of key constants. Matches SDLK_* with the addition of
    mouse buttons (MOUSELEFT, MOUSEMIDDLE, MOUSERIGHT, MOUSEWHEELUP,
    MOUSEWHEELDOWN, MOUSEBACK, MOUSEFORWARD).
]]
local key = {
    MOUSELEFT      = -1,
    MOUSEMIDDLE    = -2,
    MOUSERIGHT     = -3,
    MOUSEWHEELUP   = -4,
    MOUSEWHEELDOWN = -5,
    MOUSEBACK      = -6,
    MOUSEFORWARD   = -7,

    UNKNOWN = 0,

    RETURN = char_to_byte('\r'),
    ESCAPE = 27,
    BACKSPACE = char_to_byte('\b'),
    TAB = char_to_byte('\t'),
    SPACE = char_to_byte(' '),
    EXCLAIM = char_to_byte('!'),
    QUOTEDBL = char_to_byte('"'),
    HASH = char_to_byte('#'),
    PERCENT = char_to_byte('%'),
    DOLLAR = char_to_byte('$'),
    AMPERSAND = char_to_byte('&'),
    QUOTE = char_to_byte("'"),
    LEFTPAREN = char_to_byte('('),
    RIGHTPAREN = char_to_byte(')'),
    ASTERISK = char_to_byte('*'),
    PLUS = char_to_byte('+'),
    COMMA = char_to_byte(','),
    MINUS = char_to_byte('-'),
    PERIOD = char_to_byte('.'),
    SLASH = char_to_byte('/'),
    [0] = char_to_byte('0'),
    [1] = char_to_byte('1'),
    [2] = char_to_byte('2'),
    [3] = char_to_byte('3'),
    [4] = char_to_byte('4'),
    [5] = char_to_byte('5'),
    [6] = char_to_byte('6'),
    [7] = char_to_byte('7'),
    [8] = char_to_byte('8'),
    [9] = char_to_byte('9'),
    COLON = char_to_byte(':'),
    SEMICOLON = char_to_byte(';'),
    LESS = char_to_byte('<'),
    EQUALS = char_to_byte('='),
    GREATER = char_to_byte('>'),
    QUESTION = char_to_byte('?'),
    AT = char_to_byte('@'),
    LEFTBRACKET = char_to_byte('['),
    BACKSLASH = char_to_byte('\\'),
    RIGHTBRACKET = char_to_byte(']'),
    CARET = char_to_byte('^'),
    UNDERSCORE = char_to_byte('_'),
    BACKQUOTE = char_to_byte('`'),
    A = char_to_byte('a'),
    B = char_to_byte('b'),
    C = char_to_byte('c'),
    D = char_to_byte('d'),
    E = char_to_byte('e'),
    F = char_to_byte('f'),
    G = char_to_byte('g'),
    H = char_to_byte('h'),
    I = char_to_byte('i'),
    J = char_to_byte('j'),
    K = char_to_byte('k'),
    L = char_to_byte('l'),
    M = char_to_byte('m'),
    N = char_to_byte('n'),
    O = char_to_byte('o'),
    P = char_to_byte('p'),
    Q = char_to_byte('q'),
    R = char_to_byte('r'),
    S = char_to_byte('s'),
    T = char_to_byte('t'),
    U = char_to_byte('u'),
    V = char_to_byte('v'),
    W = char_to_byte('w'),
    X = char_to_byte('x'),
    Y = char_to_byte('y'),
    Z = char_to_byte('z'),

    CAPSLOCK = scancode_to_keycode(scancode.CAPSLOCK),

    F1 = scancode_to_keycode(scancode.F1),
    F2 = scancode_to_keycode(scancode.F2),
    F3 = scancode_to_keycode(scancode.F3),
    F4 = scancode_to_keycode(scancode.F4),
    F5 = scancode_to_keycode(scancode.F5),
    F6 = scancode_to_keycode(scancode.F6),
    F7 = scancode_to_keycode(scancode.F7),
    F8 = scancode_to_keycode(scancode.F8),
    F9 = scancode_to_keycode(scancode.F9),
    F10 = scancode_to_keycode(scancode.F10),
    F11 = scancode_to_keycode(scancode.F11),
    F12 = scancode_to_keycode(scancode.F12),

    PRINTSCREEN = scancode_to_keycode(scancode.PRINTSCREEN),
    SCROLLLOCK = scancode_to_keycode(scancode.SCROLLLOCK),
    PAUSE = scancode_to_keycode(scancode.PAUSE),
    INSERT = scancode_to_keycode(scancode.INSERT),
    HOME = scancode_to_keycode(scancode.HOME),
    PAGEUP = scancode_to_keycode(scancode.PAGEUP),
    DELETE = '\177',
    END = scancode_to_keycode(scancode.END),
    PAGEDOWN = scancode_to_keycode(scancode.PAGEDOWN),
    RIGHT = scancode_to_keycode(scancode.RIGHT),
    LEFT = scancode_to_keycode(scancode.LEFT),
    DOWN = scancode_to_keycode(scancode.DOWN),
    UP = scancode_to_keycode(scancode.UP),

    NUMLOCKCLEAR = scancode_to_keycode(scancode.NUMLOCKCLEAR),
    KP_DIVIDE = scancode_to_keycode(scancode.KP_DIVIDE),
    KP_MULTIPLY = scancode_to_keycode(scancode.KP_MULTIPLY),
    KP_MINUS = scancode_to_keycode(scancode.KP_MINUS),
    KP_PLUS = scancode_to_keycode(scancode.KP_PLUS),
    KP_ENTER = scancode_to_keycode(scancode.KP_ENTER),
    KP_1 = scancode_to_keycode(scancode.KP_1),
    KP_2 = scancode_to_keycode(scancode.KP_2),
    KP_3 = scancode_to_keycode(scancode.KP_3),
    KP_4 = scancode_to_keycode(scancode.KP_4),
    KP_5 = scancode_to_keycode(scancode.KP_5),
    KP_6 = scancode_to_keycode(scancode.KP_6),
    KP_7 = scancode_to_keycode(scancode.KP_7),
    KP_8 = scancode_to_keycode(scancode.KP_8),
    KP_9 = scancode_to_keycode(scancode.KP_9),
    KP_0 = scancode_to_keycode(scancode.KP_0),
    KP_PERIOD = scancode_to_keycode(scancode.KP_PERIOD),

    APPLICATION = scancode_to_keycode(scancode.APPLICATION),
    POWER = scancode_to_keycode(scancode.POWER),
    KP_EQUALS = scancode_to_keycode(scancode.KP_EQUALS),
    F13 = scancode_to_keycode(scancode.F13),
    F14 = scancode_to_keycode(scancode.F14),
    F15 = scancode_to_keycode(scancode.F15),
    F16 = scancode_to_keycode(scancode.F16),
    F17 = scancode_to_keycode(scancode.F17),
    F18 = scancode_to_keycode(scancode.F18),
    F19 = scancode_to_keycode(scancode.F19),
    F20 = scancode_to_keycode(scancode.F20),
    F21 = scancode_to_keycode(scancode.F21),
    F22 = scancode_to_keycode(scancode.F22),
    F23 = scancode_to_keycode(scancode.F23),
    F24 = scancode_to_keycode(scancode.F24),
    EXECUTE = scancode_to_keycode(scancode.EXECUTE),
    HELP = scancode_to_keycode(scancode.HELP),
    MENU = scancode_to_keycode(scancode.MENU),
    SELECT = scancode_to_keycode(scancode.SELECT),
    STOP = scancode_to_keycode(scancode.STOP),
    AGAIN = scancode_to_keycode(scancode.AGAIN),
    UNDO = scancode_to_keycode(scancode.UNDO),
    CUT = scancode_to_keycode(scancode.CUT),
    COPY = scancode_to_keycode(scancode.COPY),
    PASTE = scancode_to_keycode(scancode.PASTE),
    FIND = scancode_to_keycode(scancode.FIND),
    MUTE = scancode_to_keycode(scancode.MUTE),
    VOLUMEUP = scancode_to_keycode(scancode.VOLUMEUP),
    VOLUMEDOWN = scancode_to_keycode(scancode.VOLUMEDOWN),
    KP_COMMA = scancode_to_keycode(scancode.KP_COMMA),
    KP_EQUALSAS400 =
        scancode_to_keycode(scancode.KP_EQUALSAS400),

    ALTERASE = scancode_to_keycode(scancode.ALTERASE),
    SYSREQ = scancode_to_keycode(scancode.SYSREQ),
    CANCEL = scancode_to_keycode(scancode.CANCEL),
    CLEAR = scancode_to_keycode(scancode.CLEAR),
    PRIOR = scancode_to_keycode(scancode.PRIOR),
    RETURN2 = scancode_to_keycode(scancode.RETURN2),
    SEPARATOR = scancode_to_keycode(scancode.SEPARATOR),
    OUT = scancode_to_keycode(scancode.OUT),
    OPER = scancode_to_keycode(scancode.OPER),
    CLEARAGAIN = scancode_to_keycode(scancode.CLEARAGAIN),
    CRSEL = scancode_to_keycode(scancode.CRSEL),
    EXSEL = scancode_to_keycode(scancode.EXSEL),

    KP_00 = scancode_to_keycode(scancode.KP_00),
    KP_000 = scancode_to_keycode(scancode.KP_000),
    THOUSANDSSEPARATOR =
        scancode_to_keycode(scancode.THOUSANDSSEPARATOR),
    DECIMALSEPARATOR =
        scancode_to_keycode(scancode.DECIMALSEPARATOR),
    CURRENCYUNIT = scancode_to_keycode(scancode.CURRENCYUNIT),
    CURRENCYSUBUNIT =
        scancode_to_keycode(scancode.CURRENCYSUBUNIT),
    KP_LEFTPAREN = scancode_to_keycode(scancode.KP_LEFTPAREN),
    KP_RIGHTPAREN = scancode_to_keycode(scancode.KP_RIGHTPAREN),
    KP_LEFTBRACE = scancode_to_keycode(scancode.KP_LEFTBRACE),
    KP_RIGHTBRACE = scancode_to_keycode(scancode.KP_RIGHTBRACE),
    KP_TAB = scancode_to_keycode(scancode.KP_TAB),
    KP_BACKSPACE = scancode_to_keycode(scancode.KP_BACKSPACE),
    KP_A = scancode_to_keycode(scancode.KP_A),
    KP_B = scancode_to_keycode(scancode.KP_B),
    KP_C = scancode_to_keycode(scancode.KP_C),
    KP_D = scancode_to_keycode(scancode.KP_D),
    KP_E = scancode_to_keycode(scancode.KP_E),
    KP_F = scancode_to_keycode(scancode.KP_F),
    KP_XOR = scancode_to_keycode(scancode.KP_XOR),
    KP_POWER = scancode_to_keycode(scancode.KP_POWER),
    KP_PERCENT = scancode_to_keycode(scancode.KP_PERCENT),
    KP_LESS = scancode_to_keycode(scancode.KP_LESS),
    KP_GREATER = scancode_to_keycode(scancode.KP_GREATER),
    KP_AMPERSAND = scancode_to_keycode(scancode.KP_AMPERSAND),
    KP_DBLAMPERSAND =
        scancode_to_keycode(scancode.KP_DBLAMPERSAND),
    KP_VERTICALBAR =
        scancode_to_keycode(scancode.KP_VERTICALBAR),
    KP_DBLVERTICALBAR =
        scancode_to_keycode(scancode.KP_DBLVERTICALBAR),
    KP_COLON = scancode_to_keycode(scancode.KP_COLON),
    KP_HASH = scancode_to_keycode(scancode.KP_HASH),
    KP_SPACE = scancode_to_keycode(scancode.KP_SPACE),
    KP_AT = scancode_to_keycode(scancode.KP_AT),
    KP_EXCLAM = scancode_to_keycode(scancode.KP_EXCLAM),
    KP_MEMSTORE = scancode_to_keycode(scancode.KP_MEMSTORE),
    KP_MEMRECALL = scancode_to_keycode(scancode.KP_MEMRECALL),
    KP_MEMCLEAR = scancode_to_keycode(scancode.KP_MEMCLEAR),
    KP_MEMADD = scancode_to_keycode(scancode.KP_MEMADD),
    KP_MEMSUBTRACT =
        scancode_to_keycode(scancode.KP_MEMSUBTRACT),
    KP_MEMMULTIPLY =
        scancode_to_keycode(scancode.KP_MEMMULTIPLY),
    KP_MEMDIVIDE = scancode_to_keycode(scancode.KP_MEMDIVIDE),
    KP_PLUSMINUS = scancode_to_keycode(scancode.KP_PLUSMINUS),
    KP_CLEAR = scancode_to_keycode(scancode.KP_CLEAR),
    KP_CLEARENTRY = scancode_to_keycode(scancode.KP_CLEARENTRY),
    KP_BINARY = scancode_to_keycode(scancode.KP_BINARY),
    KP_OCTAL = scancode_to_keycode(scancode.KP_OCTAL),
    KP_DECIMAL = scancode_to_keycode(scancode.KP_DECIMAL),
    KP_HEXADECIMAL =
        scancode_to_keycode(scancode.KP_HEXADECIMAL),

    LCTRL = scancode_to_keycode(scancode.LCTRL),
    LSHIFT = scancode_to_keycode(scancode.LSHIFT),
    LALT = scancode_to_keycode(scancode.LALT),
    LGUI = scancode_to_keycode(scancode.LGUI),
    RCTRL = scancode_to_keycode(scancode.RCTRL),
    RSHIFT = scancode_to_keycode(scancode.RSHIFT),
    RALT = scancode_to_keycode(scancode.RALT),
    RGUI = scancode_to_keycode(scancode.RGUI),

    MODE = scancode_to_keycode(scancode.MODE),

    AUDIONEXT = scancode_to_keycode(scancode.AUDIONEXT),
    AUDIOPREV = scancode_to_keycode(scancode.AUDIOPREV),
    AUDIOSTOP = scancode_to_keycode(scancode.AUDIOSTOP),
    AUDIOPLAY = scancode_to_keycode(scancode.AUDIOPLAY),
    AUDIOMUTE = scancode_to_keycode(scancode.AUDIOMUTE),
    MEDIASELECT = scancode_to_keycode(scancode.MEDIASELECT),
    WWW = scancode_to_keycode(scancode.WWW),
    MAIL = scancode_to_keycode(scancode.MAIL),
    CALCULATOR = scancode_to_keycode(scancode.CALCULATOR),
    COMPUTER = scancode_to_keycode(scancode.COMPUTER),
    AC_SEARCH = scancode_to_keycode(scancode.AC_SEARCH),
    AC_HOME = scancode_to_keycode(scancode.AC_HOME),
    AC_BACK = scancode_to_keycode(scancode.AC_BACK),
    AC_FORWARD = scancode_to_keycode(scancode.AC_FORWARD),
    AC_STOP = scancode_to_keycode(scancode.AC_STOP),
    AC_REFRESH = scancode_to_keycode(scancode.AC_REFRESH),
    AC_BOOKMARKS = scancode_to_keycode(scancode.AC_BOOKMARKS),

    BRIGHTNESSDOWN =
        scancode_to_keycode(scancode.BRIGHTNESSDOWN),
    BRIGHTNESSUP = scancode_to_keycode(scancode.BRIGHTNESSUP),
    DISPLAYSWITCH = scancode_to_keycode(scancode.DISPLAYSWITCH),
    KBDILLUMTOGGLE =
        scancode_to_keycode(scancode.KBDILLUMTOGGLE),
    KBDILLUMDOWN = scancode_to_keycode(scancode.KBDILLUMDOWN),
    KBDILLUMUP = scancode_to_keycode(scancode.KBDILLUMUP),
    EJECT = scancode_to_keycode(scancode.EJECT),
    SLEEP = scancode_to_keycode(scancode.SLEEP)
}
M.key = key

--[[! Variable: mod
    Contains a list of key modifier constants mapping to SDL's KMOD_*.
]]
local mod = {:
    NONE     = 0x0000,
    LSHIFT   = 0x0001,
    RSHIFT   = 0x0002,
    LCTRL    = 0x0040,
    RCTRL    = 0x0080,
    LALT     = 0x0100,
    RALT     = 0x0200,
    LGUI     = 0x0400,
    RGUI     = 0x0800,
    NUM      = 0x1000,
    CAPS     = 0x2000,
    MODE     = 0x4000,
    RESERVED = 0x8000,
    SHIFT    = LSHIFT | RSHIFT,
    CTRL     = LCTRL  | RCTRL,
    ALT      = LALT   | RALT,
    GUI      = LGUI   | RGUI
:}
M.mod = mod

return M
