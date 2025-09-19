import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';

class NextPickupHighlight extends StatelessWidget {
  final TrashDate? trashDate;

  const NextPickupHighlight({super.key, required this.trashDate});

  Color _getBackgroundColor(BuildContext context, TrashType type) {
    return TrashColors.getContainerColor(context, type);
  }

  Color _getTextColor(BuildContext context, TrashType type) {
    return TrashColors.getContainerTextColor(context, type);
  }

  IconData _getIconForType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return Icons.recycling;
      case TrashType.paper:
        return Icons.description;
      case TrashType.trash:
        return Icons.delete;
      case TrashType.bio:
        return Icons.eco;
    }
  }

  Color _getIconColorForType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return Colors.black;
      case TrashType.paper:
        return Colors.white;
      case TrashType.trash:
        return Colors.white;
      case TrashType.bio:
        return Colors.white;
    }
  }

  int _calculateDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (trashDate == null) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
        ),
        child: Center(
          child: Text(
            'No upcoming trash pickup',
            style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final daysUntil = _calculateDaysUntil(trashDate!.date);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, trashDate!.type),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Next pick-up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _getTextColor(context, trashDate!.type).withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _getTextColor(context, trashDate!.type).withValues(alpha: 0.1)),
                  child: Icon(_getIconForType(trashDate!.type), size: 22, color: _getIconColorForType(trashDate!.type)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        daysUntil == 0
                            ? 'Today'
                            : daysUntil == 1
                            ? 'Tomorrow'
                            : 'in $daysUntil days',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getTextColor(context, trashDate!.type)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDayName(trashDate!.date)}, ${_formatDate(trashDate!.date)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _getTextColor(context, trashDate!.type).withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
