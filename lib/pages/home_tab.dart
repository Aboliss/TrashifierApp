import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';
import 'package:trashifier_app/widgets/next_pickup_card.dart';
import 'package:trashifier_app/widgets/upcoming_list.dart';
import 'package:trashifier_app/widgets/week_strip.dart';

/// Home: greeting, the next pickup, this week and what comes after.
class HomeTab extends StatelessWidget {
  final Map<TrashType, List<DateTime>> datesByType;
  final VoidCallback onAdd;
  final ValueChanged<DateTime> onEditDay;

  /// Round buttons at the top right (theme switch).
  final List<Widget> actions;

  /// Shown under the header when debug mode is on.
  final Widget? debugPanel;

  /// Extra space at the bottom for the floating navigation bar.
  final double bottomInset;

  const HomeTab({
    super.key,
    required this.datesByType,
    required this.onAdd,
    required this.onEditDay,
    this.actions = const [],
    this.debugPanel,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = DateTime.now();
    final days = PickupDatesHelper.upcomingDays(datesByType, now);
    final next = days.isEmpty ? null : days.first;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      children: [
        SizedBox(
          height: 48,
          child: Row(
            spacing: 8,
            children: [
              BinBuddy(size: 40, lidColor: palette.ink),
              Expanded(
                child: Text(
                  'trashifier',
                  style: AppFonts.headline(24, palette.ink),
                ),
              ),
              ...actions,
            ],
          ),
        ),
        if (debugPanel != null) ...[const SizedBox(height: 12), debugPanel!],
        const SizedBox(height: 18),
        Text(
          '${DateFormatHelper.formatDayName(now)}, '
          '${DateFormatHelper.formatDate(now)}',
          style: TextStyle(
            color: palette.muted,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          PickupCopyHelper.headline(next, now),
          style: AppFonts.headline(31, palette.ink),
        ),
        const SizedBox(height: 18),
        NextPickupCard(day: next, onAdd: onAdd),
        const SizedBox(height: 16),
        WeekStrip(datesByType: datesByType, onDayTap: onEditDay, today: now),
        const SizedBox(height: 16),
        UpcomingList(days: days.skip(1).toList()),
      ],
    );
  }
}
