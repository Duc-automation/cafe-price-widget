package com.giacaphe.gia_ca_phe

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Tác vụ nền: chạy định kỳ 15 phút.
 *
 * Chỉ fetch khi: (1) bật tự động, (2) giờ hiện tại trùng "ô 15 phút" của một giờ
 * đã cấu hình, (3) còn lượt trong ngày, (4) ô giờ này chưa fetch hôm nay.
 * Sau khi fetch -> lưu + refresh widget (không cần mở app).
 */
class CoffeePriceRefreshWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        if (!prefs.getBoolean(KEY_ENABLED, false)) return Result.success()

        // Mỗi giờ cấu hình = tối đa 1 lần/ngày (không còn giới hạn tổng).
        val now = Calendar.getInstance()
        val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now.time)
        val minutesNow = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val bucketNow = minutesNow / 15

        val timesStr = prefs.getString(KEY_TIMES, DEFAULT_TIMES) ?: DEFAULT_TIMES
        var due = false
        for (raw in timesStr.split(",")) {
            val parts = raw.trim().split(":")
            if (parts.size != 2) continue
            val h = parts[0].toIntOrNull() ?: continue
            val m = parts[1].toIntOrNull() ?: continue
            if (h !in 0..23 || m !in 0..59) continue
            if ((h * 60 + m) / 15 == bucketNow) {
                due = true
                break
            }
        }
        if (!due) return Result.success()

        // Tránh chạy 2 lần trong cùng ô giờ 15 phút của cùng 1 ngày.
        val lastRunKey = prefs.getString(KEY_LAST_RUN_KEY, "") ?: ""
        val currentRunKey = "$dateKey-$bucketNow"
        if (lastRunKey == currentRunKey) return Result.success()

        return try {
            fetchAndSave()
            prefs.edit().putString(KEY_LAST_RUN_KEY, currentRunKey).apply()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    private fun fetchAndSave() {
        val conn = URL(API_URL).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "GET"
            conn.connectTimeout = 15000
            conn.readTimeout = 15000
            conn.setRequestProperty("Accept", "application/json")
            conn.setRequestProperty("User-Agent", "gia-ca-phe-widget/1.0")
            if (conn.responseCode != 200) throw RuntimeException("HTTP ${conn.responseCode}")

            val text = conn.inputStream.bufferedReader().use { it.readText() }
            val data = JSONObject(text).getJSONObject("data")
            val dp = data.getJSONObject("domestic_price")

            val avg = dp.optString("average_price", "—")
            val change = dp.optString("price_change", "").trim()
            val updated = data.optString("updated_at", "")

            // Lưu 5 mục đầu (4 tỉnh + Hồ tiêu) đúng như app.
            val items = JSONArray()
            val source = dp.optJSONArray("item")
            if (source != null) {
                for (i in 0 until minOf(source.length(), 5)) {
                    val it = source.getJSONObject(i)
                    val o = JSONObject()
                    o.put("m", it.optString("market"))
                    o.put("p", it.optString("average_price"))
                    o.put("c", it.optString("price_change").trim())
                    items.put(o)
                }
            }

            CoffeePriceWidgetHelper.saveData(applicationContext, avg, change, updated, items.toString())
        } finally {
            conn.disconnect()
        }
    }

    companion object {
        private const val API_URL = "https://api.chocaphe.vn/v1/prices"

        // Cùng file với widget để worker đọc/ghi.
        const val PREFS = "coffee_widget"
        const val KEY_ENABLED = "schedule_enabled"
        const val KEY_TIMES = "schedule_times" // "HH:mm,HH:mm"
        const val KEY_MAX = "schedule_max"
        const val KEY_DAY = "schedule_day"
        const val KEY_COUNT = "schedule_count"
        const val KEY_LAST_RUN_KEY = "schedule_last_run"

        const val DEFAULT_TIMES = "07:30,12:00,18:00"
        const val DEFAULT_MAX = 5

        private const val UNIQUE_NAME = "coffee_fetch_periodic"

        /** Đăng ký (hoặc cập nhật) tác vụ định kỳ 15 phút. */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<CoffeePriceRefreshWorker>(
                15, TimeUnit.MINUTES
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_NAME, ExistingPeriodicWorkPolicy.UPDATE, request
            )
        }

        /** Chạy ngay 1 lần (dùng để test / "cập nhật nền ngay"). */
        fun runNow(context: Context) {
            val request = OneTimeWorkRequestBuilder<CoffeePriceRefreshWorker>().build()
            WorkManager.getInstance(context).enqueue(request)
        }
    }
}
