package com.didi.dimina.ui.container

/** The OS task survives Activity reclamation; entry path/query never identify an app. */
internal object MiniProgramTaskLookup {
    fun <T> find(
        tasks: List<T>, activityTaskId: Int?, appId: String,
        taskId: (T) -> Int, rootAppId: (T) -> String?,
    ): T? = tasks.firstOrNull { activityTaskId != null && taskId(it) == activityTaskId }
        ?: tasks.firstOrNull { rootAppId(it) == appId }
}
