#include "cube.h"
#include "engine.h"
#include "game.h"

#include "of_lapi.h"
#include "of_tools.h"

#ifdef CLIENT
    #include "client_system.h"
    #include "targeting.h"
#endif
#include "editing_system.h"
#include "message_system.h"

#include "of_entities.h"
#include "of_world.h"
#include "of_localserver.h"

#define LAPI_REG(name) \
lua_pushcfunction(L, _lua_##name); \
lua_setfield(L, -2, #name);

#define LAPI_GET_ENT(name, _log, retexpr) \
lua_getfield(L, 1, "uid"); \
int uid = lua_tointeger(L, -1); \
lua_pop(L, 1); \
\
CLogicEntity *name = LogicSystem::getLogicEntity(uid); \
if (!name) \
{ \
    logger::log( \
        logger::ERROR, "Cannot find CLE for entity %i (%s).\n", uid, _log \
    ); \
    retexpr; \
}

#define LAPI_EMPTY(name) int _lua_##name(lua_State *L) \
{ logger::log(logger::DEBUG, "stub: CAPI."#name"\n"); return 0; }

#include "of_lapi_base.h"

#undef LAPI_EMPTY
#undef LAPI_GET_ENT
#undef LAPI_REG

extern string homedir;

namespace lapi
{
    lua_State *L = NULL;
    types::String mod_dir;
    bool initialized;

    static int panic(lua_State *L) {
        fatal("error in call to the Lua API (%s)", lua_tostring(L, -1));
        return 0;
    }

    void setup_binds();

    static int create_table(lua_State *L) {
        lua_createtable(L, luaL_optinteger(L, 1, 0), luaL_optinteger(L, 2, 0));
        return 1;
    }

    void init(const char *dir)
    {
        if (initialized) return;
            initialized  = true;

        mod_dir = dir;

        L = luaL_newstate();
        lua_atpanic(L, panic);

        #define MODOPEN(name) \
            lua_pushcfunction(L, luaopen_##name); \
            lua_call(L, 0, 0);

        MODOPEN(base)
        MODOPEN(table)
        MODOPEN(string)
        MODOPEN(math)
        MODOPEN(package)
        MODOPEN(debug)
        MODOPEN(os)
        MODOPEN(io)
        MODOPEN(ffi)
        MODOPEN(bit)

        lua_getglobal(L, "package");

        /* home directory paths */
        lua_pushfstring(
            L, ";%sdata%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV
        );
        lua_pushfstring(
            L, ";%sdata%c?.lua",
            homedir, PATHDIV
        );
        lua_pushfstring(
            L, ";%sdata%clibrary%c?%cinit.lua",
            homedir, PATHDIV, PATHDIV, PATHDIV
        );

        /* root paths */
        lua_pushliteral(L, ";./data/library/core/?.lua");
        lua_pushliteral(L, ";./data/library/core/?/init.lua");
        lua_pushliteral(L, ";./data/?/init.lua");
        lua_pushliteral(L, ";./data/?.lua");
        lua_pushliteral(L, ";./data/library/?/init.lua");

        lua_concat  (L,  8);
        lua_setfield(L, -2, "path"); lua_pop(L, 1);

        lua_pushcfunction(L, create_table); lua_setglobal(L, "createtable");

        setup_binds();
    }

    void load_module(const char *name)
    {
        logger::log(
            logger::DEBUG, "Loading OF Lua module: %s%c%s.lua.\n",
            mod_dir.get_buf(), filesystem::separator(), name
        );

        types::String p(mod_dir);
        p += filesystem::separator();
        p += name;
        p += ".lua";

        if (luaL_loadfile(L, p.get_buf()) || lua_pcall(L, 0, 0, 0)) {
            fatal("%s", lua_tostring(L, -1));
        }
    }

    void setup_binds()
    {
#ifdef CLIENT
        lua_pushboolean(L,  true); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L, false); lua_setglobal(L, "SERVER");
#else
        lua_pushboolean(L, false); lua_setglobal(L, "CLIENT");
        lua_pushboolean(L,  true); lua_setglobal(L, "SERVER");
#endif
        lua_pushinteger(L, OF_CFG_VERSION); lua_setglobal(L, "OF_CFG_VERSION");

        lua_createtable(L, 0, 0);
        lapi_binds::reg_base(L);
        lua_getfield (L, LUA_REGISTRYINDEX, "_LOADED");
        lua_pushvalue(L, -2); lua_setfield (L, -2, "CAPI");
        lua_pop      (L,  1);
        lua_setglobal(L, "CAPI");
        load_module("init");
    }

    void reset() {}

    bool load_library(const char *name)
    {
        if (!name || strstr(name, "..")) return false;

        lua_getglobal(L, "package");

        types::String pattern = types::String()
            .format(";./data/library/%s/?.lua", name);

        lua_getglobal  (L, "string"); lua_getfield(L, -1, "find");
        lua_getfield   (L, -3, "path"); 
        lua_pushlstring(L, pattern.get_buf(), pattern.length());
        lua_call       (L, 2, 1);

        if (!lua_isnil(L, -1)) {
            lua_pop(L, 3);
            return true;
        }
        lua_pop(L, 2);

        /* original path */
        lua_getfield(L, -1, "path");

        /* home directory path */
        lua_pushfstring(
            L, ";%sdata%clibrary%c%s%c?.lua",
            homedir, PATHDIV, PATHDIV, name, PATHDIV
        );

        /* root path */
        lua_pushfstring(L, ";./data/library/%s/?.lua", name);

        lua_concat  (L,  3);
        lua_setfield(L, -2, "path");

        return true;
    }
} /* end namespace lapi */
