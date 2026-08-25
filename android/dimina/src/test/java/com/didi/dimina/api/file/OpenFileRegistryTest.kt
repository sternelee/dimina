package com.didi.dimina.api.file

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.io.File
import java.io.RandomAccessFile

class OpenFileRegistryTest {
    @Test
    fun `isolates descriptors by app and closes them with the owner lifecycle`() {
        val registry = OpenFileRegistry()
        val file = File.createTempFile("dimina-open-file", ".tmp")
        val handle = RandomAccessFile(file, "rw")
        try {
            val fd = registry.add("owner-app", file, handle)

            assertThrows(IllegalArgumentException::class.java) {
                registry.get("other-app", fd)
            }
            registry.closeOwner("owner-app")

            assertEquals(0, registry.size())
            assertThrows(Exception::class.java) { handle.write(1) }
        } finally {
            runCatching { handle.close() }
            file.delete()
        }
    }
}
