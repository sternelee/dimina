#include <jni.h>
#include <string>
#include <cstring>
#include <android/log.h>
#include <atomic>
#include <fstream>
#include <sstream>
#include <unordered_map>
#include <chrono>
#include <mutex>
#include "quickjs.h"
#include "cutils.h"
#include "libregexp.h"
#include "libunicode.h"

// Define log tag for Android logging
#define LOG_TAG "QuickJSEngine(cpp)"

// Logging interval for the event loop (log progress every N iterations)
static const int EVENT_LOOP_LOG_INTERVAL = 100;

// Global JavaVM pointer for JNI calls from any thread
static JavaVM* gJavaVM = nullptr;

// JNI_OnLoad is called when the native library is loaded
extern "C" JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    // Store the JavaVM pointer for later use
    gJavaVM = vm;
    
    // Return the JNI version
    return JNI_VERSION_1_6;
}

// Structure to hold instance-specific data
struct EngineInstance {
    JSRuntime* runtime = nullptr;
    JSContext* ctx = nullptr;
    jobject engineObj = nullptr;
    std::unordered_map<int, JSValue> timerCallbacks;
    std::atomic<int> nextTimerId{1};
};

// Map to store engine instances by ID
static std::unordered_map<int, EngineInstance*> gEngineInstances;
static std::mutex gEngineInstancesMutex;

// Helper function to get an engine instance by ID
static EngineInstance* getEngineInstance(int instanceId) {
    std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
    auto it = gEngineInstances.find(instanceId);
    if (it != gEngineInstances.end()) {
        return it->second;
    }
    return nullptr;
}

// Helper function to extract detailed error information from a JS exception
static std::string getDetailedJSError(JSContext* ctx, JSValue exception) {
    std::string errorMsg;
    
    // First try to get the error type (constructor name)
    JSValue constructor = JS_GetPropertyStr(ctx, exception, "constructor");
    if (!JS_IsException(constructor) && !JS_IsUndefined(constructor) && !JS_IsNull(constructor)) {
        JSValue name = JS_GetPropertyStr(ctx, constructor, "name");
        if (!JS_IsException(name) && !JS_IsUndefined(name) && !JS_IsNull(name)) {
            const char* typeName = JS_ToCString(ctx, name);
            if (typeName) {
                errorMsg = typeName;
                errorMsg += ": ";
                JS_FreeCString(ctx, typeName);
            }
        }
        JS_FreeValue(ctx, name);
    }
    JS_FreeValue(ctx, constructor);
    
    // Get the error message
    const char* str = JS_ToCString(ctx, exception);
    if (str) {
        errorMsg += str;
        JS_FreeCString(ctx, str);
    } else if (errorMsg.empty()) {
        errorMsg = "JavaScript error";
    }
    
    // Try to get stack trace if available
    JSValue stack = JS_GetPropertyStr(ctx, exception, "stack");
    if (!JS_IsUndefined(stack) && !JS_IsNull(stack)) {
        const char* stackStr = JS_ToCString(ctx, stack);
        if (stackStr) {
            // Only add the stack trace if it's not already part of the error message
            if (str && strstr(str, stackStr) == nullptr) {
                errorMsg += "\nStack trace: ";
                errorMsg += stackStr;
            }
            JS_FreeCString(ctx, stackStr);
        }
    }
    JS_FreeValue(ctx, stack);
    
    // Try to get line number and column if available
    JSValue lineNum = JS_GetPropertyStr(ctx, exception, "lineNumber");
    JSValue colNum = JS_GetPropertyStr(ctx, exception, "columnNumber");
    
    if (!JS_IsUndefined(lineNum) && !JS_IsNull(lineNum)) {
        int32_t line;
        if (JS_ToInt32(ctx, &line, lineNum) == 0) {
            errorMsg += "\nLine: " + std::to_string(line);
        }
    }
    
    if (!JS_IsUndefined(colNum) && !JS_IsNull(colNum)) {
        int32_t col;
        if (JS_ToInt32(ctx, &col, colNum) == 0) {
            errorMsg += ", Column: " + std::to_string(col);
        }
    }
    
    JS_FreeValue(ctx, lineNum);
    JS_FreeValue(ctx, colNum);
    
    // If we still have no meaningful error message, try to convert the exception to string directly
    if (errorMsg == "JavaScript error") {
        JSValue strVal = JS_ToString(ctx, exception);
        if (!JS_IsException(strVal)) {
            const char* directStr = JS_ToCString(ctx, strVal);
            if (directStr) {
                errorMsg = directStr;
                JS_FreeCString(ctx, directStr);
            }
        }
        JS_FreeValue(ctx, strVal);
    }
    
    // Add debugging info
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "JS Error details: %s", errorMsg.c_str());
    
    return errorMsg;
}

// Helper function to handle JS errors
static jstring handleJSError(JNIEnv* env, JSContext* ctx) {
    JSValue exception = JS_GetException(ctx);
    std::string errorMsg = getDetailedJSError(ctx, exception);
    jstring result = env->NewStringUTF(errorMsg.c_str());
    JS_FreeValue(ctx, exception);
    return result;
}

// Function to run the JavaScript event loop and process pending Promise jobs
static bool runJavaScriptEventLoop(JSContext *ctx) {
    int count = 0;
    JSContext *ctx1;
    int err;
    
    // Get start time for logging purposes only
    auto startTime = std::chrono::steady_clock::now();
    
    // Process pending jobs until none are left
    for(;;) {
        err = JS_ExecutePendingJob(JS_GetRuntime(ctx), &ctx1);
        if (err <= 0) {
            // No more pending jobs or error
            if (err < 0) {
                __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "Error executing pending job");
            }
            
            // Calculate total execution time for logging
            auto endTime = std::chrono::steady_clock::now();
            auto totalMs = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime).count();
            
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, 
                "Completed %d pending jobs in %.2f ms", count, (float)totalMs);
            
            return err == 0; // true if no more jobs, false if error
        }
        
        count++;
        
        // Periodically log progress for debugging purposes
        if (count % EVENT_LOOP_LOG_INTERVAL == 0) {
            auto currentTime = std::chrono::steady_clock::now();
            auto elapsedMs = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - startTime).count();
            
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, 
                "Processed %d pending jobs so far (%.2f ms elapsed)", 
                count, (float)elapsedMs);
        }
    }
}

