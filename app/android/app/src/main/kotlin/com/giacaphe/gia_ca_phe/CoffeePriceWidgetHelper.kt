package com.giacaphe.gia_ca_phe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * Dùng chung cho cả 2 widget (4x1 và 4x4).
 *
 * Dữ liệu nằm trong SharedPreferences "coffee_widget" do app Flutter ghi qua
 * MethodChannel. Widget chỉ ĐỌC + vẽ — không tự fetch mạng.
 */
object CoffeePriceWidgetHelper {

    private const val PREFS_NAME = "coffee_widget"
    private const val KEY_AVG = "avg"
    private const val KEY_CHANGE = "change"
    private const val KEY_UPDATED = "updated"
    private const val KEY_ITEMS = "items" // JSON: [{m: market, p: price, c: change}]

    /** App Flutter gọi để lưu giá mới rồi refresh toàn bộ widget đang đặt. */
    fun saveData(
        context: Context,
        avg: String,
        change: String,
        updated: String,
        itemsJson: String
    ) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_AVG, avg)
            .putString(KEY_CHANGE, change)
            .putString(KEY_UPDATED, updated)
            .putString(KEY_ITEMS, itemsJson)
            .apply()
        refreshAll(context)
    }

    /** Vẽ lại cả widget 4x1 lẫn 4x4 đang nằm trên màn hình chính. */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        updateInstances(context, manager, CoffeePriceWidget4x1Provider::class.java, full = false)
        updateInstances(context, manager, CoffeePriceWidgetProvider::class.java, full = true)
    }

    private fun updateInstances(
        context: Context,
        manager: AppWidgetManager,
        clazz: Class<*>,
        full: Boolean
    ) {
        val ids = manager.getAppWidgetIds(ComponentName(context, clazz))
        for (id in ids) {
            manager.updateAppWidget(id, build(context, full))
        }
    }

    /** Dựng RemoteViews cho widget. full=true -> layout 4x4 (có các tỉnh). */
    fun build(context: Context, full: Boolean): RemoteViews {
        @Suppress("DEPRECATION")
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_MULTI_PROCESS)
        val avg = prefs.getString(KEY_AVG, "—") ?: "—"
        val change = prefs.getString(KEY_CHANGE, "") ?: ""
        val updated = prefs.getString(KEY_UPDATED, "") ?: ""

        val layout = if (full) R.layout.widget_price_4x4 else R.layout.widget_price_4x1
        val views = RemoteViews(context.packageName, layout)

        views.setTextViewText(R.id.price, avg)
        views.setTextViewText(R.id.change, change)
        views.setTextColor(R.id.change, changeColor(change))

        if (full) {
            views.setTextViewText(R.id.updated, "Cập nhật: $updated")
            fillRows(views, prefs.getString(KEY_ITEMS, "[]") ?: "[]")
        }

        // Bấm vào widget -> mở app.
        val pi = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pi)

        return views
    }

    private fun changeColor(change: String): Int = when {
        change.startsWith("+") -> Color.parseColor("#81C784")
        change.startsWith("-") -> Color.parseColor("#EF9A9A")
        else -> Color.parseColor("#E0E0E0")
    }

    /** Điền 4 dòng tỉnh (Đắk Lắk, Lâm Đồng, Gia Lai, Đắk Nông). */
    private fun fillRows(views: RemoteViews, itemsJson: String) {
        val rows = intArrayOf(R.id.row1, R.id.row2, R.id.row3, R.id.row4)
        val markets = intArrayOf(R.id.item_m1, R.id.item_m2, R.id.item_m3, R.id.item_m4)
        val prices = intArrayOf(R.id.item_p1, R.id.item_p2, R.id.item_p3, R.id.item_p4)
        val changes = intArrayOf(R.id.item_c1, R.id.item_c2, R.id.item_c3, R.id.item_c4)

        val arr = try {
            JSONArray(itemsJson)
        } catch (e: Exception) {
            JSONArray()
        }

        for (i in rows.indices) {
            if (i < arr.length()) {
                val obj = arr.optJSONObject(i)
                views.setTextViewText(markets[i], obj?.optString("m", "") ?: "")
                views.setTextViewText(prices[i], obj?.optString("p", "") ?: "")
                val change = obj?.optString("c", "") ?: ""
                views.setTextViewText(changes[i], change)
                views.setTextColor(changes[i], changeColor(change))
                views.setViewVisibility(rows[i], View.VISIBLE)
            } else {
                views.setViewVisibility(rows[i], View.GONE)
            }
        }
    }
}
