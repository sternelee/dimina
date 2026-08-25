package com.didi.dimina.common

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.net.URI

object MediaFileUtils {
    data class ResolvedFile(val file: File, val publicPath: String)

    private val httpClient = OkHttpClient()

    suspend fun resolve(context: Context, appId: String, source: String): ResolvedFile =
        withContext(Dispatchers.IO) {
            if (PathUtils.isLegalPath(source)) {
                val file = File(PathUtils.pathToReal(context, source, appId))
                require(file.isFile) { "file does not exist" }
                return@withContext ResolvedFile(file, source)
            }

            val uri = runCatching { URI(source) }.getOrNull()
            val isHttp = uri?.scheme.equals("http", ignoreCase = true) ||
                uri?.scheme.equals("https", ignoreCase = true)
            if (!isHttp || uri?.host.equals(PathUtils.WEBVIEW_ASSET_DOMAIN, ignoreCase = true)) {
                val relativePath = if (uri?.host.equals(PathUtils.WEBVIEW_ASSET_DOMAIN, ignoreCase = true)) {
                    uri?.path.orEmpty().removePrefix("/jsapp/")
                } else {
                    source.substringBefore('?').substringBefore('#').trimStart('/')
                }.removePrefix("$appId/")
                val packageRoot = File(context.filesDir, "jsapp/$appId").canonicalFile
                val file = listOf(relativePath, "main/$relativePath")
                    .map { File(packageRoot, it).canonicalFile }
                    .filter { it.path.startsWith(packageRoot.path + File.separator) }
                    .firstOrNull(File::isFile)
                    ?: error("file does not exist")
                return@withContext ResolvedFile(file, source)
            }

            val response = httpClient.newCall(Request.Builder().url(source).build()).execute()
            response.use {
                require(it.isSuccessful) { "http status ${it.code}" }
                val body = requireNotNull(it.body) { "empty response" }
                val contentType = body.contentType()?.subtype?.substringBefore('+')?.takeIf(String::isNotBlank)
                val urlExtension = source.substringBefore('?').substringAfterLast('.', "").takeIf { ext ->
                    ext.isNotBlank() && ext.length <= 10
                }
                val extension = contentType ?: urlExtension ?: "tmp"
                val file = File.createTempFile("MEDIA_${System.currentTimeMillis()}", ".$extension", PathUtils.appTempRoot(context, appId))
                file.outputStream().use { output -> body.byteStream().copyTo(output) }
                ResolvedFile(file, PathUtils.pathToVirtual(file))
            }
        }
}
