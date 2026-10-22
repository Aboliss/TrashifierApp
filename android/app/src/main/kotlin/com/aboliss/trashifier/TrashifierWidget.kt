package com.aboliss.trashifier

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.text.format.DateFormat
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.annotation.ColorRes
import androidx.annotation.IdRes
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
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
 * the same day, their colors are shown side by side (up to four; with more,
 * three and a "+N").
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

/** 1x1 widget: just Bin Buddy, opening the app. */
class TrashifierLogoWidget : TrashifierWidgetProvider(WidgetStyle.LOGO)

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
        TrashifierWidget.syncUpdateSchedule(context)
    }

    override fun onEnabled(context: Context) {
        TrashifierWidget.syncUpdateSchedule(context)
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
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean, season: Season) =
            renderBold(context, now, narrow, season)
    },
    CLEAN(TrashifierCleanWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean, season: Season) =
            renderClean(context, now, narrow, season)
    },
    WIDE(TrashifierWideWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean, season: Season) =
            renderWide(context, now, season)
    },
    LOGO(TrashifierLogoWidget::class.java) {
        override fun render(context: Context, now: LocalDateTime, narrow: Boolean, season: Season) =
            renderLogo(context, season)
    };

    /** [narrow]: about two home screen cells wide, where text and icons compete. */
    abstract fun render(
        context: Context,
        now: LocalDateTime,
        narrow: Boolean,
        season: Season
    ): RemoteViews

    fun widgetIds(context: Context, appWidgetManager: AppWidgetManager): IntArray =
        appWidgetManager.getAppWidgetIds(ComponentName(context, provider))

    fun update(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        // The portrait width; 0 when the launcher doesn't report sizes.
        val widthDp = appWidgetManager.getAppWidgetOptions(appWidgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val narrow = widthDp in 1 until NARROW_WIDTH_DP
        val now = LocalDateTime.now()
        // Texts in the language picked in the app (or the phone's).
        val localized = localizedContext(context)
        val views = render(localized, now, narrow, seasonFor(context, now.toLocalDate()))
        openAppOnClick(context, views)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

/**
 * A bin as the app stores it (`flutter.bins`, see BinService and TrashType in
 * Dart): a built-in or a custom bin with its name, color and icon.
 */
data class WidgetBin(
    val id: String,
    val position: Int,
    val customName: String?,
    val color: Int,
    val icon: Int
) {
    val isBuiltIn: Boolean get() = id in BUILT_IN_IDS

    /** Where the app keeps the bin's dates (TrashType.storageKey in Dart). */
    val prefsKey: String get() = if (isBuiltIn) "flutter.TrashType.$id" else "flutter.bin.$id"

    val paint: BinPaint get() = BIN_PAINTS[color.coerceIn(BIN_PAINTS.indices)]
}

private val BUILT_IN_IDS = listOf("plastic", "paper", "trash", "bio")

/** Bin colors as values; mirrors BinStyle.colors in lib/models/bin_style.dart. */
class BinPaint(
    val day: Int,
    /** Fill in dark mode (BinColor.darkMode). */
    val night: Int,
    /** Brighter version for small marks on dark surfaces (BinColor.onDark). */
    val onDark: Int,
    /** Ink rather than white text and icons on this color. */
    val darkText: Boolean
)

private fun paint(day: Long, night: Long = day, onDark: Long = day, darkText: Boolean = false) =
    BinPaint(day.toInt(), night.toInt(), onDark.toInt(), darkText)

private val BIN_PAINTS = arrayOf(
    paint(0xFFFFC83D, darkText = true),
    paint(0xFF2F6BEA),
    paint(0xFF454C55, night = 0xFF6B737D, onDark = 0xFF8E98A3),
    paint(0xFF13804A, onDark = 0xFF2FB36E),
    paint(0xFF0B7F7B, onDark = 0xFF22B3AD),
    paint(0xFF8E44AD, onDark = 0xFFB67AD1),
    paint(0xFF5A7A1C, onDark = 0xFF8DB33F),
    paint(0xFF8B5E3C, onDark = 0xFFB98560),
    paint(0xFFE0A04A, darkText = true),
    paint(0xFFC62F36, onDark = 0xFFE5565C),
    paint(0xFFC2185B, onDark = 0xFFE04C86),
    paint(0xFF6EC6F5, darkText = true)
)

/** White stroke icons in BinStyle.icons order (lib/models/bin_style.dart). */
private val BIN_ICONS = intArrayOf(
    R.drawable.ic_bin_plastic, R.drawable.ic_bin_paper, R.drawable.ic_bin_trash,
    R.drawable.ic_bin_bio, R.drawable.ic_bin_glass, R.drawable.ic_bin_shirt,
    R.drawable.ic_bin_tree, R.drawable.ic_bin_sofa, R.drawable.ic_bin_box,
    R.drawable.ic_bin_battery, R.drawable.ic_bin_can, R.drawable.ic_bin_bag,
    R.drawable.ic_bin_bulb, R.drawable.ic_bin_recycle, R.drawable.ic_bin_phone,
    R.drawable.ic_bin_drop
)

private const val BINS_KEY = "flutter.bins"
private const val MAX_BINS = 10

/**
 * The visible bins in the user's order. Mirrors BinService.decode in Dart
 * loosely: anything unreadable falls back to the four built-ins.
 */
internal fun readBins(prefs: SharedPreferences): List<WidgetBin> {
    val builtIns = BUILT_IN_IDS.mapIndexed { i, id -> WidgetBin(id, i, null, i, i) }
    val raw = try {
        prefs.getString(BINS_KEY, null)
    } catch (e: ClassCastException) {
        null
    } ?: return builtIns
    return try {
        val array = JSONArray(raw)
        val bins = mutableListOf<WidgetBin>()
        for (i in 0 until minOf(array.length(), MAX_BINS)) {
            val json = array.optJSONObject(i) ?: continue
            val id = json.optString("id")
            if (id.isEmpty() || bins.any { it.id == id }) continue
            if (json.optBoolean("hidden", false)) continue
            val name = json.optString("name").takeIf { json.has("name") && it.isNotBlank() }
            if (id !in BUILT_IN_IDS && name == null) continue
            bins.add(
                WidgetBin(
                    id = id,
                    position = i,
                    customName = name?.take(24),
                    color = json.optInt("color", 0).coerceIn(BIN_PAINTS.indices),
                    icon = json.optInt("icon", 0).coerceIn(BIN_ICONS.indices)
                )
            )
        }
        bins
    } catch (e: JSONException) {
        Log.w(TAG, "Could not parse the bin list", e)
        builtIns
    }
}

/**
 * [bin]'s icon as a white bitmap, drawn here so that no drawable resource ID
 * reaches the launcher (see setDayNightColor). Tint it with setColorFilter.
 */
private fun iconBitmap(context: Context, bin: WidgetBin, sizeDp: Int): Bitmap? {
    val drawable = ContextCompat.getDrawable(context, BIN_ICONS[bin.icon]) ?: return null
    val size = dp(context, sizeDp)
    return drawable.toBitmap(size, size)
}

/** The bins that get a slot: all of them if they fit, else one slot fewer and a "+N". */
private fun shownBins(bins: List<WidgetBin>, slots: Int): List<WidgetBin> =
    if (bins.size > slots) bins.take(slots - 1) else bins

data class NextPickup(
    val date: LocalDate,
    /** In the user's bin order. */
    val types: List<WidgetBin>,
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

// Positional slots: the day's first bins in the user's order. Up to four
// show; with more, three show and a "+N" stands for the rest.
private val BOLD_ICON_SLOTS =
    intArrayOf(R.id.icon_slot_0, R.id.icon_slot_1, R.id.icon_slot_2, R.id.icon_slot_3)
private val BOLD_ICONS = intArrayOf(R.id.icon_0, R.id.icon_1, R.id.icon_2, R.id.icon_3)
private val CLEAN_TOKENS =
    intArrayOf(R.id.token_0, R.id.token_1, R.id.token_2, R.id.token_3)
private val CLEAN_TOKEN_BGS =
    intArrayOf(R.id.token_bg_0, R.id.token_bg_1, R.id.token_bg_2, R.id.token_bg_3)
private val CLEAN_TOKEN_ICONS =
    intArrayOf(R.id.token_icon_0, R.id.token_icon_1, R.id.token_icon_2, R.id.token_icon_3)
private val CLEAN_DOTS =
    intArrayOf(R.id.clean_dot_0, R.id.clean_dot_1, R.id.clean_dot_2, R.id.clean_dot_3)
private const val SLOTS = 4

private val WIDE_COLUMNS =
    intArrayOf(R.id.wide_col_0, R.id.wide_col_1, R.id.wide_col_2, R.id.wide_col_3)
private val WIDE_WHEN =
    intArrayOf(R.id.wide_when_0, R.id.wide_when_1, R.id.wide_when_2, R.id.wide_when_3)
private val WIDE_DAY =
    intArrayOf(R.id.wide_day_0, R.id.wide_day_1, R.id.wide_day_2, R.id.wide_day_3)
private val WIDE_DOTS = arrayOf(
    intArrayOf(R.id.wide_dot_0_0, R.id.wide_dot_0_1, R.id.wide_dot_0_2, R.id.wide_dot_0_3),
    intArrayOf(R.id.wide_dot_1_0, R.id.wide_dot_1_1, R.id.wide_dot_1_2, R.id.wide_dot_1_3),
    intArrayOf(R.id.wide_dot_2_0, R.id.wide_dot_2_1, R.id.wide_dot_2_2, R.id.wide_dot_2_3),
    intArrayOf(R.id.wide_dot_3_0, R.id.wide_dot_3_1, R.id.wide_dot_3_2, R.id.wide_dot_3_3)
)
private val WIDE_MORE =
    intArrayOf(R.id.wide_more_0, R.id.wide_more_1, R.id.wide_more_2, R.id.wide_more_3)

// Date skeletons, turned into each language's pattern by formatDate.
private const val DATE_SKELETON = "EEEEMMMd"
private const val NARROW_DATE_SKELETON = "EEEMMMd"
private const val SHORT_DAY_SKELETON = "EEEd"

/** Languages the app is translated into; mirrors LocaleService.languages. */
private val APP_LANGUAGES = setOf("en", "de", "es", "sk")

// Written by the app's Settings (LocaleService); "system" or missing follows
// the phone.
private const val LANGUAGE_KEY = "flutter.app_language"

/** [context] with the app language picked in Settings, if any. */
internal fun localizedContext(context: Context): Context {
    val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
    val language = try {
        prefs.getString(LANGUAGE_KEY, null)
    } catch (e: ClassCastException) {
        null
    }
    if (language == null || language !in APP_LANGUAGES) return context
    val config = Configuration(context.resources.configuration)
    config.setLocale(Locale.forLanguageTag(language))
    return context.createConfigurationContext(config)
}

/** The language of [context]'s texts; English when the app has no translation. */
private fun appLocale(context: Context): Locale {
    val locale = context.resources.configuration.locales[0]
    return if (locale.language in APP_LANGUAGES) locale else Locale.ENGLISH
}

/** [date] in the app language, e.g. "Friday, Oct 16" or "Freitag, 16. Okt.". */
private fun formatDate(context: Context, date: LocalDate, skeleton: String): String {
    val locale = appLocale(context)
    val pattern = DateFormat.getBestDateTimePattern(locale, skeleton)
    // Spanish and Slovak weekdays are lowercase; these start a line.
    return DateTimeFormatter.ofPattern(pattern, locale).format(date)
        .replaceFirstChar { it.titlecase(locale) }
}

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
    else -> context.resources.getQuantityString(
        R.plurals.in_days, daysUntil.toInt(), daysUntil.toInt()
    )
}

private fun typeName(context: Context, bin: WidgetBin): String = bin.customName
    ?: context.getString(
        when (bin.id) {
            "plastic" -> R.string.plastic_trash
            "paper" -> R.string.paper_trash
            "trash" -> R.string.general_trash
            else -> R.string.bio_trash
        }
    )

/** "Next pickup Tomorrow, Friday, Oct 16: Plastic, Paper" for screen readers. */
private fun describe(context: Context, pickup: NextPickup): String =
    context.getString(
        R.string.next_pickup_description,
        daysText(context, pickup.daysUntil),
        formatDate(context, pickup.date, DATE_SKELETON),
        pickup.types.joinToString(", ") { typeName(context, it) }
    )

private fun setVisible(views: RemoteViews, @IdRes viewId: Int, visible: Boolean) {
    views.setViewVisibility(viewId, if (visible) View.VISIBLE else View.GONE)
}

/**
 * The Bold and Clean widgets show their day text in one of two columns: a
 * narrow one whose text shrinks to fit, and one for wider sizes whose text
 * keeps its natural width so the Halloween spider can hang right next to it.
 */
private class DayText(
    @IdRes val narrowColumn: Int,
    @IdRes val wideColumn: Int,
    @IdRes val days: IntArray,
    @IdRes val date: IntArray
) {
    fun show(views: RemoteViews, narrow: Boolean) {
        setVisible(views, narrowColumn, narrow)
        setVisible(views, wideColumn, !narrow)
    }

    fun setText(views: RemoteViews, daysText: String, dateText: String) {
        days.forEach { views.setTextViewText(it, daysText) }
        date.forEach { views.setTextViewText(it, dateText) }
    }

    fun setColors(
        context: Context,
        views: RemoteViews,
        @ColorRes daysColor: Int,
        @ColorRes dateColor: Int
    ) {
        days.forEach { setDayNightColor(context, views, it, "setTextColor", daysColor) }
        date.forEach { setDayNightColor(context, views, it, "setTextColor", dateColor) }
    }
}

private val BOLD_TEXT = DayText(
    R.id.bold_text_narrow,
    R.id.bold_text_wide,
    intArrayOf(R.id.days_until_text, R.id.days_until_text_wide),
    intArrayOf(R.id.pickup_date_text, R.id.pickup_date_text_wide)
)

private val CLEAN_TEXT = DayText(
    R.id.clean_text_narrow,
    R.id.clean_text_wide,
    intArrayOf(R.id.clean_days_text, R.id.clean_days_text_wide),
    intArrayOf(R.id.clean_date_text, R.id.clean_date_text_wide)
)

/**
 * Content row padding. Christmas adds room under the lights; otherwise there
 * is none on top, so the Halloween spider's thread starts at the top edge
 * (padding would clip it). The content is centered vertically either way.
 */
private fun padUnderLights(
    context: Context,
    views: RemoteViews,
    @IdRes contentId: Int,
    season: Season
) {
    val top = if (season == Season.CHRISTMAS) 24 else 0
    views.setViewPadding(contentId, dp(context, 18), dp(context, top), dp(context, 14), dp(context, 10))
}

internal fun renderBold(
    context: Context,
    now: LocalDateTime,
    narrow: Boolean,
    season: Season
): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget)
    val nextPickup = findNextPickups(context, now, 1).firstOrNull()

    BOLD_TEXT.show(views, narrow)
    setVisible(views, R.id.bold_lights, season == Season.CHRISTMAS)
    padUnderLights(context, views, R.id.bold_content, season)
    // Only in the wide text column, so only at the wider sizes.
    setVisible(views, R.id.bold_spider, season == Season.HALLOWEEN && nextPickup != null)

    if (nextPickup == null) {
        // No pickup planned: Bin Buddy on the ink background, when it fits.
        setVisible(views, R.id.app_icon, !narrow)
        BOLD_TEXT.setText(
            views,
            context.getString(R.string.no_pickup_scheduled),
            context.getString(R.string.tap_to_add)
        )
        BOLD_TEXT.setColors(
            context, views, R.color.widget_text_on_dark, R.color.widget_text_secondary_on_dark
        )
        showSegments(context, views, emptyList())
        BOLD_ICON_SLOTS.forEach { setVisible(views, it, false) }
        setVisible(views, R.id.bold_more, false)
        return views
    }

    setVisible(views, R.id.app_icon, false)
    BOLD_TEXT.setText(
        views,
        daysText(context, nextPickup.daysUntil),
        formatDate(context, nextPickup.date, if (narrow) NARROW_DATE_SKELETON else DATE_SKELETON)
    )
    views.setContentDescription(R.id.widget_container, describe(context, nextPickup))

    val shownTypes = shownBins(nextPickup.types, SLOTS)
    showSegments(context, views, shownTypes)

    // White text is unreadable on light colors (yellow, ochre, sky), while
    // ink still reads fine on the darker segments, so any light segment
    // switches the text, icons and spider to ink.
    val darkText = shownTypes.any { it.paint.darkText }
    @ColorRes val primary =
        if (darkText) R.color.widget_ink else R.color.widget_text_on_dark
    @ColorRes val secondary =
        if (darkText) R.color.widget_ink else R.color.widget_text_secondary_on_dark
    BOLD_TEXT.setColors(context, views, primary, secondary)
    setDayNightColor(context, views, R.id.bold_spider, "setColorFilter", primary)

    BOLD_ICON_SLOTS.forEachIndexed { index, slot ->
        val bin = shownTypes.getOrNull(index)
        setVisible(views, slot, !narrow && bin != null)
        if (!narrow && bin != null) {
            views.setImageViewBitmap(BOLD_ICONS[index], iconBitmap(context, bin, 22))
            setDayNightColor(context, views, BOLD_ICONS[index], "setColorFilter", primary)
        }
    }
    val more = nextPickup.types.size - shownTypes.size
    setVisible(views, R.id.bold_more, !narrow && more > 0)
    if (more > 0) {
        views.setTextViewText(R.id.bold_more, "+$more")
        setDayNightColor(context, views, R.id.bold_more, "setTextColor", primary)
    }
    return views
}

