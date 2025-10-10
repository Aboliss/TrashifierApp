import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/calendar_helper.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';
import 'package:trashifier_app/widgets/next_pickup_highlight.dart';
import 'package:trashifier_app/widgets/trash_pickup_timeline.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TrashDate? _nextTrashDate;

  List<DateTime> _plasticDates = [];
  List<DateTime> _paperDates = [];
  List<DateTime> _garbageDates = [];
  List<DateTime> _bioDates = [];

  double? containerHeight;
  bool _debugMode = false;
  Timer? _debugModeTimer;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();

    _loadFromStorage();
    _requestExactAlarmPermission();
    _setNextTrashDate();

    containerHeight = 400;
  }

  @override
  void dispose() {
    _debugModeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                  context.read<ThemeService>().toggleTheme();
                },
                onLongPressStart: (_) => _startDebugModeTimer(),
                onLongPressEnd: (_) => _cancelDebugModeTimer(),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 6,
                  onPressed: null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      border: _debugMode
                          ? Border.all(color: Colors.purple, width: 2)
                          : null,
                    ),
                    child: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 30,
                      color: theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_debugMode) ...[
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 88.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 6,
                  onPressed: _scheduleTestNotification,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 160.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 6,
                  onPressed: _showPendingNotifications,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: const Icon(
                      Icons.list_alt,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 232.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 6,
                  onPressed: _debugNotificationScheduling,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple,
                    ),
                    child: const Icon(
                      Icons.bug_report,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
          ExpandableFab(
            childrenAnimation: ExpandableFabAnimation.values.first,
            type: ExpandableFabType.up,
            distance: 80,
            overlayStyle: ExpandableFabOverlayStyle(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            // overlayStyle: ExpandableFabOverlayStyle(blur: 3),
            openButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: Container(
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
                  child: Icon(
                    Icons.add,
                    size: 30,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            closeButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: Container(
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
                  child: Icon(
                    Icons.close,
                    size: 30,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            children: [
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.plastic),
                onPressed: () =>
                    _openAddDatesDialog(context, TrashType.plastic),
                child: Icon(
                  TrashTypeHelper.getIcon(TrashType.plastic),
                  color: TrashTypeHelper.getIconColor(TrashType.plastic),
                ),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.paper),
                onPressed: () => _openAddDatesDialog(context, TrashType.paper),
                child: Icon(
                  TrashTypeHelper.getIcon(TrashType.paper),
                  color: TrashTypeHelper.getIconColor(TrashType.paper),
                ),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.trash),
                onPressed: () => _openAddDatesDialog(context, TrashType.trash),
                child: Icon(
                  TrashTypeHelper.getIcon(TrashType.trash),
                  color: TrashTypeHelper.getIconColor(TrashType.trash),
                ),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.bio),
                onPressed: () => _openAddDatesDialog(context, TrashType.bio),
                child: Icon(
                  TrashTypeHelper.getIcon(TrashType.bio),
                  color: TrashTypeHelper.getIconColor(TrashType.bio),
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
                        child: NextPickupHighlight(trashDate: _nextTrashDate),
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
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: DateTime.now(),
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
                          CalendarHelper.buildCalendarDay(
                            context,
                            day,
                            focusedDay,
                            _plasticDates,
                            _paperDates,
                            _garbageDates,
                            _bioDates,
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
                  child: TrashPickupTimeline(
                    upcomingPickups: _getUpcomingPickups(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    var plasticDates = await StorageService.instance.loadDates(
      TrashType.plastic,
    );
    var paperDates = await StorageService.instance.loadDates(TrashType.paper);
    var garbageDates = await StorageService.instance.loadDates(TrashType.trash);
    var bioDates = await StorageService.instance.loadDates(TrashType.bio);

    setState(() {
      _plasticDates = plasticDates;
      _paperDates = paperDates;
      _garbageDates = garbageDates;
      _bioDates = bioDates;
    });

    _setNextTrashDate();
  }

  Future<void> _saveToStorage(TrashType type) async {
    switch (type) {
      case TrashType.plastic:
        await StorageService.instance.saveDates(_plasticDates, type);
        break;
      case TrashType.paper:
        await StorageService.instance.saveDates(_paperDates, type);
        break;
      case TrashType.trash:
        await StorageService.instance.saveDates(_garbageDates, type);
        break;
      case TrashType.bio:
        await StorageService.instance.saveDates(_bioDates, type);
        break;
    }
  }

  void _openAddDatesDialog(BuildContext context, TrashType type) {
    final List<DateTime> existingDates = _getExistingDates(type);
    final Color color = TrashTypeHelper.getColor(type);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CalendarDialog(
          type: type,
          color: color,
          existingDates: existingDates,
          allPlasticDates: _plasticDates,
          allPaperDates: _paperDates,
          allGarbageDates: _garbageDates,
          allBioDates: _bioDates,
          onSave: _updateSelectedDates,
        );
      },
    );
  }

  Future<void> _updateSelectedDates(
    Set<DateTime> selectedDates,
    TrashType type,
  ) async {
    List<DateTime> oldDates = List.from(_getExistingDates(type));

    switch (type) {
      case TrashType.plastic:
        _updateExistingDates(_plasticDates, selectedDates);
        await _saveToStorage(type);
        break;
      case TrashType.paper:
        _updateExistingDates(_paperDates, selectedDates);
        await _saveToStorage(type);
        break;
      case TrashType.trash:
        _updateExistingDates(_garbageDates, selectedDates);
        await _saveToStorage(type);
        break;
      case TrashType.bio:
        _updateExistingDates(_bioDates, selectedDates);
        await _saveToStorage(type);
        break;
    }

    List<DateTime> currentDates = _getExistingDates(type);
    await NotificationHelper.rescheduleNotificationsForType(
      currentDates,
      oldDates,
      type,
    );

    _setNextTrashDate();
  }

  void _updateExistingDates(
    List<DateTime> existingDates,
    Set<DateTime> selectedDates,
  ) {
    setState(() {
      // Add dates that are in selectedDates but not in existingDates
      for (var newDate in selectedDates) {
        if (!existingDates.any(
          (d) => DateFormatHelper.isSameDate(d, newDate),
        )) {
          existingDates.add(newDate);
        }
      }

      // Remove dates that are in existingDates but not in selectedDates
      existingDates.removeWhere(
        (d) => !selectedDates.any((s) => DateFormatHelper.isSameDate(d, s)),
      );
    });
  }

  List<DateTime> _getExistingDates(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return _plasticDates;
      case TrashType.paper:
        return _paperDates;
      case TrashType.trash:
        return _garbageDates;
      case TrashType.bio:
        return _bioDates;
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.trashifier_app/exact_alarm');
      try {
        await platform.invokeMethod('requestExactAlarmPermission');
      } catch (e) {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permissions may be limited. Some reminders might not work as expected.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _scheduleTestNotification() async {
    try {
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        999,
        'Test Notification',
        'This is a test notification scheduled 10 seconds ago!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder Channel',
            channelDescription: 'Channel for trash collection reminders',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Test notification scheduled for 10 seconds from now!',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule test notification: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _debugNotificationScheduling() async {
    try {
      List<String> debugInfo = [];
      debugInfo.add('=== NOTIFICATION DEBUG INFO ===');

      List<DateTime> allDates = [
        ..._plasticDates,
        ..._paperDates,
        ..._garbageDates,
        ..._bioDates,
      ];
      debugInfo.add('Total dates in memory: ${allDates.length}');

      if (allDates.isNotEmpty) {
        debugInfo.add('\nDates by type:');
        debugInfo.add('- Plastic: ${_plasticDates.length}');
        debugInfo.add('- Paper: ${_paperDates.length}');
        debugInfo.add('- Garbage: ${_garbageDates.length}');
        debugInfo.add('- Bio: ${_bioDates.length}');

        debugInfo.add('\nScheduling analysis:');
        DateTime now = DateTime.now();

        for (DateTime date in allDates) {
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day - 1,
            19,
            0,
          );
          final isPast = scheduledTime.isBefore(now);
          final daysDiff = scheduledTime.difference(now).inDays;
          final hoursDiff = scheduledTime.difference(now).inHours;

          String trashType = switch (true) {
            _ when _plasticDates.contains(date) => 'Plastic',
            _ when _paperDates.contains(date) => 'Paper',
            _ when _garbageDates.contains(date) => 'Garbage',
            _ when _bioDates.contains(date) => 'Bio',
            _ => 'Unknown',
          };

          debugInfo.add('${DateFormatHelper.formatDate(date)} ($trashType):');
          debugInfo.add('  Collection: ${date.day}/${date.month}/${date.year}');
          debugInfo.add(
            '  Notification: ${scheduledTime.day}/${scheduledTime.month} at 19:00',
          );
          debugInfo.add(
            '  Status: ${isPast ? "PAST (won't schedule)" : "FUTURE (should schedule)"}',
          );
          if (!isPast) {
            debugInfo.add('  Time until: ${daysDiff}d ${hoursDiff % 24}h');
          }
          debugInfo.add('  ID: ${date.hashCode}');
          debugInfo.add('');
        }
      }

      final pendingNotifications =
          await NotificationService.getPendingNotifications();
      debugInfo.add('Pending notifications: ${pendingNotifications.length}');

      if (pendingNotifications.isNotEmpty) {
        debugInfo.add('\nPending notification IDs:');
        for (var notif in pendingNotifications) {
          debugInfo.add('- ID: ${notif.id}, Title: ${notif.title}');
        }
      }

      if (mounted) {
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
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                },
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  await _forceRescheduleAll();
                },
                child: const Text('Force Reschedule All'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceRescheduleAll() async {
    try {
      await NotificationService.cancelAllNotifications();

      if (_plasticDates.isNotEmpty) {
        await NotificationHelper.scheduleNotificationsForDates(
          _plasticDates,
          TrashType.plastic,
        );
      }
      if (_paperDates.isNotEmpty) {
        await NotificationHelper.scheduleNotificationsForDates(
          _paperDates,
          TrashType.paper,
        );
      }
      if (_garbageDates.isNotEmpty) {
        await NotificationHelper.scheduleNotificationsForDates(
          _garbageDates,
          TrashType.trash,
        );
      }
      if (_bioDates.isNotEmpty) {
        await NotificationHelper.scheduleNotificationsForDates(
          _bioDates,
          TrashType.bio,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications rescheduled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _setNextTrashDate() {
    DateTime now = DateTime.now();

    List<TrashDate> allTrashDates = [];

    for (var date in _plasticDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.plastic));
    }

    for (var date in _paperDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.paper));
    }

    for (var date in _garbageDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.trash));
    }

    for (var date in _bioDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.bio));
    }

    List<TrashDate> futureDates = allTrashDates.where((trashDate) {
      if (trashDate.date.isAfter(now)) {
        return true;
      } else if (DateFormatHelper.isSameDate(trashDate.date, now)) {
        return now.hour < 8;
      }
      return false;
    }).toList();

    setState(() {
      if (futureDates.isNotEmpty) {
        futureDates.sort((a, b) => a.date.compareTo(b.date));
        TrashDate earliest = futureDates.first;
        _nextTrashDate = earliest;
      } else {
        _nextTrashDate = null;
      }
    });
  }

  List<TrashDate> _getUpcomingPickups() {
    DateTime now = DateTime.now();
    List<TrashDate> allTrashDates = [];

    for (var date in _plasticDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.plastic));
    }

    for (var date in _paperDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.paper));
    }

    for (var date in _garbageDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.trash));
    }

    for (var date in _bioDates) {
      allTrashDates.add(TrashDate(date: date, type: TrashType.bio));
    }

    List<TrashDate> futureDates = allTrashDates.where((trashDate) {
      if (trashDate.date.isAfter(now)) {
        return true;
      } else if (DateFormatHelper.isSameDate(trashDate.date, now)) {
        return now.hour < 8;
      }
      return false;
    }).toList();

    futureDates.sort((a, b) => a.date.compareTo(b.date));

    return futureDates;
  }

  Future<void> _showPendingNotifications() async {
    try {
      final pendingNotifications =
          await NotificationService.getPendingNotifications();

      if (!mounted) return;

      if (pendingNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No scheduled notifications found'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<Widget> notificationWidgets = [];

      for (int i = 0; i < pendingNotifications.length; i++) {
        final notification = pendingNotifications[i];

        String estimatedScheduleInfo = _analyzeNotification(notification);

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
                        backgroundColor: _getNotificationTypeColor(
                          notification.title ?? '',
                        ),
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
                      estimatedScheduleInfo,
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
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                },
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  await NotificationService.cancelAllNotifications();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('All notifications cancelled'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get pending notifications: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _analyzeNotification(PendingNotificationRequest notification) {
    List<DateTime> allDates = [
      ..._plasticDates,
      ..._paperDates,
      ..._garbageDates,
      ..._bioDates,
    ];

    for (DateTime date in allDates) {
      if (date.hashCode == notification.id) {
        final notificationTime = DateTime(
          date.year,
          date.month,
          date.day - 1,
          19,
          0,
        );
        final collectionDate =
            '${DateFormatHelper.formatDayName(date)}, ${DateFormatHelper.formatDate(date)}';
        final scheduleTime =
            '${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}';
        final scheduleDate =
            '${DateFormatHelper.formatDayName(notificationTime)}, ${DateFormatHelper.formatDate(notificationTime)}';

        String timingInfo = 'Reminder: $scheduleDate at $scheduleTime';
        String collectionInfo = 'For collection: $collectionDate';

        final now = DateTime.now();
        if (notificationTime.isBefore(now)) {
          timingInfo += ' (Past due)';
        } else {
          final hoursUntil = notificationTime.difference(now).inHours;
          final minutesUntil = notificationTime.difference(now).inMinutes;

          if (hoursUntil < 1) {
            timingInfo += ' (in ${minutesUntil}m)';
          } else if (hoursUntil < 24) {
            timingInfo += ' (in ${hoursUntil}h)';
          } else {
            final daysUntil = notificationTime.difference(now).inDays;
            timingInfo += ' (in ${daysUntil}d)';
          }
        }

        return '$timingInfo\n$collectionInfo';
      }
    }

    return 'Scheduled notification (ID: ${notification.id})';
  }

  Color _getNotificationTypeColor(String title) {
    if (title.toLowerCase().contains('plastic')) {
      return TrashColors.plasticColor;
    } else if (title.toLowerCase().contains('paper')) {
      return TrashColors.paperColor;
    } else if (title.toLowerCase().contains('bio')) {
      return TrashColors.bioColor;
    } else if (title.toLowerCase().contains('garbage') ||
        title.toLowerCase().contains('trash')) {
      return TrashColors.trashColor;
    }
    return Colors.grey;
  }
}
