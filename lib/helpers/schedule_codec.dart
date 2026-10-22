import 'dart:convert';
import 'dart:typed_data';

import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/models/bin_style.dart';
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
  /// The four built-ins (possibly empty), then any custom bins it defines,
  /// each list sorted and without duplicates. Custom bins carry the sender's
  /// name, color and icon; their ids and slots only identify them here.
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

  /// Newest format this version reads and writes (2 adds custom bins).
  static const int formatVersion = 2;

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

  /// A readable JSON file with every pickup of every bin in
  /// [datesByType], past ones included, or only those from [from] on (for
  /// sharing). Format 1 (built-ins only, readable by older versions) unless
  /// a custom bin is included; format 2 then also carries its name, color
  /// and icon.
  static String encodeFile(
    Map<TrashType, List<DateTime>> datesByType, {
    DateTime? now,
    DateTime? from,
  }) {
    final start = from == null ? null : DateFormatHelper.dateOnly(from);
    List<String> days(TrashType type) => _clean(datesByType[type] ?? const [])
        .where((date) => start == null || !date.isBefore(start))
        .map(_encodeDay)
        .toList();
    final custom = datesByType.keys.any((type) => !type.isBuiltIn);
    final data = {
      'app': appId,
      'format': custom ? formatVersion : 1,
      'exported': _encodeDay(now ?? DateTime.now()),
      'bins': custom
          ? [
              for (final type in datesByType.keys)
                {
                  'id': type.id,
                  if (!type.isBuiltIn) ...{
                    'name': type.customName,
                    'color': type.color,
                    'icon': type.icon,
                  },
                  'dates': days(type),
                },
            ]
          : {for (final type in TrashType.builtIns) type.id: days(type)},
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

    final parser = _DateListParser();
    final dates = <TrashType, List<DateTime>>{
      for (final type in TrashType.builtIns) type: <DateTime>[],
    };
    final bins = data['bins'];
    if (format == 1) {
      if (bins is! Map<String, Object?>) {
        throw const ScheduleFormatException(ScheduleError.invalid);
      }
      for (final type in TrashType.builtIns) {
        final list = bins[type.id];
        if (list != null) dates[type] = parser.parse(list);
      }
      // Bins this version doesn't know are ignored.
    } else {
      if (bins is! List<Object?> || bins.length > TrashType.maxBins) {
        throw const ScheduleFormatException(ScheduleError.invalid);
      }
      final ids = <String>{};
      for (final entry in bins) {
        if (entry is! Map<String, Object?>) {
          throw const ScheduleFormatException(ScheduleError.invalid);
        }
        final id = entry['id'];
        if (id is! String || !TrashType.isValidId(id) || !ids.add(id)) {
          throw const ScheduleFormatException(ScheduleError.invalid);
        }
        final builtIn = TrashType.builtIns.where((t) => t.id == id).firstOrNull;
        final type =
            builtIn ??
            _customBin(
              id: id,
              name: entry['name'],
              color: entry['color'],
              icon: entry['icon'],
              index: dates.length,
            );
        dates[type] = parser.parse(entry['dates'] ?? const <Object?>[]);
      }
    }
    final skipped = parser.skipped;

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
  /// Payload: per bin with dates a tag byte, then the date count, the first
  /// date as days since 2000-01-01 and the gaps in days; numbers are LEB128
  /// varints, the bytes base64url without padding. The tag is the built-in's
  /// slot (0-3), or [_customTag] followed by the color byte, the icon byte
  /// and the UTF-8 name with a length byte (version 2, only when a custom
  /// bin has dates, so links without one stay readable by older versions).
  static String encodeLink(
    Map<TrashType, List<DateTime>> datesByType, {
    DateTime? from,
  }) {
    final start = DateFormatHelper.dateOnly(from ?? DateTime.now());
    final bytes = <int>[];
    var version = 1;
    for (final type in datesByType.keys) {
      final days = _clean(
        datesByType[type] ?? const [],
      ).where((date) => !date.isBefore(start)).map(_dayNumber).toList();
      if (days.isEmpty) continue;
      if (type.isBuiltIn) {
        bytes.add(type.slot);
      } else {
        version = formatVersion;
        final name = utf8.encode(TrashType.cleanName(type.customName) ?? '?');
        bytes
          ..add(_customTag)
          ..add(type.color)
          ..add(type.icon)
          ..add(name.length)
          ..addAll(name);
      }
      _writeVarint(bytes, days.length);
      _writeVarint(bytes, days.first);
      for (var i = 1; i < days.length; i++) {
        _writeVarint(bytes, days[i] - days[i - 1]);
      }
    }
    final payload = base64Url.encode(bytes).replaceAll('=', '');
    return '$linkScheme://$linkHost?v=$version&d=$payload';
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
    final dates = <TrashType, List<DateTime>>{
      for (final type in TrashType.builtIns) type: <DateTime>[],
    };
    final seen = <int>{};
    var customs = 0;
    while (!reader.done) {
      final index = reader.byte();
      TrashType? custom;
      if (index == _customTag) {
        if (version < 2 || ++customs > TrashType.maxBins) {
          throw const ScheduleFormatException(ScheduleError.invalid);
        }
        final color = reader.byte();
        final icon = reader.byte();
        final name = reader.bytes(reader.byte());
        final String text;
        try {
          text = utf8.decode(name);
        } on FormatException {
          throw const ScheduleFormatException(ScheduleError.invalid);
        }
        custom = _customBin(
          id: 'cq$customs',
          name: text,
          color: color,
          icon: icon,
          index: dates.length,
        );
      } else if (!seen.add(index)) {
        throw const ScheduleFormatException(ScheduleError.invalid);
      }
      final count = reader.varint();
      if (count < 1 || count > maxDatesPerBin) {
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
      if (custom != null) {
        dates[custom] = list;
      } else if (index < TrashType.builtIns.length) {
        dates[TrashType.builtIns[index]] = list;
      }
      // Any other index is a bin this version doesn't know: read and ignored.
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
      for (final type in {...current.keys, ...incoming.keys})
        type: _clean([...?current[type], ...?incoming[type]]),
    };
  }

  // ---------------------------------------------------------------------------

  /// Marks a custom bin in a version 2 link (built-ins use their slot).
  static const int _customTag = 0x10;

  /// An incoming custom bin; anything invalid rejects the whole input.
  static TrashType _customBin({
    required String id,
    required Object? name,
    required Object? color,
    required Object? icon,
    required int index,
  }) {
    final cleaned = name is String ? TrashType.cleanName(name) : null;
    if (cleaned == null ||
        color is! int ||
        color < 0 ||
        color >= BinStyle.colors.length ||
        icon is! int ||
        icon < 0 ||
        icon >= BinStyle.icons.length) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }
    return TrashType(
      id: id,
      // Placeholder: identifies the bin within this schedule only.
      slot: TrashType.builtIns.length + index,
      position: index,
      customName: cleaned,
      color: color,
      icon: icon,
    );
  }

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

  /// The next [length] bytes.
  List<int> bytes(int length) {
    if (length < 1 || _pos + length > _bytes.length) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }
    final out = _bytes.sublist(_pos, _pos + length);
    _pos += length;
    return out;
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

/// Reads date lists from a backup file, counting invalid entries.
class _DateListParser {
  int skipped = 0;

  List<DateTime> parse(Object? list) {
    if (list is! List<Object?>) {
      throw const ScheduleFormatException(ScheduleError.invalid);
    }
    if (list.length > ScheduleCodec.maxDatesPerBin) {
      throw const ScheduleFormatException(ScheduleError.tooLarge);
    }
    final parsed = <DateTime>[];
    for (final value in list) {
      final date = value is String ? ScheduleCodec._decodeDay(value) : null;
      if (date == null) {
        skipped++;
      } else {
        parsed.add(date);
      }
    }
    return ScheduleCodec._clean(parsed);
  }
}
