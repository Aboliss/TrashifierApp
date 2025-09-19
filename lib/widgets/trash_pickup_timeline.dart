import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_date.dart';

class TrashPickupTimeline extends StatelessWidget {
  final List<TrashDate> upcomingPickups;

  const TrashPickupTimeline({super.key, required this.upcomingPickups});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (upcomingPickups.isEmpty) {
      return Container();
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
            'Upcoming pick-ups',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          LimitedBox(
            maxHeight: 500,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: upcomingPickups.length,
              itemBuilder: (context, index) {
                final pickup = upcomingPickups[index];
                final isFirst = index == 0;
                final isLast = index == upcomingPickups.length - 1;
                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 30,
                    color: TrashTypeHelper.getColor(pickup.type),
                    iconStyle: IconStyle(iconData: TrashTypeHelper.getIcon(pickup.type), color: TrashTypeHelper.getIconColor(pickup.type), fontSize: 16),
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
                                pickup.dayName,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pickup.formattedDate,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (pickup.daysUntil == 0 || pickup.daysUntil == 1) ? TrashTypeHelper.getBackgroundColor(pickup.type) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(2, 2))],
                            border: Border.all(color: (pickup.daysUntil == 0 || pickup.daysUntil == 1) ? TrashTypeHelper.getColor(pickup.type).withValues(alpha: 0.4) : theme.colorScheme.outline.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Text(
                            pickup.daysUntilText,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: (pickup.daysUntil == 0 || pickup.daysUntil == 1) && TrashTypeHelper.shouldUseWhiteText(pickup.type) ? Colors.white : theme.colorScheme.onSurface),
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
}
