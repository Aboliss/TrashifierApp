import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_tab.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/services/widget_service.dart';
import 'package:trashifier_app/widgets/add_pickups_sheet.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/floating_nav_bar.dart';
import 'package:trashifier_app/widgets/swipe_hint.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

/// App shell: owns the pickup dates and switches between the Home and
/// Calendar tabs.
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

  final PageController _pages = PageController();
  int _tab = 0;

  // Hidden until storage says the user hasn't swiped to the calendar yet.
  bool _showSwipeHint = false;

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
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // "Today"/"Tomorrow" labels and the season depend on the current date.
      setState(() {});
      context.read<SeasonService?>()?.refresh();
      WidgetService.updateWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeService>().themeMode;
    const navSpace = FloatingNavBar.height + 20;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SeasonBackdrop(
              child: PageView(
                controller: _pages,
                onPageChanged: _onPageChanged,
                children: [
                  // Only the visible tab runs its animations (ghosts, spiders).
                  TickerMode(
                    enabled: _tab == 0,
                    child: HomeTab(
                      datesByType: _dates,
                      onAdd: _openAddPickups,
                      onEditDay: _openDayPickupsSheet,
                      onRemovePickup: _removePickup,
                      actions: [_buildThemeButton(themeMode)],
                      debugPanel: _debugMode ? _buildDebugPanel() : null,
                      bottomInset: navSpace,
                    ),
                  ),
                  // Keeps the shown month and selected day while on Home.
                  _KeepAlive(
                    child: TickerMode(
                      enabled: _tab == 1,
                      child: CalendarTab(
                        datesByType: _dates,
                        onEditDay: _openDayPickupsSheet,
                        bottomInset: navSpace,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: navSpace + 12 + MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showSwipeHint && _tab == 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Center(child: SwipeHint()),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: FloatingNavBar(
                index: _tab,
                onSelect: (tab) => _pages.animateToPage(
                  tab,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                ),
                onAdd: _openAddPickups,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int tab) {
    setState(() => _tab = tab);
    if (tab == 1 && _showSwipeHint) {
      setState(() => _showSwipeHint = false);
      StorageService.instance.markSwipeHintSeen();
    }
  }

  Widget _buildThemeButton(ThemeMode themeMode) {
    final palette = context.palette;
    final IconData icon;
    switch (themeMode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
      case ThemeMode.light:
        icon = Icons.light_mode;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
    }

    // A plain GestureDetector instead of an InkWell or tooltip: those also
    // react to long-press and would steal the gesture that unlocks debug mode.
    return Semantics(
      button: true,
      label: 'Theme: ${themeMode.name}. Tap to switch.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.read<ThemeService>().toggleTheme(),
        onLongPressStart: (_) => _startDebugModeTimer(),
        onLongPressEnd: (_) => _cancelDebugModeTimer(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.chip,
            border: _debugMode
                ? Border.all(color: Colors.purple, width: 2)
                : null,
          ),
          child: Icon(icon, size: 20, color: palette.ink),
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    Widget button(IconData icon, String label, VoidCallback onPressed) {
      return RoundIconButton(
        icon: Icon(icon),
        tooltip: label,
        onPressed: onPressed,
        background: Colors.purple.withValues(alpha: 0.15),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          spacing: 8,
          children: [
            Text(
              'Debug',
              style: TextStyle(
                color: context.palette.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            button(Icons.widgets, 'Update widget', _debugWidget),
            button(
              Icons.bug_report,
              'Reminder plan',
              _debugNotificationScheduling,
            ),
            button(
              Icons.list_alt,
              'Pending reminders',
              _showPendingNotifications,
            ),
            button(
              Icons.notifications_active,
              'Test notification in 10 s',
              _scheduleTestNotification,
            ),
          ],
        ),
        _buildSeasonSwitch(),
      ],
    );
  }

  /// Forces a seasonal theme (or none) instead of picking it from the date.
  Widget _buildSeasonSwitch() {
    final service = context.watch<SeasonService?>();
    if (service == null) return const SizedBox.shrink();
    final palette = context.palette;
    const labels = {
      SeasonOverride.auto: 'Auto',
      SeasonOverride.normal: 'Normal',
      SeasonOverride.halloween: 'Halloween',
      SeasonOverride.christmas: 'Christmas',
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        spacing: 4,
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: service.override == entry.key,
                label: 'Season: ${entry.value}',
                excludeSemantics: true,
                child: Material(
                  color: service.override == entry.key
                      ? palette.ink
                      : Colors.transparent,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => service.setOverride(entry.key),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            color: service.override == entry.key
                                ? palette.ground
                                : palette.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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

    final seenSwipeHint = await StorageService.instance.hasSeenSwipeHint();

    if (!mounted) return;
    setState(() {
      _dates.addAll(loaded);
      _showSwipeHint = !seenSwipeHint && _tab == 0;
    });

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

  Future<void> _openAddPickups() async {
    final now = DateTime.now();
    final type = await AddPickupsSheet.show(
      context,
      upcomingCounts: {
        for (final entry in _dates.entries)
          entry.key: entry.value
              .where((date) => DateFormatHelper.isFuture(date, now))
              .length,
      },
    );
    if (type == null || !mounted) return;

    final selected = await CalendarDialog.show(
      context,
      type: type,
      datesByType: _dates,
    );
    if (selected == null || !mounted) return;

    await _applyDateChanges({
      type: selected.map(DateFormatHelper.dateOnly).toList()..sort(),
    });
  }

  Future<void> _openDayPickupsSheet(DateTime day) async {
    final selected = await DayPickupsSheet.show(
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

  /// Drops [type]'s pickup on [day], with an Undo on the snack bar.
  Future<void> _removePickup(DateTime day, TrashType type) async {
    final before = [..._dates[type]!];
    // Show the snack bar right away; saving and re-arming reminders can take
    // a moment.
    final saving = _applyDateChanges({
      type: before
          .where((date) => !DateFormatHelper.isSameDate(date, day))
          .toList(),
    });

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Removed ${TrashTypeHelper.getDisplayName(type)} on '
          '${DateFormatHelper.formatDayName(day)}, '
          '${DateFormatHelper.formatDate(day)}',
        ),
        // Clear of the floating navigation bar.
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          FloatingNavBar.height + 28 + MediaQuery.paddingOf(context).bottom,
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _applyDateChanges({type: before}),
        ),
      ),
    );
    await saving;
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

/// Keeps a [PageView] page alive while it is scrolled out of view.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
