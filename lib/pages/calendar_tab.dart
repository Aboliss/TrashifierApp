import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/season_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Month view: every collection day as colored bars, a bin filter, and a card
/// for the selected day with an Edit button.
class CalendarTab extends StatefulWidget {
  final Map<TrashType, List<DateTime>> datesByType;
  final ValueChanged<DateTime> onEditDay;

  /// Extra space at the bottom for the floating navigation bar.
  final double bottomInset;

  const CalendarTab({
    super.key,
    required this.datesByType,
    required this.onEditDay,
    this.bottomInset = 0,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 365));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 365));

  // Kept in state so rebuilds (e.g. theme changes) don't jump the calendar
  // back to the current month.
  late DateTime _focusedDay = DateFormatHelper.dateOnly(DateTime.now());
  late DateTime _selectedDay = _focusedDay;

  /// Only show this bin; null shows all.
  TrashType? _filter;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        16 + SeasonBackdrop.topInset(context),
        20,
        24 + widget.bottomInset,
      ),
      children: [
        _header(palette),
        const SizedBox(height: 16),
        _filters(palette),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TableCalendar(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.monday,
            // Horizontal swipes switch between Home and Calendar; the
            // arrows in the header change the month.
            availableGestures: AvailableGestures.none,
            calendarFormat: CalendarFormat.month,
            rowHeight: 56,
            daysOfWeekHeight: 26,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = DateFormatHelper.dateOnly(selected);
              _focusedDay = DateFormatHelper.dateOnly(focused);
            }),
            onPageChanged: (focused) => setState(
              () => _focusedDay = DateFormatHelper.dateOnly(focused),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) => Center(
                child: Text(
                  DateFormatHelper.formatDayName(day).substring(0, 3),
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
              disabledBuilder: (context, day, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _selectedDayCard(palette),
      ],
    );
  }

  Widget _header(AppPalette palette) {
    final canGoBack = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    ).isAfter(DateTime(_firstDay.year, _firstDay.month));
    final canGoForward = DateTime(
      _focusedDay.year,
      _focusedDay.month,
    ).isBefore(DateTime(_lastDay.year, _lastDay.month));

    return SizedBox(
      height: 48,
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${_monthNames[_focusedDay.month - 1]} '),
                  TextSpan(
                    text: '${_focusedDay.year}',
                    style: TextStyle(
                      color: palette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              style: AppFonts.headline(28, palette.ink),
            ),
          ),
          const HalloweenDecor(DecorAnchor.calendarHeader, spiderDrop: 26),
          RoundIconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous month',
            onPressed: canGoBack ? () => _moveMonth(-1) : null,
          ),
          RoundIconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next month',
            onPressed: canGoForward ? () => _moveMonth(1) : null,
          ),
        ],
      ),
    );
  }

  void _moveMonth(int delta) {
    var target = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    if (target.isBefore(_firstDay)) target = _firstDay;
    if (target.isAfter(_lastDay)) target = _lastDay;
    setState(() => _focusedDay = DateFormatHelper.dateOnly(target));
  }

  Widget _filters(AppPalette palette) {
    Widget chip(String label, TrashType? type) {
      final on = _filter == type;
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? palette.ink : palette.card,
          shape: StadiumBorder(
            side: BorderSide(color: on ? palette.ink : palette.line, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _filter = type),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 7,
                children: [
                  if (type != null) BinMark(type, width: 10, height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: on ? palette.ground : palette.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // One scrollable row; wrapping pushed Bio onto a line of its own.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        spacing: 8,
        children: [
          chip('All', null),
          for (final type in TrashType.values)
            chip(TrashTypeHelper.getShortName(type), type),
        ],
      ),
    );
  }

  List<TrashType> _typesOn(DateTime day) {
    return PickupDatesHelper.typesOn(
        widget.datesByType,
        day,
      ).where((type) => _filter == null || type == _filter).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  Widget _cell(
    AppPalette palette,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final types = _typesOn(day);
    final daysUntil = DateFormatHelper.calculateDaysUntil(day);
    final isPast = daysUntil < 0;
    final special = SeasonHelper.specialDayFor(day, context.season);
    final barWidth = types.isEmpty ? 0.0 : (28 / types.length) - 2;
    final bars = SizedBox(
      height: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final type in types)
            BinMark(
              type,
              width: barWidth,
              height: 5,
              // Only normal cells get the ink fill when selected.
              onDark: isSelected && special == null && !context.isDark,
            ),
        ],
      ),
    );

    if (special != null) {
      return _specialCell(
        palette,
        day,
        special,
        bars: bars,
        isPast: isPast,
        // The selected builder also handles today when it's selected.
        isToday: daysUntil == 0,
        isSelected: isSelected,
      );
    }

    final Color? background;
    final Color foreground;
    if (isSelected) {
      background = palette.ink;
      foreground = palette.ground;
    } else if (isToday) {
      background = palette.chip;
      foreground = palette.ink;
    } else {
      background = null;
      foreground = palette.ink;
    }

    return Opacity(
      opacity: isPast && !isSelected ? 0.45 : 1,
      child: Center(
        child: Container(
          width: 46,
          height: 50,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: isToday && !isSelected
                ? Border.all(color: palette.ink, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              bars,
            ],
          ),
        ),
      ),
    );
  }

  /// A holiday drawn behind the day number (pumpkin, tree, ornament, gift,
  /// champagne). Today gets the usual chip backing; selected gets a ring in
  /// the season's accent, so it can't be mistaken for today's ink ring.
  Widget _specialCell(
    AppPalette palette,
    DateTime day,
    SpecialDay special, {
    required Widget bars,
    required bool isPast,
    required bool isToday,
    required bool isSelected,
  }) {
    final number = SpecialDayArt.numberStyle(special, context.isDark);
    return Opacity(
      opacity: isPast && !isSelected ? 0.45 : 1,
      child: Center(
        child: Container(
          width: 46,
          height: 50,
          decoration: BoxDecoration(
            color: isToday ? palette.chip : null,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: palette.fab, width: 3)
                : isToday
                ? Border.all(color: palette.ink, width: 2)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpecialDayArt(special),
              // The drawings are centered on the cell, so the number is too.
              Transform.translate(
                offset: Offset(number.left, number.top),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: number.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 3,
                child: Center(child: bars),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedDayCard(AppPalette palette) {
    final types = PickupDatesHelper.typesOn(
      widget.datesByType,
      _selectedDay,
    ).toList()..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.hero,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      [
                        ?SeasonHelper.specialDayFor(
                          _selectedDay,
                          context.season,
                        )?.label,
                        PickupCopyHelper.relativeDay(_selectedDay),
                      ].join(' · ').toUpperCase(),
                      style: AppFonts.eyebrow(palette.heroMuted),
                    ),
                    Text(
                      '${DateFormatHelper.formatDayName(_selectedDay)}, '
                      '${DateFormatHelper.formatDate(_selectedDay)}',
                      style: AppFonts.headline(24, palette.heroInk),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => widget.onEditDay(_selectedDay),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.heroInk,
                  foregroundColor: palette.hero,
                  minimumSize: const Size(0, 44),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (types.isEmpty)
            Text(
              'No bins go out. Tap Edit to add some.',
              style: TextStyle(color: palette.heroMuted, fontSize: 15),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final type in types) BinPill(type, height: 36)],
            ),
        ],
      ),
    );
  }
}