// Helper function to create a JSValue object from native JSValue
static jobject createJSValueObject(JNIEnv* env, JSContext* ctx, JSValue value) {
    jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
    
    if (JS_IsString(value)) {
        const char* str = JS_ToCString(ctx, value);
        jmethodID createStringMethod = env->GetStaticMethodID(
            jsValueClass, "createString", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring jstr = env->NewStringUTF(str ? str : "");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createStringMethod, jstr);
        JS_FreeCString(ctx, str);
        return result;
    } 
    else if (JS_IsNumber(value)) {
        double num;
        JS_ToFloat64(ctx, &num, value);
        jmethodID createNumberMethod = env->GetStaticMethodID(
            jsValueClass, "createNumber", "(D)Lcom/didi/dimina/engine/qjs/JSValue;");
        return env->CallStaticObjectMethod(jsValueClass, createNumberMethod, num);
    } 
    else if (JS_IsBool(value)) {
        jboolean boolValue = JS_ToBool(ctx, value);
        jmethodID createBooleanMethod = env->GetStaticMethodID(
            jsValueClass, "createBoolean", "(Z)Lcom/didi/dimina/engine/qjs/JSValue;");
        return env->CallStaticObjectMethod(jsValueClass, createBooleanMethod, boolValue);
    } 
    else if (JS_IsNull(value)) {
        jmethodID createNullMethod = env->GetStaticMethodID(
            jsValueClass, "createNull", "()Lcom/didi/dimina/engine/qjs/JSValue;");
        return env->CallStaticObjectMethod(jsValueClass, createNullMethod);
    } 
    else if (JS_IsUndefined(value)) {
        jmethodID createUndefinedMethod = env->GetStaticMethodID(
            jsValueClass, "createUndefined", "()Lcom/didi/dimina/engine/qjs/JSValue;");
        return env->CallStaticObjectMethod(jsValueClass, createUndefinedMethod);
    } 
    else if (JS_IsObject(value)) {
        // Get global object
        JSValue global = JS_GetGlobalObject(ctx);
        
        // Get JSON object
        JSValue jsonObj = JS_GetPropertyStr(ctx, global, "JSON");
        
        // Get JSON.stringify function
        JSValue jsonStringify = JS_GetPropertyStr(ctx, jsonObj, "stringify");
        
        // Free JSON object as we don't need it anymore
        JS_FreeValue(ctx, jsonObj);
        
        // Call JSON.stringify(value) to get a proper string representation
        JSValue jsonStr;
        if (JS_IsFunction(ctx, jsonStringify)) {
            // Create an array of arguments for the function call
            JSValueConst args[1];
            args[0] = value; // We don't duplicate the value here, just reference it
            
            jsonStr = JS_Call(ctx, jsonStringify, global, 1, args);
        } else {
            // Fallback if JSON.stringify is not available
            jsonStr = JS_ToString(ctx, value);
        }
        
        // Free the stringify function
        JS_FreeValue(ctx, jsonStringify);
        
        // Free the global object
        JS_FreeValue(ctx, global);
        
        // Convert to C string
        const char* str = JS_ToCString(ctx, jsonStr);
        jmethodID createObjectMethod = env->GetStaticMethodID(
            jsValueClass, "createObject", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring jstr = env->NewStringUTF(str ? str : "[object Object]");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createObjectMethod, jstr);
        
        // Free resources
        JS_FreeCString(ctx, str);
        JS_FreeValue(ctx, jsonStr);
        
        return result;
    } 
    else if (JS_IsException(value)) {
        // For exception values, we need to get the actual exception object
        JSValue exception = JS_GetException(ctx);
        std::string errorMsg = getDetailedJSError(ctx, exception);
        JS_FreeValue(ctx, exception);
        
        // Create the error JSValue object
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring jstr = env->NewStringUTF(errorMsg.c_str());
        jobject result = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, jstr);
        env->DeleteLocalRef(jstr);
        return result;
    } 
    else {
        // Default case
        jmethodID createUndefinedMethod = env->GetStaticMethodID(
            jsValueClass, "createUndefined", "()Lcom/didi/dimina/engine/qjs/JSValue;");
        return env->CallStaticObjectMethod(jsValueClass, createUndefinedMethod);
    }
}

// QuickJSEngine methods

