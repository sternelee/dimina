package com.didi.dimina.common

import android.content.Context
import android.content.pm.PackageManager

/**
 * 版本管理类
 * Author: Doslin
 */
object VersionUtils {
    private const val KEY_JS_SDK_VERSION = "dimina_sdk_ver"
    private const val KEY_JS_APP_VERSION = "dimina_app_ver"
    private const val KEY_APP_VERSION = "dimina_host_app_ver"

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

    /**
     * 检查当前应用是否已更新或是第一次安装
     * @return 如果是第一次安装或应用版本已更新，返回 true；否则返回 false
     */
    fun isAppVersionUpdated(context: Context) : Boolean {
        // 获取上次记录的应用版本号
        val savedVersionCode = StoreUtils.getLong(KEY_APP_VERSION, 0L)
        // 获取当前应用版本号
        val currentVersionCode = getCurrentAppVersionCode(context)
        // 检查是否是第一次安装
        if (savedVersionCode == 0L) {
            // 第一次安装，设置标志并返回 true
            StoreUtils.putLong(KEY_APP_VERSION, currentVersionCode)
            return true
        }

        // 如果当前版本号大于保存的版本号，说明应用已经更新
        val isUpdated = currentVersionCode > savedVersionCode

        // 更新保存的版本号
        if (isUpdated) {
            StoreUtils.putLong(KEY_APP_VERSION, currentVersionCode)
        }
        return isUpdated
    }
    
    /**
     * 获取当前应用的版本号
     * @return 当前应用的版本号
     */
    private fun getCurrentAppVersionCode(context: Context): Long {
        return try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageInfo.longVersionCode // API 28+ 使用 longVersionCode
            } else {
                @Suppress("DEPRECATION")
                packageInfo.versionCode.toLong() // API 28 以下使用 versionCode
            }
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
            0L // 返回默认值或处理异常
        }
    }
}