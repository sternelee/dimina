package com.didi.dimina.ui.view

import android.content.Intent
import android.os.Bundle
import android.view.WindowInsets
import android.webkit.WebView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

class InputFocusTestActivity : ComponentActivity() {
    lateinit var web: WebView
    val loaded = CountDownLatch(1)
    val keyboard = CountDownLatch(1)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        com.didi.dimina.common.StoreUtils.initialize(this)
        window.decorView.setOnApplyWindowInsetsListener { _, insets ->
            if (insets.isVisible(WindowInsets.Type.ime())) keyboard.countDown()
            insets
        }
        val control = intent.getStringExtra("control") ?: "<input id='input' placeholder='将会获取焦点'>"
        val focus = if (intent.getBooleanExtra("focus", true)) "document.getElementById('input').focus()" else ""
        setContent {
            DiminaWebView(
                enableCache = intent.getBooleanExtra("cache", false),
                isPageActive = intent.getBooleanExtra("active", true),
                onInitReady = {
                    web = it
                    it.loadDataWithBaseURL("https://appassets.androidplatform.net/jssdk/test/main/pageFrame.html", """
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        $control
                        <script>$focus</script>
                    """.trimIndent(), "text/html", "UTF-8", null)
                },
                onPageCompleted = { loaded.countDown() }
            )
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::web.isInitialized && !intent.getBooleanExtra("cache", false)) web.destroy()
    }
}

@RunWith(AndroidJUnit4::class)
class InputFocusTest {
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()

    private fun launch(control: String? = null, focus: Boolean = true, active: Boolean = true, cache: Boolean = false): ActivityScenario<InputFocusTestActivity> {
        val intent = Intent(instrumentation.targetContext, InputFocusTestActivity::class.java)
            .putExtra("control", control).putExtra("focus", focus).putExtra("active", active).putExtra("cache", cache)
        return ActivityScenario.launch<InputFocusTestActivity>(intent).also { scenario ->
            lateinit var loaded: CountDownLatch
            scenario.onActivity { loaded = it.loaded }
            assertTrue("Page loaded", loaded.await(10, TimeUnit.SECONDS))
        }
    }

    private fun evaluate(scenario: ActivityScenario<InputFocusTestActivity>, script: String): String? {
        val checked = CountDownLatch(1)
        var value: String? = null
        scenario.onActivity {
            it.web.evaluateJavascript(script) { result -> value = result; checked.countDown() }
        }
        assertTrue("JS evaluation", checked.await(5, TimeUnit.SECONDS))
        return value
    }

    private fun assertKeyboard(scenario: ActivityScenario<InputFocusTestActivity>, visible: Boolean) {
        lateinit var keyboard: CountDownLatch
        scenario.onActivity { keyboard = it.keyboard }
        if (visible) assertTrue("Soft keyboard visible without a tap", keyboard.await(5, TimeUnit.SECONDS))
        else assertFalse("No unexpected soft keyboard", keyboard.await(1, TimeUnit.SECONDS))
    }

    @Test fun initialFocusShowsKeyboardWithoutTouch() {
        launch().use { scenario ->
            assertTrue("DOM input focused", evaluate(scenario, "document.activeElement.id === 'input'") == "true")
            assertKeyboard(scenario, true)
        }
    }

    @Test fun preCreatedWebViewShowsKeyboardWithoutActivityContext() {
        instrumentation.runOnMainSync { WebViewCacheManager.initialize(instrumentation.targetContext.applicationContext) }
        instrumentation.waitForIdleSync()
        try {
            launch(cache = true).use { scenario ->
                scenario.onActivity { assertFalse(it.web.context is android.app.Activity) }
                assertKeyboard(scenario, true)
            }
        } finally {
            instrumentation.runOnMainSync { WebViewCacheManager.clearCache() }
        }
    }

    @Test fun dynamicFocusShowsKeyboardWithoutTouch() {
        launch(focus = false).use { scenario ->
            assertKeyboard(scenario, false)
            evaluate(scenario, "document.getElementById('input').focus()")
            assertKeyboard(scenario, true)
        }
    }

    @Test fun textareaInitialFocusShowsKeyboard() {
        launch("<textarea id='input'></textarea>").use { assertKeyboard(it, true) }
    }

    @Test fun disabledAndReadOnlyInputsDoNotShowKeyboard() {
        for (attribute in listOf("disabled", "readonly", "type='checkbox'")) {
            launch("<input id='input' $attribute>").use { assertKeyboard(it, false) }
        }
    }

    @Test fun inactiveTabCannotShowKeyboard() {
        launch(active = false).use { assertKeyboard(it, false) }
    }

    @Test fun focusThenRemovalCancelsKeyboardRequest() {
        launch(focus = false).use { scenario ->
            evaluate(scenario, "var el = document.getElementById('input'); el.focus(); el.remove();")
            assertKeyboard(scenario, false)
        }
    }
}