// DiminaServiceBridge invoke method implementation
static JSValue js_dimina_invoke(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1 || !JS_IsObject(argv[0])) {
        return JS_ThrowTypeError(ctx, "Expected object argument");
    }

    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                break;
            }
        }
    }

    if (!instance || !instance->engineObj) {
        return JS_ThrowInternalError(ctx, "Engine instance not found or not initialized");
    }

    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }

    // Get the global JSON object
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue jsonObj = JS_GetPropertyStr(ctx, global, "JSON");
    JSValue jsonStringify = JS_GetPropertyStr(ctx, jsonObj, "stringify");

    // Call JSON.stringify on the input object
    JSValueConst args[1] = { argv[0] };
    JSValue jsonStr = JS_Call(ctx, jsonStringify, global, 1, args);

    // Free resources
    JS_FreeValue(ctx, jsonStringify);
    JS_FreeValue(ctx, jsonObj);
    JS_FreeValue(ctx, global);

    if (JS_IsException(jsonStr)) {
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        return JS_EXCEPTION;
    }

    // Get the JSON string
    const char* jsonData = JS_ToCString(ctx, jsonStr);
    if (!jsonData) {
        JS_FreeValue(ctx, jsonStr);
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        return JS_EXCEPTION;
    }

    // Call the Kotlin invokeFromJS method with JSValue? return type
    jclass cls = env->GetObjectClass(instance->engineObj);
    jclass jsonObjectClass = env->FindClass("org/json/JSONObject");
    jmethodID jsonObjectConstructor = env->GetMethodID(jsonObjectClass, "<init>", "(Ljava/lang/String;)V");
    jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
    jmethodID invokeMethod = env->GetMethodID(cls, "invokeFromJS", "(Lorg/json/JSONObject;)Lcom/didi/dimina/engine/qjs/JSValue;");

    jobject resultObj = nullptr;
    if (invokeMethod && jsonObjectConstructor) {
        jstring jJsonData = env->NewStringUTF(jsonData);
        jobject jsonObject = env->NewObject(jsonObjectClass, jsonObjectConstructor, jJsonData);
        resultObj = env->CallObjectMethod(instance->engineObj, invokeMethod, jsonObject);
        env->DeleteLocalRef(jsonObject);
        env->DeleteLocalRef(jJsonData);
    }

    JS_FreeCString(ctx, jsonData);
    JS_FreeValue(ctx, jsonStr);

    // Convert the returned JSValue? to a QuickJS JSValue
    JSValue result;
    if (resultObj == nullptr) {
        result = JS_NULL; // Kotlin returned null
    } else {
        // Get the Type enum field
        jclass typeClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue$Type");
        jfieldID typeField = env->GetFieldID(jsValueClass, "type", "Lcom/didi/dimina/engine/qjs/JSValue$Type;");
        jobject typeObj = env->GetObjectField(resultObj, typeField);

        // Get the name of the enum value
        jmethodID nameMethod = env->GetMethodID(typeClass, "name", "()Ljava/lang/String;");
        auto jTypeName = (jstring)env->CallObjectMethod(typeObj, nameMethod);
        const char* typeName = env->GetStringUTFChars(jTypeName, nullptr);

        // Handle each type
        if (strcmp(typeName, "NULL") == 0) {
            result = JS_NULL;
        } else if (strcmp(typeName, "STRING") == 0) {
            jfieldID stringField = env->GetFieldID(jsValueClass, "stringValue", "Ljava/lang/String;");
            auto jStringValue = (jstring)env->GetObjectField(resultObj, stringField);
            const char* stringValue = jStringValue ? env->GetStringUTFChars(jStringValue, nullptr) : nullptr;
            result = JS_NewString(ctx, stringValue ? stringValue : "");
            if (stringValue) env->ReleaseStringUTFChars(jStringValue, stringValue);
            if (jStringValue) env->DeleteLocalRef(jStringValue);
        } else if (strcmp(typeName, "NUMBER") == 0) {
            jfieldID numberField = env->GetFieldID(jsValueClass, "numberValue", "D");
            jdouble numberValue = env->GetDoubleField(resultObj, numberField);
            result = JS_NewFloat64(ctx, numberValue);
        } else if (strcmp(typeName, "BOOLEAN") == 0) {
            jfieldID booleanField = env->GetFieldID(jsValueClass, "booleanValue", "Z");
            jboolean booleanValue = env->GetBooleanField(resultObj, booleanField);
            result = JS_NewBool(ctx, booleanValue);
        } else if (strcmp(typeName, "OBJECT") == 0) {
            jfieldID stringField = env->GetFieldID(jsValueClass, "stringValue", "Ljava/lang/String;");
            auto jStringValue = (jstring)env->GetObjectField(resultObj, stringField);
            const char* stringValue = jStringValue ? env->GetStringUTFChars(jStringValue, nullptr) : nullptr;
            if (stringValue) {
                result = JS_ParseJSON(ctx, stringValue, strlen(stringValue), "<invokeFromJS>");
                if (JS_IsException(result)) {
                    result = JS_NULL; // Fallback to null on parsing error
                }
            } else {
                result = JS_NewObject(ctx); // Empty object if stringValue is null
            }
            if (stringValue) env->ReleaseStringUTFChars(jStringValue, stringValue);
            if (jStringValue) env->DeleteLocalRef(jStringValue);
        } else if (strcmp(typeName, "ERROR") == 0) {
            jfieldID errorField = env->GetFieldID(jsValueClass, "errorMessage", "Ljava/lang/String;");
            auto jErrorMessage = (jstring)env->GetObjectField(resultObj, errorField);
            const char* errorMessage = jErrorMessage ? env->GetStringUTFChars(jErrorMessage, nullptr) : "Unknown error";
            result = JS_ThrowInternalError(ctx, "%s", errorMessage);
            if (errorMessage) env->ReleaseStringUTFChars(jErrorMessage, errorMessage);
            if (jErrorMessage) env->DeleteLocalRef(jErrorMessage);
        } else {
            result = JS_UNDEFINED; // Fallback for unexpected types
        }

        // Free JNI resources
        env->ReleaseStringUTFChars(jTypeName, typeName);
        env->DeleteLocalRef(jTypeName);
        env->DeleteLocalRef(typeObj);
        env->DeleteLocalRef(typeClass);
        env->DeleteLocalRef(resultObj);
        env->DeleteLocalRef(jsValueClass);
    }

    // Detach from thread if needed
    if (needsDetach) {
        gJavaVM->DetachCurrentThread();
    }

    return result;
}

