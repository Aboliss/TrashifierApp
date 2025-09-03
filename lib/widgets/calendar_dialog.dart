import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/models/trash_type.dart';

class CalendarDialog extends StatefulWidget {
  final TrashType type;
  final Color color;
  final List<DateTime> existingDates;
  final void Function(Set<DateTime> selectedDates, TrashType type) onSave;

  const CalendarDialog({super.key, required this.type, required this.color, required this.existingDates, required this.onSave});

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(equals: isSameDay);

  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    for (var day in widget.existingDates) {
      _selectedDays.add(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Add dates', style: TextStyle(fontSize: 20)),
              Divider(),
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return _selectedDays.contains(day);
                },
                calendarBuilders: CalendarBuilders(defaultBuilder: (context, day, focusedDay) => _buildCalendar(context, day, focusedDay)),
                onDaySelected: _onDaySelected,
                headerStyle: const HeaderStyle(titleCentered: true, titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), leftChevronVisible: false, rightChevronVisible: false, formatButtonVisible: false),
                rangeSelectionMode: RangeSelectionMode.enforced,
                calendarStyle: CalendarStyle(
                  defaultDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  todayDecoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  weekendDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  outsideDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  selectedDecoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  selectedTextStyle: TextStyle(color: Colors.black),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(fontWeight: FontWeight.bold)),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(label: Text('Cancel'), onPressed: () => Navigator.pop(context), icon: Icon(Icons.cancel_outlined)),
                  TextButton.icon(label: Text('Save'), onPressed: _saveSelection, icon: Icon(Icons.check)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }
    });
  }

  void _saveSelection() {
    widget.onSave(_selectedDays, widget.type);
    Navigator.pop(context);
  }

  Widget? _buildCalendar(BuildContext context, DateTime day, DateTime focusedDay) {
    for (var date in widget.existingDates) {
      if (date.year == day.year && date.month == day.month && date.day == day.day) {
        return Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(5)),
          child: Center(child: Text(day.day.toString())),
        );
      }
    }
    return null;
  }
}