internal fun renderClean(
    context: Context,
    now: LocalDateTime,
    narrow: Boolean,
    season: Season
): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget_clean)
    val nextPickup = findNextPickups(context, now, 1).firstOrNull()

    CLEAN_TEXT.show(views, narrow)
    setVisible(views, R.id.clean_bg_normal, season != Season.HALLOWEEN)
    setVisible(views, R.id.clean_bg_halloween, season == Season.HALLOWEEN)
    setVisible(views, R.id.clean_lights, season == Season.CHRISTMAS)
    padUnderLights(context, views, R.id.clean_content, season)
    // Only in the wide text column, so only at the wider sizes.
    setVisible(views, R.id.clean_spider, season == Season.HALLOWEEN && nextPickup != null)
    setDayNightColor(context, views, R.id.clean_spider, "setColorFilter", R.color.widget_clean_text)

    setVisible(views, R.id.clean_buddy, nextPickup == null && !narrow)
    if (nextPickup == null) {
        CLEAN_TEXT.setText(
            views,
            context.getString(R.string.no_pickup_scheduled),
            context.getString(R.string.tap_to_add)
        )
        CLEAN_TOKENS.forEach { setVisible(views, it, false) }
        setVisible(views, R.id.clean_more, false)
        setVisible(views, R.id.clean_dots, false)
        return views
    }

    CLEAN_TEXT.setText(
        views,
        daysText(context, nextPickup.daysUntil),
        formatDate(context, nextPickup.date, if (narrow) NARROW_DATE_SKELETON else DATE_SKELETON)
    )
    views.setContentDescription(R.id.widget_container, describe(context, nextPickup))
    setVisible(views, R.id.clean_dots, narrow)
    val shownTypes = shownBins(nextPickup.types, SLOTS)
    for (index in 0 until SLOTS) {
        val bin = shownTypes.getOrNull(index)
        setVisible(views, CLEAN_TOKENS[index], bin != null && !narrow)
        setVisible(views, CLEAN_DOTS[index], bin != null && narrow)
        if (bin == null) continue
        val paint = bin.paint
        if (narrow) {
            setPaint(views, CLEAN_DOTS[index], "setColorFilter", paint.day, paint.night)
        } else {
            setPaint(views, CLEAN_TOKEN_BGS[index], "setColorFilter", paint.day, paint.night)
            views.setImageViewBitmap(CLEAN_TOKEN_ICONS[index], iconBitmap(context, bin, 22))
            val ink = if (paint.darkText) INK else WHITE
            setPaint(views, CLEAN_TOKEN_ICONS[index], "setColorFilter", ink, ink)
        }
    }
    val more = nextPickup.types.size - shownTypes.size
    setVisible(views, R.id.clean_more, more > 0 && !narrow)
    setVisible(views, R.id.clean_dots_more, more > 0 && narrow)
    views.setTextViewText(R.id.clean_more, "+$more")
    views.setTextViewText(R.id.clean_dots_more, "+$more")
    return views
}

