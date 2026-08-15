package com.adeeteya.classipod

import android.app.admin.DevicePolicyManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Enters kiosk mode only when the DAP controller has allowlisted this app. */
class DapAudioServiceActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAINTENANCE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "openBridge") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bridgeIntent = packageManager.getLaunchIntentForPackage(
                BRIDGE_PACKAGE,
            )
            if (bridgeIntent == null) {
                result.error("BRIDGE_NOT_INSTALLED", "Bridge is not installed", null)
            } else {
                startActivity(bridgeIntent)
                result.success(null)
            }
        }
    }

    override fun onResume() {
        super.onResume()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devicePolicyManager =
                getSystemService(DevicePolicyManager::class.java)
            if (devicePolicyManager.isLockTaskPermitted(packageName)) {
                startLockTask()
            } else {
                // Leaving DAP mode must also leave any transient screen-pinning
                // state created while the allowlist was being cleared.
                try {
                    stopLockTask()
                } catch (_: IllegalStateException) {
                    // The activity was not locked; there is nothing to stop.
                }
            }
        }
    }

    private companion object {
        const val BRIDGE_PACKAGE = "com.pitems.classipodbridge"
        const val MAINTENANCE_CHANNEL = "classipod/maintenance"
    }
}
