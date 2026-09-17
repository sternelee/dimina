package com.didi.dimina.ui.container

import com.didi.dimina.bean.MiniProgram
import com.didi.dimina.core.AppVisibilityLedger
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class MiniProgramEntryOptionsTest {
    private fun entry(path: String?) = MiniProgramEntryOptions.from(
        MiniProgram(appId = "query-bug", path = path), null,
    )

    @Test fun `reentry delivers the new query after hiding the runtime`() {
        val ledger = AppVisibilityLedger()
        ledger.onServiceReady()
        ledger.onShow(entry("pages/index/index?id=1&from=first"))
        ledger.onHide()
        val options = ledger.onShow(entry("pages/index/index?id=2&from=second"))!!.options!!
        assertEquals("pages/index/index", options.getString("pagePath"))
        assertEquals("2", options.getJSONObject("query").getString("id"))
        assertEquals("second", options.getJSONObject("query").getString("from"))
        assertNull(ledger.onShow())
    }

    @Test fun `visible runtime accepts new entry and readiness keeps the latest pending query`() {
        val ledger = AppVisibilityLedger()
        assertNull(ledger.onShow(entry("pages/index/index?id=1")))
        assertNull(ledger.onShow(entry("pages/index/index?id=2")))
        assertEquals("2", ledger.onServiceReady()!!.options!!.getJSONObject("query").getString("id"))
        assertEquals("3", ledger.onShow(entry("pages/index/index?id=3"))!!.options!!.getJSONObject("query").getString("id"))
        assertNull(ledger.onShow())
    }

    @Test fun `explicit path without query clears old parameters`() {
        val options = entry("/pages/other/index")
        assertEquals("pages/other/index", options.getString("pagePath"))
        assertEquals(0, options.getJSONObject("query").length())
    }

    @Test fun `missing path allows the current retained page fallback`() {
        for (path in listOf(null, "", "  ")) {
            val options = entry(path)
            assertFalse(options.has("pagePath"))
            assertFalse(options.has("query"))
            assertEquals(1001, options.getInt("scene"))
            assertEquals(0, options.getJSONObject("referrerInfo").length())
        }
    }

    @Test fun `entry preserves its scene and referrer`() {
        val referrer = JSONObject("""{"appId":"source","extraData":{"token":"new"}}""")
        val options = MiniProgramEntryOptions.from(
            MiniProgram(appId = "query-bug", path = "pages/index/index?id=2", scene = 1037), referrer,
        )
        assertEquals(1037, options.getInt("scene"))
        assertEquals(referrer.toString(), options.getJSONObject("referrerInfo").toString())
    }
}
