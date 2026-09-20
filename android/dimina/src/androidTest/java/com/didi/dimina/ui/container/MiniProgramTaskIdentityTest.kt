package com.didi.dimina.ui.container

import android.content.Intent
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MiniProgramTaskIdentityTest {
    @Test fun queryChangesDoNotChangeIdentityAndStrippedExtrasStillResolve() {
        val entries = listOf("pages/index?id=1", "pages/index?id=2", "pages/other?id=3").map { path ->
            Intent().apply {
                putExtra("path", path)
                MiniProgramTaskIdentity.attach(this, "app/id +中文", "session", 0)
            }
        }
        assertTrue(entries[0].filterEquals(entries[1]))
        entries.forEach {
            val stripped = it.cloneFilter()
            assertNull(stripped.extras)
            assertEquals("app/id +中文", MiniProgramTaskIdentity.appId(stripped, "session", 0))
        }
    }

    @Test fun destructionInvalidatesOldTasksButProcessRestartAllowsRestore() {
        val intent = Intent()
        MiniProgramTaskIdentity.attach(intent, "app", "old-process", 0)
        assertNull(MiniProgramTaskIdentity.appId(intent.cloneFilter(), "old-process", 1))
        assertEquals("app", MiniProgramTaskIdentity.appId(intent.cloneFilter(), "new-process", 0))
        assertNull(MiniProgramTaskIdentity.appId(Intent(), "old-process", 0))
    }
}
