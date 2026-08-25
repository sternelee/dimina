package com.didi.dimina.api.media

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.OptIn
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.Presentation
import androidx.media3.transformer.Composition
import androidx.media3.transformer.DefaultEncoderFactory
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import androidx.media3.transformer.VideoEncoderSettings
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.common.ApiUtils
import com.didi.dimina.common.MediaFileUtils
import com.didi.dimina.common.PathUtils
import com.didi.dimina.ui.container.DiminaActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File

@OptIn(UnstableApi::class)
class VideoToolApi : BaseApiHandler() {
    private companion object {
        const val GET_VIDEO_INFO = "getVideoInfo"
        const val SAVE_VIDEO_TO_PHOTOS_ALBUM = "saveVideoToPhotosAlbum"
        const val COMPRESS_VIDEO = "compressVideo"
    }

    override val apiNames = setOf(GET_VIDEO_INFO, SAVE_VIDEO_TO_PHOTOS_ALBUM, COMPRESS_VIDEO)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult = when (apiName) {
        GET_VIDEO_INFO -> getVideoInfo(activity, appId, params, responseCallback)
        SAVE_VIDEO_TO_PHOTOS_ALBUM -> saveVideo(activity, appId, params, responseCallback)
        COMPRESS_VIDEO -> compressVideo(activity, appId, params, responseCallback)
        else -> super.handleAction(activity, appId, apiName, params, responseCallback)
    }

