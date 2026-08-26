package com.didi.dimina.core

import java.io.File
import java.io.IOException

/** Filesystem-only part of uninstalling a mini-program package. */
internal object MiniProgramPackageCleaner {
    fun uninstall(
        filesDir: File,
        cacheDir: File,
        appId: String,
        clearUserData: Boolean,
    ) {
        val jsAppRoot = File(filesDir, "jsapp")
        deleteRecursivelyIfExists(confinedChild(jsAppRoot, appId))
        deleteRecursivelyIfExists(confinedChild(File(jsAppRoot, ".pending"), appId))

        val updateDir = File(cacheDir, "dimina-updates")
        updateDir.listFiles()?.forEach { file ->
            val version = file.name
                .takeIf { it.startsWith("$appId-") && it.endsWith(".zip") }
                ?.removePrefix("$appId-")
                ?.removeSuffix(".zip")
                ?.toIntOrNull()
            if (file.isFile && version != null) {
                deleteRecursivelyIfExists(file)
            }
        }

        // Temporary files never survive an uninstall. Persistent files and
        // Storage API data are retained unless the host explicitly clears them.
        deleteRecursivelyIfExists(
            confinedChild(File(cacheDir, "dimina-file-system"), appId)
        )
        if (clearUserData) {
            deleteRecursivelyIfExists(
                confinedChild(File(filesDir, "dimina-file-system"), appId)
            )
        }
    }

    private fun confinedChild(root: File, name: String): File {
        require(name.isNotBlank()) { "appId is required" }
        require(
            name != "." && name != ".." && name != ".pending" &&
                !name.contains('/') && !name.contains('\\') && !name.contains('\u0000')
        ) { "invalid appId" }
        val canonicalRoot = root.canonicalFile
        val child = File(canonicalRoot, name).canonicalFile
        if (child.parentFile != canonicalRoot) {
            throw IOException("invalid appId path: $name")
        }
        return child
    }

    private fun deleteRecursivelyIfExists(file: File) {
        if (file.exists() && !file.deleteRecursively()) {
            throw IOException("failed to delete ${file.path}")
        }
    }
}
