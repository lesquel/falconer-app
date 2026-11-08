package dev.openmosh.openmosh

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

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
}
