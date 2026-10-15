import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/bin_icon.dart';

/// Bottom sheet for picking which bins are collected on a single [day].
///
/// Pops with the selected types on save, or null when dismissed.
class DayPickupsSheet extends StatefulWidget {
  final DateTime day;
  final Set<TrashType> initialTypes;

  const DayPickupsSheet({
    super.key,
    required this.day,
    required this.initialTypes,
  });

  static Future<Set<TrashType>?> show(
    BuildContext context, {
    required DateTime day,
    required Set<TrashType> initialTypes,
  }) {
    return showModalBottomSheet<Set<TrashType>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          DayPickupsSheet(day: day, initialTypes: initialTypes),
    );
  }

  @override
  State<DayPickupsSheet> createState() => _DayPickupsSheetState();
}

class _DayPickupsSheetState extends State<DayPickupsSheet> {
  late final Set<TrashType> _selected = {...widget.initialTypes};

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final count = _selected.length;
    final reminder = switch (count) {
      0 => 'No bins, no reminder.',
      1 =>
        'One reminder the evening before at '
            '${PickupCopyHelper.formatHour(NotificationHelper.reminderHour)}.',
      _ =>
        '$count reminders the evening before at '
            '${PickupCopyHelper.formatHour(NotificationHelper.reminderHour)}, one per bin.',
    };
    final saveLabel = count == 0
        ? (widget.initialTypes.isEmpty ? 'Save' : 'Clear day')
        : 'Save $count ${count == 1 ? 'bin' : 'bins'}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 18,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                PickupCopyHelper.relativeDay(widget.day).toUpperCase(),
                style: AppFonts.eyebrow(palette.muted),
              ),
              Text(
                '${DateFormatHelper.formatDayName(widget.day)}, '
                '${DateFormatHelper.formatDate(widget.day)}',
                style: AppFonts.headline(30, palette.ink),
              ),
            ],
          ),
          Text(
            'Which bins go out?',
            style: TextStyle(
              color: palette.ink,
              fontWeight: FontWeight.w600,
              fontSize: 16,
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
                  selected: _selected.contains(type),
                  onTap: () => setState(() {
                    if (!_selected.remove(type)) _selected.add(type);
                  }),
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.chip,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              spacing: 12,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: palette.ink,
                  size: 22,
                ),
                Expanded(
                  child: Text(
                    reminder,
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: PillButton(
                  label: 'Cancel',
                  outlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                flex: 2,
                child: PillButton(
                  label: saveLabel,
                  onPressed: () => Navigator.pop(context, {..._selected}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Big bin tile that flips to the bin's color when selected.
class BinToggleTile extends StatelessWidget {
  final TrashType type;
  final bool selected;
  final VoidCallback onTap;

  /// Second line under the name; defaults to what goes in the bin.
  final String? subtitle;

  /// Shows an arrow instead of the check mark, for tiles that pick one bin
  /// and move on rather than toggle.
  final bool navigates;

  const BinToggleTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.navigates = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = TrashColors.getContainerColor(context, type);
    final onColor = TrashColors.getContainerTextColor(context, type);
    final fg = selected ? onColor : palette.ink;
    // Neighbouring tiles tilt opposite ways.
    final tilt = type.index.isEven ? -0.026 : 0.026;

    return Semantics(
      button: true,
      toggled: navigates ? null : selected,
      label: TrashTypeHelper.getDisplayName(type),
      excludeSemantics: true,
      child: AnimatedRotation(
        turns: selected ? tilt / 6.283 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Material(
          color: selected ? color : palette.card,
          elevation: selected ? 6 : 0,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: selected
                ? BorderSide.none
                : BorderSide(color: palette.line, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.22)
                              : color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: BinIcon(type, color: onColor, size: 26),
                      ),
                      const Spacer(),
                      _check(palette, color, onColor),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TrashTypeHelper.getShortName(type),
                        style: AppFonts.headline(20, fg),
                      ),
                      Text(
                        subtitle ?? TrashTypeHelper.getDescription(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? onColor.withValues(alpha: 0.85)
                              : palette.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _check(AppPalette palette, Color color, Color onColor) {
    if (navigates) {
      return Icon(Icons.arrow_forward_rounded, size: 22, color: palette.muted);
    }
    if (!selected) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.line, width: 2),
        ),
      );
    }
    final whiteBadge = onColor == Colors.white;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: whiteBadge ? Colors.white : const Color(0xFF16201B),
      ),
      child: Icon(
        Icons.check_rounded,
        size: 18,
        color: whiteBadge ? color : TrashColors.plasticColor,
      ),
    );
  }
}
