

#include "napi/native_api.h"
#include "js_thread.h"

const char *log_v = "dimina/v1";

using namespace std;


EXTERN_C_START static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"StartJsEngine", nullptr, StartJsEngine, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"dispatchJsTask", nullptr, dispatchJsTask, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"dispatchJsTaskAb", nullptr, dispatchJsTaskAb, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"dispatchJsTaskPath", nullptr, dispatchJsTaskPath, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"destroyJsEngine", nullptr, destroyJsEngine, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);

    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "dimina",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterDiminaModule(void) { napi_module_register(&demoModule); }