internal fun renderWide(context: Context, now: LocalDateTime, season: Season): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget_wide)
    val pickups = findNextPickups(context, now, WIDE_COLUMNS.size)

    setVisible(views, R.id.wide_bg_normal, season == Season.NONE)
    setVisible(views, R.id.wide_bg_halloween, season == Season.HALLOWEEN)
    setVisible(views, R.id.wide_bg_christmas, season == Season.CHRISTMAS)
    setVisible(views, R.id.wide_lights, season == Season.CHRISTMAS)
    // Room under the lights.
    val padding = dp(context, 8)
    val top = if (season == Season.CHRISTMAS) dp(context, 22) else padding
    views.setViewPadding(R.id.wide_content, padding, top, padding, padding)
    // "Tomorrow" in the season's accent: yellow, pumpkin orange or gold.
    setDayNightColor(
        context, views, WIDE_WHEN[0], "setTextColor",
        when (season) {
            Season.HALLOWEEN -> R.color.widget_accent_halloween
            Season.CHRISTMAS -> R.color.widget_accent_christmas
            Season.NONE -> R.color.widget_wide_accent
        }
    )

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
        views.setTextViewText(WIDE_DAY[column], formatDate(context, pickup.date, SHORT_DAY_SKELETON))
        val shownTypes = shownBins(pickup.types, SLOTS)
        WIDE_DOTS[column].forEachIndexed { index, dot ->
            val bin = shownTypes.getOrNull(index)
            setVisible(views, dot, bin != null)
            // Marks on the dark Wide background use the brighter variants.
            if (bin != null) setPaint(views, dot, "setColorFilter", bin.paint.onDark, bin.paint.onDark)
        }
        val more = pickup.types.size - shownTypes.size
        setVisible(views, WIDE_MORE[column], more > 0)
        views.setTextViewText(WIDE_MORE[column], "+$more")
    }
    return views
}

