import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/season_decor.dart';
import 'package:trashifier_app/widgets/swipe_reveal_row.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// "Coming up": one row per bin for the collection days after the next one.
/// Swiping a row right reveals Remove, which drops that bin from that day.
class UpcomingList extends StatefulWidget {
  /// Days to list; the caller leaves out the day shown on the hero card.
  final List<PickupDay> days;

  /// Removes [type]'s pickup on [date].
  final void Function(DateTime date, TrashType type) onRemove;

  /// At most this many rows are shown.
  final int maxRows;

  /// Lets the first row peek once to show Remove (see SwipeRevealRow.peek).
  final bool showRemoveHint;
  final VoidCallback? onRemoveHintShown;

  /// Screen space covered at the bottom, e.g. by the navigation bar; the
  /// hint waits until the row is clear of it.
  final double bottomInset;

  const UpcomingList({
    super.key,
    required this.days,
    required this.onRemove,
    this.maxRows = 8,
    this.showRemoveHint = false,
    this.onRemoveHintShown,
    this.bottomInset = 0,
  });

  /// Background of the revealed Remove button; white text keeps 4.5:1.
  static const Color removeColor = Color(0xFFC2412D);

  @override
  State<UpcomingList> createState() => _UpcomingListState();
}

class _UpcomingListState extends State<UpcomingList> {
  final ValueNotifier<Object?> _openRow = ValueNotifier(null);

  @override
  void dispose() {
    _openRow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rows = [
      for (final day in widget.days)
        for (final type in day.types) (day, type),
    ].take(widget.maxRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            spacing: 10,
            children: [
              Text(
                context.l10n.comingUp,
                style: AppFonts.headline(
                  18,
                  palette.ink,
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
              ),
              const HalloweenDecor(DecorAnchor.comingUpTitle),
            ],
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
              context.l10n.nothingElsePlanned,
              style: TextStyle(color: palette.muted, fontSize: 15),
            ),
          ),
        for (final (index, (day, type)) in rows.indexed)
          SwipeRevealGroup(
            openRow: _openRow,
            child: SwipeRevealRow(
              key: ValueKey('${day.date}-${type.id}'),
              borderRadius: BorderRadius.circular(20),
              actionLabel: context.l10n.removeBinOnDay(
                TrashTypeHelper.getDisplayName(type),
                DateFormatHelper.formatDayName(day.date),
              ),
              onAction: () => widget.onRemove(day.date, type),
              action: const _RemoveButton(),
              actionBackground: UpcomingList.removeColor,
              peek: widget.showRemoveHint && index == 0,
              onPeeked: widget.onRemoveHintShown,
              peekBottomInset: widget.bottomInset,
              child: Container(
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
                            DateFormatHelper.formatFullDate(day.date),
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
            ),
          ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton();

  @override
  Widget build(BuildContext context) {
    // Sits on the row's red background (actionBackground).
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
          Text(
            context.l10n.remove,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
