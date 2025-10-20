package com.example.trashifier_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

/**
 * Implementation of App Widget functionality.
 * Displays the next trash pickup information with type-specific colors and icons.
 */
class TrashifierWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule periodic updates using WorkManager
        scheduleWidgetUpdates(context)
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        scheduleWidgetUpdates(context)
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
        cancelWidgetUpdates(context)
    }
    
    companion object {
        private const val WIDGET_UPDATE_WORK_NAME = "trashifier_widget_update"
        
        /**
         * Method to trigger widget update from Flutter
         */
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, TrashifierWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
        
        /**
         * Schedule periodic widget updates every 8 hours using WorkManager
         */
        private fun scheduleWidgetUpdates(context: Context) {
            val updateWorkRequest = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                8, TimeUnit.HOURS,
                15, TimeUnit.MINUTES // Flex interval
            ).build()
            
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WIDGET_UPDATE_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP, // Keep existing work if already scheduled
                updateWorkRequest
            )
        }
        
        /**
         * Cancel scheduled widget updates
         */
        private fun cancelWidgetUpdates(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WIDGET_UPDATE_WORK_NAME)
        }
    }
}

enum class TrashType(val key: String) {
    PLASTIC("TrashType.plastic"),
    PAPER("TrashType.paper"),
    TRASH("TrashType.trash"),
    BIO("TrashType.bio")
}

data class TrashPickup(
    val date: Date,
    val type: TrashType,
    val daysUntil: Long
)

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget)
    
    // Add click intent to open the app
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    if (intent != null) {
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
    }
    
    // Get next pickup from SharedPreferences
    val nextPickup = getNextTrashPickup(context)
    
    if (nextPickup != null) {
        // Hide the app icon and show the text views
        views.setViewVisibility(R.id.app_icon, View.GONE)
        views.setViewVisibility(R.id.days_until_text, View.VISIBLE)
        views.setViewVisibility(R.id.pickup_date_text, View.VISIBLE)
        
        // Set the days until text
        val daysText = when (nextPickup.daysUntil) {
            0L -> context.getString(R.string.today)
            1L -> context.getString(R.string.tomorrow)
            else -> context.getString(R.string.days_left, nextPickup.daysUntil.toInt())
        }
        views.setTextViewText(R.id.days_until_text, daysText)
        // Set normal text size for pickup information
        views.setFloat(R.id.days_until_text, "setTextSize", 20f)
        
        // Set the date text
        val dateFormat = SimpleDateFormat("MMM d", Locale.getDefault())
        val dayFormat = SimpleDateFormat("EEEE", Locale.getDefault())
        val dateText = "${dayFormat.format(nextPickup.date)}, ${dateFormat.format(nextPickup.date)}"
        views.setTextViewText(R.id.pickup_date_text, dateText)
        
        // Set colors based on trash type (no icon needed)
        
        when (nextPickup.type) {
            TrashType.PLASTIC -> {
                views.setInt(R.id.widget_container, "setBackgroundResource", 
                    R.drawable.widget_background_plastic)
                // Use black text on yellow background for both light and dark mode
                views.setTextColor(R.id.days_until_text, 
                    ContextCompat.getColor(context, android.R.color.black))
                views.setTextColor(R.id.pickup_date_text, 
                    ContextCompat.getColor(context, android.R.color.black))
            }
            TrashType.PAPER -> {
                views.setInt(R.id.widget_container, "setBackgroundResource", 
                    R.drawable.widget_background_paper)
                views.setTextColor(R.id.days_until_text, 
                    ContextCompat.getColor(context, R.color.widget_text_on_dark))
                views.setTextColor(R.id.pickup_date_text, 
                    ContextCompat.getColor(context, R.color.widget_text_secondary_on_dark))
            }
            TrashType.TRASH -> {
                views.setInt(R.id.widget_container, "setBackgroundResource", 
                    R.drawable.widget_background_trash)
                views.setTextColor(R.id.days_until_text, 
                    ContextCompat.getColor(context, R.color.widget_text_on_dark))
                views.setTextColor(R.id.pickup_date_text, 
                    ContextCompat.getColor(context, R.color.widget_text_secondary_on_dark))
            }
            TrashType.BIO -> {
                views.setInt(R.id.widget_container, "setBackgroundResource", 
                    R.drawable.widget_background_bio)
                views.setTextColor(R.id.days_until_text, 
                    ContextCompat.getColor(context, R.color.widget_text_on_dark))
                views.setTextColor(R.id.pickup_date_text, 
                    ContextCompat.getColor(context, R.color.widget_text_secondary_on_dark))
            }
        }
    } else {
        // No pickup scheduled - show app icon instead of text
        views.setViewVisibility(R.id.app_icon, View.VISIBLE)
        views.setViewVisibility(R.id.days_until_text, View.GONE)
        views.setViewVisibility(R.id.pickup_date_text, View.GONE)
        
        // Set default background
        views.setInt(R.id.widget_container, "setBackgroundResource", 
            R.drawable.widget_background)
    }

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}

