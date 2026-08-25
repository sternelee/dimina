package com.didi.dimina.ui.view

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.core.content.FileProvider
import java.io.File

/**
 * Author: Doslin
 */
enum class MediaType {
    NONE,
    CAMERA,
    CAMERA_VIDEO,
    IMAGE,
    VIDEO,
    IMAGE_AND_VIDEO
}

data class VideoCaptureOptions(
    val camera: String = "back",
    val maxDuration: Int = 60,
)

private data class VideoCaptureRequest(
    val uri: Uri,
    val options: VideoCaptureOptions,
)

private class CaptureVideoWithOptions : ActivityResultContract<VideoCaptureRequest, Boolean>() {
    override fun createIntent(context: Context, input: VideoCaptureRequest): Intent =
        Intent(MediaStore.ACTION_VIDEO_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, input.uri)
            putExtra(MediaStore.EXTRA_DURATION_LIMIT, input.options.maxDuration.coerceIn(3, 60))
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (input.options.camera == "front") {
                // Android has no public camera-facing extra for ACTION_VIDEO_CAPTURE. These
                // widely supported OEM extras provide the requested preference where available.
                putExtra("android.intent.extra.USE_FRONT_CAMERA", true)
                putExtra("android.intent.extras.CAMERA_FACING", 1)
                putExtra("android.intent.extras.LENS_FACING_FRONT", 1)
            }
        }

    override fun parseResult(resultCode: Int, intent: Intent?): Boolean =
        resultCode == Activity.RESULT_OK
}

@Composable
fun MediaPickerRoot(
    type: MediaType,
    context: Context,
    maxCount: Int = 1,
    videoCaptureOptions: VideoCaptureOptions = VideoCaptureOptions(),
    onSelected: (List<Uri>) -> Unit = {},
) {
    var cameraUri by remember { mutableStateOf<Uri?>(null) }
    var videoCameraUri by remember { mutableStateOf<Uri?>(null) }

    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success) {
            cameraUri?.let { uri ->
                onSelected(listOf(uri))
            }
        } else {
            onSelected(emptyList())
        }
    }

    val videoCameraLauncher = rememberLauncherForActivityResult(CaptureVideoWithOptions()) { success ->
        if (success) {
            videoCameraUri?.let { uri ->
                onSelected(listOf(uri))
            }
        } else {
            onSelected(emptyList())
        }
    }

    // Launcher for picking media
    val mediaLauncher = if (maxCount == 1) {
        rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
            onSelected(uri?.let(::listOf) ?: emptyList())
        }
    } else {
        rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(maxCount)) { uris ->
            onSelected(uris)
        }
    }


    LaunchedEffect(type, videoCaptureOptions) {
        when (type) {
            MediaType.IMAGE -> {
                mediaLauncher.launch(
                    PickVisualMediaRequest(mediaType = ActivityResultContracts.PickVisualMedia.ImageOnly)
                )
            }
            MediaType.VIDEO -> {
                mediaLauncher.launch(
                    PickVisualMediaRequest(mediaType = ActivityResultContracts.PickVisualMedia.VideoOnly)
                )
            }
            MediaType.IMAGE_AND_VIDEO -> {
                mediaLauncher.launch(
                    PickVisualMediaRequest(mediaType = ActivityResultContracts.PickVisualMedia.ImageAndVideo)
                )
            }
            MediaType.CAMERA -> {
                val photoFile = File.createTempFile("IMG_${System.currentTimeMillis()}", ".jpg", context.cacheDir)
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", photoFile)
                cameraUri = uri
                cameraLauncher.launch(uri)
            }
            MediaType.CAMERA_VIDEO -> {
                val videoFile = File.createTempFile("VID_${System.currentTimeMillis()}", ".mp4", context.cacheDir)
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", videoFile)
                videoCameraUri = uri
                videoCameraLauncher.launch(VideoCaptureRequest(uri, videoCaptureOptions))
            }
            MediaType.NONE -> {
                // Do nothing or handle as needed
            }
        }
    }
}
