// A second Lua engine on its own thread, for the bots that think a lot (the
// MAESTRO): client/main/side_core.lua sends it the simulation's modules and the
// match, sim/second_core.lua plays the match's twin there and sends back the
// bots' keys. The two engines share nothing but two queues of strings.
//
//   pensiero.avvia(modules, main)  -- modules: { ["sim.game"] = source, ... }; main: the module to run (once)
//   pensiero.manda(text)           -- to the other core
//   pensiero.ricevi()              -- from the other core: the oldest message, or nil
//   pensiero.attendi(ms)           -- the same, waiting up to ms for one
//   pensiero.errore()              -- why the other core stopped, or nil
//
// Over there the same pensiero.manda and pensiero.ricevi(block) are the other ends.
#define EXTENSION_NAME Pensiero
#define LIB_NAME "Pensiero"
#define MODULE_NAME "pensiero"

#include <dmsdk/sdk.h>

#if !defined(DM_PLATFORM_HTML5)

#include <cassert>
#include <chrono>
#include <cstring>
#include <condition_variable>
#include <deque>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

extern "C" {
LUALIB_API void(luaL_openlibs)(lua_State* L);
}

struct Queue
{
    std::mutex m;
    std::condition_variable cv;
    std::deque<std::string> q;

    void Push(std::string s)
    {
        {
            std::lock_guard<std::mutex> lock(m);
            q.push_back(std::move(s));
        }
        cv.notify_one();
    }

    // wait_ms: < 0 forever, 0 not at all
    bool Pop(std::string& out, int wait_ms)
    {
        std::unique_lock<std::mutex> lock(m);
        if (q.empty() && wait_ms != 0)
        {
            if (wait_ms < 0)
                cv.wait(lock, [this] { return !q.empty(); });
            else
                cv.wait_for(lock, std::chrono::milliseconds(wait_ms), [this] { return !q.empty(); });
        }
        if (q.empty())
            return false;
        out = std::move(q.front());
        q.pop_front();
        return true;
    }
};

static Queue g_ToWorker, g_FromWorker;
static std::thread g_Thread;
static bool g_Started = false;
static std::mutex g_ErrorMutex;
static std::string g_Error;

static std::vector<std::pair<std::string, std::string>> g_Modules;
static std::string g_Main;

// Over there --------------------------------------------------------------------------

static int Worker_Send(lua_State* L)
{
    size_t n;
    const char* s = luaL_checklstring(L, 1, &n);
    g_FromWorker.Push(std::string(s, n));
    return 0;
}

static int Worker_Receive(lua_State* L)
{
    std::string s;
    if (g_ToWorker.Pop(s, lua_toboolean(L, 1) ? -1 : 0))
        lua_pushlstring(L, s.data(), s.size());
    else
        lua_pushnil(L);
    return 1;
}

static const char* BOOT =
    "local main = ...\n"
    "require(main).run({ receive = pensiero.ricevi, send = pensiero.manda })\n";

static void Fail(const char* what)
{
    std::lock_guard<std::mutex> lock(g_ErrorMutex);
    g_Error = what ? what : "?";
    dmLogError("pensiero: %s", g_Error.c_str());
}

static void WorkerMain()
{
    lua_State* L = luaL_newstate();
    if (!L)
    {
        Fail("luaL_newstate");
        return;
    }
    luaL_openlibs(L);
    static const luaL_reg fns[] = { { "manda", Worker_Send }, { "ricevi", Worker_Receive }, { 0, 0 } };
    luaL_register(L, MODULE_NAME, fns);
    lua_pop(L, 1);
    // every module in package.preload, compiled from its source
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (size_t i = 0; i < g_Modules.size(); ++i)
    {
        const std::string& name = g_Modules[i].first;
        const std::string& src = g_Modules[i].second;
        std::string chunk = "@" + name;
        if (luaL_loadbuffer(L, src.data(), src.size(), chunk.c_str()) != 0)
        {
            Fail(lua_tostring(L, -1));
            lua_close(L);
            return;
        }
        lua_setfield(L, -2, name.c_str());
    }
    lua_pop(L, 2);
    g_Modules.clear();
    if (luaL_loadbuffer(L, BOOT, strlen(BOOT), "=pensiero") != 0)
    {
        Fail(lua_tostring(L, -1));
        lua_close(L);
        return;
    }
    lua_pushstring(L, g_Main.c_str());
    if (lua_pcall(L, 1, 0, 0) != 0)
        Fail(lua_tostring(L, -1));
    lua_close(L);
}

// Here ---------------------------------------------------------------------------------

static int Start(lua_State* L)
{
    if (g_Started)
    {
        lua_pushboolean(L, 1);
        return 1;
    }
    luaL_checktype(L, 1, LUA_TTABLE);
    g_Main = luaL_checkstring(L, 2);
    g_Modules.clear();
    lua_pushnil(L);
    while (lua_next(L, 1) != 0)
    {
        if (lua_type(L, -2) == LUA_TSTRING && lua_type(L, -1) == LUA_TSTRING)
        {
            size_t n;
            const char* src = lua_tolstring(L, -1, &n);
            g_Modules.push_back(std::make_pair(std::string(lua_tostring(L, -2)), std::string(src, n)));
        }
        lua_pop(L, 1);
    }
    g_Thread = std::thread(WorkerMain);
    g_Thread.detach();
    g_Started = true;
    lua_pushboolean(L, 1);
    return 1;
}

static int Send(lua_State* L)
{
    size_t n;
    const char* s = luaL_checklstring(L, 1, &n);
    g_ToWorker.Push(std::string(s, n));
    return 0;
}

static int PushMessage(lua_State* L, int wait_ms)
{
    std::string s;
    if (g_FromWorker.Pop(s, wait_ms))
        lua_pushlstring(L, s.data(), s.size());
    else
        lua_pushnil(L);
    return 1;
}

static int Receive(lua_State* L)
{
    return PushMessage(L, 0);
}

static int Wait(lua_State* L)
{
    int ms = (int)luaL_checkinteger(L, 1);
    return PushMessage(L, ms < 1 ? 1 : ms);
}

static int Error(lua_State* L)
{
    std::lock_guard<std::mutex> lock(g_ErrorMutex);
    if (g_Error.empty())
        lua_pushnil(L);
    else
        lua_pushstring(L, g_Error.c_str());
    return 1;
}

static const luaL_reg Module_methods[] = {
    { "avvia", Start },
    { "manda", Send },
    { "ricevi", Receive },
    { "attendi", Wait },
    { "errore", Error },
    { 0, 0 }
};

static dmExtension::Result Initialize(dmExtension::Params* params)
{
    lua_State* L = params->m_L;
    int top = lua_gettop(L);
    luaL_register(L, MODULE_NAME, Module_methods);
    lua_pop(L, 1);
    assert(top == lua_gettop(L));
    return dmExtension::RESULT_OK;
}

#else

static dmExtension::Result Initialize(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

#endif

static dmExtension::Result AppInitialize(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalize(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result Finalize(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, AppInitialize, AppFinalize, Initialize, 0, 0, Finalize)
