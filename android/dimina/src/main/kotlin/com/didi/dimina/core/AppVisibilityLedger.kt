package com.didi.dimina.core

import org.json.JSONObject

internal data class AppVisibilityDelivery(
    val visible: Boolean,
    val options: JSONObject? = null,
)

/** Keeps app visibility until the service-side App instance can receive it. */
internal class AppVisibilityLedger {
    private var serviceReady = false
    private var desiredVisible: Boolean? = null
    private var sentVisible: Boolean? = null
    private var pendingShowOptions: JSONObject? = null

    // Retained pages may still carry the cold-start query after a host reentry.
    // Keep the latest explicit entry for this runtime, separate from visibility deduplication.
    private var latestEntryOptions: JSONObject? = null

    // Only a new entry may emit another onShow while already visible.
    private var pendingNewEntry = false

    @Synchronized
    fun onShow(options: JSONObject? = null, newEntry: Boolean = options != null): AppVisibilityDelivery? {
        if (newEntry && options != null) {
            latestEntryOptions = JSONObject(options.toString())
        }
        val effectiveOptions = latestEntryOptions ?: options
        if (effectiveOptions != null && (!pendingNewEntry || newEntry)) {
            pendingShowOptions = JSONObject(effectiveOptions.toString())
            pendingNewEntry = newEntry
        }
        desiredVisible = true
        return flush()
    }

    @Synchronized
    fun onHide(): AppVisibilityDelivery? {
        desiredVisible = false
        return flush()
    }

    @Synchronized
    fun onServiceReady(): AppVisibilityDelivery? {
        if (serviceReady) return null
        serviceReady = true
        // Creating the service-side App already emits its initial App.onShow.
        sentVisible = true
        return flush()
    }

    @Synchronized
    fun reset() {
        serviceReady = false
        desiredVisible = null
        latestEntryOptions = null
        sentVisible = null
        pendingShowOptions = null
        pendingNewEntry = false
    }

    private fun flush(): AppVisibilityDelivery? {
        val visible = desiredVisible ?: return null
        if (!serviceReady) return null
        if (sentVisible == visible && !(visible && pendingNewEntry)) return null

        val delivery = AppVisibilityDelivery(
            visible = visible,
            options = pendingShowOptions?.let { JSONObject(it.toString()) }.takeIf { visible },
        )
        if (visible) {
            pendingShowOptions = null
            pendingNewEntry = false
        }
        sentVisible = visible
        return delivery
    }
}
