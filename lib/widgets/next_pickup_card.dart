import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';
import 'package:trashifier_app/widgets/season_decor.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// The big dark card on the home screen: the next collection day, its bins
/// and when the reminder fires, with Bin Buddy peeking from the corner.
class NextPickupCard extends StatelessWidget {
  final PickupDay? day;

  /// Opens the add-pickups flow; shown when nothing is planned.
  final VoidCallback onAdd;

  const NextPickupCard({super.key, required this.day, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final day = this.day;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.hero,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -30,
            child: Transform.rotate(
              angle: 0.17,
              child: BinBuddy(
                size: 132,
                lidColor: palette.heroInk,
                onDark: true,
                costume: context.buddyCostume,
              ),
            ),
          ),
          // Clear of the big day text and the pills.
          const Positioned(
            right: 34,
            top: 66,
            child: HalloweenDecor(DecorAnchor.heroSky, onDark: true),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: day == null
                ? _empty(context, palette)
                : _pickup(context, palette, day),
          ),
        ],
      ),
    );
  }

  Widget _pickup(BuildContext context, AppPalette palette, PickupDay day) {
    final relative = PickupCopyHelper.relativeDay(day.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.nextPickupEyebrow,
                style: AppFonts.eyebrow(palette.heroMuted),
              ),
            ),
            Text(
              DateFormatHelper.formatShortDate(day.date),
              style: TextStyle(
                color: palette.heroInk.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Text(relative, style: AppFonts.headline(48, palette.heroInk)),
        Padding(
          // Keep the pills clear of Bin Buddy.
          padding: const EdgeInsets.only(right: 90),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final type in day.types) BinPill(type)],
          ),
        ),
        Row(
          spacing: 8,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: palette.heroInk.withValues(alpha: 0.9),
            ),
            Flexible(
              child: Text(
                PickupCopyHelper.reminderLine(
                  day,
                  null,
                  context.reminderSettings,
                ),
                style: TextStyle(
                  color: palette.heroInk.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          context.l10n.nextPickupEyebrow,
          style: AppFonts.eyebrow(palette.heroMuted),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 100),
          child: Text(
            context.l10n.nothingPlanned,
            style: AppFonts.headline(36, palette.heroInk),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 100),
          child: Text(
            PickupCopyHelper.emptyCardHint(context.reminderSettings),
            style: TextStyle(color: palette.heroMuted, fontSize: 14),
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.addPickups),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFC83D),
            foregroundColor: const Color(0xFF16201B),
            minimumSize: const Size(0, 44),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
