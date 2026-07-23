package com.jala.pasajero

import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mockLocationChannel = "app.viajeseguro/mock_location"
    private val securityChannel = "app.viajeseguro/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mockLocationChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMockLocationEnabled" -> result.success(isMockLocationEnabled())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsbDebuggingEnabled" -> result.success(isUsbDebuggingEnabled())
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun isMockLocationEnabled(): Boolean {
        val allowMock = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ALLOW_MOCK_LOCATION,
        )
        val mockApp = Settings.Secure.getString(contentResolver, "mock_location_app")
        return allowMock == "1" || !mockApp.isNullOrEmpty()
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        return Settings.Global.getInt(
            contentResolver,
            Settings.Global.ADB_ENABLED, 0
        ) > 0
    }

}
