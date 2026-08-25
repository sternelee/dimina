package com.didi.dimina.api.media

import android.media.MediaMetadataRetriever
import androidx.annotation.OptIn
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
import com.didi.dimina.ui.container.DiminaActivity
import java.io.File

@OptIn(UnstableApi::class)
internal object VideoTranscoder {
    fun start(
        activity: DiminaActivity,
        source: File,
        output: File,
        resolution: Double,
        bitrateKbps: Int,
        fps: Int?,
        onCompleted: () -> Unit,
        onError: (Throwable) -> Unit,
    ) {
        require(source.isFile) { "file does not exist" }
        require(resolution > 0.0 && resolution <= 1.0) { "invalid resolution" }
        require(bitrateKbps in 1..Int.MAX_VALUE / 1_000) { "invalid bitrate" }
        require(fps == null || fps > 0) { "invalid fps" }

        val retriever = MediaMetadataRetriever()
        val sourceHeight = try {
            retriever.setDataSource(source.absolutePath)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
        } finally {
            retriever.release()
        }

        val effects = mutableListOf<Effect>()
        val targetHeight = (sourceHeight * resolution).toInt()
        if (targetHeight > 0) effects.add(Presentation.createForHeight(targetHeight))
        val editedBuilder = EditedMediaItem.Builder(MediaItem.fromUri(source.toURI().toString()))
            .setEffects(Effects(emptyList(), effects))
        fps?.takeIf { it > 0 }?.let(editedBuilder::setFrameRate)

        val encoderFactory = DefaultEncoderFactory.Builder(activity)
            .setRequestedVideoEncoderSettings(
                VideoEncoderSettings.Builder().setBitrate(bitrateKbps * 1000).build(),
            )
            .build()
        val transformer = Transformer.Builder(activity)
            .setEncoderFactory(encoderFactory)
            .addListener(object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    onCompleted()
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException,
                ) {
                    output.delete()
                    onError(exportException)
                }
            })
            .build()
        output.delete()
        transformer.start(editedBuilder.build(), output.absolutePath)
    }
}
