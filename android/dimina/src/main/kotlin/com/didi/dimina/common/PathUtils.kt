package com.didi.dimina.common

import android.content.Context
import android.net.Uri
import java.io.File

/**
 * Author: Doslin
 */
object PathUtils {
    const val FILE_PROTOCOL = "file://"
    private const val VIRTUAL_DOMAIN_URL = "difile://"

    fun isLegalPath(path: String): Boolean {
        return path.startsWith(VIRTUAL_DOMAIN_URL)
    }

    fun pathToReal(context: Context, path: String): String {
        return if (isLegalPath(path)) {
            File(context.cacheDir, path.substring(VIRTUAL_DOMAIN_URL.length)).absolutePath
        } else {
            path
        }
    }

    fun pathToVirtual(file: File): String {
        return "$VIRTUAL_DOMAIN_URL${file.name}"
    }

    fun uriToTempFile(context: Context, uri: Uri): String? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val file = File.createTempFile("IMG_${System.currentTimeMillis()}", ".jpg", context.cacheDir)
            file.outputStream().use { output ->
                inputStream.copyTo(output)
            }
            pathToVirtual(file)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}