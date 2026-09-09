package io.github.z_y_o_y_i.yymusic

import android.app.Activity
import android.os.Build
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Owns only this Activity's system-bar session; never consumes Flutter insets. */
internal class FullscreenHost(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "io.github.z_y_o_y_i.yymusic/fullscreen")
    private data class SavedBars(val visible: Int, val hidden: Int, val behavior: Int, val legacy: Int)
    private var saved: SavedBars? = null
    private var connected = false

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.arguments != null) {
                result.error("fullscreen.invalid-call", "Fullscreen request unavailable", null)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "configure" -> connected = true
                    "getState" -> Unit
                    "enter" -> {
                        check(connected && activity.hasWindowFocus() && !activity.isFinishing)
                        enter()
                    }
                    "restore", "detach" -> {
                        check(restore())
                        if (call.method == "detach") connected = false
                    }
                    else -> {
                        result.notImplemented()
                        return@setMethodCallHandler
                    }
                }
                result.success(state())
            } catch (_: Exception) {
                if (call.method == "enter") restore()
                result.error("fullscreen.operation-failed", "Fullscreen request unavailable", null)
            }
        }
    }

    private fun state() = mapOf("enabled" to (saved != null))

    @Suppress("DEPRECATION")
    private fun enter() {
        if (saved != null) return
        val decor = activity.window.decorView
        val insets = checkNotNull(ViewCompat.getRootWindowInsets(decor))
        val controller = WindowCompat.getInsetsController(activity.window, decor)
        var visible = 0
        var hidden = 0
        for (type in intArrayOf(WindowInsetsCompat.Type.statusBars(),
                WindowInsetsCompat.Type.navigationBars(), WindowInsetsCompat.Type.captionBar())) {
            if (insets.isVisible(type)) visible = visible or type else hidden = hidden or type
        }
        saved = SavedBars(visible, hidden, controller.systemBarsBehavior, decor.systemUiVisibility)
        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        controller.hide(WindowInsetsCompat.Type.systemBars())
        publish()
    }

    @Suppress("DEPRECATION")
    fun restore(): Boolean {
        val original = saved ?: return true
        return try {
            val decor = activity.window.decorView
            val controller = WindowCompat.getInsetsController(activity.window, decor)
            controller.systemBarsBehavior = original.behavior
            if (original.visible != 0) controller.show(original.visible)
            if (original.hidden != 0) controller.hide(original.hidden)
            if (Build.VERSION.SDK_INT < 30) decor.systemUiVisibility = original.legacy
            saved = null
            publish()
            true
        } catch (_: Exception) {
            // Keep the recovery record; onPause/detach can retry without a page.
            false
        }
    }

    private fun publish() {
        if (connected) channel.invokeMethod("stateChanged", state())
    }

    fun close(): Boolean {
        val restored = restore()
        connected = false
        channel.setMethodCallHandler(null)
        return restored
    }
}
