package com.didi.dimina.ui.container

import android.app.ActivityManager
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityNodeInfo
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import com.didi.dimina.Dimina
import com.didi.dimina.api.ui.LoadingTestActivity
import com.didi.dimina.bean.MiniProgram
import com.didi.dimina.core.MiniApp
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/** Runs real Service JS and native task transitions; no lifecycle callbacks are invoked directly. */
@RunWith(AndroidJUnit4::class)
class EntryQueryResumeTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context get() = instrumentation.targetContext
    private val appId = "dimina-entry-resume-test"
    private val title = "Dimina Query Regression"
    private fun onMain(action: () -> Unit) = instrumentation.runOnMainSync(action)
    private fun await(message: String, condition: () -> Boolean) {
        val deadline = SystemClock.uptimeMillis() + 20000
        while (SystemClock.uptimeMillis() < deadline) {
            if (condition()) return
            SystemClock.sleep(100)
        }
        fail(message)
    }
    private fun state(): JSONObject? = runCatching {
        val core = MiniApp.getInstance().peekJsCore(appId) ?: return null
        JSONObject(core.evaluate("JSON.stringify({...globalThis.__entryProbe,launch:wx.getLaunchOptionsSync(),enter:wx.getEnterOptionsSync()})").toString())
    }.getOrNull()
    private fun showCount() = state()?.optJSONArray("shows")?.length() ?: 0
    private fun shell(command: String) { instrumentation.uiAutomation.executeShellCommand(command).close() }
    private fun clickTask(node: AccessibilityNodeInfo?): Boolean {
        if (node == null) return false
        if (node.text?.toString() == title || node.contentDescription?.toString()?.contains(title) == true) {
            var target: AccessibilityNodeInfo? = node
            while (target != null) {
                if (target.isClickable && target.performAction(AccessibilityNodeInfo.ACTION_CLICK)) return true
                target = target.parent
            }
        }
        return (0 until node.childCount).any { clickTask(node.getChild(it)) }
    }

    @Test fun latestEntrySurvivesActualRecentsRestoreWithoutAnotherInstance() {
        val sdk = Dimina.init(context, Dimina.DiminaConfig.Builder().setEnableMultiTask(true).build())
        val zip = File(context.cacheDir, "$appId.zip")
        val files = mapOf(
            "config.json" to """{"appId":"$appId","versionCode":1,"versionName":"1","name":"$title","path":"pages/index/index"}""",
            "main/app-config.json" to """{"app":{"pages":["pages/index/index"],"window":{"navigationBarTitleText":"$title"}},"modules":{"pages/index/index":{}}}""",
            "main/logic.js" to """
                modDefine("app",function(){App({
                  onLaunch(){globalThis.__entryProbe={launches:1,loads:0,hides:0,shows:[]}},
                  onShow(o){__entryProbe.shows.push(JSON.parse(JSON.stringify(o)))},
                  onHide(){__entryProbe.hides++}
                })});
                modDefine("pages/index/index",function(){globalThis.__extraInfo={path:"pages/index/index",usingComponents:{}};Page({onLoad(){__entryProbe.loads++}})});
            """.trimIndent(),
            "main/pages_index_index.js" to """modDefine("pages/index/index",function(){Module({path:"pages/index/index",id:"entry-test",render:()=>_createBlock(_resolveComponent("dd-view"),{},{default:_withCtx(()=>[_createTextVNode("$title")]),_:1})})});""",
            "main/app.css" to "", "main/pages_index_index.css" to "",
        )
        ZipOutputStream(zip.outputStream()).use { out -> files.forEach { (name, content) ->
            out.putNextEntry(ZipEntry(name)); out.write(content.toByteArray()); out.closeEntry()
        } }
        val installed = CountDownLatch(1)
        var installResult: Result<JSONObject>? = null
        sdk.installMiniProgram(appId, zip.path) { installResult = it; installed.countDown() }
        assertTrue(installed.await(15, TimeUnit.SECONDS)); installResult!!.getOrThrow()
        ActivityScenario.launch<LoadingTestActivity>(Intent(context, LoadingTestActivity::class.java)).use { scenario ->
            lateinit var host: LoadingTestActivity
            scenario.onActivity { host = it }
            try {
                onMain { sdk.startMiniProgram(host, MiniProgram(appId, name = title, path = "pages/index/index?id=A")) }
                await("Initial onShow A missing") { showCount() == 1 && state()?.optInt("loads") == 1 }
                val core = MiniApp.getInstance().peekJsCore(appId)
                lateinit var activity: DiminaActivity
                onMain {
                    activity = ActivityLifecycleMonitorRegistry.getInstance().getActivitiesInStage(Stage.RESUMED).filterIsInstance<DiminaActivity>().single()
                    @Suppress("DEPRECATION")
                    activity.setTaskDescription(ActivityManager.TaskDescription(title))
                }
                val taskId = activity.taskId
                assertEquals("A", state()!!.getJSONArray("shows").getJSONObject(0).getJSONObject("query").getString("id"))
                onMain { assertTrue(sdk.hideMiniProgram(appId)) }
                await("First onHide missing") { state()?.optInt("hides") == 1 }
                onMain { sdk.startMiniProgram(host, MiniProgram(appId, name = title, path = "pages/index/index?id=B")) }
                await("Entry B missing") { showCount() == 2 }
                assertEquals("B", state()!!.getJSONArray("shows").getJSONObject(1).getJSONObject("query").getString("id"))
                repeat(2) { index ->
                    shell("input keyevent KEYCODE_HOME")
                    await("Home did not hide mini program") { state()?.optInt("hides") == index + 2 }
                    shell("input keyevent KEYCODE_APP_SWITCH")
                    await("Cannot select mini program card in Recents") { clickTask(instrumentation.uiAutomation.rootInActiveWindow) }
                    await("Recents did not deliver onShow") { showCount() >= index + 3 }
                    val snapshot = state()!!
                    assertEquals(index + 3, snapshot.getJSONArray("shows").length())
                    assertEquals("B", snapshot.getJSONArray("shows").getJSONObject(index + 2).getJSONObject("query").getString("id"))
                    assertEquals("B", snapshot.getJSONObject("enter").getJSONObject("query").getString("id"))
                    assertEquals("A", snapshot.getJSONObject("launch").getJSONObject("query").getString("id"))
                    assertEquals(1, snapshot.getInt("launches")); assertEquals(1, snapshot.getInt("loads"))
                    assertSame(core, MiniApp.getInstance().peekJsCore(appId))
                    onMain {
                        assertSame(activity, ActivityLifecycleMonitorRegistry.getInstance().getActivitiesInStage(Stage.RESUMED).filterIsInstance<DiminaActivity>().single())
                    }
                    val tasks = context.getSystemService(ActivityManager::class.java).appTasks
                        .filter { it.taskInfo.baseIntent.data?.lastPathSegment == appId }
                    assertEquals(1, tasks.size); assertEquals(taskId, tasks.single().taskInfo.taskId)
                    android.util.Log.i("EntryQueryResumeTest", "cycle=$index taskId=$taskId state=$snapshot")
                }
            } finally {
                onMain { sdk.destroyAllMiniPrograms() }
            }
        }
        zip.delete()
    }
}
