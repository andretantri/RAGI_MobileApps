package com.minu.staff.myinu_staff

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "com.minu.staff.myinu_staff/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    TeachingScheduleWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
