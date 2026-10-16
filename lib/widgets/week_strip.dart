import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

/// Today and the six days after it, with a colored dot per bin.
class WeekStrip extends StatelessWidget {
  final Map<TrashType, List<DateTime>> datesByType;
  final ValueChanged<DateTime> onDayTap;
  final DateTime? today;

  const WeekStrip({
    super.key,
    required this.datesByType,
    required this.onDayTap,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final start = DateFormatHelper.dateOnly(today ?? DateTime.now());
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(start.year, start.month, start.day + i),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    'Next 7 days',
                    style: AppFonts.headline(
                      18,
                      palette.ink,
                    ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
                  ),
                ),
                const HalloweenDecor(DecorAnchor.weekTitle),
                const SizedBox(width: 12),
                Text(
                  '${DateFormatHelper.formatDate(days.first)} – '
                  '${DateFormatHelper.formatDate(days.last)}',
                  style: TextStyle(
                    color: palette.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (final day in days)
                Expanded(child: _day(context, palette, day, day == start)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _day(
    BuildContext context,
    AppPalette palette,
    DateTime day,
    bool isToday,
  ) {
    final types = PickupDatesHelper.typesOn(datesByType, day).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final label =
        '${DateFormatHelper.formatDayName(day)}, '
        '${DateFormatHelper.formatDate(day)}'
        '${types.isEmpty ? '' : ': ${types.map(TrashTypeHelper.getShortName).join(', ')}'}';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onDayTap(day),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            spacing: 6,
            children: [
              Text(
                DateFormatHelper.formatDayName(day).substring(0, 1),
                style: TextStyle(
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? palette.ink
                      : types.isNotEmpty
                      ? palette.chip
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday ? palette.ground : palette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(
                height: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [for (final type in types) BinMark(type)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
