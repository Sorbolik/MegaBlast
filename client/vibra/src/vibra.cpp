// vibra.tocco(): la micro-vibrazione del sistema (quella dei tasti della
// tastiera), dalla classe Java com.sorbolik.megablast.Vibra. Solo su Android.
#define EXTENSION_NAME Vibra
#define LIB_NAME "Vibra"
#define MODULE_NAME "vibra"

#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_ANDROID)
#include <dmsdk/dlib/android.h>

static int Tocco(lua_State* L)
{
    dmAndroid::ThreadAttacher thread;
    JNIEnv* env = thread.GetEnv();
    if (!env)
        return 0;
    jclass cls = dmAndroid::LoadClass(env, "com.sorbolik.megablast.Vibra");
    if (cls)
    {
        jmethodID tocco = env->GetStaticMethodID(cls, "tocco", "(Landroid/app/Activity;)V");
        if (tocco)
            env->CallStaticVoidMethod(cls, tocco, dmAndroid::GetActivity()->clazz);
        env->DeleteLocalRef(cls);
    }
    if (env->ExceptionCheck())
        env->ExceptionClear();
    return 0;
}

static const luaL_reg Module_methods[] = {
    {"tocco", Tocco},
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
