import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/transfer_service.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// Where an imported schedule came from.
enum ImportSource { file, link, qr }

enum ImportChoice {
  /// Add the imported pickups to the ones already in the app.
  merge,

  /// Remove the current pickups first.
  replace,
}

/// Asks before an imported schedule changes anything: shows what it holds
/// and offers Add to mine, Replace all or Cancel.
class ImportDialog extends StatelessWidget {
  final Schedule schedule;
  final ImportSource source;
  final int currentTotal;

  /// Replace all's outline and text in light mode; 4.5:1 on white.
  static const Color replaceColor = Color(0xFFC2412D);

  const ImportDialog({
    super.key,
    required this.schedule,
    required this.source,
    required this.currentTotal,
  });

  static Future<ImportChoice?> show(
    BuildContext context, {
    required Schedule schedule,
    required ImportSource source,
    required int currentTotal,
  }) {
    return showDialog<ImportChoice>(
      context: context,
      builder: (_) => ImportDialog(
        schedule: schedule,
        source: source,
        currentTotal: currentTotal,
      ),
    );
  }

  /// A short, user-facing reason an import was refused.
  static String errorMessage(ScheduleError error) {
    final l = L10n.current;
    switch (error) {
      case ScheduleError.notTrashifier:
        return l.errorNotTrashifier;
      case ScheduleError.newerVersion:
        return l.errorNewerVersion;
      case ScheduleError.tooLarge:
        return l.errorTooLarge;
      case ScheduleError.invalid:
        return l.errorInvalid;
      case ScheduleError.empty:
        return l.errorEmpty;
    }
  }

  static String transferErrorMessage(TransferError error) {
    switch (error) {
      case TransferError.tooLarge:
        return errorMessage(ScheduleError.tooLarge);
      case TransferError.unavailable:
        return L10n.current.errorUnavailable;
      case TransferError.failed:
        return L10n.current.errorFileFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = context.l10n;
    final total = schedule.total;
    final eyebrow = switch (source) {
      ImportSource.file => l.importFromFile,
      ImportSource.link => l.importFromLink,
      ImportSource.qr => l.importFromQr,
    };
    final first = schedule.first;
    final last = schedule.last;
    final range = first == null || last == null
        ? ''
        : first.year == last.year && first.month == last.month
        ? DateFormatHelper.formatMonthYear(first)
        : '${DateFormatHelper.formatMonthYear(first)} – '
              '${DateFormatHelper.formatMonthYear(last)}';

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return Dialog(
      backgroundColor: palette.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(eyebrow, style: AppFonts.eyebrow(palette.muted)),
                Text(
                  l.importCount(total),
                  style: AppFonts.headline(26, palette.ink),
                ),
                if (range.isNotEmpty)
                  Text(
                    range,
                    style: TextStyle(color: palette.muted, fontSize: 14),
                  ),
              ],
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
              children: [
                for (final type in TrashType.values)
                  _BinCount(type: type, count: schedule.count(type)),
              ],
            ),
            if (schedule.skipped > 0)
              Text(
                l.skippedEntries(schedule.skipped),
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            if (currentTotal > 0)
              Text(
                l.currentPickups(currentTotal),
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(ImportChoice.merge),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.fab,
                    foregroundColor: palette.fabInk,
                    minimumSize: const Size.fromHeight(50),
                    shape: buttonShape,
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  child: Text(currentTotal > 0 ? l.addToMine : l.importButton),
                ),
                if (currentTotal > 0)
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(ImportChoice.replace),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.isDark
                          ? const Color(0xFFFF8A75)
                          : replaceColor,
                      side: BorderSide(
                        color: context.isDark
                            ? const Color(0xFFFF8A75)
                            : replaceColor,
                        width: 2,
                      ),
                      minimumSize: const Size.fromHeight(50),
                      shape: buttonShape,
                      textStyle: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    child: Text(l.replaceAll),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.muted,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: Text(l.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BinCount extends StatelessWidget {
  final TrashType type;
  final int count;

  const _BinCount({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: palette.ground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: TrashColors.getColorByType(type),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              TrashTypeHelper.getDisplayName(type),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
