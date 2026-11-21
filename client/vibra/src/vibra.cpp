// Dalla classe Java com.sorbolik.megablast.Vibra, solo su Android:
//   vibra.tocco()            la micro-vibrazione del sistema (quella dei tasti della tastiera)
//   vibra.colpo(ms, forza)   la vibrazione di un'esplosione (forza da 1 a 255)
//   vibra.alta_frequenza()   lo schermo a 90/120 Hz, se li ha
//   vibra.modo_gioco()       0 non c'è, 1 normale, 2 prestazioni, 3 risparmio batteria
#define EXTENSION_NAME Vibra
#define LIB_NAME "Vibra"
#define MODULE_NAME "vibra"

#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_ANDROID)
#include <dmsdk/dlib/android.h>
#include <dmsdk/graphics/graphics_native.h>

// Calls the static method name(Activity, ...) of the Java class; returns its int (or 0)
static int CallVibra(const char* name, const char* sig, int a, int b, bool with_args, bool returns_int)
{
    dmAndroid::ThreadAttacher thread;
    JNIEnv* env = thread.GetEnv();
    if (!env)
        return 0;
    int out = 0;
    jclass cls = dmAndroid::LoadClass(env, "com.sorbolik.megablast.Vibra");
    if (cls)
    {
        jmethodID m = env->GetStaticMethodID(cls, name, sig);
        if (m)
        {
            jobject act = dmGraphics::GetNativeAndroidActivity();
            if (returns_int)
                out = env->CallStaticIntMethod(cls, m, act);
            else if (with_args)
                env->CallStaticVoidMethod(cls, m, act, (jint)a, (jint)b);
            else
                env->CallStaticVoidMethod(cls, m, act);
        }
        env->DeleteLocalRef(cls);
    }
    if (env->ExceptionCheck())
        env->ExceptionClear();
    return out;
}

static int Tocco(lua_State* L)
{
    CallVibra("tocco", "(Landroid/app/Activity;)V", 0, 0, false, false);
    return 0;
}

static int Colpo(lua_State* L)
{
    CallVibra("colpo", "(Landroid/app/Activity;II)V", luaL_checkinteger(L, 1), luaL_checkinteger(L, 2), true, false);
    return 0;
}

static int AltaFrequenza(lua_State* L)
{
    CallVibra("altaFrequenza", "(Landroid/app/Activity;)V", 0, 0, false, false);
    return 0;
}

static int ModoGioco(lua_State* L)
{
    lua_pushinteger(L, CallVibra("modoGioco", "(Landroid/app/Activity;)I", 0, 0, false, true));
    return 1;
}

static const luaL_reg Module_methods[] = {
    {"tocco", Tocco},
    {"colpo", Colpo},
    {"alta_frequenza", AltaFrequenza},
    {"modo_gioco", ModoGioco},
    {0, 0}
};

static dmExtension::Result Initialize(dmExtension::Params* params)
{
    luaL_register(params->m_L, MODULE_NAME, Module_methods);
    lua_pop(params->m_L, 1);
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
