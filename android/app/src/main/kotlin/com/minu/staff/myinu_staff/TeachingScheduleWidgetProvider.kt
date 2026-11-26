package com.minu.staff.myinu_staff

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class TeachingScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, forceAnnouncements = false)
        }
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_PAYLOAD = "flutter.widget_teaching_schedule_json"
        private const val KEY_ANNOUNCEMENTS = "flutter.widget_announcements_json"
        private const val KEY_IS_DOSEN = "flutter.widget_is_dosen"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TeachingScheduleWidgetProvider::class.java)
            for (id in manager.getAppWidgetIds(component)) {
                updateAppWidget(context, manager, id, forceAnnouncements = false)
            }
            CampusAnnouncementWidgetProvider.updateAllWidgets(context)
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            forceAnnouncements: Boolean
        ) {
            val views = RemoteViews(context.packageName, R.layout.teaching_schedule_widget)

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                if (forceAnnouncements) 101 else 100,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val rawSchedule = prefs.getString(KEY_PAYLOAD, null)
            val rawAnnouncements = prefs.getString(KEY_ANNOUNCEMENTS, null)
            val isDosen = prefs.getBoolean(KEY_IS_DOSEN, false)

            val rowIds = listOf(R.id.widget_row_1, R.id.widget_row_2, R.id.widget_row_3)
            val timeIds = listOf(R.id.widget_time_1, R.id.widget_time_2, R.id.widget_time_3)
            val courseIds = listOf(R.id.widget_course_1, R.id.widget_course_2, R.id.widget_course_3)
            val roomIds = listOf(R.id.widget_room_1, R.id.widget_room_2, R.id.widget_room_3)

            for (rowId in rowIds) {
                views.setViewVisibility(rowId, View.GONE)
            }
            views.setViewVisibility(R.id.widget_empty_box, View.GONE)

            val showAnnouncements = forceAnnouncements || !isDosen

            if (showAnnouncements) {
                views.setTextViewText(R.id.widget_title, "Pengumuman Kampus")
                views.setTextViewText(R.id.widget_subtitle, "MyIn-U Staff • Info Terkini")
                renderAnnouncements(views, rawAnnouncements, rowIds, timeIds, courseIds, roomIds)
            } else {
                views.setTextViewText(R.id.widget_title, "Jadwal Mengajar")
                views.setTextViewText(R.id.widget_subtitle, "MyIn-U Staff • Dosen Pengajar")
                renderTeachingSchedule(views, rawSchedule, rowIds, timeIds, courseIds, roomIds)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun renderTeachingSchedule(
            views: RemoteViews,
            rawJson: String?,
            rowIds: List<Int>,
            timeIds: List<Int>,
            courseIds: List<Int>,
            roomIds: List<Int>
        ) {
            if (rawJson.isNullOrBlank()) {
                views.setTextViewText(R.id.widget_date, "Hari Ini")
                views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty,
                    "Buka aplikasi MyIn-U Staff untuk menyinkronkan jadwal mengajar."
                )
                return
            }

            try {
                val json = JSONObject(rawJson)
                val dayLabel = json.optString("day_label", "Hari Ini")
                views.setTextViewText(R.id.widget_date, dayLabel)

                val classes = json.optJSONArray("classes")
                if (classes == null || classes.length() == 0) {
                    views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_empty,
                        "Tidak ada jadwal mengajar hari ini."
                    )
                } else {
                    val count = minOf(classes.length(), 3)
                    for (i in 0 until count) {
                        val item = classes.getJSONObject(i)
                        val time = item.optString("time", "-")
                        val course = item.optString("course", "Mata Kuliah")
                        val room = item.optString("room", "-")
                        val className = item.optString("class_name", "")
                        val meta = if (className.isNotEmpty()) "$room • $className" else room

                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(timeIds[i], time)
                        views.setTextViewText(courseIds[i], course)
                        views.setTextViewText(roomIds[i], meta)
                    }
                }
            } catch (_: Exception) {
                views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                views.setTextViewText(R.id.widget_empty, "Ketuk untuk melihat jadwal mengajar.")
            }
        }

        private fun renderAnnouncements(
            views: RemoteViews,
            rawJson: String?,
            rowIds: List<Int>,
            timeIds: List<Int>,
            courseIds: List<Int>,
            roomIds: List<Int>
        ) {
            if (rawJson.isNullOrBlank()) {
                views.setTextViewText(R.id.widget_date, "Terbaru")
                views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_empty,
                    "Buka aplikasi MyIn-U Staff untuk memuat pengumuman kampus terbaru."
                )
                return
            }

            try {
                val json = JSONObject(rawJson)
                val dayLabel = json.optString("day_label", "Terbaru")
                views.setTextViewText(R.id.widget_date, dayLabel)

                val items: JSONArray? = json.optJSONArray("items")
                if (items == null || items.length() == 0) {
                    views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                    views.setTextViewText(
                        R.id.widget_empty,
                        "Belum ada pengumuman kampus terbaru saat ini."
                    )
                } else {
                    val count = minOf(items.length(), 3)
                    for (i in 0 until count) {
                        val item = items.getJSONObject(i)
                        val category = item.optString("category", "Info")
                        val title = item.optString("title", "Pengumuman Kampus")
                        val subtitle = item.optString("subtitle", "")

                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(timeIds[i], category)
                        views.setTextViewText(courseIds[i], title)
                        views.setTextViewText(roomIds[i], subtitle)
                    }
                }
            } catch (_: Exception) {
                views.setViewVisibility(R.id.widget_empty_box, View.VISIBLE)
                views.setTextViewText(R.id.widget_empty, "Ketuk untuk melihat pengumuman kampus.")
            }
        }
    }
}
