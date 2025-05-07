#ifndef QJS_TIMEOUT_h
#define QJS_TIMEOUT_h

#include "quickjs.h"

#ifdef __cplusplus
extern "C" {
#endif

JSModuleDef *js_init_module_uv(JSContext *ctx, const char *module_name);

// 日志回调函数类型定义
typedef void (*DebugLog)(const char *);
typedef void (*ExceptionLog)(JSContext *ctx);

// 全局变量，用于存储日志回调函数的指针
static DebugLog debugLog = NULL;
static ExceptionLog exceptionLog = NULL;

void timeoutInit(JSContext *ctx);
void clearAllTimers(JSContext *ctx);

void setLogger(DebugLog debugLog, ExceptionLog exceptionLog);

#ifdef __cplusplus
}
#endif

#endif
