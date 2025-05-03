package com.didi.dimina.api.device

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.text.TextUtils
import com.didi.dimina.api.APIResult
import com.didi.dimina.api.AsyncResult
import com.didi.dimina.api.BaseApiHandler
import com.didi.dimina.ui.container.DiminaActivity
import org.json.JSONObject

/**
 * Device - Vibrate API
 * Author: Doslin
 */
class VibrateAPI : BaseApiHandler() {
    private companion object {
        const val VIBRATE_SHORT = "vibrateShort"
        const val VIBRATE_LONG = "vibrateLong"
    }

    override val apiNames = setOf(VIBRATE_SHORT, VIBRATE_LONG)

    override fun handleAction(
        activity: DiminaActivity,
        appId: String,
        apiName: String,
        params: JSONObject,
        responseCallback: (String) -> Unit,
    ): APIResult {
        return when (apiName) {
            VIBRATE_SHORT -> {
                val type = params.optString("type")
                vibrate(activity, getVibrationEffect(type))
                AsyncResult(JSONObject().apply {
                    put("errMsg", "$VIBRATE_SHORT:ok")
                })
            }
            VIBRATE_LONG -> {
                vibrate(activity, VibrationEffect.createOneShot(400, VibrationEffect.DEFAULT_AMPLITUDE))
                AsyncResult(JSONObject().apply {
                    put("errMsg", "$VIBRATE_LONG:ok")
                })
            }
            else -> super.handleAction(activity, appId, apiName, params, responseCallback)
        }
    }

    private fun getVibrationEffect(type: String?): VibrationEffect {
        val pattern = if (TextUtils.equals(
                "light",
                type
            )
        ) {
            VibrationEffect.createWaveform(
                longArrayOf(15),
                intArrayOf(85),
                -1
            )
        } else if (TextUtils.equals(
                "medium",
                type
            )
        ) {
            VibrationEffect.createWaveform(
                longArrayOf(15),
                intArrayOf(170),
                -1
            )
        } else {
            VibrationEffect.createWaveform(
                longArrayOf(15),
                intArrayOf(255),
                -1
            )
        }
        return pattern
    }
    private fun vibrate(activity: DiminaActivity, effect: VibrationEffect) {
        // Get Vibrator service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            val vibrator = vibratorManager.defaultVibrator
            vibrator.vibrate(effect)
        } else {
            val vibrator = activity.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.vibrate(effect)
        }
    }
}