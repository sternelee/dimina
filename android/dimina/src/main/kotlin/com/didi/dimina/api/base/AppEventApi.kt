package com.didi.dimina.api.base

import com.didi.dimina.api.APIResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Author: Doslin
 */
class AppEventApi : BaseApiHandler() {
    private companion object {
        const val ON_ERROR = "onError"
        const val OFF_ERROR = "offError"
        const val ON_APP_SHOW = "onAppShow"
        const val ON_APP_HIDE = "onAppHide"
        const val OFF_APP_SHOW = "offAppShow"
        const val OFF_APP_HIDE = "offAppHide"
    }

    override val apiNames =
        setOf(ON_ERROR, OFF_ERROR, ON_APP_SHOW, ON_APP_HIDE, OFF_APP_SHOW, OFF_APP_HIDE)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        //TODO Not yet implemented
        return NoneResult()
    }
}