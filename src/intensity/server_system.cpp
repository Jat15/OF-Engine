
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"
#include "server_system.h"
#include "world_system.h"
#include "editing_system.h"
#include "of_world.h"
#include "of_tools.h"

#define SERVER_UPDATE_INTERVAL 300

namespace server
{
    extern bool shutdown_if_empty;
    extern bool shutdown_if_idle;
    extern int  shutdown_idle_interval;
    char*& getUsername(int clientNumber);
}

bool should_quit = false;

void ServerSystem::newMap(std::string name)
{
    assert(0);
}

void ServerSystem::setMap(std::string name)
{
    assert(0);
}


void ServerSystem::importClientMap(std::string prefix, int updatingClientNumber)
{
    assert(0);
}


static uchar unusedmask; // For the further utility functions

// Utility function, a headless version of octarender::gencubeverts
void headlessGenCubeVerts(cube &c, int x, int y, int z, int size, int csi, uchar &vismask, uchar &clipmask)
{
    loopi(6) if(visibleface(c, i, x, y, z, size))
    {
        // this is necessary for physics to work, even if the face is merged
        if(touchingface(c, i)) 
        {
            c.visible |= 1<<i; // Kripken: Indeed, without this (and the same later), physics fails, things fall through cubes...
        }
    }
    else if(touchingface(c, i))
    {
        if(visibleface(c, i, x, y, z, size, MAT_AIR, MAT_NOCLIP, MATF_CLIP)) c.visible |= 1<<i;
    }
}

// Utility, headless version of octarender::rendercube
void headlessRenderCube(cube &c, int cx, int cy, int cz, int size, int csi, uchar &vismask = unusedmask, uchar &clipmask = unusedmask)
{
    if(c.children)
    {
        uchar clipchild[8];
        loopi(8)
        {
            ivec o(i, cx, cy, cz, size/2);
            headlessRenderCube(c.children[i], o.x, o.y, o.z, size/2, csi-1, c.vismasks[i], clipchild[i]);
        }
    }

    if(!isempty(c)) headlessGenCubeVerts(c, cx, cy, cz, size, csi, vismask, clipmask);
}

void headlessSetVa(cube &c, int cx, int cy, int cz, int size, int csi)
{
    headlessRenderCube(c, cx, cy, cz, size, csi);
}

void headlessUpdateVa(cube *c, int cx, int cy, int cz, int size, int csi)
{
    loopi(8)                                    // counting number of semi-solid/solid children cubes
    {
        ivec o(i, cx, cy, cz, size);
        if(c[i].children) headlessUpdateVa(c[i].children, o.x, o.y, o.z, size/2, csi-1);
        headlessSetVa(c[i], o.x, o.y, o.z, size, csi);
    }
}

// Sort of a headless octarender()
void ServerSystem::generatePhysicsVisibilities()
{
    printf("Generating physics-related information...\r\n");
    int csi = 0;
    while(1<<csi < GETIV(mapsize)) csi++;

//    varoot.setsizenodelete(0);
    headlessUpdateVa(worldroot, 0, 0, 0, GETIV(mapsize)/2, csi-1);
}


extern const char *sethomedir(const char *dir); // shared/tools.cpp

extern void show_server_stats();   // from server.cpp
extern void server_init();         // from server.cpp
extern void server_runslice();     // from server.cpp
extern void force_network_flush(); // from server.cpp


void ServerSystem::fatalMessageToClients(std::string message)
{
    MessageSystem::send_PersonalServerMessage(-1, "Server shutting down due to error (see log)", message);
    force_network_flush();
}

bool ServerSystem::isRunningMap()
{
    return of_world_scenario_code != NULL;
}

void update_username(int clientNumber, std::string username)
{
    char *uname = server::getUsername(clientNumber);
    if (uname) OF_FREE(uname);
    uname = strdup(username.c_str()); // Signals that this client is logged in TODO: Nicer
}

void create_lua_entities()
{
    server::createluaEntity(-1);
}

void set_admin(int clientNumber, bool isAdmin)
{
    server::setAdmin(clientNumber, isAdmin);
}

// INTENSITY: *New* function, to parallel sauer's client version
void serverkeepalive()
{
    extern ENetHost *serverhost;
    if(serverhost)
        enet_host_service(serverhost, NULL, 0);
}

