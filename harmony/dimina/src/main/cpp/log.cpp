#include "log.h"
#include "cutils.h"
#include "quickjs.h"
#include "utils.h"
#include <exception>
#include <sstream>

const char *js_engine_tag = "dimina/QuickJS";
const int js_engine_domain = 0x8989;

static void DumpObj(JSContext *ctx, JSValueConst val) {
    const char *str = JS_ToCString(ctx, val);
    OHError("%{public}s", str);
    JS_FreeCString(ctx, str);
}

static void StdDumpError(JSContext *ctx, JSValueConst exception_val) {
    JSValue val;
    BOOL is_error;

    is_error = JS_IsError(ctx, exception_val);
    DumpObj(ctx, exception_val);
    if (is_error) {
        val = JS_GetPropertyStr(ctx, exception_val, "stack");
        if (!JS_IsUndefined(val)) {
            DumpObj(ctx, val);
        }
        JS_FreeValue(ctx, val);
    }
}


void debugLogFunc(const char *str) { OHLog("%{public}s", str); }

void exceptionLogFunc(JSContext *ctx) {
    OHError("PrintJSException");
    JSValue exception_val = JS_GetException(ctx);
    StdDumpError(ctx, exception_val);
    JS_FreeValue(ctx, exception_val);
}


// 兼容多种 log 类型
static JSValue consoleLog(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int magic) {
    std::stringstream msg;
    try {
        for (int i = 0; i < argc; i++) {
            const char *str = JSValueToString(ctx, argv[i]);
            if (str != nullptr) {
                if (i > 0)
                    msg << " "; // Adding space between items
                msg << str;
            } else {
                msg << "<invalid>"; // Placeholder for null or invalid strings
            }
        }

        LogLevel level = LOG_DEBUG;
        switch (magic) {
        case 0:
            level = LOG_DEBUG;
            break;
        case 1:
            level = LOG_INFO;
            break;
        case 2:
            level = LOG_WARN;
            break;
        case 3:
            level = LOG_ERROR;
            break;
        case 4:
            level = LOG_FATAL;
            break;
        }

        OH_LOG_Print(LOG_APP, level, js_engine_domain, js_engine_tag, "[dimina][service]: %{public}s",
                     msg.str().c_str());
        
        
    } catch (const std::exception &e) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, js_engine_domain, js_engine_tag, "[dimina][service] exception: %{public}s",
                     e.what());
        return JS_EXCEPTION;
    }

    return JS_UNDEFINED;
}

// 注册 Console 多种 log，不再依赖 NativeLog
void consoleInit(JSContext *ctx) {
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue console = JS_NewObject(ctx);

    // Register each console function
    JS_SetPropertyStr(ctx, console, "log",
                      JS_NewCFunctionMagic(ctx, consoleLog, "log", 1, JS_CFUNC_generic_magic, 0)); // LOG
    JS_SetPropertyStr(ctx, console, "info",
                      JS_NewCFunctionMagic(ctx, consoleLog, "info", 1, JS_CFUNC_generic_magic, 1)); // INFO
    JS_SetPropertyStr(ctx, console, "warn",
                      JS_NewCFunctionMagic(ctx, consoleLog, "warn", 1, JS_CFUNC_generic_magic, 2)); // WARN
    JS_SetPropertyStr(ctx, console, "error",
                      JS_NewCFunctionMagic(ctx, consoleLog, "error", 1, JS_CFUNC_generic_magic, 3)); // ERROR

    JS_SetPropertyStr(ctx, global, "console", console);
    JS_FreeValue(ctx, global);
}
