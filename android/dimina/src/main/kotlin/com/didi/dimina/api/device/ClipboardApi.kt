package com.didi.dimina.api.device

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Clipboard API
 * Author: Doslin
 */
class ClipboardApi : BaseApiHandler() {
    private companion object {
        const val SET_CLIPBOARD_DATA = "setClipboardData"
        const val GET_CLIPBOARD_DATA = "getClipboardData"
    }

    override val apiNames = setOf(SET_CLIPBOARD_DATA, GET_CLIPBOARD_DATA)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            SET_CLIPBOARD_DATA -> {
                val data = params.optString("data")
                AsyncResult(JSONObject().apply {
                    // 获取 ClipboardManager
                    val clipboardManager =
                        activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val success = setClipboardContent(clipboardManager, data)
                    put("errMsg", "$SET_CLIPBOARD_DATA:${if (success) "ok" else "fail"}")
                })
            }

            GET_CLIPBOARD_DATA -> {
                AsyncResult(JSONObject().apply {
                    // 获取剪贴板内容
                    val clipboardManager =
                        activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clipboardData = getClipboardContent(clipboardManager)
                    put("data", clipboardData)
                    put("errMsg", "$GET_CLIPBOARD_DATA:ok")
                })
            }

            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun setClipboardContent(clipboardManager: ClipboardManager, data: String): Boolean {
        return try {
            // 创建 ClipData 对象
            val clip = ClipData.newPlainText("text", data)
            // 设置到剪贴板
            clipboardManager.setPrimaryClip(clip)
            true // 成功
        } catch (e: Exception) {
            // 处理可能的异常（如权限问题或系统限制）
            false // 失败
        }
    }

    private fun getClipboardContent(clipboardManager: ClipboardManager): String? {
        // 检查剪贴板是否有内容
        if (!clipboardManager.hasPrimaryClip()) {
            return null // 剪贴板为空
        }

        val clip = clipboardManager.primaryClip
        if (clip != null && clip.itemCount > 0) {
            // 获取剪贴板的第一项内容
            val item = clip.getItemAt(0)
            return item.text?.toString() // 返回文本内容，如果是其他类型（如图片）则返回 null
        }

        return null
    }

}