//! Should be called from the server when doing anything long, to keep both ENet connections alive
void keep_alive()
{
    clientkeepalive(); // make sure our connection doesn't time out while loading maps etc. - client (internal headless) version
    serverkeepalive(); // make sure our connection doesn't time out while loading maps etc. - server (main) version
}

void send_text_message(int clientNumber, std::string text, bool sound)
{
    MessageSystem::send_PersonalServerMessage(clientNumber, "", text);
    if (sound)
        MessageSystem::send_SoundToClientsByName(clientNumber, 0, 0, 0, "olpc/FlavioGaete/Vla_G_Major", -1);
}

int main(int argc, char **argv)
{
    // Pre-initializations
    static Texture dummyTexture;

    dummyTexture.name = (char*)"";
    dummyTexture.type = Texture::IMAGE;
    dummyTexture.w = 1;
    dummyTexture.h = 1;
    dummyTexture.xs = 1;
    dummyTexture.ys = 1;
    dummyTexture.bpp = 8;
    dummyTexture.clamp = 1;
    dummyTexture.mipmap = 0;
    dummyTexture.canreduce = 0;
    dummyTexture.id = -1;
    dummyTexture.alphamask = new uchar[100]; // Whatever

    notexture = &dummyTexture;

    setlogfile(NULL);

    char *loglevel  = (char*)"WARNING";
    char *map_asset = NULL;
    for(int i = 1; i < argc; i++)
    {
        if(argv[i][0]=='-') switch(argv[i][1])
        {
            case 'q': 
            {
                const char *dir = sethomedir(&argv[i][2]);
                if(dir) logoutf("Using home directory: %s", dir);
                break;
            }
            case 'g': logoutf("Setting logging level", &argv[i][2]); loglevel = &argv[i][2]; break;
            case 'm': logoutf("Setting map", &argv[i][2]); map_asset = &argv[i][2]; break;
            default:
            {
                if (!strcmp(argv[i], "-shutdown-if-empty"))
                    server::shutdown_if_empty = true;
                else if (!strcmp(argv[i], "-shutdown-if-idle"))
                    server::shutdown_if_idle = true;
                else if (!strcmp(argv[i], "-shutdown-idle-interval"))
                {
                    char *endptr = NULL;
                    int interval = strtol(argv[i + 1], &endptr, 10);
                    if (!endptr && interval) server::shutdown_idle_interval = interval;
                }
            }
        }
        else gameargs.add(argv[i]);
    }
    Logging::init(loglevel);

    if (!map_asset)
    {
        Logging::log(Logging::ERROR, "No map asset to run. Shutting down.");
        return 1;
    }

    lua::engine.create();
    server_init();

    Logging::log(Logging::DEBUG, "Running first slice.\n");
    server_runslice();

    int last_server_update = 0;
    int servermillis = time(0) * 1000;
    while (!should_quit)
    {
        while ((time(0) * 1000) - servermillis < 33)
            continue;

        servermillis = time(0) * 1000;

        if (!should_quit)
            server_runslice();

        if (time(0) - last_server_update >= SERVER_UPDATE_INTERVAL)
        {
            Logging::log(Logging::DEBUG, "Setting map ..\n");
            last_server_update = time(0);
            of_world_set_map(map_asset);
        }
    }

    Logging::log(Logging::WARNING, "Stopping main server.");
    var::flush();

    return 0;
}


//=====================================================================================
// Utilities to make the server able to use Cube code that was client-only in the past
//=====================================================================================

void show_out_of_renderloop_progress(float bar1, const char *text1, float bar2, const char *text2L, GLuint tex)
{
    std::string text = text1;
    text = text + "\r\n";
    Logging::log(Logging::DEBUG, text.c_str());
}

#define CONSTRLEN 512

void conoutfv(int type, const char *fmt, va_list args)
{
    static char buf[CONSTRLEN];
    vformatstring(buf, fmt, args);
    printf("%s\r\n", buf);
}

void conoutf(int type, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(type, fmt, args);
    va_end(args);
}

void conoutf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    conoutfv(CON_INFO, fmt, args);
    va_end(args); 
}

// Stuff the client has in various files, which the server needs replacements for

Texture *notexture = NULL; // Replacement for texture.cpp's notexture

int hasstencil = 0; // For rendergl.cpp

Shader *Shader::lastshader = NULL;
void Shader::bindprograms() { assert(0); };
void Shader::flushenvparams(Slot* slot) { assert(0); };
void Shader::setslotparams(Slot& slot, VSlot &vslot) { assert(0); };

