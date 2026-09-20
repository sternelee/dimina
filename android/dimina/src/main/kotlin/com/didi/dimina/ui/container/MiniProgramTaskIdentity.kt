package com.didi.dimina.ui.container

import android.content.Intent
import android.net.Uri

/** RecentTaskInfo can strip extras. Keep app identity in the filter-preserved data URI. */
internal object MiniProgramTaskIdentity {
    fun attach(intent: Intent, appId: String, session: String, generation: Long) {
        intent.data = Uri.Builder().scheme("dimina").authority("mini-program")
            .appendPath(appId).appendQueryParameter("session", session)
            .appendQueryParameter("generation", generation.toString()).build()
    }

    fun appId(intent: Intent, session: String, generation: Long): String? {
        val uri = intent.data ?: return null
        if (uri.scheme != "dimina" || uri.authority != "mini-program" || uri.pathSegments.size != 1) return null
        if (uri.getQueryParameter("session") == session &&
            uri.getQueryParameter("generation") != generation.toString()) return null
        return uri.lastPathSegment
    }
}
