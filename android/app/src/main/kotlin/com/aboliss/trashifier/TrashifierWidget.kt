package com.aboliss.trashifier

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Build
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.ColorRes
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONException
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException
import java.time.temporal.ChronoUnit
import java.util.Locale

/**
 * Home screen widget showing the next trash pickup. When several bins go out
 * on the same day, their colors are shown side by side (up to [MAX_SEGMENTS]).
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
    }

    companion object {
        /**
         * Method to trigger widget update from Flutter
         */
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TrashifierWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}

/** Must stay in the same order as the Dart `TrashType` enum. */
enum class TrashType(
    val prefsKey: String,
    @ColorRes val color: Int,
    val usesDarkText: Boolean
) {
    PLASTIC("flutter.TrashType.plastic", R.color.plastic_color, true),
    PAPER("flutter.TrashType.paper", R.color.paper_color, false),
    TRASH("flutter.TrashType.trash", R.color.trash_color, false),
    BIO("flutter.TrashType.bio", R.color.bio_color, false)
}

data class NextPickup(
    val date: LocalDate,
    val types: List<TrashType>,
    val daysUntil: Long
)

private const val TAG = "TrashifierWidget"
private const val PREFS_FILE = "FlutterSharedPreferences"

// shared_preferences stores string lists as this prefix followed by JSON.
private const val JSON_LIST_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu!"

// Keep in sync with DateFormatHelper.pickupCutoffHour in Dart.
private const val PICKUP_CUTOFF_HOUR = 8
private const val FULL_LEVEL = 10000

// Top-most first: segment_1 is drawn above segment_2 and so on.
private val SEGMENT_VIEWS =
    intArrayOf(R.id.segment_1, R.id.segment_2, R.id.segment_3, R.id.segment_4)

// One segment per trash type, so every same-day combination fits.
private val MAX_SEGMENTS = SEGMENT_VIEWS.size

// English to match the rest of the app's UI.
private val DATE_FORMAT = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.ENGLISH)

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

    val nextPickup = findNextPickup(context, LocalDateTime.now())

    if (nextPickup != null) {
        views.setViewVisibility(R.id.app_icon, View.GONE)
        views.setViewVisibility(R.id.days_until_text, View.VISIBLE)
        views.setViewVisibility(R.id.pickup_date_text, View.VISIBLE)

        val daysText = when (nextPickup.daysUntil) {
            0L -> context.getString(R.string.today)
            1L -> context.getString(R.string.tomorrow)
            else -> context.getString(R.string.days_left, nextPickup.daysUntil.toInt())
        }
        views.setTextViewText(R.id.days_until_text, daysText)
        views.setTextViewTextSize(R.id.days_until_text, TypedValue.COMPLEX_UNIT_SP, 20f)
        views.setTextViewText(R.id.pickup_date_text, DATE_FORMAT.format(nextPickup.date))

        val shownTypes = nextPickup.types.take(MAX_SEGMENTS)
        showSegments(context, views, shownTypes)

        // White text is unreadable on yellow (plastic), while black still reads
        // fine on the blue, grey and green segments, so any light segment
        // switches the text to black.
        val darkText = shownTypes.any { it.usesDarkText }
        @ColorRes val primary =
            if (darkText) android.R.color.black else R.color.widget_text_on_dark
        @ColorRes val secondary =
            if (darkText) android.R.color.black else R.color.widget_text_secondary_on_dark
        setDayNightColor(context, views, R.id.days_until_text, "setTextColor", primary)
        setDayNightColor(context, views, R.id.pickup_date_text, "setTextColor", secondary)
    } else {
        // No pickup scheduled - show app icon instead of text
        views.setViewVisibility(R.id.app_icon, View.VISIBLE)
        views.setViewVisibility(R.id.days_until_text, View.GONE)
        views.setViewVisibility(R.id.pickup_date_text, View.GONE)
        showSegments(context, views, emptyList())
    }

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}

/**
 * Segment i shows the left (i + 1) / n of the rounded segment shape, tinted
 * with its bin color. Stacked with the left-most type on top, this renders n
 * equal side-by-side segments.
 */
private fun showSegments(context: Context, views: RemoteViews, types: List<TrashType>) {
    SEGMENT_VIEWS.forEachIndexed { index, viewId ->
        if (index < types.size) {
            views.setViewVisibility(viewId, View.VISIBLE)
            setDayNightColor(context, views, viewId, "setColorFilter", types[index].color)
            views.setInt(viewId, "setImageLevel", (index + 1) * FULL_LEVEL / types.size)
        } else {
            views.setViewVisibility(viewId, View.GONE)
        }
    }
}

/**
 * Calls [method] on the view with the color value of [colorRes].
 *
 * Never pass resource IDs to the widget host: IDs shift whenever resources are
 * added, and some launchers (HyperOS) keep resolving them against the
 * pre-update copy of the app, which showed every bin in the wrong color.
 * On Android 12+ both the day and night value are sent so the launcher
 * switches with the system theme.
 */
private fun setDayNightColor(
    context: Context,
    views: RemoteViews,
    viewId: Int,
    method: String,
    @ColorRes colorRes: Int
) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        views.setColorInt(
            viewId,
            method,
            resolveColor(context, colorRes, night = false),
            resolveColor(context, colorRes, night = true)
        )
    } else {
        views.setInt(viewId, method, ContextCompat.getColor(context, colorRes))
    }
}

private fun resolveColor(context: Context, @ColorRes colorRes: Int, night: Boolean): Int {
    val config = Configuration(context.resources.configuration)
    val nightBits = if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
    config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or nightBits
    return ContextCompat.getColor(context.createConfigurationContext(config), colorRes)
}

/**
 * Finds the earliest upcoming pickup day and every bin collected on it.
 * Dates are calendar days: a pickup today counts until [PICKUP_CUTOFF_HOUR].
 */
internal fun findNextPickup(context: Context, now: LocalDateTime): NextPickup? {
    val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
    val today = now.toLocalDate()
    val typesByDate = sortedMapOf<LocalDate, MutableSet<TrashType>>()

    for (type in TrashType.values()) {
        for (date in readDates(prefs, type.prefsKey)) {
            val upcoming = date.isAfter(today) ||
                (date == today && now.hour < PICKUP_CUTOFF_HOUR)
            if (upcoming) {
                typesByDate.getOrPut(date) { sortedSetOf() }.add(type)
            }
        }
    }

    val (date, types) = typesByDate.entries.firstOrNull() ?: return null
    return NextPickup(date, types.toList(), ChronoUnit.DAYS.between(today, date))
}

private fun readDates(prefs: SharedPreferences, key: String): List<LocalDate> {
    val raw = try {
        prefs.getString(key, null)
    } catch (e: ClassCastException) {
        null
    } ?: return emptyList()

    if (!raw.startsWith(JSON_LIST_PREFIX)) {
        Log.w(TAG, "Unexpected format for $key")
        return emptyList()
    }

    return try {
        val array = JSONArray(raw.substring(JSON_LIST_PREFIX.length))
        (0 until array.length()).mapNotNull { parseDate(array.optString(it)) }
    } catch (e: JSONException) {
        Log.w(TAG, "Could not parse $key", e)
        emptyList()
    }
}

/**
 * Accepts `yyyy-MM-dd` and legacy ISO timestamps (`2025-10-05T00:00:00.000Z`).
 * Only the calendar day is used, matching StorageService.decodeDate in Dart.
 */
private fun parseDate(value: String): LocalDate? {
    return try {
        LocalDate.parse(value.take(10))
    } catch (e: DateTimeParseException) {
        null
    }
}
