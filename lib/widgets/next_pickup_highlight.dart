import 'package:flutter/material.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_date.dart';

class NextPickupHighlight extends StatelessWidget {
  final TrashDate? trashDate;

  const NextPickupHighlight({super.key, required this.trashDate});

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
            'No upcoming pick-up',
            style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TrashTypeHelper.getContainerColor(context, trashDate!.type),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Next pick-up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TrashTypeHelper.getContainerTextColor(context, trashDate!.type).withValues(alpha: 0.8)),
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: TrashTypeHelper.getContainerTextColor(context, trashDate!.type).withValues(alpha: 0.1)),
                  child: Icon(TrashTypeHelper.getIcon(trashDate!.type), size: 22, color: TrashTypeHelper.getIconColor(trashDate!.type)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trashDate!.daysUntilText,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TrashTypeHelper.getContainerTextColor(context, trashDate!.type)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trashDate!.dayName}, ${trashDate!.formattedDate}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TrashTypeHelper.getContainerTextColor(context, trashDate!.type).withValues(alpha: 0.8)),
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
