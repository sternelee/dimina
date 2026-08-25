package com.didi.dimina.api.media

import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.common.ApiUtils
import com.didi.dimina.common.PathUtils
import com.didi.dimina.ui.container.DiminaActivity
import com.didi.dimina.ui.view.MediaType
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import android.media.MediaMetadataRetriever

/**
 * Author: Doslin
 */
class VideoApi : BaseApiHandler() {
    private companion object {
        const val CHOOSE_MEDIA = "chooseMedia"
        const val CHOOSE_VIDEO = "chooseVideo"
    }

    override val apiNames = setOf(CHOOSE_MEDIA, CHOOSE_VIDEO)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            CHOOSE_MEDIA -> {
                val count = params.optInt("count", 9)
                val mediaType = params.optJSONArray("mediaType")?: JSONArray().apply {
                    put("image")
                    put("video")
                } // image, video, mix
                val sourceType = params.optJSONArray("sourceType")?: JSONArray().apply {
                    put("album")
                    put("camera")
                }
                val maxDuration = params.optInt("maxDuration", 10) // 拍摄视频最长拍摄时间，单位秒。时间范围为 3s 至 60s 之间。
                val sizeType = params.optJSONArray("sizeType")?: JSONArray().apply {
                    put("original")
                    put("compressed")
                } // TODO: 是否压缩所选文件
                var camera = params.optString("camera", "back")

                // 检查是否允许从相册或相机选择
                val allowAlbum =
                    (0 until sourceType.length()).any { sourceType.getString(it) == "album" }
                val allowCamera =
                    (0 until sourceType.length()).any { sourceType.getString(it) == "camera" }

                if (!allowAlbum && !allowCamera) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$CHOOSE_VIDEO:fail invalid sourceType")
                    })
                }
                val types = (0 until mediaType.length()).mapNotNull { mediaType.optString(it).lowercase() }
                val type = when {
                    types.contains("image") && types.contains("video") -> MediaType.IMAGE_AND_VIDEO
                    types.contains("image") -> MediaType.IMAGE
                    types.contains("video") -> MediaType.VIDEO
                    else -> MediaType.NONE
                }
                activity.handleChooseMedia(
                    type = type,
                    count = count,
                    allowAlbum = allowAlbum,
                    allowCamera = allowCamera
                ) { imagePaths ->
                    val tempFilePaths = JSONArray()
                    val tempFiles = JSONArray()

                    imagePaths.take(count).forEach { path ->
                        tempFilePaths.put(path)
                        tempFiles.put(JSONObject().apply {
                            put("path", path)
                            put("size", File(path).length())
                        })
                    }
                    val result = JSONObject().apply {
                        put("errMsg", "$CHOOSE_MEDIA:ok")
                        put("tempFilePaths", tempFilePaths)
                        put("tempFiles", tempFiles)
                    }
                    ApiUtils.invokeSuccess(params, result, responseCallback)
                    ApiUtils.invokeComplete(params, responseCallback)
                }
                NoneResult()
            }

            CHOOSE_VIDEO -> {
                val sourceType = params.optJSONArray("sourceType")?: JSONArray().apply {
                    put("album")
                    put("camera")
                }
                val compressed = params.optBoolean("compressed", true)
                val maxDuration = params.optInt("maxDuration", 60)
                var camera = params.optString("camera", "back")
                // 检查是否允许从相册或相机选择
                val allowAlbum =
                    (0 until sourceType.length()).any { sourceType.getString(it) == "album" }
                val allowCamera =
                    (0 until sourceType.length()).any { sourceType.getString(it) == "camera" }

                if (!allowAlbum && !allowCamera) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$CHOOSE_MEDIA:fail invalid sourceType")
                    })
                }
                activity.handleChooseMedia(
                    type = MediaType.VIDEO,
                    count = 1,
                    allowAlbum = allowAlbum,
                    allowCamera = allowCamera
                ) { imagePaths ->
                    val virtualPath = imagePaths.firstOrNull()
                    if (virtualPath == null) {
                        val failure = JSONObject().apply { put("errMsg", "$CHOOSE_VIDEO:fail cancel") }
                        ApiUtils.invokeFail(params, failure, responseCallback)
                        ApiUtils.invokeComplete(params, responseCallback, failure)
                        return@handleChooseMedia
                    }
                    val result = videoMetadata(activity, appId, virtualPath).apply {
                        put("errMsg", "$CHOOSE_VIDEO:ok")
                        put("tempFilePath", virtualPath)
                    }
                    ApiUtils.invokeSuccess(params, result, responseCallback)
                    ApiUtils.invokeComplete(params, responseCallback, result)
                }
                NoneResult()
            }

            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun videoMetadata(activity: DiminaActivity, appId: String, path: String): JSONObject {
        val file = File(PathUtils.pathToReal(activity, path, appId))
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            JSONObject().apply {
                put("duration", (retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toDoubleOrNull() ?: 0.0) / 1000.0)
                put("width", retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0)
                put("height", retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0)
                put("size", file.length())
            }
        } finally {
            retriever.release()
        }
    }

}
