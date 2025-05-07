//
// Created on 2024/6/26.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef DIMINA_HARMONYOS_THREAD_H
#define DIMINA_HARMONYOS_THREAD_H

#include "napi/native_api.h"
#include "quickjs.h"
using namespace std;

extern napi_value StartJsEngine(napi_env env, napi_callback_info info);
extern napi_value dispatchJsTask(napi_env env, napi_callback_info info);
extern napi_value dispatchJsTaskAb(napi_env env, napi_callback_info info);
extern napi_value dispatchJsTaskPath(napi_env env, napi_callback_info info);
extern napi_value destroyJsEngine(napi_env env, napi_callback_info info);

#endif //DIMINA_HARMONYOS_THREAD_H
