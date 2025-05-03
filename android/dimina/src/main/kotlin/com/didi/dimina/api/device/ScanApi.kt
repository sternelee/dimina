package com.didi.dimina.api.device

import com.didi.dimina.api.APIResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Scan API
 * Author: Doslin
 */
class ScanApi : BaseApiHandler() {
    private companion object {
        const val SCAN_CODE = "scanCode"
    }

    override val apiNames = setOf(SCAN_CODE)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when(apiName) {
            SCAN_CODE -> {
                NoneResult()
            }
            else -> super.handleAction(activity, appId, apiName, params, responseCallback)
        }

    }
}