// DiminaServiceBridge publish method implementation
static JSValue js_dimina_publish(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 2 || !JS_IsString(argv[0]) || !JS_IsObject(argv[1])) {
        return JS_ThrowTypeError(ctx, "Expected string and object arguments");
    }
    
    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                break;
            }
        }
    }
    
    if (!instance || !instance->engineObj) {
        return JS_ThrowInternalError(ctx, "Engine instance not found or not initialized");
    }
    
    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }
    
    // Get the global JSON object
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue jsonObj = JS_GetPropertyStr(ctx, global, "JSON");
    JSValue jsonStringify = JS_GetPropertyStr(ctx, jsonObj, "stringify");
    
    // Call JSON.stringify on the object
    JSValueConst args[1] = { argv[1] };
    JSValue jsonStr = JS_Call(ctx, jsonStringify, global, 1, args);
    
    // Free resources
    JS_FreeValue(ctx, jsonStringify);
    JS_FreeValue(ctx, jsonObj);
    JS_FreeValue(ctx, global);
    
    if (JS_IsException(jsonStr)) {
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        return JS_EXCEPTION;
    }
    
    // Get the JSON string
    const char* jsonData = JS_ToCString(ctx, jsonStr);
    if (!jsonData) {
        JS_FreeValue(ctx, jsonStr);
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        return JS_EXCEPTION;
    }
    
    // Get the id string
    const char* id = JS_ToCString(ctx, argv[0]);
    if (!id) {
        JS_FreeCString(ctx, jsonData);
        JS_FreeValue(ctx, jsonStr);
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        return JS_EXCEPTION;
    }
    
    // Call the Kotlin publish method
    jclass cls = env->GetObjectClass(instance->engineObj);
    jclass jsonObjectClass = env->FindClass("org/json/JSONObject");
    jmethodID jsonObjectConstructor = env->GetMethodID(jsonObjectClass, "<init>", "(Ljava/lang/String;)V");
    jmethodID publishMethod = env->GetMethodID(cls, "publishFromJS", "(Ljava/lang/String;Lorg/json/JSONObject;)V");
    
    if (publishMethod && jsonObjectConstructor) {
        jstring jId = env->NewStringUTF(id);
        jstring jJsonData = env->NewStringUTF(jsonData);
        jobject jsonObject = env->NewObject(jsonObjectClass, jsonObjectConstructor, jJsonData);
        env->CallVoidMethod(instance->engineObj, publishMethod, jId, jsonObject);
        env->DeleteLocalRef(jsonObject);
        env->DeleteLocalRef(jJsonData);
        env->DeleteLocalRef(jId);
    }
    
    JS_FreeCString(ctx, id);
    JS_FreeCString(ctx, jsonData);
    JS_FreeValue(ctx, jsonStr);
    
    // Detach from thread if needed
    if (needsDetach) {
        gJavaVM->DetachCurrentThread();
    }
    
    return JS_UNDEFINED;
}

// clearTimeout implementation
static JSValue js_clear_timeout(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1 || !JS_IsNumber(argv[0])) {
        return JS_ThrowTypeError(ctx, "clearTimeout expects a timer ID as first argument");
    }
    
    // Get the timer ID
    int32_t timerId = 0;
    JS_ToInt32(ctx, &timerId, argv[0]);
    
    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    int instanceId = -1;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                instanceId = pair.first;
                break;
            }
        }
    }
    
    if (!instance) {
        return JS_ThrowInternalError(ctx, "Could not find engine instance for this context");
    }
    
    // Check if we have a valid engine object
    if (!instance->engineObj) {
        return JS_ThrowInternalError(ctx, "Engine object not initialized");
    }
    
    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }
    
    // Call the Java method to clear the timer
    jclass cls = env->GetObjectClass(instance->engineObj);
    jmethodID clearTimerMethod = env->GetMethodID(cls, "clearTimer", "(I)Z");
    
    jboolean result = JNI_FALSE;
    if (clearTimerMethod) {
        result = env->CallBooleanMethod(instance->engineObj, clearTimerMethod, timerId);
        
        // Log that we cleared a timer
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Cleared timer %d for instance %d: %s", 
                           timerId, instanceId, result == JNI_TRUE ? "success" : "not found");
    }
    
    // Clean up JNI if needed
    if (needsDetach) {
        gJavaVM->DetachCurrentThread();
    }
    
    return JS_UNDEFINED;
}

// setTimeout implementation
static JSValue js_set_timeout(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1 || (!JS_IsFunction(ctx, argv[0]) && !JS_IsString(argv[0]))) {
        return JS_ThrowTypeError(ctx, "setTimeout expects at least a function or string as first argument");
    }
    
    // Get the delay time in milliseconds (default to 0 if not provided)
    int32_t delay = 0;
    if (argc >= 2 && JS_IsNumber(argv[1])) {
        JS_ToInt32(ctx, &delay, argv[1]);
        if (delay < 0) delay = 0;
    }
    
    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    int instanceId = -1;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                instanceId = pair.first;
                break;
            }
        }
    }
    
    if (!instance) {
        return JS_ThrowInternalError(ctx, "Could not find engine instance for this context");
    }
    
    // Generate a unique timer ID
    int timerId = instance->nextTimerId++;
    
    // Store the callback function with a duplicate to prevent garbage collection
    instance->timerCallbacks[timerId] = JS_DupValue(ctx, argv[0]);
    
    // Check if we have a valid engine object
    if (!instance->engineObj) {
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);
        return JS_ThrowInternalError(ctx, "Engine object not initialized");
    }
    
    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
            instance->timerCallbacks.erase(timerId);
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }
    
    // Call the Java method to schedule the timer
    jclass cls = env->GetObjectClass(instance->engineObj);
    jmethodID scheduleTimerMethod = env->GetMethodID(cls, "scheduleTimer", "(II)V");
    
    if (scheduleTimerMethod) {
        env->CallVoidMethod(instance->engineObj, scheduleTimerMethod, timerId, delay, instanceId);
        
        // Log that we scheduled a timer
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Scheduled timer %d with delay %d ms for instance %d", 
                           timerId, delay, instanceId);
        
        // Clean up JNI if needed
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        
        // Return the timer ID to JavaScript
        return JS_NewInt32(ctx, timerId);
    } else {
        // If the method is not found, clean up and throw an error
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);
        
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }
        
        return JS_ThrowInternalError(ctx, "Failed to schedule timer: Java method not found");
    }
}

