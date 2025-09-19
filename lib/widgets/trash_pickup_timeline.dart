import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';

class TrashPickupTimeline extends StatelessWidget {
  final List<TrashDate> upcomingPickups;

  const TrashPickupTimeline({super.key, required this.upcomingPickups});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (upcomingPickups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No upcoming trash pickups', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Pickups',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          LimitedBox(
            maxHeight: 500, // Maximum height, but can be smaller if less content
            child: ListView.builder(
              shrinkWrap: true, // Allow ListView to size itself based on content
              itemCount: upcomingPickups.length,
              itemBuilder: (context, index) {
                final pickup = upcomingPickups[index];
                final isFirst = index == 0;
                final isLast = index == upcomingPickups.length - 1;
                final daysUntil = _calculateDaysUntil(pickup.date);

                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 30,
                    color: TrashColors.getColorByType(pickup.type),
                    iconStyle: IconStyle(iconData: _getIconForType(pickup.type), color: _getIconColorForType(pickup.type), fontSize: 16),
                  ),
                  beforeLineStyle: LineStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), thickness: 2),
                  afterLineStyle: LineStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), thickness: 2),
                  endChild: Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDayName(pickup.date),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(pickup.date),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: daysUntil == 0 ? TrashColors.getLightColorByType(pickup.type) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(2, 2))],
                            border: Border.all(color: daysUntil == 0 ? TrashColors.getColorByType(pickup.type).withValues(alpha: 0.4) : theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Text(
                            daysUntil == 0
                                ? 'Today'
                                : daysUntil == 1
                                ? 'Tomorrow'
                                : 'in $daysUntil days',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: daysUntil == 0 && (pickup.type == TrashType.paper || pickup.type == TrashType.trash) ? Colors.white : theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TrashType type) {
    switch (type) {
      case TrashType.plastic:
        return Icons.recycling;
      case TrashType.paper:
        return Icons.description;
      case TrashType.trash:
        return Icons.delete;
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
    }
  }

  int _calculateDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }

  String _formatDayName(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
