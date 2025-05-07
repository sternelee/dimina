#ifndef QJS_TIMEOUT_C
#define QJS_TIMEOUT_C

#include "types/qjs_extension/settimeout.h"
#include "quickjs.h"
#include <assert.h>
#include <uv.h>
#include <stdlib.h>

// 声明从 JSContext 获取 uv_loop_t 的外部函数
extern uv_loop_t* js_core_get_loop_from_ctx(JSContext* ctx);

#define countof(x) (sizeof(x) / sizeof((x)[0]))

void setLogger(DebugLog newDebugLog, ExceptionLog newExceptionLog) {
    debugLog = newDebugLog;
    exceptionLog = newExceptionLog;
}

typedef struct {
    JSContext *ctx;
    uv_timer_t handle;
    int interval;
    JSValue func;
    int argc;
    JSValue argv[];
} UVTimer;

static JSClassID uv_timer_class_id;

void clearTimer(UVTimer *th) {
    // debugLog("---lehem clearTimer");
    JSContext *ctx = th->ctx;
    JS_FreeValue(ctx, th->func);
    th->func = JS_UNDEFINED;

    for (int i = 0; i < th->argc; i++) {
        JS_FreeValue(ctx, th->argv[i]);
        th->argv[i] = JS_UNDEFINED;
    }

    th->argc = 0;
}

void on_uv_close(uv_handle_t *handle) {
    // debugLog("---lehem on_uv_close");
    if (handle) {
        UVTimer *th = handle->data;
        // todo 还需要更加友好的 th 判空办法
        free(th);
    }
}

static void uv_timer_finalizer(JSRuntime *rt, JSValue val) {
    // debugLog("---lehem uv_timer_finalizer");
    UVTimer *th = JS_GetOpaque(val, uv_timer_class_id);
    if (th) {
        clearTimer(th);
        uv_close((uv_handle_t *)&th->handle, on_uv_close);
    }
}

static void uv_timer_mark(JSRuntime *rt, JSValueConst val, JS_MarkFunc *mark_func) {
    // debugLog("---lehem uv_timer_mark");
    UVTimer *th = JS_GetOpaque(val, uv_timer_class_id);
    if (th) {
        JS_MarkValue(rt, th->func, mark_func);
        for (int i = 0; i < th->argc; i++)
            JS_MarkValue(rt, th->argv[i], mark_func);
    }
}

static JSClassDef uv_timer_class = {
    "UVTimer",
    .finalizer = uv_timer_finalizer,
    .gc_mark = uv_timer_mark,
};

static void callJs(UVTimer *th) {
    // debugLog("---lehem begin call js");
    JSContext *ctx = th->ctx;
    if (ctx == NULL) {
        debugLog("JavaScript context is NULL");
        return;
    }

    JSValue ret, func1;
    if (JS_IsUndefined(th->func) || JS_IsNull(th->func)) {
        debugLog("Function is undefined or null");
        return;
    }

    /* 'func' might be destroyed when calling itself (if it frees the handler), so must take extra care */
    func1 = JS_DupValue(ctx, th->func);
    ret = JS_Call(ctx, func1, JS_UNDEFINED, th->argc, (JSValueConst *)th->argv);
    JS_FreeValue(ctx, func1);

    if (JS_IsException(ret)) {
        exceptionLog(ctx);
    }

    JS_FreeValue(ctx, ret);
    // debugLog("---lehem end call js");
}

void processPendingJobs(JSContext *ctx) {
    JSContext *ctx1;
    int err;

    // 循环处理所有挂起的任务
    while ((err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx1)) > 0) {
        if (err < 0) {
            debugLog("JS_ExecutePendingJob error");
            break;
        }
    }
}

static void timerCallback(uv_timer_t *handle) {
    UVTimer *th = handle->data;
    // todo 还需要更加友好的 th 判空办法

    processPendingJobs(th->ctx);

    callJs(th);
    if (!th->interval) {
        clearTimer(th);
        // 清理 globalTimerMap 中的条目
        JSContext *ctx = th->ctx;
        JSValue global = JS_GetGlobalObject(ctx);
        JSValue timerMap = JS_GetPropertyStr(ctx, global, "globalTimerMap");

        char timerIdStr[21];
        snprintf(timerIdStr, sizeof(timerIdStr), "%llu", (unsigned long long)th);
        JSAtom propAtom = JS_NewAtom(ctx, timerIdStr);

        JS_DeleteProperty(ctx, timerMap, propAtom, 0);
        JS_FreeAtom(ctx, propAtom);
    }
}

