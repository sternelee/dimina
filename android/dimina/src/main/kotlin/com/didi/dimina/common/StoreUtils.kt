package com.didi.dimina.common

import android.content.Context
import com.tencent.mmkv.MMKV
import java.io.File

/**
 * Author: Doslin
 */
object StoreUtils {
    private lateinit var mmkv: MMKV

    // 是否已初始化标志
    private var isInitialized = false

    /**
     * 初始化 MMKV
     * @param context 上下文
     * @param rootDir 可选的根目录，默认使用 filesDir
     */
    fun initialize(context: Context, rootDir: String? = null) {
        if (!isInitialized) {
            synchronized(this) {
                if (!isInitialized) {
                    // 设置根目录，默认使用 filesDir
                    val dir = rootDir ?: (context.filesDir.absolutePath + File.separator + "jsstore")
                    MMKV.initialize(context, dir)
                    mmkv = MMKV.defaultMMKV()
                    isInitialized = true
                }
            }
        }
    }

    /**
     * 确保已初始化，未初始化时抛出异常
     */
    private fun ensureInitialized() {
        if (!isInitialized) {
            throw IllegalStateException("StoreUtils not initialized. Please call initialize() first.")
        }
    }

    // 存储方法
    fun putString(key: String, value: String) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    fun putInt(key: String, value: Int) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    fun putLong(key: String, value: Long) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    fun putFloat(key: String, value: Float) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    fun putBoolean(key: String, value: Boolean) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    fun putByteArray(key: String, value: ByteArray) {
        ensureInitialized()
        mmkv.encode(key, value)
    }

    // 获取方法
    fun getString(key: String, defaultValue: String = ""): String {
        ensureInitialized()
        return mmkv.decodeString(key, defaultValue) ?: defaultValue
    }

    fun getInt(key: String, defaultValue: Int = 0): Int {
        ensureInitialized()
        return mmkv.decodeInt(key, defaultValue)
    }

    fun getLong(key: String, defaultValue: Long = 0L): Long {
        ensureInitialized()
        return mmkv.decodeLong(key, defaultValue)
    }

    fun getFloat(key: String, defaultValue: Float = 0f): Float {
        ensureInitialized()
        return mmkv.decodeFloat(key, defaultValue)
    }

    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean {
        ensureInitialized()
        return mmkv.decodeBool(key, defaultValue)
    }

    fun getByteArray(key: String, defaultValue: ByteArray? = null): ByteArray? {
        ensureInitialized()
        return mmkv.decodeBytes(key, defaultValue)
    }

    // 其他实用方法
    /**
     * 检查是否包含某个 key
     */
    fun containsKey(key: String): Boolean {
        ensureInitialized()
        return mmkv.containsKey(key)
    }

    /**
     * 删除指定 key
     */
    fun remove(key: String) {
        ensureInitialized()
        mmkv.removeValueForKey(key)
    }

    /**
     * 清除所有数据
     */
    fun clearAll() {
        ensureInitialized()
        mmkv.clearAll()
    }

    /**
     * 获取所有键
     */
    fun getAllKeys(): Array<String> {
        ensureInitialized()
        return mmkv.allKeys() ?: emptyArray()
    }
}