package com.didi.dimina.common

import org.junit.Assert.assertEquals
import org.junit.Test

class StatusBarInsetResolverTest {
    @Test
    fun `keeps pixel cutout safe area instead of truncating it to legacy resource height`() {
        val topInset = StatusBarInsetResolver.resolveTopInsetPx(
            statusBarInsetPx = 96,
            displayCutoutInsetPx = 132,
            statusBarResourcePx = 96,
            defaultStatusBarResourcePx = 72,
        )

        assertEquals(132, topInset)
    }

    @Test
    fun `uses current status bar inset before framework resources`() {
        val topInset = StatusBarInsetResolver.resolveTopInsetPx(
            statusBarInsetPx = 120,
            displayCutoutInsetPx = 0,
            statusBarResourcePx = 96,
            defaultStatusBarResourcePx = 72,
        )

        assertEquals(120, topInset)
    }

    @Test
    fun `falls back to device status bar resource while insets are unavailable`() {
        val topInset = StatusBarInsetResolver.resolveTopInsetPx(
            statusBarInsetPx = 0,
            displayCutoutInsetPx = 0,
            statusBarResourcePx = 108,
            defaultStatusBarResourcePx = 72,
        )

        assertEquals(108, topInset)
    }

    @Test
    fun `falls back to default status bar resource when device resource is unavailable`() {
        val topInset = StatusBarInsetResolver.resolveTopInsetPx(
            statusBarInsetPx = 0,
            displayCutoutInsetPx = 0,
            statusBarResourcePx = 0,
            defaultStatusBarResourcePx = 72,
        )

        assertEquals(72, topInset)
    }
}
