import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';

/// "Coming up": one row per bin for the collection days after the next one.
class UpcomingList extends StatelessWidget {
  /// Days to list; the caller leaves out the day shown on the hero card.
  final List<PickupDay> days;

  /// At most this many rows are shown.
  final int maxRows;

  const UpcomingList({super.key, required this.days, this.maxRows = 8});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = [
      for (final day in days)
        for (final type in day.types) (day, type),
    ].take(maxRows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Coming up',
            style: AppFonts.headline(
              18,
              palette.ink,
            ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
          ),
        ),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Nothing else planned yet.',
              style: TextStyle(color: palette.muted, fontSize: 15),
            ),
          ),
        for (final (day, type) in rows)
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              spacing: 12,
              children: [
                BinIconTile(type),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        TrashTypeHelper.getDisplayName(type),
                        style: TextStyle(
                          color: palette.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${DateFormatHelper.formatDayName(day.date)}, '
                        '${DateFormatHelper.formatDate(day.date)}',
                        style: TextStyle(
                          color: palette.muted,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.chip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormatHelper.getDaysUntilText(day.date),
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
