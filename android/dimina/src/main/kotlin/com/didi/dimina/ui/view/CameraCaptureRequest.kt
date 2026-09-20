package com.didi.dimina.ui.view

/** 拍照与录像共用的授权流程；只有授权成功后才创建文件并启动系统相机。 */
internal class CameraCaptureRequest {
    private var pendingCapture: (() -> Unit)? = null
    private var pendingCancellation: (() -> Unit)? = null

    fun start(
        hasPermission: Boolean,
        requestPermission: () -> Unit,
        capture: () -> Unit,
        onCancelled: () -> Unit,
    ) {
        pendingCapture = capture
        pendingCancellation = onCancelled
        if (hasPermission) {
            onPermissionResult(true)
        } else {
            try {
                requestPermission()
            } catch (_: Exception) {
                onPermissionResult(false)
            }
        }
    }

    fun onPermissionResult(granted: Boolean) {
        val capture = pendingCapture ?: return
        val onCancelled = pendingCancellation
        clear()
        if (!granted) {
            onCancelled?.invoke()
            return
        }
        // 权限可能在检查后被撤销，设备也可能没有可处理拍摄 Intent 的应用。
        val launched = try {
            capture()
            true
        } catch (_: Exception) {
            false
        }
        if (!launched) onCancelled?.invoke()
    }

    fun clear() {
        pendingCapture = null
        pendingCancellation = null
    }
}
