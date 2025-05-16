package com.didi.dimina.api.device

import android.app.Activity
import android.content.Context
import android.view.inputmethod.InputMethodManager
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Keyboard API
 * Author: Doslin
 */
class KeyboardApi : BaseApiHandler() {
    private companion object {
        const val HIDE_KEYBOARD = "hideKeyboard"
        const val ADJUST_POSITION = "adjustPosition"
    }
    
    override val apiNames = setOf(HIDE_KEYBOARD, ADJUST_POSITION)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            HIDE_KEYBOARD -> {
                AsyncResult(JSONObject().apply {
                    val success = hideSoftKeyboard(activity)
                    put("errMsg", "$HIDE_KEYBOARD:${if (success) "ok" else "fail"}")
                })
            }

            ADJUST_POSITION -> {
                val bottom = params.optDouble("bottom", 0.0)
                if (bottom > 0) {
                    activity.adjustViewPosition(bottom)
                }
                NoneResult()
            }

            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun hideSoftKeyboard(currentActivity: Activity): Boolean {
        return try {
            // 获取 InputMethodManager
            val inputMethodManager =
                currentActivity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

            // 获取当前焦点视图
            val currentFocus = currentActivity.currentFocus
            if (currentFocus != null) {
                // 隐藏软键盘
                inputMethodManager.hideSoftInputFromWindow(currentFocus.windowToken, 0)
                true
            } else {
                // 没有焦点视图，尝试隐藏整个 Activity 的键盘
                currentActivity.window.decorView.rootView?.let {
                    inputMethodManager.hideSoftInputFromWindow(it.windowToken, 0)
                    true
                } == true
            }
        } catch (_: Exception) {
            // 处理可能的异常
            false
        }
    }
}