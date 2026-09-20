package com.didi.dimina.ui.container

import org.junit.Assert.*
import org.junit.Test

class MiniProgramTaskLookupTest {
    private data class Task(val id: Int, val appId: String?, val path: String)
    private fun find(tasks: List<Task>, appId: String, liveId: Int? = null) =
        MiniProgramTaskLookup.find(tasks, liveId, appId, { it.id }, { it.appId })

    @Test fun `different query entries reuse one OS task without an Activity registry`() {
        val original = Task(2, "app", "pages/index?id=1")
        val tasks = mutableListOf(Task(1, null, "host"), original, Task(3, "other", "pages/index?id=2"))
        for (query in listOf("2", "3", "4")) {
            val task = find(tasks, "app") ?: Task(4, "app", "pages/index?id=$query").also(tasks::add)
            assertSame(original, task)
        }
        assertEquals(1, tasks.count { it.appId == "app" })
    }

    @Test fun `live page task wins even when the root belongs to its opener`() {
        val task = Task(4, "opener", "pages/index")
        assertSame(task, find(listOf(Task(2, "app", "old"), task), "app", 4))
    }

    @Test fun `missing live task falls back to same app but never another app or host`() {
        val task = Task(2, "app", "pages/index?id=1")
        assertSame(task, find(listOf(task), "app", 99))
        assertNull(find(listOf(Task(1, null, "host"), task), "missing"))
    }

    @Test fun `a finishing top page does not hide a retained live root`() {
        val registry = MiniProgramActivityRegistry<String>()
        registry.register("app", "root")
        registry.register("app", "finishing-detail")
        assertEquals("root", registry.lastMatching("app") { it != "finishing-detail" })
        assertNull(registry.lastMatching("missing") { true })
    }
}
