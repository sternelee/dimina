package com.didi.dimina.ui.container

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.VideoView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.skydoves.landscapist.ImageOptions
import com.skydoves.landscapist.coil.CoilImage
import org.json.JSONArray
import org.json.JSONObject

class MediaPreviewActivity : ComponentActivity() {
    data class Item(val url: String, val type: String, val poster: String = "")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val items = parseItems(intent.getStringExtra(EXTRA_SOURCES).orEmpty())
        if (items.isEmpty()) {
            finish()
            return
        }
        val current = intent.getIntExtra(EXTRA_CURRENT, 0).coerceIn(items.indices)
        setContent {
            MaterialTheme {
                PreviewPager(items, current) { finish() }
            }
        }
    }

    @OptIn(ExperimentalFoundationApi::class)
    @Composable
    private fun PreviewPager(items: List<Item>, current: Int, onClose: () -> Unit) {
        val state = rememberPagerState(initialPage = current, pageCount = { items.size })
        Box(Modifier.fillMaxSize().background(Color.Black)) {
            HorizontalPager(state = state, modifier = Modifier.fillMaxSize()) { page ->
                val item = items[page]
                if (item.type == "video") {
                    AndroidView(
                        factory = { context ->
                            VideoView(context).apply {
                                if (item.url.startsWith("http://") || item.url.startsWith("https://")) {
                                    setVideoURI(Uri.parse(item.url))
                                } else {
                                    setVideoPath(item.url)
                                }
                                setMediaController(android.widget.MediaController(context).also { it.setAnchorView(this) })
                                setOnPreparedListener { player ->
                                    player.isLooping = false
                                    start()
                                }
                            }
                        },
                        modifier = Modifier.fillMaxSize(),
                    )
                } else {
                    CoilImage(
                        imageModel = { item.url },
                        imageOptions = ImageOptions(contentScale = ContentScale.Fit, alignment = Alignment.Center),
                        modifier = Modifier.fillMaxSize().clickable(onClick = onClose),
                    )
                }
            }
            Text(
                text = "${state.currentPage + 1}/${items.size}",
                color = Color.White,
                modifier = Modifier.align(Alignment.TopCenter).padding(top = 32.dp),
            )
        }
    }

    private fun parseItems(value: String): List<Item> = runCatching {
        val array = JSONArray(value)
        List(array.length()) { index ->
            val item = array.getJSONObject(index)
            Item(item.getString("url"), item.optString("type", "image"), item.optString("poster"))
        }
    }.getOrDefault(emptyList())

    companion object {
        private const val EXTRA_SOURCES = "sources"
        private const val EXTRA_CURRENT = "current"

        fun launch(context: Context, items: List<Item>, current: Int) {
            val sources = JSONArray().apply {
                items.forEach { item ->
                    put(JSONObject().apply {
                        put("url", item.url)
                        put("type", item.type)
                        put("poster", item.poster)
                    })
                }
            }
            context.startActivity(Intent(context, MediaPreviewActivity::class.java).apply {
                putExtra(EXTRA_SOURCES, sources.toString())
                putExtra(EXTRA_CURRENT, current.coerceIn(items.indices))
            })
        }
    }
}
