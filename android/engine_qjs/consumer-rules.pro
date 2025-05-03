# 保留 QuickJSEngine 类及其所有方法
-keep class com.didi.dimina.engine.qjs.QuickJSEngine {
    *;
}

# 保留 JSValue 类及其所有内部类和方法
-keep class com.didi.dimina.engine.qjs.JSValue {
    *;
}
-keep class com.didi.dimina.engine.qjs.JSValue$* {
    *;
}

# 保留所有与 JNI 相关的本地方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留所有被 JNI 调用的方法
-keepclassmembers class com.didi.dimina.engine.qjs.QuickJSEngine {
    public void scheduleTimer(int, int);
    public void scheduleInterval(int, int);
    public boolean clearTimer(int);
    public boolean clearInterval(int);
    public com.didi.dimina.engine.qjs.JSValue invokeFromJS(org.json.JSONObject);
    public void publishFromJS(java.lang.String, org.json.JSONObject);
}

# 保留 JSON 相关类
-keep class org.json.** { *; }
