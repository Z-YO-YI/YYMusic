package io.github.z_y_o_y_i.yymusic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var fullscreen: FullscreenHost? = null
    private var audioOutput: AudioOutputHost? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioOutput?.close()
        audioOutput = AudioOutputHost(this, flutterEngine.dartExecutor.binaryMessenger)
        // A failed restore must not lose the old window snapshot to a new host.
        if (fullscreen?.close() == false) return
        fullscreen = FullscreenHost(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onPause() {
        fullscreen?.restore()
        super.onPause()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) fullscreen?.restore()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        audioOutput?.close()
        audioOutput = null
        fullscreen?.close()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        audioOutput?.close()
        audioOutput = null
        fullscreen?.close()
        fullscreen = null
        super.onDestroy()
    }
}
