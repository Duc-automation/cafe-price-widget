package com.giacaphe.gia_ca_phe

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/** Widget 4x3: giá trung bình + thay đổi + giờ cập nhật + giá 4 tỉnh. */
class CoffeePriceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                id,
                CoffeePriceWidgetHelper.build(context, full = true)
            )
        }
    }
}
