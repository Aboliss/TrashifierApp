package com.example.trashifier_app

import io.flutter.embedding.android.FlutterActivity

import android.os.Build
import android.provider.Settings
import android.content.Intent
import android.app.AlarmManager
import android.content.Context
import android.net.Uri
import android.os.PowerManager
import android.content.ComponentName
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.trashifier_app/exact_alarm")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"requestExactAlarmPermission" -> {
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
					"requestBatteryOptimization" -> {
						requestBatteryOptimizationExemption()
						result.success(null)
					}
					"openMiuiAutoStart" -> {
						openMiuiAutoStartSettings()
						result.success(null)
					}
					"openMiuiNotificationSettings" -> {
						openMiuiNotificationSettings()
						result.success(null)
					}
				}
			}
	}
	
	private fun requestBatteryOptimizationExemption() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
			if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
				val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
				intent.data = Uri.parse("package:$packageName")
				startActivity(intent)
			}
		}
	}
	
	private fun openMiuiAutoStartSettings() {
		try {
			val intent = Intent()
			intent.component = ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
			startActivity(intent)
		} catch (e: Exception) {
			try {
				val intent = Intent("miui.intent.action.OP_AUTO_START")
				intent.addCategory(Intent.CATEGORY_DEFAULT)
				startActivity(intent)
			} catch (e2: Exception) {
				// Fallback to general settings
				val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
				intent.data = Uri.parse("package:$packageName")
				startActivity(intent)
			}
		}
	}
	
	private fun openMiuiNotificationSettings() {
		try {
			val intent = Intent()
			intent.component = ComponentName("com.miui.securitycenter", "com.miui.notificationmanagement.NotificationManagementActivity")
			startActivity(intent)
		} catch (e: Exception) {
			// Fallback to general notification settings
			val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
			intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
			startActivity(intent)
		}
	}
}
