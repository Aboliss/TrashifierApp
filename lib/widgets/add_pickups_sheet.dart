import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/season_decor.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// First step of adding pickups: choose the bin whose dates to edit.
///
/// Pops with the chosen type, or null when dismissed.
class AddPickupsSheet extends StatelessWidget {
  /// Planned upcoming pickups per bin, shown on its tile.
  final Map<TrashType, int> upcomingCounts;

  const AddPickupsSheet({super.key, required this.upcomingCounts});

  static Future<TrashType?> show(
    BuildContext context, {
    required Map<TrashType, int> upcomingCounts,
  }) {
    return showModalBottomSheet<TrashType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddPickupsSheet(upcomingCounts: upcomingCounts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.l10n.addPickups,
                  style: AppFonts.headline(30, palette.ink),
                ),
              ),
              const HalloweenDecor(DecorAnchor.addSheet, spiderDrop: 10),
            ],
          ),
          Text(
            context.l10n.addPickupsHint,
            style: TextStyle(
              color: palette.muted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              for (final type in TrashType.values)
                BinToggleTile(
                  type: type,
                  selected: false,
                  navigates: true,
                  subtitle: context.l10n.upcomingCount(
                    upcomingCounts[type] ?? 0,
                  ),
                  onTap: () => Navigator.pop(context, type),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
