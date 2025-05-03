package com.didi.dimina.common

import android.util.Log
import com.didi.dimina.common.LogUtils.json

/**
 * 日志工具类
 * Author: Doslin
 */
object LogUtils {
    // 默认 TAG
    private const val DEFAULT_TAG = "Dimina"

    // 是否启用日志
    private var isDebug: Boolean = false

    /**
     * 初始化日志工具
     * @param debug 是否启用调试日志
     */
    fun initialize(debug: Boolean) {
        isDebug = debug
    }

    /**
     * Verbose 级别日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     */
    fun v(tag: String = DEFAULT_TAG, message: String) {
        if (isDebug) {
            Log.v(tag, message)
        }
    }

    /**
     * Debug 级别日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     */
    fun d(tag: String = DEFAULT_TAG, message: String) {
        if (isDebug) {
            Log.d(tag, message)
        }
    }

    /**
     * Info 级别日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     */
    fun i(tag: String = DEFAULT_TAG, message: String) {
        if (isDebug) {
            Log.i(tag, message)
        }
    }

    /**
     * Warning 级别日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     */
    fun w(tag: String = DEFAULT_TAG, message: String) {
        if (isDebug) {
            Log.w(tag, message)
        }
    }

    /**
     * Error 级别日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     * @param throwable 可选的异常信息
     */
    fun e(tag: String = DEFAULT_TAG, message: String, throwable: Throwable? = null) {
        if (isDebug) {
            if (throwable != null) {
                Log.e(tag, message, throwable)
            } else {
                Log.e(tag, message)
            }
        }
    }

    /**
     * 打印带有调用栈信息的日志
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param message 日志消息
     */
    fun trace(tag: String = DEFAULT_TAG, message: String) {
        if (isDebug) {
            val stackTrace = Thread.currentThread().stackTrace
            val caller = stackTrace.getOrNull(3) // 获取调用者的栈帧
            val callerInfo = caller?.let {
                "${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})"
            } ?: "Unknown"
            Log.d(tag, "$callerInfo: $message")
        }
    }

    /**
     * 格式化打印 JSON 字符串
     * @param tag 日志标签，默认为 DEFAULT_TAG
     * @param json JSON 字符串
     */
    fun json(tag: String = DEFAULT_TAG, json: String) {
        if (isDebug) {
            try {
                val formattedJson = if (json.trim().startsWith("{")) {
                    // 简单的 JSON 格式化
                    json.split(",").joinToString(",\n    ") { it.trim() }
                        .replace("{", "{\n    ")
                        .replace("}", "\n}")
                } else {
                    json
                }
                Log.d(tag, formattedJson)
            } catch (e: Exception) {
                Log.e(tag, "Failed to format JSON: $json", e)
            }
        }
    }
}