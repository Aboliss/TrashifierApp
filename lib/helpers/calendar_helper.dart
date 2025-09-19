import 'package:flutter/material.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';

class CalendarHelper {
  static Widget? buildCalendarDay(BuildContext context, DateTime day, DateTime focusedDay, List<DateTime> plasticDates, List<DateTime> paperDates, List<DateTime> garbageDates, List<DateTime> bioDates) {
    bool hasPlastic = plasticDates.any((date) => DateFormatHelper.isSameDate(date, day));
    bool hasPaper = paperDates.any((date) => DateFormatHelper.isSameDate(date, day));
    bool hasTrash = garbageDates.any((date) => DateFormatHelper.isSameDate(date, day));
    bool hasBio = bioDates.any((date) => DateFormatHelper.isSameDate(date, day));

    if (!hasPlastic && !hasPaper && !hasTrash && !hasBio) {
      return null;
    }

    List<Color> colors = [];
    List<Color> borderColors = [];

    if (hasPlastic) {
      colors.add(TrashColors.plasticColor);
      borderColors.add(TrashColors.plasticColor);
    }
    if (hasPaper) {
      colors.add(TrashColors.paperColor);
      borderColors.add(TrashColors.paperColor);
    }
    if (hasTrash) {
      colors.add(TrashColors.trashColor);
      borderColors.add(TrashColors.trashColor);
    }
    if (hasBio) {
      colors.add(TrashColors.bioColor);
      borderColors.add(TrashColors.bioColor);
    }

    if (colors.length == 1) {
      return Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.first,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1, color: borderColors.first),
        ),
        child: Center(
          child: Text(
            day.day.toString(),
            style: TextStyle(color: _getCalendarTextColor(colors, hasPaper, hasTrash, hasBio), fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1, color: Colors.grey.shade400),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          children: [
            Row(
              children: colors.map((color) {
                return Expanded(
                  child: Container(height: double.infinity, color: color),
                );
              }).toList(),
            ),
            Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(color: _getCalendarTextColor(colors, hasPaper, hasTrash, hasBio), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getCalendarTextColor(List<Color> colors, bool hasPaper, bool hasTrash, bool hasBio) {
    if (hasPaper || hasTrash || hasBio) {
      return Colors.white;
    }
    return Colors.black;
  }
}