bool glaring = false; // glare.cpp

void damageblend(int n) { };

void damagecompass(int n, const vec &loc) { };

void playsound(int n, const vec *loc, extentity *ent) { }

void renderprogress(float bar, const char *text, GLuint tex, bool background)
{
    keep_alive(); // Keep both client and server ENet connections alive

    printf("|");
    for (int i = 0; i < 10; i++)
    {
        if (i < int(bar*10))
            printf("#");
        else
            printf("-");
    }
    printf("| %s\r", text);
    fflush(stdout);
}

bool interceptkey(int sym) { return false; };

void fatal(const char *s, ...)
{
    printf("FATAL: %s\r\n", s);
    exit(-1);
};

bool printparticles(extentity &e, char *buf) { return true; };
void clearparticleemitters() { };

void createtexture(int tnum, int w, int h, void *pixels, int clamp, int filter, GLenum component, GLenum subtarget, int pw, int ph, int pitch, bool resize) { assert(0); };

vec worldpos;
vec camdir;
bvec watercolor, waterfallcolor, lavacolor;
int hidehud; // to replace
dynent *player = NULL;
physent *camera1 = NULL;
float loadprogress = 0.333;
vector<LightMap> lightmaps;
int initing = NOT_INITING;
bool shadowmapping = false;
Shader *nocolorshader = NULL, *notextureshader = NULL, *lineshader = NULL;
bool fading = false;
int xtraverts = 0, xtravertsva = 0;
bool reflecting = false;
int refracting = 0;
float reflectz;
bool fogging = false;

bool hasVBO = false, hasDRE = false, hasOQ = false, hasTR = false, hasFBO = false, hasDS = false, hasTF = false, hasBE = false, hasBC = false, hasCM = false, hasNP2 = false, hasTC = false, hasTE = false, hasMT = false, hasD3 = false, hasAF = false, hasVP2 = false, hasVP3 = false, hasPP = false, hasMDA = false, hasTE3 = false, hasTE4 = false, hasVP = false, hasFP = false, hasGLSL = false, hasGM = false, hasNVFB = false, hasSGIDT = false, hasSGISH = false, hasDT = false, hasSH = false, hasNVPCF = false, hasRN = false, hasPBO = false, hasFBB = false, hasUBO = false, hasBUE = false, hasTEX = false;

GLuint fogtex = -1;
glmatrixf mvmatrix, projmatrix, mvpmatrix, invmvmatrix, invmvpmatrix, envmatrix;
volatile bool check_calclight_progress = false;
bool calclight_canceled = false;
int curtexnum = 0;
Shader *defaultshader = NULL, *rectshader = NULL, *foggedshader = NULL, *foggednotextureshader = NULL, *stdworldshader = NULL;
bool inbetweenframes = false, renderedframe = false;
vec shadowoffset(0, 0, 0), shadowfocus(0, 0, 0), shadowdir(0, 0.707, 1);
int explicitsky = 0;
double skyarea = 0;
vector<LightMapTexture> lightmaptexs;
vtxarray *visibleva = NULL;

int lightmapping = 0;

