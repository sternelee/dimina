package com.didi.dimina.common

internal object StatusBarInsetResolver {
    /**
     * Runtime insets describe the current window and must take precedence over framework
     * dimension resources. A display cutout and the status bar can overlap, so their top
     * boundaries are combined with max rather than added together.
     */
    fun resolveTopInsetPx(
        statusBarInsetPx: Int,
        displayCutoutInsetPx: Int,
        statusBarResourcePx: Int,
        defaultStatusBarResourcePx: Int,
    ): Int {
        val runtimeInsetPx = maxOf(statusBarInsetPx, displayCutoutInsetPx)
        if (runtimeInsetPx > 0) {
            return runtimeInsetPx
        }

        return when {
            statusBarResourcePx > 0 -> statusBarResourcePx
            defaultStatusBarResourcePx > 0 -> defaultStatusBarResourcePx
            else -> 0
        }
    }
}
