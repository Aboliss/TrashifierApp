import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// Picks every collection day of one bin [type] at once.
///
/// Pops with the full set of selected days on save, or null when cancelled.
class CalendarDialog extends StatefulWidget {
  final TrashType type;

  /// All bins' dates; other bins are shown as small marks for orientation.
  final Map<TrashType, List<DateTime>> datesByType;

  const CalendarDialog({
    super.key,
    required this.type,
    required this.datesByType,
  });

  static Future<Set<DateTime>?> show(
    BuildContext context, {
    required TrashType type,
    required Map<TrashType, List<DateTime>> datesByType,
  }) {
    return showDialog<Set<DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CalendarDialog(type: type, datesByType: datesByType),
    );
  }

  /// "+3 new · 1 removed", or the hint when nothing changed yet.
  static String changeSummary(int added, int removed) {
    final l = L10n.current;
    if (added == 0 && removed == 0) return l.tapDaysHint;
    return [
      if (added > 0) l.changeAdded(added),
      if (removed > 0) l.changeRemoved(removed),
    ].join(' · ');
  }

  /// "Add 3 days", "Remove 1 day", "Save changes" or "Save".
  static String saveLabel(int added, int removed) {
    final l = L10n.current;
    if (added > 0 && removed == 0) return l.addDays(added);
    if (removed > 0 && added == 0) return l.removeDays(removed);
    if (added > 0) return l.saveChanges;
    return l.save;
  }

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  // table_calendar hands out UTC dates while stored dates are local, so both
  // equality and hash must only look at the calendar day.
  final Set<DateTime> _selectedDays = _daySet();

  /// The bin's dates when the dialog opened, to count what changes.
  final Set<DateTime> _initialDays = _daySet();

  static Set<DateTime> _daySet() => LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: (date) => date.year * 10000 + date.month * 100 + date.day,
  );

  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 365));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _selectedDays.addAll(widget.datesByType[widget.type] ?? const []);
    _initialDays.addAll(_selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = widget.type;
    final added = _selectedDays.difference(_initialDays).length;
    final removed = _initialDays.difference(_selectedDays).length;
    final changed = added > 0 || removed > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Row(
              spacing: 12,
              children: [
                BinIconTile(type, size: 44),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.binDays(
                          TrashTypeHelper.getShortName(type),
                        ),
                        style: AppFonts.headline(24, palette.ink),
                      ),
                      Text(
                        CalendarDialog.changeSummary(added, removed),
                        style: TextStyle(
                          color: changed ? palette.ink : palette.muted,
                          fontWeight: changed
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: _firstDay,
                lastDay: _lastDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.horizontalSwipe,
                calendarFormat: CalendarFormat.month,
                rowHeight: 48,
                daysOfWeekHeight: 24,
                selectedDayPredicate: _selectedDays.contains,
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                locale: context.l10n.localeName,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: AppFonts.headline(18, palette.ink),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: palette.ink,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: palette.ink,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) => Center(
                    child: Text(
                      DateFormatHelper.formatShortDayName(day),
                      style: TextStyle(
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  defaultBuilder: (context, day, _) => _cell(palette, day),
                  todayBuilder: (context, day, _) =>
                      _cell(palette, day, isToday: true),
                  selectedBuilder: (context, day, _) =>
                      _cell(palette, day, isSelected: true),
                  outsideBuilder: (context, day, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: PillButton(
                    label: context.l10n.cancel,
                    outlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: PillButton(
                    label: CalendarDialog.saveLabel(added, removed),
                    onPressed: () => Navigator.pop(
                      context,
                      _selectedDays.map(DateFormatHelper.dateOnly).toSet(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    AppPalette palette,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final type = widget.type;
    final others =
        PickupDatesHelper.typesOn(
            widget.datesByType,
            day,
          ).where((other) => other != type).toList()
          ..sort((a, b) => a.index.compareTo(b.index));

    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? TrashColors.getContainerColor(context, type)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: isToday && !isSelected
              ? Border.all(color: palette.ink, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? TrashColors.getContainerTextColor(context, type)
                    : palette.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  for (final other in others)
                    BinMark(other, width: 6, height: 4),
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
      _focusedDay = focusedDay;
      if (!_selectedDays.remove(selectedDay)) {
        _selectedDays.add(selectedDay);
      }
    });
  }
}