bool getkeydown() { return false; };
bool getkeyup() { return false; };
bool getmousedown() { return false; };
bool getmouseup() { return false; };
void drawminimap() { };
void g3d_addgui(g3d_callback *cb, vec &origin, int flags) { };
Texture *loadthumbnail(Slot &slot) { return notexture; };
void renderblendbrush(GLuint tex, float x, float y, float w, float h) { };
void previewblends(const ivec &bo, const ivec &bs) { };
bool loadimage(const char *filename, ImageData &image) { return false; }; // or return true?
void clearmapsounds() { };
void cleanreflections() { };
void resetlightmaps(bool fullclean) { };
void clearparticles() { };
void cleardecals() { };
void clearmainmenu() { };
void clearlights() { };
void clearlightcache(int e) { };
void lightent(extentity &e, float height) { };
void fixlightmapnormals() { };
void initlights() { };
void newsurfaces(cube &c, const surfaceinfo *surfs, int numsurfs) { };
void brightencube(cube &c) { };
Texture *textureload(const char *name, int clamp, bool mipit, bool msg) { return notexture; }; // or return no-texture texture?
void renderbackground(const char *caption, Texture *mapshot, const char *mapname, const char *mapinfo, bool restore, bool force) { };
void loadpvs(gzFile f) { };
void savepvs(gzFile f) { };
void writebinds(stream *f) { };
const char *addreleaseaction(const char *s) { return NULL; };
void freesurfaces(cube &c) { };
occludequery *newquery(void *owner) { return NULL; };
void drawbb(const ivec &bo, const ivec &br, const vec &camera) { };
void renderblob(int type, const vec &o, float radius, float fade) { };
void flushblobs() { };
bool bboccluded(const ivec &bo, const ivec &br) { return true; };
int isvisiblesphere(float rad, const vec &cv) { return 0; };
bool isfoggedsphere(float rad, const vec &cv) { return false; };
bool isshadowmapcaster(const vec &o, float rad) { return false; };
bool checkquery(occludequery *query, bool nowait) { return true; };
bool addshadowmapcaster(const vec &o, float xyrad, float zrad) { return false; };
void lightreaching(const vec &target, vec &color, vec &dir, bool fast, extentity *t, float ambient) { };
void dynlightreaching(const vec &target, vec &color, vec &dir, bool hud) { };
Shader *lookupshaderbyname(const char *name) { return NULL; };
Texture *cubemapload(const char *name, bool mipit, bool msg, bool transient) { return notexture; };
Shader *useshaderbyname(const char *name) { return NULL; };
void resettmu(int n) { };
void setuptmu(int n, const char *rgbfunc, const char *alphafunc) { };
void colortmu(int n, float r, float g, float b, float a) { };
void scaletmu(int n, int rgbscale, int alphascale) { };
void getwatercolour(uchar *wcol) { };
void createfogtex() { };
void setenvparamf(const char *name, int type, int index, float x, float y, float z, float w) { };
void setenvparamfv(const char *name, int type, int index, const float *v) { };
void setfogplane(const plane &p, bool flush) { };
ushort closestenvmap(const vec &o) { return 0; };
ushort closestenvmap(int orient, int x, int y, int z, int size) { return 0; };
GLuint lookupenvmap(Slot &slot) { return 0; };
GLuint lookupenvmap(ushort emid) { return 0; };
void loadalphamask(Texture *t) { };
void createtexture(int tnum, int w, int h, void *pixels, int clamp, int filter, GLenum component, GLenum subtarget, int pw, int ph, int pitch, bool resize, GLenum format) { };

vector<VSlot *> vslots;
vector<Slot *> slots;
Slot dummyslot;
VSlot dummyvslot(&dummyslot);

Slot &lookupslot(int index, bool load)
    {
        static Slot sl;
        static Shader sh;
        sl.shader = &sh;
        return sl;
    };

VSlot &lookupvslot(int index, bool load)
{
    static VSlot vsl;
    static Slot sl = lookupslot(0, 0);
    vsl.slot = &sl;
    return vsl;
}

VSlot *editvslot(const VSlot &src, const VSlot &delta)
{
    return &lookupvslot(0, 0);
}

VSlot *findvslot(Slot &slot, const VSlot &src, const VSlot &delta)
{
    return &lookupvslot(0, 0);
}

void clearslots() { };
void compactvslots(cube *c, int n) { };
int compactvslots() { return 0; };
void compactvslot(int &index) { };
void mergevslot(VSlot &dst, const VSlot &src, const VSlot &delta) { };

const char *getshaderparamname(const char *name) { return ""; };

int Shader::uniformlocversion() { return 0; };

void check_calclight_canceled() { };
void setupmaterials(int start, int len) { };
void invalidatepostfx() { };
void resetblobs() { };
int findmaterial(const char *name) { return 0; };
void keyrepeat(bool on) { };
bool g3d_windowhit(bool on, bool act) { return false; };
void enablepolygonoffset(GLenum type) { };
void disablepolygonoffset(GLenum type) { };
vec menuinfrontofplayer() { return vec(0,0,0); };
void genmatsurfs(cube &c, int cx, int cy, int cz, int size, vector<materialsurface> &matsurfs, uchar &vismask, uchar &clipmask) { };
void resetqueries() { };
void initenvmaps() { };
void guessshadowdir() { };
void genenvmaps() { };
int optimizematsurfs(materialsurface *matbuf, int matsurfs) { return 0; };
void texturereset(int n) { };

void seedparticles() { };

glmatrixf fogmatrix;