// setIntervalNative implementation
static JSValue js_set_interval(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1 || (!JS_IsFunction(ctx, argv[0]) && !JS_IsString(argv[0]))) {
        return JS_ThrowTypeError(ctx, "setIntervalNative expects at least a function or string as first argument");
    }

    // Get the interval time in milliseconds (default to 0 if not provided)
    int32_t interval = 0;
    if (argc >= 2 && JS_IsNumber(argv[1])) {
        JS_ToInt32(ctx, &interval, argv[1]);
        if (interval < 0) interval = 0;
    }

    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    int instanceId = -1;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                instanceId = pair.first;
                break;
            }
        }
    }

    if (!instance) {
        return JS_ThrowInternalError(ctx, "Could not find engine instance for this context");
    }

    // Generate a unique timer ID
    int timerId = instance->nextTimerId++;

    // Store the callback function with a duplicate to prevent garbage collection
    instance->timerCallbacks[timerId] = JS_DupValue(ctx, argv[0]);

    // Check if we have a valid engine object
    if (!instance->engineObj) {
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);
        return JS_ThrowInternalError(ctx, "Engine object not initialized");
    }

    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
            instance->timerCallbacks.erase(timerId);
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }

    // Call the Java method to schedule the interval
    jclass cls = env->GetObjectClass(instance->engineObj);
    jmethodID scheduleIntervalMethod = env->GetMethodID(cls, "scheduleInterval", "(II)V");

    if (scheduleIntervalMethod) {
        env->CallVoidMethod(instance->engineObj, scheduleIntervalMethod, timerId, interval, instanceId);

        // Log that we scheduled an interval
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Scheduled interval %d with delay %d ms for instance %d",
                            timerId, interval, instanceId);

        // Clean up JNI if needed
        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }

        // Return the timer ID to JavaScript
        return JS_NewInt32(ctx, timerId);
    } else {
        // If the method is not found, clean up and throw an error
        JS_FreeValue(ctx, instance->timerCallbacks[timerId]);
        instance->timerCallbacks.erase(timerId);

        if (needsDetach) {
            gJavaVM->DetachCurrentThread();
        }

        return JS_ThrowInternalError(ctx, "Failed to schedule interval: Java method not found");
    }
}

// clearIntervalNative implementation
static JSValue js_clear_interval(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    if (argc < 1 || !JS_IsNumber(argv[0])) {
        return JS_ThrowTypeError(ctx, "clearIntervalNative expects a timer ID as first argument");
    }

    // Get the timer ID
    int32_t timerId = 0;
    JS_ToInt32(ctx, &timerId, argv[0]);

    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    int instanceId = -1;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                instanceId = pair.first;
                break;
            }
        }
    }

    if (!instance) {
        return JS_ThrowInternalError(ctx, "Could not find engine instance for this context");
    }

    // Check if we have a valid engine object
    if (!instance->engineObj) {
        return JS_ThrowInternalError(ctx, "Engine object not initialized");
    }

    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }

    // Call the Java method to clear the interval
    jclass cls = env->GetObjectClass(instance->engineObj);
    jmethodID clearIntervalMethod = env->GetMethodID(cls, "clearInterval", "(I)Z");

    jboolean result = JNI_FALSE;
    if (clearIntervalMethod) {
        result = env->CallBooleanMethod(instance->engineObj, clearIntervalMethod, timerId);

        // Log that we cleared an interval
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Cleared interval %d for instance %d: %s",
                            timerId, instanceId, result == JNI_TRUE ? "success" : "not found");
    }

    // Clean up JNI if needed
    if (needsDetach) {
        gJavaVM->DetachCurrentThread();
    }

    return JS_UNDEFINED;
}

// Function to clear a timer
extern "C" JNIEXPORT jboolean JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeClearTimer(
        JNIEnv* env,
        jobject thiz,
        jint timerId,
        jint instanceId) {
    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, 
            "Failed to clear timer %d for instance %d: Instance not found or context is null", 
            timerId, instanceId);
        return JNI_FALSE;
    }
    
    // Check if the timer exists in the map
    auto it = instance->timerCallbacks.find(timerId);
    if (it != instance->timerCallbacks.end()) {
        // Free the callback value
        JS_FreeValue(instance->ctx, it->second);
        
        // Remove the timer from the map
        instance->timerCallbacks.erase(it);
        
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, 
            "Cleared timer %d for instance %d from native side", timerId, instanceId);
        return JNI_TRUE;
    }
    
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, 
        "Timer %d for instance %d not found on native side", timerId, instanceId);
    return JNI_FALSE;
}

// Function to execute a stored timer callback
extern "C" JNIEXPORT void JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeExecuteTimer(
        JNIEnv* env,
        jobject thiz,
        jint timerId,
        jint instanceId) {
    
    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, 
            "Failed to execute timer %d for instance %d: Instance not found or context is null", 
            timerId, instanceId);
        return;
    }
    
    JSContext* ctx = instance->ctx;
    
    // Find the callback function for this timer ID
    auto it = instance->timerCallbacks.find(timerId);
    if (it == instance->timerCallbacks.end()) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, 
            "Failed to execute timer %d for instance %d: Callback not found", 
            timerId, instanceId);
        return;
    }
    
    JSValue callback = it->second;
    
    // Execute the callback
    JSValue result;
    if (JS_IsFunction(ctx, callback)) {
        // If it's a function, call it
        JSValue global = JS_GetGlobalObject(ctx);
        result = JS_Call(ctx, callback, global, 0, nullptr);
        JS_FreeValue(ctx, global);
    } else if (JS_IsString(callback)) {
        // If it's a string, evaluate it as code
        const char* code = JS_ToCString(ctx, callback);
        if (code) {
            result = JS_Eval(ctx, code, strlen(code), "<setTimeout>", JS_EVAL_TYPE_GLOBAL);
            JS_FreeCString(ctx, code);
        } else {
            result = JS_EXCEPTION;
        }
    } else {
        result = JS_UNDEFINED;
    }
    
    // Handle any exceptions
    if (JS_IsException(result)) {
        JSValue exception = JS_GetException(ctx);
        std::string errorMsg = getDetailedJSError(ctx, exception);
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, 
            "Error in setTimeout callback for instance %d: %s", 
            instanceId, errorMsg.c_str());
        JS_FreeValue(ctx, exception);
    }
    
    // Free the result
    JS_FreeValue(ctx, result);
    
    // Free the callback and remove it from the map
    JS_FreeValue(ctx, callback);
    instance->timerCallbacks.erase(timerId);
    
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Executed timer %d for instance %d", timerId, instanceId);
}

