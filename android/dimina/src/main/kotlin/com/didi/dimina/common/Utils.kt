package com.didi.dimina.common

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.os.Environment
import android.provider.MediaStore
import android.widget.Toast
import coil.imageLoader
import coil.request.ImageRequest
import com.didi.dimina.bean.App
import com.didi.dimina.bean.MergedPageConfig
import com.didi.dimina.bean.PageModule
import com.didi.dimina.bean.PathInfo
import com.didi.dimina.bean.WindowConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipInputStream
import kotlin.math.absoluteValue
import org.json.JSONObject

/**
 * Author: Doslin
 */
object Utils {

    private const val TAG = "utils"

    /**
     * 解析 URL，拆分成 pagePath 和 query
     * @param url 输入的 URL 字符串，例如 "pages/index/index?id=123&name=abc"
     * @return PathInfo 包含 pagePath 和 query 的数据对象
     */
    fun queryPath(url: String): PathInfo {
        // 如果 URL 为空，返回默认值
        if (url.isEmpty()) {
            return PathInfo("", null)
        }

        // 分离路径和查询字符串
        val parts = url.split("?", limit = 2)
        val pagePath = parts[0].trim() // 去除首尾空白

        // 如果没有查询字符串，返回只有 pagePath 的结果
        if (parts.size == 1) {
            return PathInfo(pagePath, null)
        }

        // 解析查询字符串
        val queryString = parts[1]
        val queryMap = mutableMapOf<String, String>()

        // 分割参数并处理键值对
        queryString.split("&").forEach { param ->
            val keyValue = param.split("=", limit = 2)
            if (keyValue.size == 2 && keyValue[0].isNotEmpty()) {
                queryMap[keyValue[0].trim()] = keyValue[1].trim()
            } else if (keyValue.size == 1 && keyValue[0].isNotEmpty()) {
                queryMap[keyValue[0].trim()] = ""
            }
        }

        // 将 queryMap 转换为 JSON 字符串
        val queryJson = if (queryMap.isNotEmpty()) {
            JSONObject(queryMap)
        } else {
            null
        }

        // 返回结果
        return PathInfo(pagePath, queryJson)
    }

    /**
     * 合并页面配置
     * @param appConfig 全局应用配置
     * @param pageConfig 页面私有配置
     * @return 合并后的页面配置
     */
    fun mergePageConfig(appConfig: App, pageConfig: PageModule?): MergedPageConfig {
        val appWindowConfig = appConfig.window ?: WindowConfig()
        val pagePrivateConfig = pageConfig ?: PageModule()

        return MergedPageConfig(
            navigationBarTitleText = pagePrivateConfig.navigationBarTitleText
                ?: appWindowConfig.navigationBarTitleText ?: "",
            navigationBarBackgroundColor = pagePrivateConfig.navigationBarBackgroundColor
                ?: appWindowConfig.navigationBarBackgroundColor ?: "#000",
            navigationBarTextStyle = pagePrivateConfig.navigationBarTextStyle
                ?: appWindowConfig.navigationBarTextStyle ?: "white",
            backgroundColor = pagePrivateConfig.backgroundColor
                ?: appWindowConfig.backgroundColor ?: "#fff",
            navigationStyle = pagePrivateConfig.navigationStyle
                ?: appWindowConfig.navigationStyle ?: "default",
            usingComponents = pagePrivateConfig.usingComponents ?: emptyMap()
        )
    }

    private const val CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    /**
     * 生成指定长度的随机 UUID 字符串
     * @param len 生成的字符串长度，默认为 5
     * @return 随机字符串
     */
    fun uuid(len: Int = 5): String {
        // 生成随机字节数组
        val randomValues = ByteArray(len) { (0..255).random().toByte() } // 使用 Kotlin 的 random()

        // 将字节映射到字符集并连接成字符串
        return randomValues.joinToString("") { byte ->
            CHARACTERS[byte.toInt() and 0xFF % CHARACTERS.length].toString()
        }
    }

