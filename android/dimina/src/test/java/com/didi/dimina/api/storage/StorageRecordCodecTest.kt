package com.didi.dimina.api.storage

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StorageRecordCodecTest {
    @Test
    fun `round trips primitive and JSON value types without metadata keys`() {
        val values = listOf<Any>(
            7,
            "true",
            true,
            1.5f,
            9L,
            2.5,
            JSONArray().put("a"),
            JSONObject().put("x", 1),
        )

        values.forEach { value ->
            val record = StorageRecordCodec.decode(StorageRecordCodec.encodeValue(value))
            assertFalse(record?.deleted ?: true)
            assertEquals(value.toString(), record?.value.toString())
        }
    }

    @Test
    fun `user keys ending with type remain ordinary data keys`() {
        assertEquals("data:token_type", StorageRecordCodec.dataKey("token_type"))
        assertNotEquals(StorageRecordCodec.dataKey("token"), StorageRecordCodec.dataKey("token_type"))
    }

    @Test
    fun `tombstone suppresses legacy fallback state`() {
        val record = StorageRecordCodec.decode(StorageRecordCodec.encodeDeleted())
        assertTrue(record?.deleted == true)
    }

    @Test
    fun `storage ids remain distinct for ambiguous app id spellings`() {
        assertNotEquals(StorageRecordCodec.storageId("a_b"), StorageRecordCodec.storageId("a"))
    }
}
