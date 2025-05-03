package com.didi.dimina.api.ui

import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.common.Utils
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Author: Doslin
 */
class MenuApi : BaseApiHandler() {
    private companion object {
        const val GET_MENU_BUTTON_BOUNDING_CLIENT_RECT = "getMenuButtonBoundingClientRect"
    }

    override val apiNames = setOf(GET_MENU_BUTTON_BOUNDING_CLIENT_RECT)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            GET_MENU_BUTTON_BOUNDING_CLIENT_RECT -> {
                val width = 87;
                val height = 32;
                val top = Utils.getStatusBarHeight(activity);
                val right = activity.window.decorView.width - 10;
                val left = right - width;
                val bottom = top + height;

                AsyncResult(JSONObject().apply {
                    put("width", width)
                    put("height", height)
                    put("top", top)
                    put("right", right)
                    put("bottom", bottom)
                    put("left", left)
                })
            }

            else -> super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }
}