package dev.openmosh.openmosh

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // FLAG_SECURE for the whole app, always, before the first frame (T-5):
        // terminal, keys, pairing, inbox and answer screens all show sensitive
        // content. Blocks screenshots, screen recording and the recents
        // thumbnail. Nothing in the app clears it.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.openmosh/clipboard")
            .setMethodCallHandler { call, result ->
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                when (call.method) {
                    // Copies text the keyboard's clipboard preview and history
                    // must not show (Android 13+ honors EXTRA_IS_SENSITIVE).
                    "setSensitive" -> {
                        val text = call.argument<String>("text") ?: ""
                        val clip = ClipData.newPlainText("OpenMosh", text)
                        clip.description.extras = PersistableBundle().apply {
                            val key = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                ClipDescription.EXTRA_IS_SENSITIVE
                            } else {
                                "android.content.extra.IS_SENSITIVE"
                            }
                            putBoolean(key, true)
                        }
                        clipboard.setPrimaryClip(clip)
                        result.success(null)
                    }
                    // Removes the clip entirely (an empty clip still shows in
                    // some keyboards' history).
                    "clear" -> {
                        clipboard.clearPrimaryClip() // API 28 = minSdk.
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
