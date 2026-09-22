package com.didi.dimina.core

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AppVisibilityLedgerTest {

    private fun entry(id: String) = JSONObject().apply {
        put("pagePath", "pages/index/index")
        put("query", JSONObject().put("id", id))
        put("scene", 1001)
    }

    @Test
    fun `A then B entry keeps B through repeated task switcher resumes`() {
        val ledger = AppVisibilityLedger()
        val first = entry("A")
        assertNull(ledger.onShow(first, newEntry = false))
        assertNull(ledger.onServiceReady())
        ledger.onHide()
        val second = entry("B")
        assertEquals("B", ledger.onShow(second)!!.options!!.getJSONObject("query").getString("id"))
        second.getJSONObject("query").put("id", "caller mutation")
        repeat(3) {
            ledger.onHide()
            val resumed = ledger.onShow(first, newEntry = false)!!.options!!
            assertEquals("B", resumed.getJSONObject("query").getString("id"))
            resumed.getJSONObject("query").put("id", "delivery mutation")
            assertNull(ledger.onShow(first, newEntry = false))
        }
    }

    @Test
    fun `empty new entry replaces B and reset discards retained entry`() {
        val ledger = AppVisibilityLedger()
        ledger.onServiceReady()
        ledger.onShow(entry("B"))
        val empty = entry("unused").put("query", JSONObject())
        ledger.onShow(empty)
        ledger.onHide()
        assertEquals(0, ledger.onShow(entry("A"), newEntry = false)!!.options!!.getJSONObject("query").length())
        ledger.reset()
        assertNull(ledger.onShow(entry("C"), newEntry = false))
        assertNull(ledger.onServiceReady())
        ledger.onHide()
        assertEquals("C", ledger.onShow(entry("C"), newEntry = false)!!.options!!.getJSONObject("query").getString("id"))
    }

    @Test
    fun `ordinary foreground refreshes current page without duplicating cold show`() {
        val ledger = AppVisibilityLedger()
        val current = JSONObject("""{"pagePath":"pages/current","query":{"id":"3"}}""")
        assertNull(ledger.onShow(current, newEntry = false))
        assertNull(ledger.onServiceReady())
        assertNull(ledger.onShow(current, newEntry = false))
        ledger.onHide()
        val delivery = ledger.onShow(current, newEntry = false)!!
        assertEquals("3", delivery.options!!.getJSONObject("query").getString("id"))
        assertNull(ledger.onShow(current, newEntry = false))
    }

    @Test
    fun `ordinary show cannot replace a new entry waiting for service readiness`() {
        val ledger = AppVisibilityLedger()
        val entry = JSONObject("""{"query":{"id":"2"}}""")
        assertNull(ledger.onShow(entry))
        assertNull(ledger.onShow(JSONObject("""{"query":{"id":"1"}}"""), newEntry = false))
        assertEquals("2", ledger.onServiceReady()!!.options!!.getJSONObject("query").getString("id"))
        assertNull(ledger.onShow())
    }

    @Test
    fun `cold start uses the App show emitted while the service creates the app`() {
        val ledger = AppVisibilityLedger()

        assertNull(ledger.onShow())
        assertNull(ledger.onServiceReady())
    }

    @Test
    fun `hide before service readiness is delivered after the implicit initial show`() {
        val ledger = AppVisibilityLedger()

        assertNull(ledger.onShow())
        assertNull(ledger.onHide())
        val delivery = ledger.onServiceReady()!!

        assertFalse(delivery.visible)
        assertNull(delivery.options)
    }

    @Test
    fun `return show is retained with its options and duplicate directions are suppressed`() {
        val ledger = AppVisibilityLedger()
        ledger.onServiceReady()

        assertFalse(ledger.onHide()!!.visible)
        assertNull(ledger.onHide())

        val delivery = ledger.onShow(JSONObject("""{"scene":1038}"""))!!
        assertTrue(delivery.visible)
        assertEquals(1038, delivery.options!!.getInt("scene"))
        assertNull(ledger.onShow())
    }

    @Test
    fun `reset removes readiness and pending visibility from the old runtime`() {
        val ledger = AppVisibilityLedger()
        ledger.onServiceReady()
        ledger.onHide()
        ledger.reset()

        assertNull(ledger.onShow())
        assertNull(ledger.onServiceReady())
    }
}
