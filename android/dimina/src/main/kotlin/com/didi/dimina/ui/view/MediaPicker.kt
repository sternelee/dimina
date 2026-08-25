package com.didi.dimina.ui.view

import android.content.Context
import android.net.Uri
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

@Composable
fun MediaPickerRoot(
    type: MediaType,
    context: Context,
    maxCount: Int = 1,
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

    val videoCameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CaptureVideo()) { success ->
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


    LaunchedEffect(type) { // Use type as the key
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
                videoCameraLauncher.launch(uri)
            }
            MediaType.NONE -> {
                // Do nothing or handle as needed
            }
        }
    }
}