private fun getNextTrashPickup(context: Context): TrashPickup? {
    // Try both possible SharedPreferences files Flutter might use
    val possiblePrefFiles = listOf(
        "FlutterSharedPreferences",
        context.packageName + "_preferences"
    )
    
    var prefs: SharedPreferences? = null
    var prefsFileName = ""
    
    // Find which SharedPreferences file has data
    for (prefFile in possiblePrefFiles) {
        val testPrefs = context.getSharedPreferences(prefFile, Context.MODE_PRIVATE)
        if (testPrefs.all.isNotEmpty()) {
            prefs = testPrefs
            prefsFileName = prefFile
            break
        }
    }
    
    if (prefs == null) {
        // If no prefs found, default to FlutterSharedPreferences
        prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefsFileName = "FlutterSharedPreferences"
    }
    
    // Debug logging to see what keys are available and their values
    Log.d("TrashifierWidget", "=== SharedPreferences Debug ===")
    Log.d("TrashifierWidget", "Using preferences file: $prefsFileName")
    Log.d("TrashifierWidget", "Available SharedPreferences keys: ${prefs.all.keys}")
    Log.d("TrashifierWidget", "Total keys: ${prefs.all.size}")
    
    for ((key, value) in prefs.all) {
        Log.d("TrashifierWidget", "Key: '$key', Value: '$value' (${value?.javaClass?.simpleName})")
    }
    Log.d("TrashifierWidget", "=== End SharedPreferences Debug ===")
    
    val currentTime = System.currentTimeMillis()
    val today = Calendar.getInstance().apply {
        timeInMillis = currentTime
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }
    
    val allPickups = mutableListOf<TrashPickup>()
    
    // Load dates for each trash type using the Flutter SharedPreferences format
    for (trashType in TrashType.values()) {
        Log.d("TrashifierWidget", "Looking for key: ${trashType.key}")
        
        // Based on debug logs, Flutter uses "flutter.TrashType.xxx" format
        val possibleKeys = listOf(
            "flutter.${trashType.key}",  // "flutter.TrashType.plastic" - This is the correct format!
            trashType.key,  // "TrashType.plastic"
            trashType.name.lowercase(),  // "plastic"
            "TrashType.${trashType.name.lowercase()}",  // "TrashType.plastic"
            // Also try with flutter prefix variations
            "flutter.${trashType.name.lowercase()}",
            "flutter.TrashType.${trashType.name.lowercase()}"
        )
        
        var dateStrings: Collection<String> = emptyList()
        var foundKey = ""
        
        for (key in possibleKeys) {
            try {
                // Check if this key exists first
                if (!prefs.contains(key)) {
                    continue
                }
                
                val rawValue = prefs.all[key]
                Log.d("TrashifierWidget", "Key '$key' exists with raw value: '$rawValue' (${rawValue?.javaClass?.simpleName})")
                
                // Try different value types
                when (rawValue) {
                    is String -> {
                        if (rawValue.isNotEmpty()) {
                            Log.d("TrashifierWidget", "Processing String value for $key: $rawValue")
                            
                            // Flutter SharedPreferences stores data with a prefix and ! separator
                            var actualData = rawValue
                            if (rawValue.contains("!")) {
                                actualData = rawValue.substringAfter("!")
                                Log.d("TrashifierWidget", "Extracted actual data after '!': $actualData")
                            }
                            
                            // Check if it's a JSON array format
                            if (actualData.startsWith("[") && actualData.endsWith("]")) {
                                val cleanedString = actualData.substring(1, actualData.length - 1)
                                if (cleanedString.isNotEmpty()) {
                                    dateStrings = cleanedString.split(",")
                                        .map { it.trim().replace("\"", "").replace("'", "") }
                                        .filter { it.isNotEmpty() && it != "null" }
                                    foundKey = key
                                    Log.d("TrashifierWidget", "Parsed JSON array for $key: $dateStrings")
                                    break
                                }
                            } else {
                                // Maybe it's just a single date string?
                                dateStrings = listOf(actualData)
                                foundKey = key
                                Log.d("TrashifierWidget", "Using single string for $key: $actualData")
                                break
                            }
                        }
                    }
                    is Set<*> -> {
                        @Suppress("UNCHECKED_CAST")
                        val stringSet = rawValue as? Set<String>
                        if (stringSet != null && stringSet.isNotEmpty()) {
                            dateStrings = stringSet
                            foundKey = key
                            Log.d("TrashifierWidget", "Found StringSet for $key: $stringSet")
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("TrashifierWidget", "Error reading key $key: ${e.message}")
            }
        }
        
        if (dateStrings.isEmpty()) {
            Log.d("TrashifierWidget", "No data found for ${trashType.key}")
        } else {
            Log.d("TrashifierWidget", "Processing ${dateStrings.size} dates for ${trashType.key} from key '$foundKey'")
        }
        
        for (dateString in dateStrings) {
            try {
                // Parse ISO8601 date string
                val date = Date.from(java.time.Instant.parse(dateString))
                val pickupCalendar = Calendar.getInstance().apply {
                    time = date
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                
                // Only include future dates or today (if before 8 AM)
                if (pickupCalendar.timeInMillis >= today.timeInMillis ||
                    (pickupCalendar.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR) &&
                     pickupCalendar.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                     Calendar.getInstance().get(Calendar.HOUR_OF_DAY) < 8)) {
                    
                    val daysUntil = TimeUnit.MILLISECONDS.toDays(
                        pickupCalendar.timeInMillis - today.timeInMillis
                    )
                    
                    allPickups.add(TrashPickup(date, trashType, daysUntil))
                }
            } catch (e: Exception) {
                // Skip invalid dates
                continue
            }
        }
    }
    
    // Return the earliest pickup
    return allPickups.minByOrNull { it.daysUntil }
}