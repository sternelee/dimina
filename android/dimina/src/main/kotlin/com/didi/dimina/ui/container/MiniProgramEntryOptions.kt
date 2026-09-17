package com.didi.dimina.ui.container

import com.didi.dimina.bean.MiniProgram
import com.didi.dimina.common.Utils
import org.json.JSONObject

/** A new host entry may carry a path even when the runtime and page stack are retained. */
internal object MiniProgramEntryOptions {
    fun from(program: MiniProgram, referrerInfo: JSONObject?): JSONObject = JSONObject().apply {
        put("scene", program.scene)
        put("referrerInfo", referrerInfo ?: JSONObject())
        program.path?.takeIf { it.isNotBlank() }?.let { path ->
            val pathInfo = Utils.queryPath(path)
            put("pagePath", pathInfo.pagePath)
            // An explicit path without query must clear the previous entry's query.
            put("query", pathInfo.query ?: JSONObject())
        }
        // No explicit path: dispatchMiniProgramShow fills in the retained current page.
    }
}
