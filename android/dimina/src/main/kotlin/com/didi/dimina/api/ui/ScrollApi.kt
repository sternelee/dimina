package com.didi.dimina.api.ui

import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Author: Doslin
 */
class ScrollApi : BaseApiHandler() {
    private companion object {
        const val PAGE_SCROLL_TO = "pageScrollTo"
    }

    override val apiNames = setOf(PAGE_SCROLL_TO)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            PAGE_SCROLL_TO -> {
                val scrollTop = params.optInt("scrollTop")
                val duration = params.optInt("duration", 300)

                activity.pageScrollTo(scrollTop, duration)
                AsyncResult(JSONObject().apply {
                    put("errMsg", "$PAGE_SCROLL_TO:ok")
                })
            }

            else -> super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }
}