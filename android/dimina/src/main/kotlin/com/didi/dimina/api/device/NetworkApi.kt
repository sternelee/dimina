package com.didi.dimina.api.device

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Network API
 * Author: Doslin
 */
class NetworkApi : BaseApiHandler() {
    private companion object {
        const val GET_NETWORK_TYPE = "getNetworkType"
    }

    override val apiNames = setOf(GET_NETWORK_TYPE)
    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {

        return when (apiName) {
            GET_NETWORK_TYPE -> {
                AsyncResult(
                    JSONObject().apply {
                        // 获取网络类型
                        val connectivityManager =
                            activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        val networkType = getNetworkType(activity, connectivityManager)
                        put("networkType", networkType)
                        put("errMsg", "$GET_NETWORK_TYPE:ok")
                    }
                )
            }

            else ->
                super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun getNetworkType(
        currentActivity: Activity,
        connectivityManager: ConnectivityManager,
    ): String {
        // 检查是否具有 ACCESS_NETWORK_STATE 权限
        if (ContextCompat.checkSelfPermission(
                currentActivity,
                Manifest.permission.ACCESS_NETWORK_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return "unknown" // 没有权限时返回 "unknown"
        }

        // 获取当前活跃网络
        val activeNetwork = connectivityManager.activeNetwork ?: return "none"
        val networkCapabilities =
            connectivityManager.getNetworkCapabilities(activeNetwork) ?: return "none"

        // 检查 Wi-Fi
        if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
            return "wifi"
        }

        // 检查移动网络
        if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
            val telephonyManager =
                currentActivity.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            return when (telephonyManager.dataNetworkType) {
                TelephonyManager.NETWORK_TYPE_GPRS,
                TelephonyManager.NETWORK_TYPE_EDGE,
                TelephonyManager.NETWORK_TYPE_CDMA,
                TelephonyManager.NETWORK_TYPE_1xRTT,
                TelephonyManager.NETWORK_TYPE_IDEN,
                    -> "2g"

                TelephonyManager.NETWORK_TYPE_UMTS,
                TelephonyManager.NETWORK_TYPE_EVDO_0,
                TelephonyManager.NETWORK_TYPE_EVDO_A,
                TelephonyManager.NETWORK_TYPE_HSDPA,
                TelephonyManager.NETWORK_TYPE_HSUPA,
                TelephonyManager.NETWORK_TYPE_HSPA,
                TelephonyManager.NETWORK_TYPE_EVDO_B,
                TelephonyManager.NETWORK_TYPE_EHRPD,
                TelephonyManager.NETWORK_TYPE_HSPAP,
                    -> "3g"

                TelephonyManager.NETWORK_TYPE_LTE -> "4g"

                TelephonyManager.NETWORK_TYPE_NR -> "5g"

                else -> "unknown"
            }
        }

        // 其他不常见的网络类型（如以太网、VPN 等）
        return "unknown"
    }
}