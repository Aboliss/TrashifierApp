import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/qr_code_view.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// The upcoming pickups as a QR code for another phone to scan, with a
/// fallback to send them as a file.
class ShareQrSheet extends StatelessWidget {
  final String link;
  final Schedule upcoming;
  final VoidCallback onSendFile;

  const ShareQrSheet({
    super.key,
    required this.link,
    required this.upcoming,
    required this.onSendFile,
  });

  /// Shows the sheet; returns false without showing it when there is
  /// nothing upcoming to share.
  static Future<bool> show(
    BuildContext context, {
    required Map<TrashType, List<DateTime>> datesByType,
    required VoidCallback onSendFile,
    DateTime? now,
  }) async {
    final link = ScheduleCodec.encodeLink(datesByType, from: now);
    final Schedule upcoming;
    try {
      upcoming = ScheduleCodec.decodeLink(link);
    } on ScheduleFormatException {
      return false;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          ShareQrSheet(link: link, upcoming: upcoming, onSendFile: onSendFile),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = upcoming.total;
    final first = upcoming.first!;
    final last = upcoming.last!;
    final range = first.year == last.year && first.month == last.month
        ? DateFormatHelper.formatMonthYear(first)
        : '${DateFormatHelper.formatMonthYear(first)} – '
              '${DateFormatHelper.formatMonthYear(last)}';
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                context.l10n.qrTitle,
                style: AppFonts.headline(24, palette.ink),
              ),
              Text(
                context.l10n.qrSubtitle(total, range),
                style: TextStyle(color: palette.muted, fontSize: 14),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.fab,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: QrCodeView(
                  data: link,
                  semanticLabel: context.l10n.qrA11y(total),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.chip,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: palette.ink),
                Expanded(
                  child: Text(
                    context.l10n.qrHint,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 14,
                      height: 1.4,
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
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSendFile();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.ink,
                    side: BorderSide(color: palette.line, width: 2),
                    minimumSize: const Size.fromHeight(50),
                    shape: buttonShape,
                  ),
                  child: Text(context.l10n.sendAsFile),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.ink,
                    foregroundColor: palette.ground,
                    minimumSize: const Size.fromHeight(50),
                    shape: buttonShape,
                  ),
                  child: Text(context.l10n.done),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
