import 'dart:convert';
import 'dart:typed_data';

import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Why an imported schedule was rejected.
enum ScheduleError {
  /// Not a Trashifier file or link at all.
  notTrashifier,

  /// Made by a newer app version with a format this one doesn't know.
  newerVersion,

  /// Bigger than any real schedule; refused before parsing.
  tooLarge,

  /// Broken or tampered with.
  invalid,

  /// Valid, but without a single pickup.
  empty,
}

class ScheduleFormatException implements Exception {
  final ScheduleError error;

  const ScheduleFormatException(this.error);

  @override
  String toString() => 'ScheduleFormatException(${error.name})';
}

/// Pickup dates read from a backup file or a shared link.
class Schedule {
  /// Every bin type, each list sorted and without duplicates.
  final Map<TrashType, List<DateTime>> dates;

  /// Entries that were dropped because they weren't valid dates.
  final int skipped;

  const Schedule(this.dates, {this.skipped = 0});

  int get total => dates.values.fold(0, (sum, list) => sum + list.length);

  int count(TrashType type) => dates[type]?.length ?? 0;

  DateTime? get first => _all.isEmpty ? null : _all.first;
  DateTime? get last => _all.isEmpty ? null : _all.last;

  List<DateTime> get _all => [for (final list in dates.values) ...list]..sort();
}

/// Encodes pickup dates for backups and sharing, and decodes them again.
///
/// Everything decoded here is untrusted (a file or QR code from someone
/// else), so decoding is strict: sizes are capped before parsing, only known
/// bins and real calendar days in [minDate]..[maxDate] are kept, and any
/// structural problem rejects the whole input.
class ScheduleCodec {
  static const String appId = 'trashifier';
  static const int formatVersion = 1;

  /// Room for a decade of all four bins every day (about 290 000
  /// characters). Same cap as MAX_CHARS in TransferChannel.kt.
  static const int maxFileChars = 512 * 1024;
  static const int maxDatesPerBin = 5000;
  static const int maxLinkChars = 4096;

  static final DateTime minDate = DateTime(2000);
  static final DateTime maxDate = DateTime(2100, 12, 31);

  static const String linkScheme = 'trashifier';
  static const String linkHost = 'import';

  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  // ---------------------------------------------------------------------------
  // Backup file (JSON)
  // ---------------------------------------------------------------------------

  /// A readable JSON file with every pickup, past ones included, or only
  /// those from [from] on (for sharing).
  static String encodeFile(
    Map<TrashType, List<DateTime>> datesByType, {
    DateTime? now,
    DateTime? from,
  }) {
    final start = from == null ? null : DateFormatHelper.dateOnly(from);
    final data = {
      'app': appId,
      'format': formatVersion,
      'exported': _encodeDay(now ?? DateTime.now()),
      'bins': {
        for (final type in TrashType.values)
          type.name: _clean(datesByType[type] ?? const [])
              .where((date) => start == null || !date.isBefore(start))
              .map(_encodeDay)
              .toList(),
      },
    };
    return '${const JsonEncoder.withIndent('  ').convert(data)}\n';
  }

  static Schedule decodeFile(String text) {
    if (text.length > maxFileChars) {
      throw const ScheduleFormatException(ScheduleError.tooLarge);
    }

    final Object? data;
    try {
      data = jsonDecode(text);
    } on FormatException {
      throw const ScheduleFormatException(ScheduleError.notTrashifier);
    }
    if (data is! Map<String, Object?> || data['app'] != appId) {
      throw const ScheduleFormatException(ScheduleError.notTrashifier);
    }

    final format = data['format'];
    if (format is! int || format < 1) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }
    if (format > formatVersion) {
      throw const ScheduleFormatException(ScheduleError.newerVersion);
    }

