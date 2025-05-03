package com.didi.dimina.common

/**
 * 版本管理类
 * Author: Doslin
 */
object VersionUtils {
    private const val KEY_JS_SDK_VERSION = "dimina_sdk_ver"
    private const val KEY_JS_APP_VERSION = "dimina_app_ver"

    fun getJSVersion(): Int {
        return StoreUtils.getInt(KEY_JS_SDK_VERSION, 0)
    }

    fun setJSVersion(version: Int) {
        StoreUtils.putInt(KEY_JS_SDK_VERSION, version)
    }

    fun getAppVersion(appId: String): Int {
        return StoreUtils.getInt("${KEY_JS_APP_VERSION}_$appId", 0)
    }

    fun setAppVersion(appId:String, version: Int) {
        StoreUtils.putInt("${KEY_JS_APP_VERSION}_$appId", version)
    }
}