#ifdef WINDOWS
// Need to create a 'stub' DLL, like with Linux, but for now try this FIXME
#include "GL/gl.h"
#else // LINUX
// OpenGL stubs - prevent the need to load OpenGL libs
void glGenTextures(GLsizei n, GLuint *textures) { };
void glBegin(GLenum mode) { };
void glVertex3fv(const GLfloat *v) { };
void glEnd() { };
void glColor3f(GLfloat red , GLfloat green , GLfloat blue) { };
void glColor3ub(GLubyte red, GLubyte green, GLubyte blue) { };
void glLineWidth(GLfloat width) { };
void glPolygonMode(GLenum face, GLenum mode) { };
void glDepthFunc(GLenum func) { };
void glFlush() { };
void glColorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha) { };
void glDepthMask(GLboolean flag) { };
void glEnable(GLenum cap) { };
void glDisable(GLenum cap) { };
void glVertex3f(GLfloat x, GLfloat y ,GLfloat z) { };
void glEnableClientState(GLenum cap) { };
void glDisableClientState(GLenum cap) { };
void glVertexPointer(GLint size, GLenum type, GLsizei stride, const GLvoid *pointer) { };
void glNormalPointer(GLenum type, GLsizei stride, const GLvoid *pointer) { };
void glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const GLvoid * pointer) { };
void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) { };
void glMaterialfv(GLenum face, GLenum pname, const GLfloat * params) { };
void glTexGeni( GLenum coord, GLenum pname, GLint param) { };
void glBindTexture(GLenum target, GLuint texture) { };
void glTexGenfv( GLenum coord, GLenum pname, const GLfloat *params ) { };
void glLightfv(    GLenum      light, GLenum      pname, const GLfloat *      params) { };
void glBlendFunc( GLenum sfactor, GLenum dfactor ) { };
void glAlphaFunc( GLenum func, GLclampf ref ) { };
void glMatrixMode( GLenum mode ) { };
void glPushMatrix( void ) { };
void glTranslatef( GLfloat x, GLfloat y, GLfloat z ) { };
void glDrawElements( GLenum mode, GLsizei count, GLenum type, const GLvoid *indices ) { };
void glPopMatrix(          void) { };
void glLightModelfv(    GLenum      pname, const GLfloat *      params) { }
void glMultMatrixf( const GLfloat *m ) { };
void glScalef( GLfloat x, GLfloat y, GLfloat z ) { };
void glLoadMatrixf( const GLfloat *m ) { };
void glLoadIdentity( void ) { };
void glTexCoord2fv( const GLfloat *v ) { };
void glVertex2f( GLfloat x, GLfloat y ) { };
void glDeleteTextures( GLsizei n, const GLuint *textures ) { };
#endif

PFNGLBEGINQUERYARBPROC glBeginQuery_ = NULL;
PFNGLENDQUERYARBPROC glEndQuery_ = NULL;
PFNGLDISABLEVERTEXATTRIBARRAYARBPROC glDisableVertexAttribArray_ = NULL;
PFNGLPROGRAMENVPARAMETERS4FVEXTPROC   glProgramEnvParameters4fv_ = NULL;
PFNGLPROGRAMENVPARAMETER4FVARBPROC   glProgramEnvParameter4fv_   = NULL;
PFNGLDELETEBUFFERSARBPROC    glDeleteBuffers_    = NULL;
PFNGLGENBUFFERSARBPROC       glGenBuffers_       = NULL;
PFNGLBINDBUFFERARBPROC       glBindBuffer_ = NULL;
PFNGLBUFFERDATAARBPROC       glBufferData_       = NULL;
PFNGLCLIENTACTIVETEXTUREARBPROC glClientActiveTexture_ = NULL;
PFNGLENABLEVERTEXATTRIBARRAYARBPROC  glEnableVertexAttribArray_  = NULL;
PFNGLVERTEXATTRIBPOINTERARBPROC      glVertexAttribPointer_      = NULL;
PFNGLACTIVETEXTUREARBPROC       glActiveTexture_ = NULL;
PFNGLDRAWRANGEELEMENTSEXTPROC glDrawRangeElements_ = NULL;
PFNGLGETBUFFERSUBDATAARBPROC glGetBufferSubData_ = NULL;
PFNGLUNIFORM4FVARBPROC                glUniform4fv_               = NULL;
PFNGLBUFFERSUBDATAARBPROC    glBufferSubData_    = NULL;
PFNGLBINDBUFFERBASEPROC          glBindBufferBase_          = NULL;
PFNGLUNIFORMBUFFEREXTPROC        glUniformBuffer_        = NULL;
