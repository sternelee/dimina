package com.didi.dimina.api

import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Test

class ApiHandlerContractTest {
    @Test
    fun `async results carry the same payload into complete by default`() {
        val result = AsyncResult(JSONObject().put("errMsg", "example:ok"))

        assertTrue(result.completeCarriesResult)
    }
}