    private fun getVideoInfo(
        activity: DiminaActivity,
        appId: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val src = params.optString("src")
        if (src.isBlank()) return failure(GET_VIDEO_INFO, "src is required")
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val outcome = runCatching {
                val resolved = MediaFileUtils.resolve(activity, appId, src)
                metadata(resolved.file).apply { put("errMsg", "$GET_VIDEO_INFO:ok") }
            }
            withContext(Dispatchers.Main) { settle(params, responseCallback, GET_VIDEO_INFO, outcome) }
        }
        return NoneResult()
    }

    private fun saveVideo(
        activity: DiminaActivity,
        appId: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val filePath = params.optString("filePath")
        if (!PathUtils.isLegalPath(filePath)) return failure(SAVE_VIDEO_TO_PHOTOS_ALBUM, "invalid filePath")
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
        ) return failure(SAVE_VIDEO_TO_PHOTOS_ALBUM, "auth deny")

        activity.lifecycleScope.launch(Dispatchers.IO) {
            val outcome = runCatching {
                val source = File(PathUtils.pathToReal(activity, filePath, appId))
                require(source.isFile) { "file does not exist" }
                val values = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, "video_${System.currentTimeMillis()}.${source.extension.ifBlank { "mp4" }}")
                    put(MediaStore.Video.Media.MIME_TYPE, "video/${source.extension.ifBlank { "mp4" }}")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES)
                        put(MediaStore.Video.Media.IS_PENDING, 1)
                    }
                }
                val uri = requireNotNull(activity.contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values))
                try {
                    activity.contentResolver.openOutputStream(uri).use { output ->
                        requireNotNull(output) { "cannot open album destination" }
                        source.inputStream().use { input -> input.copyTo(output) }
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        activity.contentResolver.update(uri, ContentValues().apply {
                            put(MediaStore.Video.Media.IS_PENDING, 0)
                        }, null, null)
                    }
                } catch (error: Throwable) {
                    activity.contentResolver.delete(uri, null, null)
                    throw error
                }
                JSONObject().apply { put("errMsg", "$SAVE_VIDEO_TO_PHOTOS_ALBUM:ok") }
            }
            withContext(Dispatchers.Main) { settle(params, responseCallback, SAVE_VIDEO_TO_PHOTOS_ALBUM, outcome) }
        }
        return NoneResult()
    }

    private fun compressVideo(
        activity: DiminaActivity,
        appId: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val src = params.optString("src")
        if (!PathUtils.isLegalPath(src)) return failure(COMPRESS_VIDEO, "invalid src")
        val resolution = params.optDouble("resolution", 1.0)
        if (resolution <= 0.0 || resolution > 1.0) return failure(COMPRESS_VIDEO, "invalid resolution")
        val source = runCatching { File(PathUtils.pathToReal(activity, src, appId)) }.getOrNull()
            ?: return failure(COMPRESS_VIDEO, "invalid src")
        if (!source.isFile) return failure(COMPRESS_VIDEO, "file does not exist")

        val sourceInfo = runCatching { metadata(source) }.getOrNull()
            ?: return failure(COMPRESS_VIDEO, "unsupported video")
        val output = File.createTempFile("VIDEO_${System.currentTimeMillis()}", ".mp4", PathUtils.appTempRoot(activity, appId))
        val bitrateKbps = params.optInt("bitrate", 0).takeIf { it > 0 } ?: when (params.optString("quality", "medium")) {
            "low" -> 1_000
            "high" -> 4_000
            else -> 2_000
        }
        val effects = mutableListOf<Effect>()
        val targetHeight = (sourceInfo.optInt("height") * resolution).toInt()
        if (targetHeight > 0) effects.add(Presentation.createForHeight(targetHeight))
        val editedBuilder = EditedMediaItem.Builder(MediaItem.fromUri(source.toURI().toString()))
            .setEffects(Effects(emptyList(), effects))
        params.optInt("fps", 0).takeIf { it > 0 }?.let(editedBuilder::setFrameRate)

        val encoderFactory = DefaultEncoderFactory.Builder(activity)
            .setRequestedVideoEncoderSettings(VideoEncoderSettings.Builder().setBitrate(bitrateKbps * 1000).build())
            .build()
        val transformer = Transformer.Builder(activity)
            .setEncoderFactory(encoderFactory)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    val result = JSONObject().apply {
                        put("tempFilePath", PathUtils.pathToVirtual(output))
                        put("size", (output.length() + 1023) / 1024)
                        put("errMsg", "$COMPRESS_VIDEO:ok")
                    }
                    ApiUtils.invokeSuccess(params, result, responseCallback)
                    ApiUtils.invokeComplete(params, responseCallback, result)
                }

                override fun onError(composition: Composition, exportResult: ExportResult, exportException: ExportException) {
                    output.delete()
                    val result = JSONObject().apply { put("errMsg", "$COMPRESS_VIDEO:fail ${exportException.message}") }
                    ApiUtils.invokeFail(params, result, responseCallback)
                    ApiUtils.invokeComplete(params, responseCallback, result)
                }
            })
            .build()
        output.delete()
        transformer.start(editedBuilder.build(), output.absolutePath)
        return NoneResult()
    }

    private fun metadata(file: File): JSONObject {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            JSONObject().apply {
                put("duration", (retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toDoubleOrNull() ?: 0.0) / 1000.0)
                put("width", retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0)
                put("height", retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0)
                put("orientation", when (rotation) { 90 -> "right"; 180 -> "down"; 270 -> "left"; else -> "up" })
                put("type", file.extension.lowercase().ifBlank { "unknown" })
                put("size", (file.length() + 1023) / 1024)
                put("bitrate", (retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toLongOrNull() ?: 0L) / 1000L)
                put("fps", retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)?.toDoubleOrNull() ?: 0.0)
            }
        } finally {
            retriever.release()
        }
    }

    private fun settle(
        params: JSONObject,
        responseCallback: (String) -> Unit,
        apiName: String,
        outcome: Result<JSONObject>,
    ) {
        outcome.fold(
            onSuccess = { result -> ApiUtils.invokeSuccess(params, result, responseCallback); ApiUtils.invokeComplete(params, responseCallback, result) },
            onFailure = { error ->
                val result = JSONObject().apply { put("errMsg", "$apiName:fail ${error.message}") }
                ApiUtils.invokeFail(params, result, responseCallback)
                ApiUtils.invokeComplete(params, responseCallback, result)
            },
        )
    }

    private fun failure(apiName: String, reason: String) = AsyncResult(JSONObject().apply {
        put("errMsg", "$apiName:fail $reason")
    }, completeCarriesResult = true)
}
