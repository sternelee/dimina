//
// Created on 2024/2/26.
// Author: Lehem
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef DIMINA_HARMONYOS_UTILS_H
#define DIMINA_HARMONYOS_UTILS_H


#include "quickjs.h"
#include "napi/native_api.h"
#include <string>

using namespace std;

napi_value ConvertJSObjectToNapiObject(napi_env env, JSContext *ctx, JSValueConst jsValue);
napi_value ConvertJSValueToNapiValue(napi_env env, JSContext *ctx, JSValueConst jsValue);

JSValue ConvertNapiObjectToJSObject(napi_env env, JSContext *ctx, napi_value napiObject);
JSValue ConvertNapiValueToJsValue(napi_env env, JSContext *ctx, napi_value napiValue);


char *getStringFromNapi(napi_env env, napi_value value);

napi_value createNapiString(napi_env env, string str);
napi_value createNapiInt(napi_env env, int64_t value);


bool endsWithSync(const char *str);

void checkType(napi_env env, napi_value value, const char *tag);

void printNapiValue(napi_env env, napi_value value, int indentLevel = 0);
void printJsValue(JSContext *ctx, JSValueConst jsValue, int indentLevel = 0);

char* JSValueToString(JSContext *ctx, JSValueConst val);

void printFuncName(JSContext *ctx, JSValueConst funcObj);

napi_status CopyObject(napi_env env, napi_value source, napi_value *destination);

bool isMainThread();

#endif // DIMINA_HARMONYOS_UTIL_H