// Function to execute a stored interval callback
extern "C" JNIEXPORT void JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeExecuteInterval(
        JNIEnv* env,
        jobject thiz,
        jint timerId,
        jint instanceId) {

    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG,
                            "Failed to execute interval %d for instance %d: Instance not found or context is null",
                            timerId, instanceId);
        return;
    }

    JSContext* ctx = instance->ctx;

    // Find the callback function for this timer ID
    auto it = instance->timerCallbacks.find(timerId);
    if (it == instance->timerCallbacks.end()) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG,
                            "Failed to execute interval %d for instance %d: Callback not found",
                            timerId, instanceId);
        return;
    }

    JSValue callback = it->second;

    // Execute the callback
    JSValue result;
    if (JS_IsFunction(ctx, callback)) {
        // If it's a function, call it
        JSValue global = JS_GetGlobalObject(ctx);
        result = JS_Call(ctx, callback, global, 0, nullptr);
        JS_FreeValue(ctx, global);
    } else if (JS_IsString(callback)) {
        // If it's a string, evaluate it as code
        const char* code = JS_ToCString(ctx, callback);
        if (code) {
            result = JS_Eval(ctx, code, strlen(code), "<setIntervalNative>", JS_EVAL_TYPE_GLOBAL);
            JS_FreeCString(ctx, code);
        } else {
            result = JS_EXCEPTION;
        }
    } else {
        result = JS_UNDEFINED;
    }

    // Handle any exceptions
    if (JS_IsException(result)) {
        JSValue exception = JS_GetException(ctx);
        std::string errorMsg = getDetailedJSError(ctx, exception);
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG,
                            "Error in setIntervalNative callback for instance %d: %s",
                            instanceId, errorMsg.c_str());
        JS_FreeValue(ctx, exception);
    }

    // Free the result
    JS_FreeValue(ctx, result);

    // Note: Unlike setTimeoutNative, we do NOT free the callback or remove it from the map
    // because setIntervalNative needs to keep the callback for repeated execution

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Executed interval %d for instance %d", timerId, instanceId);
}

// Function to clear an interval
extern "C" JNIEXPORT jboolean JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeClearInterval(
        JNIEnv* env,
        jobject thiz,
        jint timerId,
        jint instanceId) {

    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG,
                            "Failed to clear interval %d for instance %d: Instance not found or context is null",
                            timerId, instanceId);
        return JNI_FALSE;
    }

    // Check if the interval exists in the map
    auto it = instance->timerCallbacks.find(timerId);
    if (it != instance->timerCallbacks.end()) {
        // Free the callback value
        JS_FreeValue(instance->ctx, it->second);

        // Remove the interval from the map
        instance->timerCallbacks.erase(it);

        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG,
                            "Cleared interval %d for instance %d from native side", timerId, instanceId);
        return JNI_TRUE;
    }

    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG,
                        "Interval %d for instance %d not found on native side", timerId, instanceId);
    return JNI_FALSE;
}

// Native log function to call into Java/Kotlin with integer log level
static JSValue js_native_log(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv, int level) {
    if (argc < 1) {
        return JS_UNDEFINED;
    }

    // Find the engine instance for this context
    EngineInstance* instance = nullptr;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        for (const auto& pair : gEngineInstances) {
            if (pair.second->ctx == ctx) {
                instance = pair.second;
                break;
            }
        }
    }

    if (!instance || !instance->engineObj) {
        return JS_ThrowInternalError(ctx, "Engine instance not found or not initialized");
    }

    // Get JNI environment
    JNIEnv* env;
    bool needsDetach = false;
    jint jniResult = gJavaVM->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (jniResult == JNI_EDETACHED) {
        jniResult = gJavaVM->AttachCurrentThread(&env, nullptr);
        if (jniResult != JNI_OK) {
            return JS_ThrowInternalError(ctx, "Failed to attach to Java thread");
        }
        needsDetach = true;
    } else if (jniResult != JNI_OK) {
        return JS_ThrowInternalError(ctx, "Failed to get JNI environment");
    }

    // Convert all remaining arguments to strings and concatenate them
    std::string logMessage;
    for (int i = 0; i < argc; i++) {
        if (i > 0) {
            logMessage += " ";
        }

        if (JS_IsObject(argv[i])) {
            // For objects, use JSON.stringify
            JSValue global = JS_GetGlobalObject(ctx);
            JSValue jsonObj = JS_GetPropertyStr(ctx, global, "JSON");
            JSValue jsonStringify = JS_GetPropertyStr(ctx, jsonObj, "stringify");

            JSValueConst args[1];
            args[0] = argv[i];
            JSValue jsonStr = JS_Call(ctx, jsonStringify, global, 1, args);
            const char* str = JS_ToCString(ctx, jsonStr);
            if (str) {
                logMessage += str;
                JS_FreeCString(ctx, str);
            } else {
                logMessage += "[object Object]";
            }

            JS_FreeValue(ctx, jsonStr);
            JS_FreeValue(ctx, jsonStringify);
            JS_FreeValue(ctx, jsonObj);
            JS_FreeValue(ctx, global);
        } else {
            const char* str = JS_ToCString(ctx, argv[i]);
            if (str) {
                logMessage += str;
                JS_FreeCString(ctx, str);
            }
        }
    }

    // Log directly using Android logging API based on level
    switch (level) {
        case 0: // LOG
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "[JS] %s", logMessage.c_str());
            break;
        case 1: // INFO
            __android_log_print(ANDROID_LOG_INFO, LOG_TAG, "[JS] %s", logMessage.c_str());
            break;
        case 2: // WARN
            __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "[JS] %s", logMessage.c_str());
            break;
        case 3: // ERROR
            __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "[JS] %s", logMessage.c_str());
            break;
        default:
            __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "[JS] [Unknown Level %d] %s", level, logMessage.c_str());
            break;
    }

    // Detach from thread if needed
    if (needsDetach) {
        gJavaVM->DetachCurrentThread();
    }

    return JS_UNDEFINED;
}
// Register console API
static void register_console_api(JSContext *ctx) {
    JSValue global = JS_GetGlobalObject(ctx);

    JSValue console = JS_NewObject(ctx);

    // Register each console function
    JS_SetPropertyStr(ctx, console, "log",
                      JS_NewCFunctionMagic(ctx, js_native_log, "log", 1, JS_CFUNC_generic_magic, 0)); // LOG
    JS_SetPropertyStr(ctx, console, "info",
                      JS_NewCFunctionMagic(ctx, js_native_log, "info", 1, JS_CFUNC_generic_magic, 1)); // INFO
    JS_SetPropertyStr(ctx, console, "warn",
                      JS_NewCFunctionMagic(ctx, js_native_log, "warn", 1, JS_CFUNC_generic_magic, 2)); // WARN
    JS_SetPropertyStr(ctx, console, "error",
                      JS_NewCFunctionMagic(ctx, js_native_log, "error", 1, JS_CFUNC_generic_magic, 3)); // ERROR

    // Register console methods
    JS_SetPropertyStr(ctx, global, "console", console);

    // Free the global object reference
    JS_FreeValue(ctx, global);
}

