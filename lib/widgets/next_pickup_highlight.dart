import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/trash_date.dart';
import 'package:trashifier_app/models/trash_type.dart';

class NextPickupHighlight extends StatelessWidget {
  final TrashDate? trashDate;

  const NextPickupHighlight({super.key, required this.trashDate});

  Color _getBackgroundColor(TrashType type) {
    return TrashColors.getBackgroundColorByType(type);
  }

  Color _getTextColor(TrashType type) {
    return type == TrashType.plastic ? Colors.black : Colors.white;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (trashDate == null) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
        ),
        child: const Center(
          child: Text(
            'No upcoming trash pickup',
            style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getBackgroundColor(trashDate!.type),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 5, offset: const Offset(5, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Next trash\npick up:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _getTextColor(trashDate!.type), height: 1.2),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDayName(trashDate!.date),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: _getTextColor(trashDate!.type)),
                  ),
                  Text(
                    _formatDate(trashDate!.date),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getTextColor(trashDate!.type)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
