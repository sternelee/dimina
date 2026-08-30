package com.didi.dimina

import com.didi.dimina.common.PathUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class VirtualFilePrefixConfigTest {
    @Test
    fun builderNormalizesVirtualFilePrefix() {
        val config = Dimina.DiminaConfig.Builder()
            .setVirtualFilePrefix("HostFile://")
            .build()

        assertEquals("hostfile://", config.virtualFilePrefix)
    }

    @Test
    fun builderUsesBackwardCompatibleDefault() {
        val config = Dimina.DiminaConfig.Builder().build()

        assertEquals(PathUtils.DEFAULT_VIRTUAL_DOMAIN_URL, config.virtualFilePrefix)
    }

    @Test
    fun builderRejectsPrefixPaths() {
        assertThrows(IllegalArgumentException::class.java) {
            Dimina.DiminaConfig.Builder().setVirtualFilePrefix("host-file://usr/")
        }
        assertThrows(IllegalArgumentException::class.java) {
            Dimina.DiminaConfig.Builder().setVirtualFilePrefix("https://")
        }
    }

    @Test
    fun pathConfigurationUpdatesSchemeAndPrefixTogether() {
        val previous = PathUtils.VIRTUAL_DOMAIN_URL
        try {
            PathUtils.configureVirtualFilePrefix("HostFile://")
            assertEquals("hostfile", PathUtils.VIRTUAL_SCHEME)
            assertEquals("hostfile://", PathUtils.VIRTUAL_DOMAIN_URL)
        } finally {
            PathUtils.configureVirtualFilePrefix(previous)
        }
    }
}
