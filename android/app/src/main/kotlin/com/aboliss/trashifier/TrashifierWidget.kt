package com.aboliss.trashifier

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.ColorRes
import androidx.annotation.IdRes
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
 * Bold widget: the next pickup on its bin colors. When several bins go out on
 * the same day, their colors are shown side by side (up to [MAX_SEGMENTS]).
 *
 * Keeps its original class name so widgets placed before the Clean and Wide
 * styles existed keep working.
 */
class TrashifierWidget : TrashifierWidgetProvider(WidgetStyle.BOLD) {
    companion object {
        /** Redraws every placed widget of every style. Called from Flutter. */
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            for (style in WidgetStyle.values()) {
                for (appWidgetId in style.widgetIds(context, appWidgetManager)) {
                    style.update(context, appWidgetManager, appWidgetId)
                }
            }
        }

        /**
         * Schedules the periodic refresh while any widget is placed. Called on
         * app start so installs that already have a widget get the schedule
         * without the widget being re-added.
         */
        fun syncUpdateSchedule(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val anyPlaced = WidgetStyle.values().any {
                it.widgetIds(context, appWidgetManager).isNotEmpty()
            }
            if (anyPlaced) {
                WidgetUpdateWorker.schedule(context)
            } else {
                WidgetUpdateWorker.cancel(context)
            }
        }
    }
}

/** Clean widget: the next pickup on a plain card, bins as round tokens. */
class TrashifierCleanWidget : TrashifierWidgetProvider(WidgetStyle.CLEAN)

/** Wide widget: the next four collection days with a dot per bin. */
class TrashifierWideWidget : TrashifierWidgetProvider(WidgetStyle.WIDE)

abstract class TrashifierWidgetProvider(private val style: WidgetStyle) :
    AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            style.update(context, appWidgetManager, appWidgetId)
        }
        WidgetUpdateWorker.schedule(context)
    }

    override fun onEnabled(context: Context) {
        WidgetUpdateWorker.schedule(context)
    }

    // Only the last widget of this style is gone; others may remain.
    override fun onDisabled(context: Context) {
        TrashifierWidget.syncUpdateSchedule(context)
    }

    // Resized: switch between the narrow and wide arrangement.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        style.update(context, appWidgetManager, appWidgetId)
    }
}

