package com.didi.dimina.ui.view

import org.junit.Assert.assertEquals
import org.junit.Test

class WebResourceMimeTypeTest {
    @Test
    fun javascriptUsesExplicitMimeTypeWhenPlatformLookupIsMissing() {
        val mimeType = resolveWebResourceMimeType("js") { null }

        assertEquals("text/javascript", mimeType)
    }

    @Test
    fun extensionLookupStillHandlesOtherKnownTypes() {
        val mimeType = resolveWebResourceMimeType("png") { extension ->
            if (extension == "png") "image/png" else null
        }

        assertEquals("image/png", mimeType)
    }

    @Test
    fun heifFamilyUsesStableMimeTypesWithoutPlatformLookup() {
        assertEquals("image/heic", resolveWebResourceMimeType("HEIC") { null })
        assertEquals("image/heif", resolveWebResourceMimeType("heif") { null })
    }

    @Test
    fun heifFamilyRequiresNativeTranscodingForWebView() {
        assertEquals(true, requiresHeifWebResourceTranscode("heic"))
        assertEquals(true, requiresHeifWebResourceTranscode("HEIF"))
        assertEquals(false, requiresHeifWebResourceTranscode("jpeg"))
    }

    @Test
    fun unknownExtensionFallsBackToOctetStream() {
        val mimeType = resolveWebResourceMimeType("bin") { null }

        assertEquals("application/octet-stream", mimeType)
    }
}