// Register timer functions (setTimeout and clearTimeout)
static void register_timer_functions(JSContext *ctx) {
    JSValue global = JS_GetGlobalObject(ctx);
    
    // Register setTimeout function
    JS_SetPropertyStr(ctx, global, "setTimeout",
                      JS_NewCFunction(ctx, js_set_timeout, "setTimeout", 2));
    
    // Register clearTimeout function
    JS_SetPropertyStr(ctx, global, "clearTimeout",
                      JS_NewCFunction(ctx, js_clear_timeout, "clearTimeout", 1));

    // Register setInterval function
    JS_SetPropertyStr(ctx, global, "setInterval",
                      JS_NewCFunction(ctx, js_set_interval, "setInterval", 2));

    // Register clearInterval function
    JS_SetPropertyStr(ctx, global, "clearInterval",
                      JS_NewCFunction(ctx, js_clear_interval, "clearInterval", 1));

    // Free the global object reference
    JS_FreeValue(ctx, global);
}

// Register DiminaServiceBridge global object and methods
static void register_dimina_service_bridge(JSContext *ctx) {
    // Create the DiminaServiceBridge object
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue diminaObj = JS_NewObject(ctx);
    
    // Register methods
    JS_SetPropertyStr(ctx, diminaObj, "invoke", 
                      JS_NewCFunction(ctx, js_dimina_invoke, "invoke", 1));
    JS_SetPropertyStr(ctx, diminaObj, "publish", 
                      JS_NewCFunction(ctx, js_dimina_publish, "publish", 1));
    
    // Add DiminaServiceBridge to global object
    JS_SetPropertyStr(ctx, global, "DiminaServiceBridge", diminaObj);
    
    // Free the global object reference
    JS_FreeValue(ctx, global);
}

// Initialize QuickJS runtime and context
extern "C" JNIEXPORT jboolean JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeInitialize(
        JNIEnv* env,
        jobject thiz,
        jint instanceId) {
    
    // Check if instance already exists
    std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
    if (gEngineInstances.find(instanceId) != gEngineInstances.end()) {
        __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "Instance %d already initialized", instanceId);
        return JNI_FALSE;
    }
    
    // Create new engine instance
    auto* instance = new EngineInstance();
    
    // Store global reference to Java object
    instance->engineObj = env->NewGlobalRef(thiz);
    
    // Create QuickJS runtime
    instance->runtime = JS_NewRuntime();
    if (!instance->runtime) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "Failed to create QuickJS runtime for instance %d", instanceId);
        env->DeleteGlobalRef(instance->engineObj);
        delete instance;
        return JNI_FALSE;
    }
    
    // Create QuickJS context
    instance->ctx = JS_NewContext(instance->runtime);
    if (!instance->ctx) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, "Failed to create QuickJS context for instance %d", instanceId);
        JS_FreeRuntime(instance->runtime);
        env->DeleteGlobalRef(instance->engineObj);
        delete instance;
        return JNI_FALSE;
    }
    
    // Register DiminaServiceBridge global object
    register_dimina_service_bridge(instance->ctx);
    
    // Register console API
    register_console_api(instance->ctx);
    
    // Register timer functions
    register_timer_functions(instance->ctx);
    
    // Store pointers in Java object
    jclass cls = env->GetObjectClass(thiz);
    jfieldID runtimeField = env->GetFieldID(cls, "nativeRuntimePtr", "J");
    jfieldID contextField = env->GetFieldID(cls, "nativeContextPtr", "J");
    
    env->SetLongField(thiz, runtimeField, (jlong)instance->runtime);
    env->SetLongField(thiz, contextField, (jlong)instance->ctx);
    
    // Store instance in global map
    gEngineInstances[instanceId] = instance;
    
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "QuickJS instance %d initialized successfully", instanceId);
    return JNI_TRUE;
}

