package com.didi.dimina.ui.view

import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.IOException

class CameraCaptureRequestTest {
    private val request = CameraCaptureRequest()
    private val events = mutableListOf<String>()

    private fun start(granted: Boolean = false, capture: () -> Unit = { events.add("capture") }) {
        request.start(granted, { events.add("permission") }, capture, { events.add("cancel") })
    }

    @Test fun waitsForPermissionBeforeCapture() {
        start()
        assertEquals(listOf("permission"), events)
        request.onPermissionResult(true)
        assertEquals(listOf("permission", "capture"), events)
        request.onPermissionResult(true)
        assertEquals(listOf("permission", "capture"), events)
    }

    @Test fun deniedPermissionCancelsExactlyOnceWithoutOpeningCamera() {
        start()
        request.onPermissionResult(false)
        request.onPermissionResult(false)
        assertEquals(listOf("permission", "cancel"), events)
    }

    @Test fun existingPermissionLaunchesImmediately() {
        start(granted = true)
        assertEquals(listOf("capture"), events)
    }

    @Test fun revokedPermissionDuringLaunchCancels() {
        start(granted = true) { throw SecurityException("CAMERA revoked") }
        assertEquals(listOf("cancel"), events)
    }

    @Test fun launchFailureAfterPermissionGrantCancels() {
        start { throw SecurityException("CAMERA revoked") }
        request.onPermissionResult(true)
        assertEquals(listOf("permission", "cancel"), events)
    }

    @Test fun outputFileFailureCancels() {
        start(granted = true) { throw IOException("Cannot create output file") }
        assertEquals(listOf("cancel"), events)
    }

    @Test fun permissionLauncherFailureCancels() {
        request.start(false, { throw IllegalStateException("Launcher unavailable") },
            { events.add("capture") }, { events.add("cancel") })
        assertEquals(listOf("cancel"), events)
    }

    @Test fun disposedPickerIgnoresLatePermissionResult() {
        start()
        request.clear()
        request.onPermissionResult(true)
        assertEquals(listOf("permission"), events)
    }

    @Test fun canRetryAfterDenial() {
        start()
        request.onPermissionResult(false)
        start()
        request.onPermissionResult(true)
        assertEquals(listOf("permission", "cancel", "permission", "capture"), events)
    }
}
