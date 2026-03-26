package com.example.fashionhub

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val secureChannel = "fashionhub/secure_screen"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureChannel)
			.setMethodCallHandler { call, result ->
				if (call.method == "setSecureFlag") {
					val enabled = call.argument<Boolean>("enabled") ?: false
					runOnUiThread {
						if (enabled) {
							window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
						} else {
							window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
						}
					}
					result.success(null)
				} else {
					result.notImplemented()
				}
			}
	}
}