// Execute JavaScript from a file path and return JSValue
extern "C" JNIEXPORT jobject JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeEvaluateFromFile(
        JNIEnv* env,
        jobject thiz,
        jstring filePath,
        jint instanceId) {
    
    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = env->NewStringUTF("QuickJS context is null or instance not found");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        return result;
    }
    
    JSContext* ctx = instance->ctx;
    
    // Convert Java string to C string
    const char* filePathStr = env->GetStringUTFChars(filePath, nullptr);
    if (!filePathStr) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = env->NewStringUTF("Failed to get file path string");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        return result;
    }
    
    // Read file content
    std::ifstream file(filePathStr);
    if (!file.is_open()) {
        env->ReleaseStringUTFChars(filePath, filePathStr);
        std::string errorMsg = "Failed to open file: ";
        errorMsg += filePathStr;
        JSValue error = JS_NewError(ctx);
        JS_SetPropertyStr(ctx, error, "message", JS_NewString(ctx, errorMsg.c_str()));
        jobject result = createJSValueObject(env, ctx, error);
        JS_FreeValue(ctx, error);
        return result;
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string scriptContent = buffer.str();
    file.close();
    
    // Release file path string
    env->ReleaseStringUTFChars(filePath, filePathStr);
    
    if (scriptContent.empty()) {
        JSValue error = JS_NewError(ctx);
        JS_SetPropertyStr(ctx, error, "message", JS_NewString(ctx, "File is empty"));
        jobject result = createJSValueObject(env, ctx, error);
        JS_FreeValue(ctx, error);
        return result;
    }
    
    // Evaluate JavaScript
    JSValue val = JS_Eval(ctx, scriptContent.c_str(), scriptContent.length(), filePathStr, JS_EVAL_TYPE_GLOBAL);
    
    // Check if there was an exception during evaluation
    if (JS_IsException(val)) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = handleJSError(env, ctx);
        jobject errorResult = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        JS_FreeValue(ctx, val);
        return errorResult;
    }
    
    // Run the event loop to process any pending Promise jobs
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Running event loop to process pending Promise jobs from file for instance %d", instanceId);
    bool allJobsProcessed = runJavaScriptEventLoop(ctx);
    if (!allJobsProcessed) {
        __android_log_print(ANDROID_LOG_WARN, LOG_TAG, 
            "Error processing async jobs from file for instance %d", instanceId);
    } else {
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "All pending Promise jobs from file processed successfully for instance %d", instanceId);
    }
    
    // Create JSValue object from result
    jobject result = createJSValueObject(env, ctx, val);
    JS_FreeValue(ctx, val);
    
    return result;
}

// Evaluate JavaScript code and return JSValue
extern "C" JNIEXPORT jobject JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeEvaluate(
        JNIEnv* env,
        jobject thiz,
        jstring script,
        jint instanceId) {
    
    // Get the engine instance
    EngineInstance* instance = getEngineInstance(instanceId);
    if (!instance || !instance->ctx) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = env->NewStringUTF("QuickJS context is null or instance not found");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        return result;
    }
    
    JSContext* ctx = instance->ctx;
    
    // Convert Java string to C string
    const char* scriptStr = env->GetStringUTFChars(script, nullptr);
    if (!scriptStr) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = env->NewStringUTF("Failed to get script string");
        jobject result = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        return result;
    }
    
    // Evaluate JavaScript
    JSValue val = JS_Eval(ctx, scriptStr, strlen(scriptStr), "<input>", JS_EVAL_TYPE_GLOBAL);
    env->ReleaseStringUTFChars(script, scriptStr);
    
    // Check if there was an exception during evaluation
    if (JS_IsException(val)) {
        jclass jsValueClass = env->FindClass("com/didi/dimina/engine/qjs/JSValue");
        jmethodID createErrorMethod = env->GetStaticMethodID(
            jsValueClass, "createError", "(Ljava/lang/String;)Lcom/didi/dimina/engine/qjs/JSValue;");
        jstring errorMsg = handleJSError(env, ctx);
        jobject errorResult = env->CallStaticObjectMethod(jsValueClass, createErrorMethod, errorMsg);
        env->DeleteLocalRef(errorMsg);
        JS_FreeValue(ctx, val);
        return errorResult;
    }
    
    // Run the event loop to process any pending Promise jobs
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "Running event loop to process pending Promise jobs for instance %d", instanceId);
    bool allJobsProcessed = runJavaScriptEventLoop(ctx);
    if (!allJobsProcessed) {
        __android_log_print(ANDROID_LOG_WARN, LOG_TAG, 
            "Error processing async jobs for instance %d", instanceId);
    } else {
        __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "All pending Promise jobs processed successfully for instance %d", instanceId);
    }
    
    // Convert result to JSValue object
    jobject result = createJSValueObject(env, ctx, val);
    JS_FreeValue(ctx, val);
    
    return result;
}

// Destroy QuickJS runtime and context
extern "C" JNIEXPORT void JNICALL
Java_com_didi_dimina_engine_qjs_QuickJSEngine_nativeDestroy(
        JNIEnv* env,
        jobject thiz,
        jint instanceId) {
    
    // Get the engine instance
    EngineInstance* instance = nullptr;
    {
        std::lock_guard<std::mutex> lock(gEngineInstancesMutex);
        auto it = gEngineInstances.find(instanceId);
        if (it == gEngineInstances.end()) {
            __android_log_print(ANDROID_LOG_WARN, LOG_TAG, "Instance %d not found in nativeDestroy", instanceId);
            return;
        }
        instance = it->second;
        // Remove from map immediately to prevent double-free issues
        gEngineInstances.erase(it);
    }
    
    // Set fields to 0 in Java object
    jclass cls = env->GetObjectClass(thiz);
    jfieldID runtimeField = env->GetFieldID(cls, "nativeRuntimePtr", "J");
    jfieldID contextField = env->GetFieldID(cls, "nativeContextPtr", "J");
    env->SetLongField(thiz, contextField, 0L);
    env->SetLongField(thiz, runtimeField, 0L);
    
    // Free context and runtime in the correct order
    if (instance->ctx && instance->runtime) {
        // Run garbage collection before freeing the context to clean up any lingering objects
        JS_RunGC(instance->runtime);
        
        // Clean up any remaining timer callbacks
        for (auto& pair : instance->timerCallbacks) {
            JS_FreeValue(instance->ctx, pair.second);
        }
        instance->timerCallbacks.clear();
        
        // Free the context first
        JS_FreeContext(instance->ctx);
        instance->ctx = nullptr;
        
        // Run garbage collection one more time before freeing the runtime
        JS_RunGC(instance->runtime);
        
        // Free the runtime last
        JS_FreeRuntime(instance->runtime);
        instance->runtime = nullptr;
    } else {
        // Handle partial initialization cases
        if (instance->ctx) {
            JS_FreeContext(instance->ctx);
        }
        
        if (instance->runtime) {
            JS_FreeRuntime(instance->runtime);
        }
    }
    
    // Release global reference to Java object
    if (instance->engineObj != nullptr) {
        env->DeleteGlobalRef(instance->engineObj);
        instance->engineObj = nullptr;
    }
    
    // Delete the instance
    delete instance;
    
    __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, "QuickJS instance %d destroyed successfully", instanceId);
}