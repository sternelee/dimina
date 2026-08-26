package com.didi.dimina.core

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

class MiniProgramPackageCleanerTest {
    @get:Rule
    val temporaryFolder = TemporaryFolder()

    @Test
    fun `uninstall removes package and temporary data but preserves persistent user files`() {
        val filesDir = temporaryFolder.newFolder("files")
        val cacheDir = temporaryFolder.newFolder("cache")
        val appId = "wx-test"
        val active = file(filesDir, "jsapp/$appId/main/logic.js")
        val pending = file(filesDir, "jsapp/.pending/$appId/main/logic.js")
        val user = file(filesDir, "dimina-file-system/$appId/usr/saved.txt")
        val temp = file(cacheDir, "dimina-file-system/$appId/tmp/image.jpg")
        val update = file(cacheDir, "dimina-updates/$appId-2.zip")
        val anotherAppUpdate = file(cacheDir, "dimina-updates/$appId-other-2.zip")

        MiniProgramPackageCleaner.uninstall(filesDir, cacheDir, appId, clearUserData = false)

        assertFalse(active.exists())
        assertFalse(pending.exists())
        assertFalse(temp.exists())
        assertFalse(update.exists())
        assertTrue(user.exists())
        assertTrue(anotherAppUpdate.exists())
    }

    @Test
    fun `clearUserData removes persistent files`() {
        val filesDir = temporaryFolder.newFolder("files")
        val cacheDir = temporaryFolder.newFolder("cache")
        val appId = "wx-test"
        val user = file(filesDir, "dimina-file-system/$appId/usr/saved.txt")

        MiniProgramPackageCleaner.uninstall(filesDir, cacheDir, appId, clearUserData = true)

        assertFalse(user.exists())
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects appId path traversal`() {
        MiniProgramPackageCleaner.uninstall(
            temporaryFolder.newFolder("files"),
            temporaryFolder.newFolder("cache"),
            "../outside",
            clearUserData = true,
        )
    }

    private fun file(root: File, relativePath: String): File =
        File(root, relativePath).apply {
            parentFile?.mkdirs()
            writeText("test")
        }
}
