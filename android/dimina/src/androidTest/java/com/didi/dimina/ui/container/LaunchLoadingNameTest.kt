package com.didi.dimina.ui.container

import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.activity.compose.setContent
import androidx.compose.runtime.mutableStateOf
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.didi.dimina.api.ui.LoadingTestActivity
import com.didi.dimina.bean.MiniProgram
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class LaunchLoadingNameTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()

    @Test fun emptyAndBlankNamesRenderAndNameChangesUpdateTheInitial() {
        val program = mutableStateOf(MiniProgram("launch-name-test", path = null))
        ActivityScenario.launch<LoadingTestActivity>(
            Intent(instrumentation.targetContext, LoadingTestActivity::class.java)
        ).use { scenario ->
            scenario.onActivity { activity ->
                val container = DiminaActivity()
                activity.setContent { container.LoadingAnimation(program.value) }
            }
            awaitText("小")
            val screenshot = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            File(instrumentation.targetContext.cacheDir, "launch-empty-name.png").outputStream().use {
                screenshot.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
            }
            screenshot.recycle()
            for ((name, initial) in listOf("星河" to "星", "   " to "小", "Demo" to "D", "" to "小")) {
                scenario.onActivity { program.value = program.value.copy(name = name) }
                awaitText(initial)
            }
        }
    }

    private fun awaitText(text: String) {
        val deadline = SystemClock.uptimeMillis() + 5_000
        do {
            if (containsText(instrumentation.uiAutomation.rootInActiveWindow, text)) return
            SystemClock.sleep(50)
        } while (SystemClock.uptimeMillis() < deadline)
        assertTrue("Launch animation should display initial '$text'", false)
    }

    private fun containsText(node: AccessibilityNodeInfo?, text: String): Boolean {
        if (node == null) return false
        if (node.text?.toString() == text) return true
        return (0 until node.childCount).any { containsText(node.getChild(it), text) }
    }
}
