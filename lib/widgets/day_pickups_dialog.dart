import 'package:flutter/material.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Lets the user pick which bins are collected on a single [day].
///
/// Pops with the selected types on save, or null when cancelled.
class DayPickupsDialog extends StatefulWidget {
  final DateTime day;
  final Set<TrashType> initialTypes;

  const DayPickupsDialog({
    super.key,
    required this.day,
    required this.initialTypes,
  });

  static Future<Set<TrashType>?> show(
    BuildContext context, {
    required DateTime day,
    required Set<TrashType> initialTypes,
  }) {
    return showDialog<Set<TrashType>>(
      context: context,
      builder: (context) =>
          DayPickupsDialog(day: day, initialTypes: initialTypes),
    );
  }

  @override
  State<DayPickupsDialog> createState() => _DayPickupsDialogState();
}

class _DayPickupsDialogState extends State<DayPickupsDialog> {
  late final Set<TrashType> _selected = {...widget.initialTypes};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Text(
                    DateFormatHelper.formatDayName(widget.day),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatHelper.formatDate(widget.day),
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: 8),
            for (final type in TrashType.values) _buildTypeTile(theme, type),
            const SizedBox(height: 8),
            Divider(
              color: theme.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, {..._selected}),
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTile(ThemeData theme, TrashType type) {
    final color = TrashTypeHelper.getColor(type);

    return CheckboxListTile(
      value: _selected.contains(type),
      onChanged: (checked) {
        setState(() {
          if (checked ?? false) {
            _selected.add(type);
          } else {
            _selected.remove(type);
          }
        });
      },
      activeColor: color,
      checkColor: TrashTypeHelper.getIconColor(type),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      secondary: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          TrashTypeHelper.getIcon(type),
          color: TrashTypeHelper.getIconColor(type),
        ),
      ),
      title: Text(
        TrashTypeHelper.getDisplayName(type),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
