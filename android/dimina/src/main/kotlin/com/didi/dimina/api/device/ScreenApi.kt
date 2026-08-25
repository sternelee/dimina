package com.didi.dimina.api.device

import android.view.WindowManager
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

class ScreenApi : BaseApiHandler() {
    private companion object {
        const val SET_KEEP_SCREEN_ON = "setKeepScreenOn"
    }

    override val apiNames = setOf(SET_KEEP_SCREEN_ON)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        if (!params.has("keepScreenOn")) {
            return AsyncResult(JSONObject().apply {
                put("errMsg", "$SET_KEEP_SCREEN_ON:fail invalid keepScreenOn")
            }, completeCarriesResult = true)
        }
        if (params.optBoolean("keepScreenOn")) {
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        return AsyncResult(JSONObject().apply {
            put("errMsg", "$SET_KEEP_SCREEN_ON:ok")
        }, completeCarriesResult = true)
    }
}
