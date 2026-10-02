import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/calendar_helper.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/services/widget_service.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';
import 'package:trashifier_app/widgets/day_pickups_dialog.dart';
import 'package:trashifier_app/widgets/next_pickup_highlight.dart';
import 'package:trashifier_app/widgets/trash_pickup_timeline.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const int _testNotificationId = 999;

  final Map<TrashType, List<DateTime>> _dates = {
    for (final type in TrashType.values) type: <DateTime>[],
  };

  // Kept in state so rebuilds (e.g. theme changes) don't jump the calendar
  // back to the current month.
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 365));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 365));

  bool _debugMode = false;
  Timer? _debugModeTimer;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadFromStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debugModeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // "Today"/"Tomorrow" labels depend on the current date.
      setState(() {});
      WidgetService.updateWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<ThemeService>().themeMode;
    final upcomingPickups = _getUpcomingPickups();

    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  if (_debugMode) ...[
                    _buildDebugButton(
                      icon: Icons.widgets,
                      color: Colors.teal,
                      onPressed: _debugWidget,
                    ),
                    _buildDebugButton(
                      icon: Icons.bug_report,
                      color: Colors.purple,
                      onPressed: _debugNotificationScheduling,
                    ),
                    _buildDebugButton(
                      icon: Icons.list_alt,
                      color: Colors.blue,
                      onPressed: _showPendingNotifications,
                    ),
                    _buildDebugButton(
                      icon: Icons.notifications_active,
                      color: Colors.orange,
                      onPressed: _scheduleTestNotification,
                    ),
                  ],
                  _buildThemeButton(theme, themeMode),
                ],
              ),
            ),
          ),
          ExpandableFab(
            childrenAnimation: ExpandableFabAnimation.values.first,
            type: ExpandableFabType.up,
            distance: 80,
            overlayStyle: ExpandableFabOverlayStyle(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            openButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: _buildGradientFabContent(theme, Icons.add),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            closeButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: _buildGradientFabContent(theme, Icons.close),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            children: [
              for (final type in TrashType.values)
                FloatingActionButton(
                  heroTag: null,
                  backgroundColor: TrashTypeHelper.getColor(type),
                  onPressed: () => _openAddDatesDialog(context, type),
                  child: Icon(
                    TrashTypeHelper.getIcon(type),
                    color: TrashTypeHelper.getIconColor(type),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: 10,
                          left: 10,
                          top: 10,
                        ),
                        child: NextPickupHighlight(
                          trashDate: upcomingPickups.isEmpty
                              ? null
                              : upcomingPickups.first,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(right: 10, left: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.3),
                        blurRadius: 5,
                        offset: const Offset(5, 5),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                      _openDayPickupsDialog(selectedDay);
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      leftChevronVisible: true,
                      rightChevronVisible: true,
                      formatButtonVisible: false,
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.onSurface,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    calendarFormat: CalendarFormat.month,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) =>
                          _buildCalendarDay(context, day, focusedDay),
                      todayBuilder: (context, day, focusedDay) =>
                          _buildCalendarDay(
                            context,
                            day,
                            focusedDay,
                            isToday: true,
                          ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      defaultTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      weekendTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      outsideTextStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      weekendStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    right: 10,
                    left: 10,
                    bottom: 10,
                  ),
                  child: TrashPickupTimeline(upcomingPickups: upcomingPickups),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildCalendarDay(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool isToday = false,
  }) {
    return CalendarHelper.buildCalendarDay(
      context,
      day,
      focusedDay,
      _dates[TrashType.plastic]!,
      _dates[TrashType.paper]!,
      _dates[TrashType.trash]!,
      _dates[TrashType.bio]!,
      isToday: isToday,
    );
  }

  Widget _buildThemeButton(ThemeData theme, ThemeMode themeMode) {
    final isDark = theme.brightness == Brightness.dark;
    final IconData icon;
    switch (themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
      case ThemeMode.light:
        icon = Icons.light_mode;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
    }

    // No `tooltip` on the FAB: tooltips trigger on long-press and would steal
    // the gesture that unlocks debug mode.
    return GestureDetector(
      onTap: () {
        context.read<ThemeService>().toggleTheme();
      },
      onLongPressStart: (_) => _startDebugModeTimer(),
      onLongPressEnd: (_) => _cancelDebugModeTimer(),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: Colors.transparent,
        elevation: 6,
        onPressed: null,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white : Colors.black,
            border: _debugMode
                ? Border.all(color: Colors.purple, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            size: 30,
            color: isDark ? Colors.black : Colors.white,
            semanticLabel: 'Theme: ${themeMode.name}',
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: Colors.transparent,
      elevation: 6,
      onPressed: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _buildGradientFabContent(ThemeData theme, IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            TrashColors.plasticColor,
            TrashColors.paperColor,
            TrashColors.trashColor,
            TrashColors.bioColor,
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
        ),
        child: Icon(icon, size: 30, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    final loaded = <TrashType, List<DateTime>>{};
    for (final type in TrashType.values) {
      try {
        loaded[type] = await StorageService.instance.loadDates(type);
      } catch (e) {
        debugPrint('Failed to load $type: $e');
        loaded[type] = [];
      }
    }

    if (!mounted) return;
    setState(() => _dates.addAll(loaded));

    // Re-arm reminders on every start: Android drops alarms when the app is
    // force-stopped, updated or the exact alarm permission changes.
    await _syncReminders();
    await WidgetService.updateWidget();
  }

  Future<RescheduleResult?> _syncReminders() async {
    try {
      return await NotificationHelper.rescheduleAll(_dates);
    } catch (e) {
      debugPrint('Failed to sync reminders: $e');
      return null;
    }
  }

  void _openAddDatesDialog(BuildContext context, TrashType type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CalendarDialog(
          type: type,
          color: TrashTypeHelper.getColor(type),
          existingDates: _dates[type]!,
          allPlasticDates: _dates[TrashType.plastic]!,
          allPaperDates: _dates[TrashType.paper]!,
          allGarbageDates: _dates[TrashType.trash]!,
          allBioDates: _dates[TrashType.bio]!,
          onSave: _updateSelectedDates,
        );
      },
    );
  }

  Future<void> _updateSelectedDates(
    Set<DateTime> selectedDates,
    TrashType type,
  ) async {
    await _applyDateChanges({
      type: selectedDates.map(DateFormatHelper.dateOnly).toList()..sort(),
    });
  }

  Future<void> _openDayPickupsDialog(DateTime day) async {
    final selected = await DayPickupsDialog.show(
      context,
      day: day,
      initialTypes: PickupDatesHelper.typesOn(_dates, day),
    );
    if (selected == null || !mounted) return;

    final changes = PickupDatesHelper.setTypesForDay(_dates, day, selected);
    if (changes.isNotEmpty) {
      await _applyDateChanges(changes);
    }
  }

  /// Replaces the dates of the given types, then persists them and re-syncs
  /// reminders and the home screen widget.
  Future<void> _applyDateChanges(Map<TrashType, List<DateTime>> changes) async {
    setState(() => _dates.addAll(changes));

    for (final entry in changes.entries) {
      try {
        // Also refreshes the home screen widget.
        await StorageService.instance.saveDates(entry.value, entry.key);
      } catch (e) {
        _showSnackBar('Failed to save dates: $e', Colors.red);
      }
    }

    await _syncReminders();
  }

  List<TrashDate> _getUpcomingPickups() {
    final now = DateTime.now();
    final upcoming = <TrashDate>[
      for (final entry in _dates.entries)
        for (final date in entry.value)
          if (DateFormatHelper.isFuture(date, now))
            TrashDate(date: date, type: entry.key),
    ];

    upcoming.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.type.index.compareTo(b.type.index);
    });
    return upcoming;
  }

  void _showSnackBar(String message, [Color? color]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _scheduleTestNotification() async {
    try {
      await NotificationService.scheduleNotification(
        _testNotificationId,
        'Test Notification',
        'This is a test notification scheduled 10 seconds ago!',
        DateTime.now().add(const Duration(seconds: 10)),
        exact: await NotificationService.canScheduleExactAlarms(),
      );
      _showSnackBar('Test notification scheduled for 10 seconds from now!');
    } catch (e) {
      _showSnackBar('Failed to schedule test notification: $e', Colors.red);
    }
  }

  Future<void> _debugNotificationScheduling() async {
    try {
      final notificationsEnabled =
          await NotificationService.areNotificationsEnabled();
      final exactAllowed = await NotificationService.canScheduleExactAlarms();
      final pending = await NotificationService.getPendingNotifications();
      final pendingIds = pending.map((n) => n.id).toSet();
      final plan = NotificationHelper.planReminders(_dates);

      final debugInfo = <String>[
        '=== NOTIFICATION DEBUG INFO ===',
        'Notifications enabled: ${notificationsEnabled ? "yes" : "NO"}',
        'Exact alarms allowed: ${exactAllowed ? "yes" : "NO (inexact)"}',
        '',
        'Dates by type:',
        for (final type in TrashType.values)
          '- ${type.name}: ${_dates[type]!.length}',
        '',
        'Planned reminders: ${plan.length}',
        'Pending (plugin cache): ${pending.length}',
        'Missing from cache: '
            '${plan.where((r) => !pendingIds.contains(r.id)).length}',
        '',
        for (final reminder in plan.take(20)) ...[
          '${DateFormatHelper.formatDate(reminder.pickupDate)} '
              '(${reminder.type.name}):',
          '  Reminder: ${_formatDateTime(reminder.time)}',
          '  ID: ${reminder.id}'
              '${pendingIds.contains(reminder.id) ? "" : "  (NOT PENDING)"}',
          '',
        ],
        if (plan.length > 20) '... ${plan.length - 20} more',
      ];

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Debug'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Text(
                debugInfo.join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _forceRescheduleAll();
              },
              child: const Text('Force Reschedule All'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Debug failed: $e', Colors.red);
    }
  }

  Future<void> _forceRescheduleAll() async {
    final result = await _syncReminders();
    if (result == null) {
      _showSnackBar('Failed to reschedule', Colors.red);
      return;
    }
    _showSnackBar(
      'Rescheduled ${result.scheduled} reminders'
      '${result.exact ? "" : " (inexact)"}'
      '${result.failed > 0 ? ", ${result.failed} failed" : ""}',
      result.failed > 0 ? Colors.orange : Colors.green,
    );
  }

  Future<void> _debugWidget() async {
    try {
      await WidgetService.updateWidget();
      _showSnackBar('Widget update triggered!');
    } catch (e) {
      _showSnackBar('Widget update failed: $e', Colors.red);
    }
  }

  void _startDebugModeTimer() {
    _isLongPressing = true;
    _debugModeTimer = Timer(const Duration(seconds: 5), () {
      if (_isLongPressing && mounted) {
        _toggleDebugMode();
      }
    });
  }

  void _cancelDebugModeTimer() {
    _isLongPressing = false;
    _debugModeTimer?.cancel();
    _debugModeTimer = null;
  }

  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
    });
  }

  Future<void> _showPendingNotifications() async {
    try {
      final pendingNotifications =
          await NotificationService.getPendingNotifications();

      if (!mounted) return;

      if (pendingNotifications.isEmpty) {
        _showSnackBar('No scheduled notifications found', Colors.orange);
        return;
      }

      final plannedById = {
        for (final reminder in NotificationHelper.planReminders(_dates))
          reminder.id: reminder,
      };
      pendingNotifications.sort((a, b) => a.id.compareTo(b.id));

      List<Widget> notificationWidgets = [];

      for (int i = 0; i < pendingNotifications.length; i++) {
        final notification = pendingNotifications[i];
        final reminder =
            plannedById[notification.id] ??
            NotificationHelper.decodeNotificationId(notification.id);

        notificationWidgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: reminder != null
                            ? TrashColors.getColorByType(reminder.type)
                            : Colors.grey,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification.title ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.body ?? 'No content',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _describeReminder(notification, reminder),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${notification.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled Notifications (${pendingNotifications.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(children: notificationWidgets),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationService.cancelAllNotifications();
                  _showSnackBar('All notifications cancelled', Colors.red);
                },
                child: const Text(
                  'Cancel All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar('Failed to get pending notifications: $e', Colors.red);
    }
  }

  String _describeReminder(
    PendingNotificationRequest notification,
    PlannedReminder? reminder,
  ) {
    if (reminder == null) {
      return 'Scheduled notification (ID: ${notification.id})';
    }

    final collectionDate =
        '${DateFormatHelper.formatDayName(reminder.pickupDate)}, '
        '${DateFormatHelper.formatDate(reminder.pickupDate)}';
    var timingInfo = 'Reminder: ${_formatDateTime(reminder.time)}';

    final untilReminder = reminder.time.difference(DateTime.now());
    if (untilReminder.isNegative) {
      timingInfo += ' (Past due)';
    } else if (untilReminder.inHours < 1) {
      timingInfo += ' (in ${untilReminder.inMinutes}m)';
    } else if (untilReminder.inHours < 24) {
      timingInfo += ' (in ${untilReminder.inHours}h)';
    } else {
      timingInfo += ' (in ${untilReminder.inDays}d)';
    }

    return '$timingInfo\nFor collection: $collectionDate';
  }

  String _formatDateTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${DateFormatHelper.formatDayName(time)}, '
        '${DateFormatHelper.formatDate(time)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
