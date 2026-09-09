package com.giacaphe.gia_ca_phe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

/**
 * Widget giá cà phê: hiện giá đã được lưu sẵn (để mở khóa là thấy ngay).
 *
 * Dữ liệu nằm trong SharedPreferences "coffee_widget" do app Flutter ghi qua
 * MethodChannel (xem MainActivity). Widget chỉ ĐỌC + vẽ lại — không tự fetch.
 */
class CoffeePriceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        private const val PREFS_NAME = "coffee_widget"
        private const val KEY_AVG = "avg"
        private const val KEY_CHANGE = "change"
        private const val KEY_UPDATED = "updated"

        /** App Flutter gọi để lưu giá mới rồi refresh toàn bộ widget. */
        fun saveData(context: Context, avg: String, change: String, updated: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_AVG, avg)
                .putString(KEY_CHANGE, change)
                .putString(KEY_UPDATED, updated)
                .apply()
            refreshAll(context)
        }

        /** Vẽ lại tất cả widget đang đặt trên màn hình chính. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, CoffeePriceWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
            // MODE_MULTI_PROCESS: đọc lại từ đĩa để không dính cache cũ.
            @Suppress("DEPRECATION")
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_MULTI_PROCESS)
            val avg = prefs.getString(KEY_AVG, "—") ?: "—"
            val change = prefs.getString(KEY_CHANGE, "") ?: ""
            val updated = prefs.getString(KEY_UPDATED, "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.widget_price)
            views.setTextViewText(R.id.price, avg)
            views.setTextViewText(R.id.change, change)
            views.setTextViewText(R.id.updated, "Cập nhật: $updated")

            // Màu theo dấu tăng/giảm (nền nâu -> dùng màu sáng).
            val color = when {
                change.startsWith("+") -> Color.parseColor("#81C784")
                change.startsWith("-") -> Color.parseColor("#EF9A9A")
                else -> Color.parseColor("#E0E0E0")
            }
            views.setTextColor(R.id.change, color)

            // Bấm vào widget -> mở app.
            val intent = Intent(context, MainActivity::class.java)
            val pi = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            manager.updateAppWidget(id, views)
        }
    }
}
