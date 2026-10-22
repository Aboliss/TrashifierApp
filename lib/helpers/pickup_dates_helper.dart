import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// One collection day and every bin that goes out on it.
class PickupDay {
  final DateTime date;

  /// In the user's bin order.
  final List<TrashType> types;

  const PickupDay(this.date, this.types);

  int daysUntil([DateTime? now]) =>
      DateFormatHelper.calculateDaysUntil(date, now);
}

class PickupDatesHelper {
  /// Upcoming collection days (see [DateFormatHelper.isFuture]), earliest
  /// first, each with its bins.
  static List<PickupDay> upcomingDays(
    Map<TrashType, List<DateTime>> datesByType, [
    DateTime? now,
  ]) {
    now ??= DateTime.now();
    final byDay = <DateTime, Set<TrashType>>{};
    for (final entry in datesByType.entries) {
      for (final date in entry.value) {
        if (!DateFormatHelper.isFuture(date, now)) continue;
        byDay
            .putIfAbsent(DateFormatHelper.dateOnly(date), () => {})
            .add(entry.key);
      }
    }

    final days = byDay.keys.toList()..sort();
    return [
      for (final day in days)
        PickupDay(
          day,
          byDay[day]!.toList()..sort((a, b) => a.index.compareTo(b.index)),
        ),
    ];
  }

  /// Trash types collected on [day].
  static Set<TrashType> typesOn(
    Map<TrashType, List<DateTime>> datesByType,
    DateTime day,
  ) {
    return {
      for (final entry in datesByType.entries)
        if (entry.value.any((date) => DateFormatHelper.isSameDate(date, day)))
          entry.key,
    };
  }

  /// Makes [selected] exactly the types collected on [day].
  ///
  /// Returns the new, sorted date list for every type whose membership on
  /// [day] changes; types that stay the same are left out, so an empty map
  /// means nothing needs saving.
  static Map<TrashType, List<DateTime>> setTypesForDay(
    Map<TrashType, List<DateTime>> datesByType,
    DateTime day,
    Set<TrashType> selected,
  ) {
    final pickupDay = DateFormatHelper.dateOnly(day);
    final changes = <TrashType, List<DateTime>>{};

    for (final type in {...datesByType.keys, ...selected}) {
      final dates = datesByType[type] ?? const <DateTime>[];
      final hasDay = dates.any(
        (date) => DateFormatHelper.isSameDate(date, pickupDay),
      );
      final wantsDay = selected.contains(type);
      if (hasDay == wantsDay) continue;

      changes[type] = wantsDay
          ? ([...dates, pickupDay]..sort())
          : dates
                .where((date) => !DateFormatHelper.isSameDate(date, pickupDay))
                .toList();
    }
    return changes;
  }
}