internal fun renderLogo(context: Context, season: Season): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.trashifier_widget_logo)
    setVisible(views, R.id.logo_bg_normal, season == Season.NONE)
    setVisible(views, R.id.logo_bg_halloween, season == Season.HALLOWEEN)
    setVisible(views, R.id.logo_bg_christmas, season == Season.CHRISTMAS)
    setVisible(views, R.id.logo_buddy_normal, season == Season.NONE)
    setVisible(views, R.id.logo_buddy_pumpkin, season == Season.HALLOWEEN)
    setVisible(views, R.id.logo_buddy_santa, season == Season.CHRISTMAS)
    return views
}

private fun dp(context: Context, value: Int): Int =
    (value * context.resources.displayMetrics.density).toInt()

/** Seasonal look of the widgets; mirrors Season in lib/models/season.dart. */
enum class Season { NONE, HALLOWEEN, CHRISTMAS }

// Written by the app's debug panel (SeasonService); "auto" when missing.
private const val SEASON_OVERRIDE_KEY = "flutter.season_override"

/**
 * Halloween in October, Christmas in December, unless the app's debug panel
 * forces one. Keep in sync with SeasonHelper.seasonFor in Dart.
 */
internal fun seasonFor(context: Context, date: LocalDate): Season {
    val prefs = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
    val override = try {
        prefs.getString(SEASON_OVERRIDE_KEY, null)
    } catch (e: ClassCastException) {
        null
    }
    return when (override) {
        "normal" -> Season.NONE
        "halloween" -> Season.HALLOWEEN
        "christmas" -> Season.CHRISTMAS
        else -> when (date.monthValue) {
            10 -> Season.HALLOWEEN
            12 -> Season.CHRISTMAS
            else -> Season.NONE
        }
    }
}

