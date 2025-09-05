package com.example.trashifier_app

import io.flutter.embedding.android.FlutterActivity

import android.os.Build
import android.provider.Settings
import android.content.Intent
import android.app.AlarmManager
import android.content.Context
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.trashifier_app/exact_alarm")
			.setMethodCallHandler { call, result ->
				if (call.method == "requestExactAlarmPermission") {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
						val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
						if (!alarmManager.canScheduleExactAlarms()) {
							val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
							intent.data = Uri.parse("package:$packageName")
							startActivity(intent)
						}
					}
					result.success(null)
				}
			}
	}
}
