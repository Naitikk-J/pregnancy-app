package com.pregnancycompanion.pregnancy_companion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing the current pregnancy week, days-to-go and baby
 * size. Data is pushed from Flutter via the `home_widget` plugin (stored in
 * SharedPreferences) and rendered here with RemoteViews. Tapping opens the app.
 */
class PregnancyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pregnancy_widget).apply {
                setTextViewText(
                    R.id.widget_week,
                    widgetData.getString("week_line", "Pregnancy Companion"),
                )
                setTextViewText(
                    R.id.widget_sub,
                    widgetData.getString("sub_line", "Open to set up your journey"),
                )
                setTextViewText(
                    R.id.widget_size,
                    widgetData.getString("size_line", ""),
                )
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
