import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<DateTime> _plasticDates = [];
  List<DateTime> _paperDates = [];
  List<DateTime> _garbageDates = [];

  final _plasticColorLight = Colors.yellow.shade300;
  final _plasticColor = Colors.yellow.shade600;
  final _paperColorLight = Colors.blue.shade300;
  final _paperColor = Colors.blue.shade600;
  final _trashColorLight = Colors.grey.shade500;
  final _trashColor = Colors.grey.shade600;

  double? containerHeight;

  @override
  void initState() {
    super.initState();

    _loadFromStorage();
    requestExactAlarmPermission();

    // Show a test notification instantly to verify notification system
    NotificationService.showInstantNotification("Test Notification", "If you see this, notifications are working.");

    containerHeight = 400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        childrenAnimation: ExpandableFabAnimation.values.first,
        type: ExpandableFabType.up,
        distance: 80,
        overlayStyle: ExpandableFabOverlayStyle(color: Colors.black.withValues(alpha: 0.5)),
        // overlayStyle: ExpandableFabOverlayStyle(blur: 3),
        openButtonBuilder: RotateFloatingActionButtonBuilder(child: const Icon(Icons.add, size: 30), backgroundColor: Colors.white),
        closeButtonBuilder: RotateFloatingActionButtonBuilder(child: const Icon(Icons.close, size: 30), backgroundColor: Colors.white),
        children: [
          FloatingActionButton.extended(label: Text('Plastic'), icon: Icon(Icons.add), backgroundColor: _plasticColor, onPressed: () => _openAddDatesDialog(context, TrashType.plastic)),
          FloatingActionButton.extended(label: Text('Paper'), icon: Icon(Icons.add), backgroundColor: _paperColor, onPressed: () => _openAddDatesDialog(context, TrashType.paper)),
          FloatingActionButton.extended(label: Text('Trash'), icon: Icon(Icons.add), backgroundColor: _trashColorLight, onPressed: () => _openAddDatesDialog(context, TrashType.trash)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // const Row(
                //   children: [Expanded(child: SizedBox(height: 100, child: Placeholder()))],
                // ),
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: DateTime.now(),
                  headerStyle: const HeaderStyle(titleCentered: true, titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600), leftChevronVisible: true, rightChevronVisible: true, formatButtonVisible: false),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  calendarFormat: CalendarFormat.month,
                  calendarBuilders: CalendarBuilders(defaultBuilder: (context, day, focusedDay) => _buildCalendar(context, day, focusedDay)),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // TextButton(
                //   onPressed: () {
                //     NotificationService.showInstantNotification("Instant Notification", "This shows an instant notifications");
                //   },
                //   child: const Text("Show Notification"),
                // ),
                // ElevatedButton(
                //   onPressed: () {
                //     DateTime scheduledDate = DateTime.now().add(const Duration(seconds: 5));
                //     NotificationService.scheduleNotification(0, "Scheduled Notification", "This notification is scheduled to appear after 5 seconds", scheduledDate);
                //   },
                //   child: const Text('Schedule Notification'),
                // ),
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

  Widget? _buildCalendar(BuildContext context, DateTime day, DateTime focusedDay) {
    Widget? buildCell(List<DateTime> dates, Color color, Color borderColor) {
      if (dates.any((date) => _equalsDate(date, day))) {
        return Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(width: 1, color: borderColor),
          ),
          child: Center(child: Text(day.day.toString())),
        );
      }
      return null;
    }

    return buildCell(_plasticDates, _plasticColor, _plasticColor) ?? buildCell(_paperDates, _paperColorLight, _paperColor) ?? buildCell(_garbageDates, _trashColorLight, _trashColor);
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
    // Find newly added dates
    List<DateTime> newlyAddedDates = selectedDates.where((newDate) => !existingDates.any((d) => _equalsDate(d, newDate))).toList();

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

    _scheduleNotifications(newlyAddedDates, type);
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

      // Schedule for 10 seconds from now
      DateTime scheduledTime = DateTime.now().add(Duration(seconds: 30));
      print('Scheduling notification: id=${date.hashCode}, title=$title, body=$body, scheduledTime=$scheduledTime');
      NotificationService.scheduleNotification(date.hashCode, title, body, scheduledTime);
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
    switch (type) {
      case TrashType.plastic:
        return _plasticColor;
      case TrashType.paper:
        return _paperColor;
      case TrashType.trash:
        return _trashColor;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.trashifier_app/exact_alarm');
      try {
        await platform.invokeMethod('requestExactAlarmPermission');
      } catch (e) {
        print('Error requesting exact alarm permission: $e');
      }
    }
  }
}
