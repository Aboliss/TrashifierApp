import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

class CalendarDialog extends StatefulWidget {
  final TrashType type;
  final Color color;
  final List<DateTime> existingDates;
  final List<DateTime> allPlasticDates;
  final List<DateTime> allPaperDates;
  final List<DateTime> allGarbageDates;
  final List<DateTime> allBioDates;
  final void Function(Set<DateTime> selectedDates, TrashType type) onSave;

  const CalendarDialog({
    super.key,
    required this.type,
    required this.color,
    required this.existingDates,
    required this.allPlasticDates,
    required this.allPaperDates,
    required this.allGarbageDates,
    required this.allBioDates,
    required this.onSave,
  });

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
  );

  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    for (var day in widget.existingDates) {
      _selectedDays.add(day);
    }
  }

  Color? _getOtherTrashTypeColor(DateTime day) {
    if (widget.allPlasticDates.any((date) => isSameDay(date, day)) &&
        widget.type != TrashType.plastic) {
      return TrashTypeHelper.getColor(TrashType.plastic);
    }
    if (widget.allPaperDates.any((date) => isSameDay(date, day)) &&
        widget.type != TrashType.paper) {
      return TrashTypeHelper.getColor(TrashType.paper);
    }
    if (widget.allGarbageDates.any((date) => isSameDay(date, day)) &&
        widget.type != TrashType.trash) {
      return TrashTypeHelper.getColor(TrashType.trash);
    }
    if (widget.allBioDates.any((date) => isSameDay(date, day)) &&
        widget.type != TrashType.bio) {
      return TrashTypeHelper.getColor(TrashType.bio);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 40.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TrashTypeHelper.getIcon(widget.type),
                            color: widget.color,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add ${widget.type.name} dates',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return _selectedDays.contains(day);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final otherTrashColor = _getOtherTrashTypeColor(day);
                    if (otherTrashColor != null) {
                      return Container(
                        margin: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: otherTrashColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: _onDaySelected,
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
                rangeSelectionMode: RangeSelectionMode.enforced,
                calendarStyle: CalendarStyle(
                  defaultDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                  ),
                  weekendDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                  ),
                  outsideDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(8),
                    shape: BoxShape.rectangle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: TrashTypeHelper.getContainerTextColor(
                      context,
                      widget.type,
                    ),
                  ),
                  defaultTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  weekendTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                  outsideTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            const SizedBox(height: 24),
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveSelection,
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: TrashTypeHelper.getContainerTextColor(
                          context,
                          widget.type,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
