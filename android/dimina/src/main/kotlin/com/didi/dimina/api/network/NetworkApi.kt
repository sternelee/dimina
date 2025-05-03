package com.didi.dimina.api.network

import android.webkit.MimeTypeMap
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.common.ApiUtils
import com.didi.dimina.common.PathUtils
import com.didi.dimina.ui.container.DiminaActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Network API implementation
 * Author: Doslin
 *
 * Handles network operations like HTTP requests, file downloads, and uploads
 */
class NetworkApi : BaseApiHandler() {
    private companion object {
        const val REQUEST = "request"
        const val DOWNLOAD_FILE = "downloadFile"
        const val UPLOAD = "uploadFile"

        // 单例 OkHttpClient
        val client: OkHttpClient by lazy {
            OkHttpClient.Builder()
                .connectTimeout(60_000, TimeUnit.MILLISECONDS) // 默认超时时间
                .readTimeout(60_000, TimeUnit.MILLISECONDS)
                .writeTimeout(60_000, TimeUnit.MILLISECONDS)
                .build()
        }
    }

    override val apiNames = setOf(REQUEST, DOWNLOAD_FILE, UPLOAD)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            REQUEST -> {
                val url = params.optString("url")

                if (url.isEmpty()) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$REQUEST:fail url is required")
                    })
                }

                val data = params.optString("data")
                val header = params.optJSONObject("header")
                val timeout = params.optInt("timeout", 60000)
                val method = params.optString("method", "GET")
                val dataType = params.optString("dataType", "json")
                val responseType = params.optString("responseType", "text")

                // Create OkHttp client with timeout
                // 使用单例 client，但根据参数动态调整超时时间
                val adjustedClient = if (timeout != 60000) { // 如果超时时间不是默认值
                    client.newBuilder()
                        .connectTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .readTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .writeTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .build()
                } else {
                    client // 直接使用单例
                }

                // Build request
                val requestBuilder = Request.Builder()
                    .url(url)

                // Set headers
                header?.let {
                    header.keys().forEach { key ->
                        requestBuilder.addHeader(key, header.optString(key))
                    }
                }

                // Set request body based on method
                when (method) {
                    "POST", "PUT" -> {
                        val mediaType = when (dataType.lowercase()) {
                            "json" -> "application/json; charset=utf-8"
                            else -> "text/plain; charset=utf-8"
                        }
                        val body = if (data.isNotEmpty()) {
                            data.toRequestBody(mediaType.toMediaTypeOrNull())
                        } else {
                            "".toRequestBody(mediaType.toMediaTypeOrNull())
                        }
                        requestBuilder.method(method, body)
                    }

                    "GET", "HEAD", "DELETE" -> {
                        requestBuilder.method(method, null)
                    }

                    else -> {
                        return AsyncResult(JSONObject().apply {
                            put("errMsg", "$REQUEST:fail unsupported method $method")
                        })
                    }
                }

                val request = requestBuilder.build()
                try {
                    CoroutineScope(Dispatchers.IO).launch {
                        val response = adjustedClient.newCall(request).execute()
                        val responseBody = response.body

                        val result = JSONObject().apply {
                            put("errMsg", "$REQUEST:ok")
                            put("statusCode", response.code)

                            when (responseType.lowercase()) {
                                "text" -> {
                                    put("data", responseBody?.string() ?: "")
                                }

                                "json" -> {
                                    val bodyString = responseBody?.string() ?: ""
                                    try {
                                        put("data", JSONObject(bodyString))
                                    } catch (e: Exception) {
                                        put(
                                            "data",
                                            bodyString
                                        ) // Fallback to raw string if JSON parsing fails
                                    }
                                }
                            }
                            put("header", JSONObject().apply {
                                response.headers.toMultimap().forEach { (key, values) ->
                                    put(key, values.joinToString(","))
                                }
                            })
                        }

                        response.close()
                        ApiUtils.invokeSuccess(params, result, responseCallback)
                        ApiUtils.invokeComplete(params, responseCallback)
                    }
                } catch (e: IOException) {
                    AsyncResult(JSONObject().apply {
                        put("errMsg", "$REQUEST:fail network error: ${e.message}")
                    })
                } catch (e: Exception) {
                    AsyncResult(JSONObject().apply {
                        put("errMsg", "$REQUEST:fail ${e.message}")
                    })
                }

                NoneResult()
            }

            DOWNLOAD_FILE -> {
                val url = params.optString("url")

                if (url.isEmpty()) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$DOWNLOAD_FILE:fail url is required")
                    })
                }

                val header = params.optJSONObject("header")
                val timeout = params.optInt("timeout", 60000)
                val filePath = params.optString("filePath")

                val adjustedClient = if (timeout != 60000) { // 如果超时时间不是默认值
                    client.newBuilder()
                        .connectTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .readTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .writeTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .build()
                } else {
                    client // 直接使用单例
                }

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val requestBuilder = Request.Builder()
                            .url(url)

                        // Set headers
                        header?.let {
                            header.keys().forEach { key ->
                                requestBuilder.addHeader(key, header.optString(key))
                            }
                        }
                        val request = requestBuilder.build()
                        val response = adjustedClient.newCall(request).execute()

                        if (!response.isSuccessful) {
                            ApiUtils.invokeFail(params, JSONObject().apply {
                                put("errMsg", "$DOWNLOAD_FILE:fail HTTP ${response.code}")
                            }, responseCallback)
                            ApiUtils.invokeComplete(params, responseCallback)
                            return@launch
                        }

                        val body = response.body
                        if (body == null) {
                            ApiUtils.invokeFail(params, JSONObject().apply {
                                put("errMsg", "$DOWNLOAD_FILE:fail empty response")
                            }, responseCallback)
                            ApiUtils.invokeComplete(params, responseCallback)
                            return@launch
                        }

                        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(body.contentType()?.toString()) ?: "tmp"
                        val outFile = if (filePath.isNotEmpty()) {
                            File(activity.cacheDir, filePath)
                        } else {
                            File.createTempFile("download_${System.currentTimeMillis()}", ".$ext", activity.cacheDir)
                        }

                        outFile.outputStream().use { output ->
                            body.byteStream().use { input ->
                                input.copyTo(output)
                            }
                        }

                        ApiUtils.invokeSuccess(params, JSONObject().apply {
                            put("tempFilePath", PathUtils.pathToVirtual(outFile))
                            put("filePath", filePath)
                            put("statusCode", response.code)
                            put("errMsg", "$DOWNLOAD_FILE:ok")
                        }, responseCallback)

                        ApiUtils.invokeComplete(params, responseCallback)

                    } catch (e: Exception) {
                        ApiUtils.invokeFail(params, JSONObject().apply {
                            put("errMsg", "$DOWNLOAD_FILE:fail ${e.message}")
                        }, responseCallback)

                        ApiUtils.invokeComplete(params, responseCallback)
                    }
                }

                NoneResult()
            }

            UPLOAD -> {
                val url = params.optString("url")

                if (url.isEmpty()) {
                    return AsyncResult(JSONObject().apply {
                        put("errMsg", "$DOWNLOAD_FILE:fail url is required")
                    })
                }

                val header = params.optJSONObject("header")
                val timeout = params.optInt("timeout", 60000)
                val filePath = params.optString("filePath")
                val name = params.optString("name")
                val formData = params.optJSONObject("name")

                val adjustedClient = if (timeout != 60000) { // 如果超时时间不是默认值
                    client.newBuilder()
                        .connectTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .readTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .writeTimeout(timeout.toLong(), TimeUnit.MILLISECONDS)
                        .build()
                } else {
                    client // 直接使用单例
                }

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        var file = File(PathUtils.pathToReal(activity, filePath))
                        val fileRequestBody = file.asRequestBody("application/octet-stream".toMediaTypeOrNull())
                        val multipartBuilder = MultipartBody.Builder().setType(MultipartBody.FORM)
                            .addFormDataPart(name, file.name, fileRequestBody)

                        // 附加 formData 参数
                        formData?.keys()?.forEach { key ->
                            multipartBuilder.addFormDataPart(key, formData.optString(key))
                        }

                        val requestBuilder = Request.Builder()
                            .url(url)
                            .post(multipartBuilder.build())

                        // Set headers
                        header?.let {
                            header.keys().forEach { key ->
                                requestBuilder.addHeader(key, header.optString(key))
                            }
                        }

                        val response = adjustedClient.newCall(requestBuilder.build()).execute()
                        val responseBody = response.body?.string() ?: ""

                        ApiUtils.invokeSuccess(params, JSONObject().apply {
                            put("statusCode", response.code)
                            put("data", responseBody)
                            put("errMsg", "$UPLOAD:ok")
                        }, responseCallback)

                        ApiUtils.invokeComplete(params, responseCallback)

                    } catch (e: Exception) {
                        ApiUtils.invokeFail(params, JSONObject().apply {
                            put("errMsg", "$UPLOAD:fail ${e.message}")
                        }, responseCallback)

                        ApiUtils.invokeComplete(params, responseCallback)
                    }
                }
                NoneResult()
            }

            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }
}
