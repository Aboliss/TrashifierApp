import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';
import 'package:trashifier_app/widgets/next_pickup_highlight.dart';

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

  double? containerHeight;

  @override
  void initState() {
    super.initState();

    _loadFromStorage();
    _requestExactAlarmPermission();
    _setNextTrashDate();

    containerHeight = 400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, color: theme.colorScheme.onSurface),
          onPressed: () {
            context.read<ThemeService>().toggleTheme();
          },
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        childrenAnimation: ExpandableFabAnimation.values.first,
        type: ExpandableFabType.up,
        distance: 80,
        overlayStyle: ExpandableFabOverlayStyle(color: Colors.black.withValues(alpha: 0.5)),
        // overlayStyle: ExpandableFabOverlayStyle(blur: 3),
        openButtonBuilder: RotateFloatingActionButtonBuilder(child: const Icon(Icons.add, size: 30), backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.onSurface),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(child: const Icon(Icons.close, size: 30), backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.onSurface),
        children: [
          // FloatingActionButton.extended(label: Text('Test Schedule'), icon: Icon(Icons.notifications), backgroundColor: Colors.orange, onPressed: () => _testScheduledNotification()),
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              label: const Text('Plastic', style: TextStyle(color: Colors.black)),
              icon: const Icon(Icons.add, color: Colors.black),
              backgroundColor: TrashColors.plasticColor,
              onPressed: () => _openAddDatesDialog(context, TrashType.plastic),
            ),
          ),
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              label: const Text('Paper', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add, color: Colors.white),
              backgroundColor: TrashColors.paperColor,
              onPressed: () => _openAddDatesDialog(context, TrashType.paper),
            ),
          ),
          SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              label: const Text('Trash', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.add, color: Colors.white),
              backgroundColor: TrashColors.trashColor,
              onPressed: () => _openAddDatesDialog(context, TrashType.trash),
            ),
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
                      child: SizedBox(child: NextPickupHighlight(trashDate: _nextTrashDate)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: DateTime.now(),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                      leftChevronVisible: true,
                      rightChevronVisible: true,
                      formatButtonVisible: false,
                      leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
                      rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                    ),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    calendarFormat: CalendarFormat.month,
                    calendarBuilders: CalendarBuilders(defaultBuilder: (context, day, focusedDay) => _buildCalendar(context, day, focusedDay)),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                      defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                      weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                      outsideTextStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
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
    var plasticDates = await StorageService.instance.loadDates(TrashType.plastic);
    var paperDates = await StorageService.instance.loadDates(TrashType.paper);
    var garbageDates = await StorageService.instance.loadDates(TrashType.trash);

    setState(() {
      _plasticDates = plasticDates;
      _paperDates = paperDates;
      _garbageDates = garbageDates;
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
    }
  }

  Color _getCalendarTextColor(List<Color> colors, bool hasPaper, bool hasTrash) {
    if (hasPaper || hasTrash) {
      return Colors.white;
    }
    return Colors.black;
  }

  Widget? _buildCalendar(BuildContext context, DateTime day, DateTime focusedDay) {
    bool hasPlastic = _plasticDates.any((date) => _equalsDate(date, day));
    bool hasPaper = _paperDates.any((date) => _equalsDate(date, day));
    bool hasTrash = _garbageDates.any((date) => _equalsDate(date, day));

    if (!hasPlastic && !hasPaper && !hasTrash) {
      return null;
    }

    List<Color> colors = [];
    List<Color> borderColors = [];

    if (hasPlastic) {
      colors.add(TrashColors.plasticColor);
      borderColors.add(TrashColors.plasticColor);
    }
    if (hasPaper) {
      colors.add(TrashColors.paperColor);
      borderColors.add(TrashColors.paperColor);
    }
    if (hasTrash) {
      colors.add(TrashColors.trashColor);
      borderColors.add(TrashColors.trashColor);
    }

    if (colors.length == 1) {
      return Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.first,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1, color: borderColors.first),
        ),
        child: Center(
          child: Text(
            day.day.toString(),
            style: TextStyle(color: _getCalendarTextColor(colors, hasPaper, hasTrash), fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1, color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            Row(
              children: colors.map((color) {
                return Expanded(
                  child: Container(height: double.infinity, color: color),
                );
              }).toList(),
            ),
            Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(color: _getCalendarTextColor(colors, hasPaper, hasTrash), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _equalsDate(DateTime date, DateTime day) {
    return date.year == day.year && date.month == day.month && date.day == day.day;
  }

  void _openAddDatesDialog(BuildContext context, TrashType type) {
    final List<DateTime> existingDates = _getExistingDates(type);
    final Color color = _getColorByType(type);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CalendarDialog(type: type, color: color, existingDates: existingDates, onSave: _updateSelectedDates);
      },
    );
  }

  void _updateSelectedDates(Set<DateTime> selectedDates, TrashType type) {
    List<DateTime> existingDates = _getExistingDates(type);
    List<DateTime> newlyAddedDates = selectedDates.where((newDate) => !existingDates.any((d) => _equalsDate(d, newDate))).toList();
    List<DateTime> removedDates = existingDates.where((existingDate) => !selectedDates.any((s) => _equalsDate(s, existingDate))).toList();

    switch (type) {
      case TrashType.plastic:
        _updateExistingDates(_plasticDates, selectedDates);
        _saveToStorage(type);
        break;
      case TrashType.paper:
        _updateExistingDates(_paperDates, selectedDates);
        _saveToStorage(type);
        break;
      case TrashType.trash:
        _updateExistingDates(_garbageDates, selectedDates);
        _saveToStorage(type);
        break;
    }

    if (newlyAddedDates.isNotEmpty) {
      _scheduleNotifications(newlyAddedDates, type);
    }

    if (removedDates.isNotEmpty) {
      _cancelNotifications(removedDates);
    }

    _setNextTrashDate();

    // _checkPendingNotifications();
  }

  void _updateExistingDates(List<DateTime> existingDates, Set<DateTime> selectedDates) {
    setState(() {
      // Add dates that are in selectedDates but not in existingDates
      for (var newDate in selectedDates) {
        if (!existingDates.any((d) => _equalsDate(d, newDate))) {
          existingDates.add(newDate);
        }
      }

      // Remove dates that are in existingDates but not in selectedDates
      existingDates.removeWhere((d) => !selectedDates.any((s) => _equalsDate(d, s)));
    });
  }

  void _scheduleNotifications(List<DateTime> newlyAddedDates, TrashType type) {
    for (var date in newlyAddedDates) {
      String title = '';
      String body = '';
      switch (type) {
        case TrashType.plastic:
          title = 'Plastic Collection Reminder';
          body = 'Remember to take out your plastic trash!';
          break;
        case TrashType.paper:
          title = 'Paper Collection Reminder';
          body = 'Remember to take out your paper trash!';
          break;
        case TrashType.trash:
          title = 'General Trash Reminder';
          body = 'Remember to take out your trash!';
          break;
      }

      DateTime scheduledTime = DateTime(date.year, date.month, date.day - 1, 19, 0);

      if (scheduledTime.isBefore(DateTime.now())) {
        continue;
      }

      NotificationService.scheduleNotification(date.hashCode, title, body, scheduledTime);
    }
  }

  void _cancelNotifications(List<DateTime> removedDates) {
    for (var date in removedDates) {
      NotificationService.cancelNotification(date.hashCode);
    }
  }

  List<DateTime> _getExistingDates(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return _plasticDates;
      case TrashType.paper:
        return _paperDates;
      case TrashType.trash:
        return _garbageDates;
    }
  }

  Color _getColorByType(TrashType type) {
    return TrashColors.getColorByType(type);
  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.trashifier_app/exact_alarm');
      try {
        await platform.invokeMethod('requestExactAlarmPermission');
      } catch (e) {
        //TODO: Handle error
      }
    }
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

    List<TrashDate> futureDates = allTrashDates.where((trashDate) => trashDate.date.isAfter(now) || _equalsDate(trashDate.date, now)).toList();

    setState(() {
      if (futureDates.isNotEmpty) {
        futureDates.sort((a, b) => a.date.compareTo(b.date));
        TrashDate earliest = futureDates.first;
        _nextTrashDate = earliest;
      } else {
        // No future dates found
        _nextTrashDate = null;
      }
    });
  }

  // Future<void> _checkPendingNotifications() async {
  //   final pendingNotifications = await NotificationService.getPendingNotifications();
  //   print('Pending notifications count: ${pendingNotifications.length}');
  //   for (var notification in pendingNotifications) {
  //     print('Pending: ID=${notification.id}, Title=${notification.title}, Body=${notification.body}');
  //   }
  // }

  // Future<void> _testScheduledNotification() async {
  //   DateTime testTime = DateTime.now().add(Duration(seconds: 10));
  //   await NotificationService.scheduleNotification(999, 'Test Scheduled Notification', 'This is a test scheduled notification!', testTime);

  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test notification scheduled for 10 seconds from now')));
  //   }

  //   _checkPendingNotifications();
  // }
}