enum class WidgetStyle(private val provider: Class<out AppWidgetProvider>) {
    BOLD(TrashifierWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean) =
            renderBold(context, now, narrow)
    },
    CLEAN(TrashifierCleanWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean) =
            renderClean(context, now, narrow)
    },
    WIDE(TrashifierWideWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean) =
            renderWide(context, now)
    };

    /** [narrow]: about two home screen cells wide, where text and icons compete. */
    abstract fun render(context: Context, now: LocalDateTime, narrow: Boolean): RemoteViews

    fun widgetIds(context: Context, appWidgetManager: AppWidgetManager): IntArray =
        appWidgetManager.getAppWidgetIds(ComponentName(context, provider))

    fun update(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        // The portrait width; 0 when the launcher doesn't report sizes.
        val widthDp = appWidgetManager.getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val narrow = widthDp in 1 until NARROW_WIDTH_DP
        val views = render(context, LocalDateTime.now(), narrow)
        openAppOnClick(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
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

// Below this width the Bold widget drops its bin icons and the Clean widget
// shows small dots instead of tokens, so the day text stays readable.
private const val NARROW_WIDTH_DP = 250

// Top-most first: segment_1 is drawn above segment_2 and so on.
private val SEGMENT_VIEWS =
    intArrayOf(R.id.segment_1, R.id.segment_2, R.id.segment_3, R.id.segment_4)

// One segment per trash type, so every same-day combination fits.
private val MAX_SEGMENTS = SEGMENT_VIEWS.size

// Per-type views, in TrashType order.
private val BOLD_ICON_SLOTS = intArrayOf(
    R.id.icon_slot_plastic, R.id.icon_slot_paper, R.id.icon_slot_trash, R.id.icon_slot_bio
)
private val BOLD_ICONS =
    intArrayOf(R.id.icon_plastic, R.id.icon_paper, R.id.icon_trash, R.id.icon_bio)
private val CLEAN_TOKENS =
    intArrayOf(R.id.token_plastic, R.id.token_paper, R.id.token_trash, R.id.token_bio)
private val CLEAN_DOTS =
    intArrayOf(R.id.clean_dot_plastic, R.id.clean_dot_paper, R.id.clean_dot_trash, R.id.clean_dot_bio)

private val WIDE_COLUMNS =
    intArrayOf(R.id.wide_col_0, R.id.wide_col_1, R.id.wide_col_2, R.id.wide_col_3)
private val WIDE_WHEN =
    intArrayOf(R.id.wide_when_0, R.id.wide_when_1, R.id.wide_when_2, R.id.wide_when_3)
private val WIDE_DAY =
    intArrayOf(R.id.wide_day_0, R.id.wide_day_1, R.id.wide_day_2, R.id.wide_day_3)
private val WIDE_DOTS = arrayOf(
    intArrayOf(R.id.wide_dot_0_plastic, R.id.wide_dot_0_paper, R.id.wide_dot_0_trash, R.id.wide_dot_0_bio),
    intArrayOf(R.id.wide_dot_1_plastic, R.id.wide_dot_1_paper, R.id.wide_dot_1_trash, R.id.wide_dot_1_bio),
    intArrayOf(R.id.wide_dot_2_plastic, R.id.wide_dot_2_paper, R.id.wide_dot_2_trash, R.id.wide_dot_2_bio),
    intArrayOf(R.id.wide_dot_3_plastic, R.id.wide_dot_3_paper, R.id.wide_dot_3_trash, R.id.wide_dot_3_bio)
)

// English to match the rest of the app's UI.
private val DATE_FORMAT = DateTimeFormatter.ofPattern("EEEE, MMM d", Locale.ENGLISH)
private val NARROW_DATE_FORMAT = DateTimeFormatter.ofPattern("EEE, MMM d", Locale.ENGLISH)
private val SHORT_DAY_FORMAT = DateTimeFormatter.ofPattern("EEE d", Locale.ENGLISH)

private fun openAppOnClick(context: Context, views: RemoteViews) {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: return
    val pendingIntent = PendingIntent.getActivity(
        context,
        0,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
}

private fun daysText(context: Context, daysUntil: Long): String = when (daysUntil) {
    0L -> context.getString(R.string.today)
    1L -> context.getString(R.string.tomorrow)
    else -> context.getString(R.string.in_days, daysUntil.toInt())
}

private fun typeName(context: Context, type: TrashType): String = context.getString(
    when (type) {
        TrashType.PLASTIC -> R.string.plastic_trash
        TrashType.PAPER -> R.string.paper_trash
        TrashType.TRASH -> R.string.general_trash
        TrashType.BIO -> R.string.bio_trash
    }
)

/** "Next pickup Tomorrow, Friday, Oct 16: Plastic, Paper" for screen readers. */
private fun describe(context: Context, pickup: NextPickup): String =
    context.getString(
        R.string.next_pickup_description,
        daysText(context, pickup.daysUntil),
        DATE_FORMAT.format(pickup.date),
        pickup.types.joinToString(", ") { typeName(context, it) }
    )

private fun setVisible(views: RemoteViews, @IdRes viewId: Int, visible: Boolean) {
    views.setViewVisibility(viewId, if (visible) View.VISIBLE else View.GONE)
}

internal fun renderBold(context: Context, now: LocalDateTime, narrow: Boolean): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget)
    val nextPickup = findNextPickups(context, now, 1).firstOrNull()

    if (nextPickup == null) {
        // No pickup planned: Bin Buddy on the ink background, when it fits.
        setVisible(views, R.id.app_icon, !narrow)
        views.setTextViewText(
            R.id.days_until_text, context.getString(R.string.no_pickup_scheduled)
        )
        views.setTextViewText(R.id.pickup_date_text, context.getString(R.string.tap_to_add))
        setDayNightColor(context, views, R.id.days_until_text, "setTextColor", R.color.widget_text_on_dark)
        setDayNightColor(
            context, views, R.id.pickup_date_text, "setTextColor", R.color.widget_text_secondary_on_dark
        )
        showSegments(context, views, emptyList())
        BOLD_ICON_SLOTS.forEach { setVisible(views, it, false) }
        return views
    }

    setVisible(views, R.id.app_icon, false)
    views.setTextViewText(R.id.days_until_text, daysText(context, nextPickup.daysUntil))
    views.setTextViewText(
        R.id.pickup_date_text,
        (if (narrow) NARROW_DATE_FORMAT else DATE_FORMAT).format(nextPickup.date)
    )
    views.setContentDescription(R.id.widget_container, describe(context, nextPickup))

    val shownTypes = nextPickup.types.take(MAX_SEGMENTS)
    showSegments(context, views, shownTypes)

    // White text is unreadable on yellow (plastic), while ink still reads
    // fine on the blue, grey and green segments, so any light segment
    // switches the text and icons to ink.
    val darkText = shownTypes.any { it.usesDarkText }
    @ColorRes val primary =
        if (darkText) R.color.widget_ink else R.color.widget_text_on_dark
    @ColorRes val secondary =
        if (darkText) R.color.widget_ink else R.color.widget_text_secondary_on_dark
    setDayNightColor(context, views, R.id.days_until_text, "setTextColor", primary)
    setDayNightColor(context, views, R.id.pickup_date_text, "setTextColor", secondary)

    TrashType.values().forEachIndexed { index, type ->
        val shown = !narrow && type in shownTypes
        setVisible(views, BOLD_ICON_SLOTS[index], shown)
        if (shown) {
            setDayNightColor(context, views, BOLD_ICONS[index], "setColorFilter", primary)
        }
    }
    return views
}

internal fun renderClean(context: Context, now: LocalDateTime, narrow: Boolean): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget_clean)
    val nextPickup = findNextPickups(context, now, 1).firstOrNull()

    setVisible(views, R.id.clean_buddy, nextPickup == null && !narrow)
    if (nextPickup == null) {
        views.setTextViewText(
            R.id.clean_days_text, context.getString(R.string.no_pickup_scheduled)
        )
        views.setTextViewText(R.id.clean_date_text, context.getString(R.string.tap_to_add))
        CLEAN_TOKENS.forEach { setVisible(views, it, false) }
        setVisible(views, R.id.clean_dots, false)
        return views
    }

    views.setTextViewText(R.id.clean_days_text, daysText(context, nextPickup.daysUntil))
    views.setTextViewText(
        R.id.clean_date_text,
        (if (narrow) NARROW_DATE_FORMAT else DATE_FORMAT).format(nextPickup.date)
    )
    views.setContentDescription(R.id.widget_container, describe(context, nextPickup))
    setVisible(views, R.id.clean_dots, narrow)
    TrashType.values().forEachIndexed { index, type ->
        val collected = type in nextPickup.types
        setVisible(views, CLEAN_TOKENS[index], collected && !narrow)
        setVisible(views, CLEAN_DOTS[index], collected && narrow)
    }
    return views
}

