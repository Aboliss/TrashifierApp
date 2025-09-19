import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/calendar_helper.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 6,
                onPressed: () {
                  context.read<ThemeService>().toggleTheme();
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                  child: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, size: 30, color: theme.brightness == Brightness.dark ? Colors.black : Colors.white),
                ),
              ),
            ),
          ),
          ExpandableFab(
            childrenAnimation: ExpandableFabAnimation.values.first,
            type: ExpandableFabType.up,
            distance: 80,
            overlayStyle: ExpandableFabOverlayStyle(color: Colors.black.withValues(alpha: 0.5)),
            // overlayStyle: ExpandableFabOverlayStyle(blur: 3),
            openButtonBuilder: DefaultFloatingActionButtonBuilder(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [TrashColors.plasticColor, TrashColors.paperColor, TrashColors.trashColor, TrashColors.bioColor], stops: const [0.0, 0.33, 0.66, 1.0]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface),
                  child: Icon(Icons.add, size: 30, color: theme.colorScheme.onSurface),
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
                  gradient: LinearGradient(colors: [TrashColors.plasticColor, TrashColors.paperColor, TrashColors.trashColor, TrashColors.bioColor], stops: const [0.0, 0.33, 0.66, 1.0]),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface),
                  child: Icon(Icons.close, size: 30, color: theme.colorScheme.onSurface),
                ),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onSurface,
            ),
            children: [
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.plastic),
                onPressed: () => _openAddDatesDialog(context, TrashType.plastic),
                child: Icon(TrashTypeHelper.getIcon(TrashType.plastic), color: TrashTypeHelper.getIconColor(TrashType.plastic)),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.paper),
                onPressed: () => _openAddDatesDialog(context, TrashType.paper),
                child: Icon(TrashTypeHelper.getIcon(TrashType.paper), color: TrashTypeHelper.getIconColor(TrashType.paper)),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.trash),
                onPressed: () => _openAddDatesDialog(context, TrashType.trash),
                child: Icon(TrashTypeHelper.getIcon(TrashType.trash), color: TrashTypeHelper.getIconColor(TrashType.trash)),
              ),
              FloatingActionButton(
                backgroundColor: TrashTypeHelper.getColor(TrashType.bio),
                onPressed: () => _openAddDatesDialog(context, TrashType.bio),
                child: Icon(TrashTypeHelper.getIcon(TrashType.bio), color: TrashTypeHelper.getIconColor(TrashType.bio)),
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
                        margin: const EdgeInsets.only(right: 10, left: 10, top: 10),
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
                    calendarBuilders: CalendarBuilders(defaultBuilder: (context, day, focusedDay) => CalendarHelper.buildCalendarDay(context, day, focusedDay, _plasticDates, _paperDates, _garbageDates, _bioDates)),
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
                Container(
                  margin: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
                  child: TrashPickupTimeline(upcomingPickups: _getUpcomingPickups()),
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
        return CalendarDialog(type: type, color: color, existingDates: existingDates, onSave: _updateSelectedDates);
      },
    );
  }

  Future<void> _updateSelectedDates(Set<DateTime> selectedDates, TrashType type) async {
    List<DateTime> existingDates = _getExistingDates(type);

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
      case TrashType.bio:
        _updateExistingDates(_bioDates, selectedDates);
        _saveToStorage(type);
        break;
    }

    await NotificationHelper.rescheduleNotificationsForType(selectedDates.toList(), existingDates, type);

    _setNextTrashDate();

    // _checkPendingNotifications();
  }

  void _updateExistingDates(List<DateTime> existingDates, Set<DateTime> selectedDates) {
    setState(() {
      // Add dates that are in selectedDates but not in existingDates
      for (var newDate in selectedDates) {
        if (!existingDates.any((d) => DateFormatHelper.isSameDate(d, newDate))) {
          existingDates.add(newDate);
        }
      }

      // Remove dates that are in existingDates but not in selectedDates
      existingDates.removeWhere((d) => !selectedDates.any((s) => DateFormatHelper.isSameDate(d, s)));
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
