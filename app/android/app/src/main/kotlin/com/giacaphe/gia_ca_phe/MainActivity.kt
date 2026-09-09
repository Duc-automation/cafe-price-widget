package com.giacaphe.gia_ca_phe

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cầu nối: Flutter gọi để lưu giá / cấu hình lịch -> widget & worker xử lý.
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
                "setSchedule" -> {
                    val prefs = getSharedPreferences(
                        CoffeePriceRefreshWorker.PREFS, Context.MODE_PRIVATE
                    )
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val times = call.argument<String>("times")
                        ?: CoffeePriceRefreshWorker.DEFAULT_TIMES
                    val max = call.argument<Int>("max")
                        ?: CoffeePriceRefreshWorker.DEFAULT_MAX
                    prefs.edit()
                        .putBoolean(CoffeePriceRefreshWorker.KEY_ENABLED, enabled)
                        .putString(CoffeePriceRefreshWorker.KEY_TIMES, times)
                        .putInt(CoffeePriceRefreshWorker.KEY_MAX, max)
                        .apply()
                    CoffeePriceRefreshWorker.schedule(this)
                    result.success(true)
                }
                "getSchedule" -> {
                    val prefs = getSharedPreferences(
                        CoffeePriceRefreshWorker.PREFS, Context.MODE_PRIVATE
                    )
                    result.success(
                        mapOf(
                            "enabled" to prefs.getBoolean(
                                CoffeePriceRefreshWorker.KEY_ENABLED, false
                            ),
                            "times" to prefs.getString(
                                CoffeePriceRefreshWorker.KEY_TIMES,
                                CoffeePriceRefreshWorker.DEFAULT_TIMES
                            ),
                            "max" to prefs.getInt(
                                CoffeePriceRefreshWorker.KEY_MAX,
                                CoffeePriceRefreshWorker.DEFAULT_MAX
                            )
                        )
                    )
                }
                "runNow" -> {
                    CoffeePriceRefreshWorker.runNow(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Luôn đảm bảo có tác vụ nền định kỳ (kể cả chưa mở màn cấu hình).
        CoffeePriceRefreshWorker.schedule(this)
    }
}