internal fun renderWide(context: Context, now: LocalDateTime): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget_wide)
    val pickups = findNextPickups(context, now, WIDE_COLUMNS.size)

    setVisible(views, R.id.wide_empty, pickups.isEmpty())
    WIDE_COLUMNS.forEachIndexed { column, columnId ->
        val pickup = pickups.getOrNull(column)
        // Unused columns stay INVISIBLE so the used ones keep their width.
        views.setViewVisibility(
            columnId,
            when {
                pickups.isEmpty() -> View.GONE
                pickup == null -> View.INVISIBLE
                else -> View.VISIBLE
            }
        )
        if (pickup == null) return@forEachIndexed

        views.setTextViewText(WIDE_WHEN[column], daysText(context, pickup.daysUntil))
        views.setTextViewText(WIDE_DAY[column], SHORT_DAY_FORMAT.format(pickup.date))
        TrashType.values().forEachIndexed { index, type ->
            setVisible(views, WIDE_DOTS[column][index], type in pickup.types)
        }
    }
    return views
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
 * The next [limit] collection days, earliest first, each with every bin
 * collected on it. Dates are calendar days: a pickup today counts until
 * [PICKUP_CUTOFF_HOUR].
 */
internal fun findNextPickups(context: Context, now: LocalDateTime, limit: Int): List<NextPickup> {
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

    return typesByDate.entries.take(limit).map { (date, types) ->
        NextPickup(date, types.toList(), ChronoUnit.DAYS.between(today, date))
    }
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