    final bins = data['bins'];
    if (bins is! Map<String, Object?>) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }

    var skipped = 0;
    final dates = <TrashType, List<DateTime>>{};
    for (final type in TrashType.values) {
      final list = bins[type.name];
      if (list == null) {
        dates[type] = [];
        continue;
      }
      if (list is! List<Object?>) {
        throw const ScheduleFormatException(ScheduleError.invalid);
      }
      if (list.length > maxDatesPerBin) {
        throw const ScheduleFormatException(ScheduleError.tooLarge);
      }
      final parsed = <DateTime>[];
      for (final value in list) {
        final date = value is String ? _decodeDay(value) : null;
        if (date == null) {
          skipped++;
        } else {
          parsed.add(date);
        }
      }
      dates[type] = _clean(parsed);
    }
    // Bins this version doesn't know (e.g. custom bins from a newer version)
    // are ignored.

    final schedule = Schedule(dates, skipped: skipped);
    if (schedule.total == 0) {
      throw const ScheduleFormatException(ScheduleError.empty);
    }
    return schedule;
  }

  // ---------------------------------------------------------------------------
  // Share link (QR code)
  // ---------------------------------------------------------------------------

  /// A compact `trashifier://import?v=1&d=...` link with the pickups from
  /// [from] (default today) on, small enough for one QR code.
  ///
  /// Payload: per bin with dates, its index byte, the date count, the first
  /// date as days since 2000-01-01, then the gaps in days; numbers are
  /// LEB128 varints, the bytes base64url without padding.
  static String encodeLink(
    Map<TrashType, List<DateTime>> datesByType, {
    DateTime? from,
  }) {
    final start = DateFormatHelper.dateOnly(from ?? DateTime.now());
    final bytes = <int>[];
    for (final type in TrashType.values) {
      final days = _clean(
        datesByType[type] ?? const [],
      ).where((date) => !date.isBefore(start)).map(_dayNumber).toList();
      if (days.isEmpty) continue;
      bytes.add(type.index);
      _writeVarint(bytes, days.length);
      _writeVarint(bytes, days.first);
      for (var i = 1; i < days.length; i++) {
        _writeVarint(bytes, days[i] - days[i - 1]);
      }
    }
    final payload = base64Url.encode(bytes).replaceAll('=', '');
    return '$linkScheme://$linkHost?v=$formatVersion&d=$payload';
  }

  /// Pickups from a link made by [encodeLink].
  static Schedule decodeLink(String link) {
    if (link.length > maxLinkChars) {
      throw const ScheduleFormatException(ScheduleError.tooLarge);
    }
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != linkScheme || uri.host != linkHost) {
      throw const ScheduleFormatException(ScheduleError.notTrashifier);
    }

    // Throws on malformed percent-encoding such as "%FF".
    final Map<String, String> params;
    try {
      params = uri.queryParameters;
    } on FormatException {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }

    final version = int.tryParse(params['v'] ?? '');
    if (version == null || version < 1) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }
    if (version > formatVersion) {
      throw const ScheduleFormatException(ScheduleError.newerVersion);
    }

    final Uint8List bytes;
    try {
      final payload = params['d'] ?? '';
      bytes = base64Url.decode(base64Url.normalize(payload));
    } on FormatException {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }

    final reader = _VarintReader(bytes);
    final dates = {for (final type in TrashType.values) type: <DateTime>[]};
    final seen = <int>{};
    while (!reader.done) {
      final index = reader.byte();
      final count = reader.varint();
      if (count < 1 || count > maxDatesPerBin || !seen.add(index)) {
        throw const ScheduleFormatException(ScheduleError.invalid);
      }
      var day = reader.varint();
      final maxDay = _dayNumber(maxDate);
      final list = <DateTime>[];
      for (var i = 0; i < count; i++) {
        if (i > 0) {
          final gap = reader.varint();
          if (gap < 1) {
            throw const ScheduleFormatException(ScheduleError.invalid);
          }
          day += gap;
        }
        // Checked before converting: huge day numbers overflow DateTime.
        if (day > maxDay) {
          throw const ScheduleFormatException(ScheduleError.invalid);
        }
        final date = _dateFromNumber(day);
        list.add(date);
      }
      // A bin index this version doesn't know is read and ignored.
      if (index < TrashType.values.length) {
        dates[TrashType.values[index]] = list;
      }
    }

    final schedule = Schedule(dates);
    if (schedule.total == 0) {
      throw const ScheduleFormatException(ScheduleError.empty);
    }
    return schedule;
  }

  // ---------------------------------------------------------------------------
  // Merging
  // ---------------------------------------------------------------------------

  /// [current] plus [incoming], per bin, without duplicates.
  static Map<TrashType, List<DateTime>> merge(
    Map<TrashType, List<DateTime>> current,
    Map<TrashType, List<DateTime>> incoming,
  ) {
    return {
      for (final type in TrashType.values)
        type: _clean([...?current[type], ...?incoming[type]]),
    };
  }

  // ---------------------------------------------------------------------------

  static String _encodeDay(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _decodeDay(String value) {
    final match = _datePattern.firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // Rejects overflowing days such as 2026-02-31.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    if (date.isBefore(minDate) || date.isAfter(maxDate)) return null;
    return date;
  }

  /// Calendar days, sorted, without duplicates.
  static List<DateTime> _clean(Iterable<DateTime> dates) {
    final unique = {for (final date in dates) DateFormatHelper.dateOnly(date)};
    return unique.toList()..sort();
  }

  static final DateTime _epoch = DateTime.utc(2000);

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

  static DateTime _dateFromNumber(int day) {
    final utc = _epoch.add(Duration(days: day));
    return DateTime(utc.year, utc.month, utc.day);
  }

  static void _writeVarint(List<int> out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    out.add(v);
  }
}

class _VarintReader {
  final Uint8List _bytes;
  int _pos = 0;

  _VarintReader(this._bytes);

  bool get done => _pos >= _bytes.length;

  int byte() {
    if (done) throw const ScheduleFormatException(ScheduleError.invalid);
    return _bytes[_pos++];
  }

  int varint() {
    var result = 0;
    for (var shift = 0; shift < 28; shift += 7) {
      final b = byte();
      result |= (b & 0x7F) << shift;
      if (b < 0x80) return result;
    }
    // Longer than any day number or count we write.
    throw const ScheduleFormatException(ScheduleError.invalid);
  }
}
