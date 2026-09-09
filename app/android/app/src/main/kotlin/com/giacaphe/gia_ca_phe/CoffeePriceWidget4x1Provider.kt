package com.giacaphe.gia_ca_phe

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/** Widget 4x1: chỉ hiện giá trung bình + thay đổi. */
class CoffeePriceWidget4x1Provider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(
                id,
                CoffeePriceWidgetHelper.build(context, full = false)
            )
        }
    }
}
