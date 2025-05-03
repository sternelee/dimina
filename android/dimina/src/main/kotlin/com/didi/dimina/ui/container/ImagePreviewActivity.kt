package com.didi.dimina.ui.container

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.didi.dimina.common.Utils
import com.didi.dimina.ui.view.ActionSheet
import com.skydoves.landscapist.ImageOptions
import com.skydoves.landscapist.coil.CoilImage

/**
 * Author: Doslin
 */
class ImagePreviewActivity : ComponentActivity() {
    private val showActionSheet = mutableStateOf(false)
    private var actionSheetOptions = listOf<String>()
    private var actionSheetCallback: ((Int) -> Unit)? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val urls = intent.getStringArrayListExtra("urls") ?: emptyList()
        val current = intent.getStringExtra("current") ?: urls.firstOrNull()
        val showMenu = intent.getBooleanExtra("showMenu", true)

        if (urls.isEmpty() || current == null) {
            finish()
            return
        }

        setContent {
            MaterialTheme {
                if (showActionSheet.value) {
                    ActionSheet(
                        buttonLabels = actionSheetOptions,
                        onButtonClick = { index ->
                            actionSheetCallback?.invoke(index)
                            showActionSheet.value = false
                        },
                        onDismiss = { showActionSheet.value = false }
                    )
                }
                ImagePreviewPager(
                    urls = urls,
                    currentUrl = current,
                    showMenu = showMenu,
                    onClose = { finish() }
                )
            }
        }
    }
    fun showImageMenu(context: Context, url: String) {
        actionSheetOptions = listOf("保存图片")
        actionSheetCallback = { index ->
            when (index) {
                0 -> Utils.saveImageToGallery(context, url)
            }
        }
        showActionSheet.value = true
    }

    @OptIn(ExperimentalFoundationApi::class)
    @Composable
    fun ZoomableImage(
        url: String,
        showMenu: Boolean = true,
        onTap: () -> Unit = {}
    ) {
        var scale by remember { mutableFloatStateOf(1f) }
        val context = LocalContext.current

        Box(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    awaitPointerEventScope {
                        while (true) {
                            val event = awaitPointerEvent(PointerEventPass.Main)
                            when (event.changes.size) {
                                2 -> {
                                    // 双指操作：处理缩放
                                    val first = event.changes[0]
                                    val second = event.changes[1]
                                    val oldDistance = (first.previousPosition - second.previousPosition).getDistance()
                                    val newDistance = (first.position - second.position).getDistance()
                                    if (oldDistance > 0f && newDistance > 0f) {
                                        val zoom = newDistance / oldDistance
                                        scale = (scale * zoom).coerceIn(1f, 5f)
                                    }
                                    event.changes.forEach { it.consume() } // 消费缩放事件
                                }
                            }
                        }
                    }
                }
                .combinedClickable(
                    onClick = { onTap() },
                    onLongClick = {
                        if (showMenu) showImageMenu(context, url)
                    }
                )
        ) {
            CoilImage(
                imageModel = { url },
                loading = {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = Color.White,
                            modifier = Modifier.size(48.dp),
                            strokeWidth = 4.dp
                        )
                    }
                },
                imageOptions = ImageOptions(
                    contentScale = ContentScale.Fit,
                    alignment = Alignment.Center
                ),
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer(scaleX = scale, scaleY = scale)
            )
        }
    }

    @OptIn(ExperimentalFoundationApi::class)
    @Composable
    fun ImagePreviewPager(
        urls: List<String>,
        currentUrl: String,
        showMenu: Boolean = true,
        onClose: () -> Unit
    ) {
        val initialPage = urls.indexOfFirst { it == currentUrl }.coerceAtLeast(0)
        val pagerState = rememberPagerState(
            initialPage = initialPage,
            pageCount = { urls.size }
        )

        Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
            // 页码指示器
            Text(
                text = "${pagerState.currentPage + 1}/${urls.size}",
                color = Color.White,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 30.dp)
                    .background(Color(0x99000000), RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp)
            )

            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize()
            ) { page ->
                ZoomableImage(
                    url = urls[page],
                    showMenu = showMenu,
                    onTap = onClose
                )
            }
        }
    }

    companion object {
        fun launch(
            context: Context,
            urls: List<String>,
            current: String = urls.first(),
            showMenu: Boolean = true
        ) {
            val intent = Intent(context, ImagePreviewActivity::class.java).apply {
                putStringArrayListExtra("urls", ArrayList(urls))
                putExtra("current", current)
                putExtra("showMenu", showMenu)
            }
            context.startActivity(intent)
        }
    }
}



