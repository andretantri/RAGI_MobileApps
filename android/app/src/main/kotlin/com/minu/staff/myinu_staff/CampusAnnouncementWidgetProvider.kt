package com.minu.staff.myinu_staff

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context

class CampusAnnouncementWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            TeachingScheduleWidgetProvider.updateAppWidget(
                context,
                appWidgetManager,
                appWidgetId,
                forceAnnouncements = true
            )
        }
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, CampusAnnouncementWidgetProvider::class.java)
            for (id in manager.getAppWidgetIds(component)) {
                TeachingScheduleWidgetProvider.updateAppWidget(
                    context,
                    manager,
                    id,
                    forceAnnouncements = true
                )
            }
        }
    }
}
