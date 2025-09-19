import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
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
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
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
              Text('Add dates', style: TextStyle(fontSize: 20, color: theme.colorScheme.onSurface)),
              Divider(color: theme.dividerColor),
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

                onDaySelected: _onDaySelected,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  formatButtonVisible: false,
                ),
                rangeSelectionMode: RangeSelectionMode.enforced,
                calendarStyle: CalendarStyle(
                  defaultDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  todayDecoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  weekendDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  outsideDecoration: BoxDecoration(borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  selectedDecoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(5), shape: BoxShape.rectangle),
                  selectedTextStyle: TextStyle(color: TrashColors.getContainerTextColor(context, widget.type)),
                  defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  weekendTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  outsideTextStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              Divider(color: theme.dividerColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    label: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface)),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.onSurface),
                  ),
                  TextButton.icon(
                    label: Text('Save', style: TextStyle(color: theme.colorScheme.primary)),
                    onPressed: _saveSelection,
                    icon: Icon(Icons.check, color: theme.colorScheme.primary),
                  ),
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
      final inSelected = _selectedDays.any((d) => isSameDay(d, selectedDay));

      if (inSelected) {
        _selectedDays.removeWhere((d) => isSameDay(d, selectedDay));
      } else {
        _selectedDays.add(selectedDay);
      }
    });
  }

  void _saveSelection() {
    widget.onSave(_selectedDays, widget.type);
    Navigator.pop(context);
  }
}
