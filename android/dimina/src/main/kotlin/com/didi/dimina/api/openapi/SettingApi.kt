package com.didi.dimina.api.openapi

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.api.NoneResult
import com.didi.dimina.common.ApiUtils
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

class SettingApi : BaseApiHandler() {
    private companion object {
        const val GET_SETTING = "getSetting"
        const val OPEN_SETTING = "openSetting"
        const val AUTHORIZE = "authorize"
    }

    override val apiNames = setOf(GET_SETTING, OPEN_SETTING, AUTHORIZE)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult = when (apiName) {
        GET_SETTING -> AsyncResult(settingResult(activity, GET_SETTING), completeCarriesResult = true)
        AUTHORIZE -> authorize(activity, params, responseCallback)
        OPEN_SETTING -> openSetting(activity, params, responseCallback)
        else -> super.handleAction(activity, appId, apiName, params, responseCallback)
    }

    private fun authorize(
        activity: DiminaActivity,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val scope = params.optString("scope")
        val permissions = permissionsForScope(scope)
            ?: return AsyncResult(JSONObject().apply { put("errMsg", "$AUTHORIZE:fail invalid scope") }, completeCarriesResult = true)
        activity.handleAuthorization(permissions) { granted ->
            val result = JSONObject().apply {
                put("errMsg", if (granted) "$AUTHORIZE:ok" else "$AUTHORIZE:fail auth deny")
            }
            if (granted) ApiUtils.invokeSuccess(params, result, responseCallback)
            else ApiUtils.invokeFail(params, result, responseCallback)
            ApiUtils.invokeComplete(params, responseCallback, result)
        }
        return NoneResult()
    }

    private fun openSetting(
        activity: DiminaActivity,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        val launched = activity.handleOpenAppSettings {
            val result = settingResult(activity, OPEN_SETTING)
            ApiUtils.invokeSuccess(params, result, responseCallback)
            ApiUtils.invokeComplete(params, responseCallback, result)
        }
        if (!launched) {
            return AsyncResult(JSONObject().apply { put("errMsg", "$OPEN_SETTING:fail settings already open") }, completeCarriesResult = true)
        }
        return NoneResult()
    }

    private fun settingResult(activity: DiminaActivity, apiName: String): JSONObject = JSONObject().apply {
        val authSetting = JSONObject()
        supportedScopes().forEach { scope ->
            val permissions = permissionsForScope(scope).orEmpty()
            authSetting.put(scope, permissions.all {
                ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
            })
        }
        put("authSetting", authSetting)
        put("errMsg", "$apiName:ok")
    }

    private fun supportedScopes(): List<String> = listOf(
        "scope.camera",
        "scope.record",
        "scope.userLocation",
        "scope.addPhoneContact",
        "scope.bluetooth",
        "scope.writePhotosAlbum",
    )

    private fun permissionsForScope(scope: String): Array<String>? = when (scope) {
        "scope.camera" -> arrayOf(Manifest.permission.CAMERA)
        "scope.record" -> arrayOf(Manifest.permission.RECORD_AUDIO)
        "scope.userLocation" -> arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        "scope.addPhoneContact" -> arrayOf(Manifest.permission.WRITE_CONTACTS)
        "scope.bluetooth" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        "scope.writePhotosAlbum" -> if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        } else emptyArray()
        else -> null
    }
}