    /**
     * Unzips the mini program package from assets
     * @param zipFileName The ID of the mini program to unzip
     * @param target The directory to extract the mini program to
     * @param keep Whether to keep the existing files in the target directory
     * @return true if extraction was successful, false otherwise
     */
    fun unzipAssets(context: Context, zipFileName: String, target: String, keep: Boolean = false): Boolean {
        // Create directory for the mini program if it doesn't exist
        val miniProgramDir = File(context.filesDir, target)
        if (miniProgramDir.exists()) {
            if (keep) {
                LogUtils.d(TAG, "Existing directory for mini program: $zipFileName")
                return false
            } else {
                miniProgramDir.deleteRecursively() // Clean up existing files
            }
        }
        miniProgramDir.mkdirs()

        // Get the zip file from assets
        LogUtils.d(TAG, "Extracting from assets: $zipFileName")

        try {
            // Open the zip file from assets
            context.assets.open(zipFileName).use { inputStream ->
                ZipInputStream(inputStream).use { zipInputStream ->
                    var zipEntry = zipInputStream.nextEntry
                    val buffer = ByteArray(1024)

                    // Extract all files from the zip
                    while (zipEntry != null) {
                        val entryName = zipEntry.name
                        val newFile = File(miniProgramDir, entryName)

                        // Create directories if needed
                        if (zipEntry.isDirectory) {
                            newFile.mkdirs()
                        } else {
                            // Create parent directories if they don't exist
                            newFile.parentFile?.mkdirs()

                            // Extract the file
                            FileOutputStream(newFile).use { fileOutputStream ->
                                var len: Int
                                while (zipInputStream.read(buffer).also { len = it } > 0) {
                                    fileOutputStream.write(buffer, 0, len)
                                }
                            }
                        }

                        zipInputStream.closeEntry()
                        zipEntry = zipInputStream.nextEntry
                    }
                }
            }

            return true

        } catch (e: IOException) {
            LogUtils.e(TAG, "Error extracting: ${e.message}")
            e.printStackTrace()
            return false
        } catch (e: Exception) {
            LogUtils.e(TAG, "Unexpected error: ${e.message}")
            e.printStackTrace()
            return false
        }
    }

    // Helper method to get status bar height
    @SuppressLint("InternalInsetResource")
    fun getStatusBarHeight(currentActivity: Activity): Int {
        var result = 0
        val resourceId = currentActivity.resources.getIdentifier("status_bar_height", "dimen", "android")
        if (resourceId > 0) {
            result = currentActivity.resources.getDimensionPixelSize(resourceId)
        }
        return result
    }

    fun saveImageToGallery(context: Context, url: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val request = ImageRequest.Builder(context)
                    .data(url)
                    .allowHardware(false)
                    .build()

                val drawable = context.imageLoader.execute(request).drawable as? BitmapDrawable
                val bitmap = drawable?.bitmap

                bitmap?.let {
                    val contentValues = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, "image_${System.currentTimeMillis()}.jpg")
                        put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                        put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES) // Scoped Storage 目录
                    }

                    val uri = context.contentResolver.insert(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues
                    )

                    uri?.let {
                        context.contentResolver.openOutputStream(it)?.use { outputStream ->
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                        }
                        withContext(Dispatchers.Main) {
                            Toast.makeText(context, "图片已保存", Toast.LENGTH_SHORT).show()
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "保存失败: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    // Function to generate a consistent color based on the name string
    fun generateColorFromName(name: String): Long {
        // If name is empty, return a default color
        if (name.isEmpty()) {
            return 0xFF2196F3 // Material Blue
        }

        // Use the hash code of the name as a seed for color generation
        val hash = name.hashCode()

        // Generate HSV color with consistent hue based on name
        // Use a limited range of saturation and value for visually pleasing colors
        val hue = (hash.absoluteValue % 360).toFloat()
        val saturation = 0.7f + (hash % 3000) / 10000f // Range: 0.7-1.0
        val value = 0.8f + (hash % 2000) / 10000f // Range: 0.8-1.0

        // Convert HSV to RGB
        val hsv = floatArrayOf(hue, saturation, value)
        val rgbColor = android.graphics.Color.HSVToColor(hsv)

        // Add full opacity (0xFF) and convert to Long
        return 0xFF000000 or rgbColor.toLong()
    }
}