static JSValue js_uv_setTimer(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int type) {
    // debugLog("---lehem js_uv_setTimer");

    int32_t delay = 0;
    if (argc >= 2) {
        if (JS_ToInt32(ctx, &delay, argv[1]))
            return JS_EXCEPTION;
    }

    JSValue func = argv[0];
    if (!JS_IsFunction(ctx, func))
        return JS_ThrowTypeError(ctx, "Argument must be a function");

    int nargs = argc > 2 ? argc - 2 : 0;
    size_t size = offsetof(UVTimer, argv) + nargs * sizeof(JSValue);
    UVTimer *th = (UVTimer *)calloc(1, size);
    if (!th)
        return JS_EXCEPTION;

    th->ctx = ctx;
    th->func = JS_DupValue(ctx, func);
    th->argc = nargs;
    for (int i = 0; i < nargs; i++) {
        th->argv[i] = JS_DupValue(ctx, argv[i + 2]);
    }

    // 获取 uv_loop_t
    uv_loop_t *loop = js_core_get_loop_from_ctx(ctx);
    uv_timer_init(loop, &th->handle);
    th->handle.data = th;
    th->interval = type ? delay : 0;
    uv_timer_start(&th->handle, timerCallback, type ? 0 : delay, th->interval);


    // 创建定时器 JS 对象
    JSValue timerValue = JS_NewObjectClass(ctx, uv_timer_class_id);
    JS_SetOpaque(timerValue, th);

    JSValue global = JS_GetGlobalObject(ctx);
    JSValue globalTimerMap = JS_GetPropertyStr(ctx, global, "globalTimerMap");

    // 生成唯一的 timerId
    uint64_t timerId = (uint64_t)th;
    char timerIdStr[21]; // 足够长以容纳64位整数的字符串表示
    snprintf(timerIdStr, sizeof(timerIdStr), "%lld", (long long)timerId);
    JSAtom propAtom = JS_NewAtom(ctx, timerIdStr);
    JS_SetProperty(ctx, globalTimerMap, propAtom, timerValue);
    JS_FreeAtom(ctx, propAtom);
    return JS_NewInt64(ctx, timerId);
}

// 函数用于 setTimeout
static JSValue js_uv_setTimeout(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    return js_uv_setTimer(ctx, this_val, argc, argv, 0); // 0 表示不重复
}

// 函数用于 setInterval
static JSValue js_uv_setInterval(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    return js_uv_setTimer(ctx, this_val, argc, argv, 1); // 1 表示重复
}


static JSValue js_uv_clearTimer(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    // debugLog("---lehem js_uv_clearTimer");
    int64_t timerId;
    if (JS_ToInt64(ctx, &timerId, argv[0]))
        return JS_EXCEPTION;

    JSValue global = JS_GetGlobalObject(ctx);
    JSValue globalTimerMap = JS_GetPropertyStr(ctx, global, "globalTimerMap");

    // 将 timerId 转换为字符串
    char timerIdStr[21];
    snprintf(timerIdStr, sizeof(timerIdStr), "%lld", (long long)timerId);

    JSAtom propAtom = JS_NewAtom(ctx, timerIdStr);
    // 获取并释放定时器对象
    JSValue timerValue = JS_GetProperty(ctx, globalTimerMap, propAtom);
    if (JS_IsUndefined(timerValue)) {
        JS_FreeAtom(ctx, propAtom);
        return JS_UNDEFINED;
    }

    UVTimer *th = JS_GetOpaque(timerValue, uv_timer_class_id);
    if (th) {
        clearTimer(th);
    }
    JS_DeleteProperty(ctx, globalTimerMap, propAtom, 0);

    JS_FreeAtom(ctx, propAtom);
    JS_FreeValue(ctx, timerValue);

    return JS_UNDEFINED;
}

void timeoutInit(JSContext *ctx) {
    JS_NewClassID(&uv_timer_class_id);
    JS_NewClass(JS_GetRuntime(ctx), uv_timer_class_id, &uv_timer_class);

    JSValue global = JS_GetGlobalObject(ctx);

    JSValue globalTimerMap = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, global, "globalTimerMap", JS_DupValue(ctx, globalTimerMap));

    JSValue setTimeout_func = JS_NewCFunction(ctx, js_uv_setTimeout, "setTimeout", 2);
    JS_SetPropertyStr(ctx, global, "setTimeout", setTimeout_func);

    JSValue clearTimeout_func = JS_NewCFunction(ctx, js_uv_clearTimer, "clearTimeout", 1);
    JS_SetPropertyStr(ctx, global, "clearTimeout", clearTimeout_func);

    JSValue setInterval_func = JS_NewCFunction(ctx, js_uv_setInterval, "setInterval", 2);
    JS_SetPropertyStr(ctx, global, "setInterval", setInterval_func);

    JSValue clearInterval_func = JS_NewCFunction(ctx, js_uv_clearTimer, "clearInterval", 1);
    JS_SetPropertyStr(ctx, global, "clearInterval", clearInterval_func);

    JS_FreeValue(ctx, global);
}

void clearAllTimers(JSContext *ctx) {
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue timerMap = JS_GetPropertyStr(ctx, global, "globalTimerMap");

    // 获取所有 timer 的属性名
    JSPropertyEnum *props;
    uint32_t len, i;
    JS_GetOwnPropertyNames(ctx, &props, &len, timerMap, JS_GPN_STRING_MASK | JS_GPN_ENUM_ONLY);

    // 遍历所有 timer
    for (i = 0; i < len; i++) {
        JSAtom propAtom = props[i].atom;
        JSValue timerValue = JS_GetProperty(ctx, timerMap, propAtom);

        UVTimer *th = JS_GetOpaque(timerValue, uv_timer_class_id);
        if (th) {
            // 停止定时器
            uv_timer_stop(&th->handle);
            // 关闭 handle，防止内存泄漏
            uv_close((uv_handle_t *)&th->handle, NULL);
            // 释放 UVTimer 相关资源
            if (th) {
                clearTimer(th);
                uv_close((uv_handle_t *)&th->handle, on_uv_close);
            }
        }

        JS_FreeValue(ctx, timerValue);
        JS_FreeAtom(ctx, propAtom);
    }

    // 清理资源
    js_free(ctx, props);
    JS_FreeValue(ctx, timerMap);
    JS_FreeValue(ctx, global);
}

#endif // QJS_TIMEOUT_C
