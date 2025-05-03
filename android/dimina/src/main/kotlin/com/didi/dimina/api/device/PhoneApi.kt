package com.didi.dimina.api.device

import android.content.Intent
import androidx.core.net.toUri
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Phone API
 * Author: Doslin
 */
class PhoneApi : BaseApiHandler() {
    private companion object {
        const val MAKE_PHONE_CALL = "makePhoneCall"
    }

    override val apiNames = setOf(MAKE_PHONE_CALL)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            MAKE_PHONE_CALL -> {
                val phoneNumber = params.optString("phoneNumber")
                if (phoneNumber.isEmpty()) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$MAKE_PHONE_CALL:fail phoneNumber is required")
                    })
                }
                val intent = Intent(Intent.ACTION_DIAL).apply {
                    data = "tel:$phoneNumber".toUri()
                }
                activity.startActivity(intent)
                return AsyncResult(JSONObject().apply {
                    put("errMsg", "$MAKE_PHONE_CALL:ok")
                })
            }

            else -> super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

}