/*
 * of_tools.cpp, version 1
 * Various utilities for OctaForge engine.
 *
 * author: q66 <quaker66@gmail.com>
 * license: see COPYING.txt
 */

#include "engine.h"
#include "of_world.h"
#include "of_tools.h"
#include <sys/stat.h>
#include <ctype.h>

/* avoid libsupc++ linkage, we don't need most of the runtime
 * disabled, experimental, do not use
 */
#if 0
extern "C"
{
    __extension__ typedef int __guard __attribute__((mode (__DI__)));

    void __cxa_pure_virtual()
    {
        fprintf(stderr, "ERROR: Pure virtual method call.\n");
        abort();
    }

    int __cxa_guard_acquire(__guard *g)
    {
        return (*((char*)g) == 0);
    }

    void __cxa_guard_release(__guard *g)
    {
        *((char*)g) = 1;
    }
}
#endif

void writebinds(stream *f);

namespace tools
{
    bool valanumeric(const char *str, const char *allow)
    {
        for (; *str; str++)
        {
            if (!isalnum(*str) && !strchr(allow, *str))
                return false;
        }
        return true;
    }

    bool valrpath(const char *path)
    {
        int level = -1;
        char  *p = newstring(path);
        char  *t = strtok(p, "/\\");
        while (t)
        {
            if (!strcmp(t, "..")) level--;
            else if (strcmp(t, ".") && strcmp(t, "")) level++;
            if (level < 0)
            {
                delete[] p;
                return false;
            }
            t = strtok(NULL, "/\\");
        }
        level--;
        delete[] p;
        return (level >= 0);
    }

    bool fnewer(const char *file, const char *otherfile)
    {
        struct stat buf, buf2;
        if (stat(file,      &buf )) return false;
        if (stat(otherfile, &buf2)) return true;
        if (buf.st_mtime > buf2.st_mtime) return true;
        return false;
    }

    bool fcopy(const char *src, const char *dest)
    {
        FILE *from, *to;
        char c;

        if (!(from = fopen(src,  "rb"))) return false;
        if (!(to   = fopen(dest, "wb")))
        {
            fclose(from);
            return false;
        }

        while (!feof(from))
        {
            c = fgetc(from);
            if (ferror(from))
            {
                fclose(from);
                fclose(to);
                return false;
            }
            if (!feof(from)) fputc(c, to);
            if (ferror(to))
            {
                fclose(from);
                fclose(to);
                return false;
            }
        }

        fclose(from);
        fclose(to);
        return true;
    }

    bool fdel(const char *file)
    {
#ifdef WIN32
        return (DeleteFile(file) != 0);
#else
        return (remove(file) == 0);
#endif
    }

    bool fempty(const char *file)
    {
        FILE *f = fopen(file, "w");
        if (!f) return false;
        fclose(f);
        return true;
    }

    bool execfile(const char *cfgfile, bool msg)
    {
        string s;
        copystring(s, cfgfile);
        char *buf = loadfile(path(s), NULL);
        if(!buf)
        {
            if(msg) {
                logger::log(logger::ERROR, "could not read \"%s\"", cfgfile);
            }
            return false;
        }
        defformatstring(chunk, "@%s", cfgfile);
        if (lua::load_string(buf,  chunk) || lua_pcall(lua::L, 0, 0, 0)) {
            if (msg) {
                logger::log(logger::ERROR, "%s", lua_tostring(lua::L, -1));
            }
            lua_pop(lua::L, 1);
            delete[] buf;
            return false;
        }
        delete[] buf;
        return true;
    }
} /* end namespace tools */
