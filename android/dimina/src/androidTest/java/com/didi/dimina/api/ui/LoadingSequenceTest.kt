package com.didi.dimina.api.ui

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.graphics.Bitmap
import java.io.File
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.compose.ui.platform.ComposeView
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

class LoadingTestActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(FrameLayout(this).apply { setBackgroundColor(android.graphics.Color.WHITE) })
    }
}

@RunWith(AndroidJUnit4::class)
class LoadingSequenceTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()
    // Exercise the exact presenter used by showLoading/hideLoading without booting a JS engine.
    private fun show(api: InteractionApi, activity: LoadingTestActivity, duration: Int = Int.MAX_VALUE) {
        InteractionApi::class.java.getDeclaredMethod("showToast", Context::class.java,
            String::class.java, String::class.java, Int::class.javaPrimitiveType,
            Boolean::class.javaPrimitiveType).apply { isAccessible = true }
            .invoke(api, activity, "Loading", "loading", duration, true)
    }
    private fun hide(api: InteractionApi, activity: LoadingTestActivity) {
        InteractionApi::class.java.getDeclaredMethod("hideToast", Context::class.java)
            .apply { isAccessible = true }.invoke(api, activity)
    }
    private fun launch(separateTask: Boolean = false) = ActivityScenario.launch<LoadingTestActivity>(
        Intent(instrumentation.targetContext, LoadingTestActivity::class.java).apply {
            if (separateTask) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
        })
    private fun count(activity: LoadingTestActivity): Int {
        val root = activity.window.decorView.rootView as ViewGroup
        return (0 until root.childCount).count { root.getChildAt(it) is ComposeView }
    }
    private fun assertCount(scenario: ActivityScenario<LoadingTestActivity>, expected: Int) {
        instrumentation.waitForIdleSync()
        scenario.onActivity { assertEquals(expected, count(it)) }
    }

    private fun capture(scenario: ActivityScenario<LoadingTestActivity>, name: String) {
        // A removed View can precede SurfaceFlinger's displayed frame. Check the
        // actual pixels until the expected presentation is visible, bounded by 3s.
        val expectHidden = name.contains("hide")
        val deadline = android.os.SystemClock.uptimeMillis() + 3_000
        var screenshot: Bitmap
        var matches: Boolean
        do {
            val frame = java.util.concurrent.CountDownLatch(1)
            scenario.onActivity { activity ->
                activity.window.decorView.postOnAnimation { frame.countDown() }
            }
            org.junit.Assert.assertTrue(frame.await(5, java.util.concurrent.TimeUnit.SECONDS))
            screenshot = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            val center = screenshot.getPixel(screenshot.width / 2, screenshot.height / 2)
            val white = android.graphics.Color.red(center) > 240 &&
                android.graphics.Color.green(center) > 240 && android.graphics.Color.blue(center) > 240
            matches = white == expectHidden
            if (matches || android.os.SystemClock.uptimeMillis() >= deadline) break
            screenshot.recycle()
        } while (true)
        File(instrumentation.targetContext.cacheDir, name).outputStream().use {
            screenshot.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        screenshot.recycle()
        org.junit.Assert.assertTrue("Rendered loading state for $name", matches)
    }

    @Test fun loadingCanShowAndHideTwiceFromTheBridgeThread() {
        launch().use { scenario ->
            lateinit var activity: LoadingTestActivity
            scenario.onActivity { activity = it }
            val api = InteractionApi()
            repeat(2) {
                show(api, activity)
                assertCount(scenario, 1)
                if (it == 1) capture(scenario, "loading-second-show.png")
                hide(api, activity)
                assertCount(scenario, 0)
                if (it == 1) capture(scenario, "loading-second-hide.png")
            }
        }
    }

    @Test fun replacingAQueuedToastDoesNotDropTheNewLoadingRequest() {
        launch().use { scenario ->
            val api = InteractionApi()
            scenario.onActivity {
                show(api, it, duration = 0)
                show(api, it)
            }
            assertCount(scenario, 1)
            scenario.onActivity { hide(api, it) }
            assertCount(scenario, 0)
        }
    }

    @Test fun rapidDoubleCycleLeavesNoOverlayOrMask() {
        launch().use { scenario ->
            val api = InteractionApi()
            var childrenBefore = 0
            scenario.onActivity { childrenBefore = (it.window.decorView as ViewGroup).childCount }
            scenario.onActivity {
                show(api, it); hide(api, it); show(api, it); hide(api, it)
            }
            assertCount(scenario, 0)
            scenario.onActivity { assertEquals(childrenBefore, (it.window.decorView as ViewGroup).childCount) }
        }
    }

    @Test fun anOldToastTimeoutDoesNotDismissTheReplacementLoading() {
        launch().use { scenario ->
            val api = InteractionApi()
            scenario.onActivity {
                show(api, it, duration = 50)
                show(api, it)
            }
            // Wait past the old deadline via a main-loop barrier, not a production delay.
            val deadlinePassed = java.util.concurrent.CountDownLatch(1)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ deadlinePassed.countDown() }, 100)
            org.junit.Assert.assertTrue(deadlinePassed.await(5, java.util.concurrent.TimeUnit.SECONDS))
            assertCount(scenario, 1)
            scenario.onActivity { hide(api, it) }
            assertCount(scenario, 0)
        }
    }

    @Test fun hideRemovesOverlayFromItsActualParentAfterActivityChanges() {
        launch().use { first ->
            val api = InteractionApi()
            first.onActivity { show(api, it) }
            assertCount(first, 1)
            launch(separateTask = true).use { second ->
                second.onActivity { hide(api, it) }
                assertCount(first, 0)
                second.onActivity { show(api, it) }
                assertCount(second, 1)
                second.onActivity { hide(api, it) }
                assertCount(second, 0)
            }
        }
    }
}
