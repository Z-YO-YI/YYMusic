package io.github.z_y_o_y_i.yymusic

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Read/launch only: no routing guess, device enumeration or volume mutation. */
internal class AudioOutputHost(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "io.github.z_y_o_y_i.yymusic/audio-output")

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.arguments != null) {
                result.error("audio-output.invalid-call", "Output request unavailable", null)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "getState" -> result.success(mapOf(
                        "observation" to "unknown",
                        "canOpenSettings" to canOpenSettings()
                    ))
                    "openSystemSettings" -> result.success(openSettings())
                    else -> result.notImplemented()
                }
            } catch (_: RuntimeException) {
                result.error("audio-output.failed", "Output request unavailable", null)
            }
        }
    }

    private fun canOpenSettings(): Boolean =
        !activity.isFinishing && !activity.isDestroyed &&
            Intent(Settings.ACTION_SOUND_SETTINGS).resolveActivity(activity.packageManager) != null

    private fun openSettings(): String {
        if (!activity.hasWindowFocus() || !canOpenSettings()) return "unavailable"
        return try {
            activity.startActivity(Intent(Settings.ACTION_SOUND_SETTINGS))
            "opened"
        } catch (_: ActivityNotFoundException) {
            "unavailable"
        } catch (_: SecurityException) {
            "failed"
        }
    }

    fun close() = channel.setMethodCallHandler(null)
}
