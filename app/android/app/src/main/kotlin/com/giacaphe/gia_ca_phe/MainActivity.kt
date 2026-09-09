package com.giacaphe.gia_ca_phe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cầu nối: Flutter gọi để lưu giá -> widget đọc lại và vẽ.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.giacaphe/coffee_widget"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "save" -> {
                    val avg = call.argument<String>("avg") ?: ""
                    val change = call.argument<String>("change") ?: ""
                    val updated = call.argument<String>("updated") ?: ""
                    val items = call.argument<String>("items") ?: "[]"
                    CoffeePriceWidgetHelper.saveData(this, avg, change, updated, items)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