/**
 * Segment i shows the left (i + 1) / n of the rounded segment shape, tinted
 * with its bin color. Stacked with the left-most type on top, this renders n
 * equal side-by-side segments.
 */
private fun showSegments(context: Context, views: RemoteViews, types: List<WidgetBin>) {
    SEGMENT_VIEWS.forEachIndexed { index, viewId ->
        if (index < types.size) {
            views.setViewVisibility(viewId, View.VISIBLE)
            setPaint(views, viewId, "setColorFilter", types[index].paint.day, types[index].paint.night)
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

/** Like [setDayNightColor], for color values (bin colors). */
private fun setPaint(views: RemoteViews, viewId: Int, method: String, day: Int, night: Int) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        views.setColorInt(viewId, method, day, night)
    } else {
        views.setInt(viewId, method, day)
    }
}

private const val INK = 0xFF16201B.toInt()
private const val WHITE = 0xFFFFFFFF.toInt()

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
    val typesByDate = sortedMapOf<LocalDate, MutableList<WidgetBin>>()

    // readBins keeps the user's order, so each day's list follows it.
    for (bin in readBins(prefs)) {
        for (date in readDates(prefs, bin.prefsKey).distinct()) {
            val upcoming = date.isAfter(today) ||
                (date == today && now.hour < PICKUP_CUTOFF_HOUR)
            if (upcoming) {
                typesByDate.getOrPut(date) { mutableListOf() }.add(bin)
            }
        }
    }

    return typesByDate.entries.take(limit).map { (date, types) ->
        NextPickup(date, types, ChronoUnit.DAYS.between(today, date))
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
