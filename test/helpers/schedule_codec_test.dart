import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Days since 2000-01-01, computed independently of the codec.
int dayNumber(DateTime date) => DateTime.utc(
  date.year,
  date.month,
  date.day,
).difference(DateTime.utc(2000)).inDays;

/// LEB128 varint, written independently of the codec.
List<int> varint(int value) {
  final out = <int>[];
  var v = value;
  while (v >= 0x80) {
    out.add((v & 0x7F) | 0x80);
    v >>= 7;
  }
  out.add(v);
  return out;
}

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String linkFromBytes(List<int> bytes, {String version = '1'}) {
  final payload = base64Url.encode(bytes).replaceAll('=', '');
  return 'trashifier://import?v=$version&d=$payload';
}

/// Raw link payload for one bin: index, count, first day, gaps.
List<int> binBytes(int index, List<int> days) {
  return [
    index,
    ...varint(days.length),
    ...varint(days.first),
    for (var i = 1; i < days.length; i++) ...varint(days[i] - days[i - 1]),
  ];
}

String fileJson(
  Object? bins, {
  Object? app = 'trashifier',
  Object? format = 1,
}) {
  return jsonEncode({
    'app': app,
    'format': format,
    'exported': '2026-10-18',
    'bins': bins,
  });
}

Matcher throwsScheduleError(ScheduleError error) => throwsA(
  isA<ScheduleFormatException>().having((e) => e.error, 'error', error),
);

Map<TrashType, List<DateTime>> emptyBins() => {
  for (final type in TrashType.builtIns) type: <DateTime>[],
};

void main() {
  group('ScheduleCodec', () {
    group('Schedule', () {
      test('should compute total, count, first and last', () {
        final schedule = Schedule({
          TrashType.plastic: [DateTime(2026, 1, 5), DateTime(2026, 3, 1)],
          TrashType.paper: [DateTime(2025, 12, 30)],
          TrashType.trash: [],
          TrashType.bio: [DateTime(2026, 6, 1)],
        }, skipped: 2);

        expect(schedule.total, equals(4));
        expect(schedule.count(TrashType.plastic), equals(2));
        expect(schedule.count(TrashType.trash), equals(0));
        expect(schedule.first, equals(DateTime(2025, 12, 30)));
        expect(schedule.last, equals(DateTime(2026, 6, 1)));
        expect(schedule.skipped, equals(2));
      });

      test('should handle missing bins and no dates', () {
        const schedule = Schedule({});

        expect(schedule.total, equals(0));
        expect(schedule.count(TrashType.bio), equals(0));
        expect(schedule.first, isNull);
        expect(schedule.last, isNull);
        expect(schedule.skipped, equals(0));
      });
    });

    group('encodeFile', () {
      test('should write app, format, exported date and all bins', () {
        final text = ScheduleCodec.encodeFile({
          TrashType.plastic: [DateTime(2026, 1, 5)],
        }, now: DateTime(2026, 10, 18, 14, 30));

        final data = jsonDecode(text) as Map<String, dynamic>;
        expect(data['app'], equals('trashifier'));
        expect(data['format'], equals(1));
        expect(data['exported'], equals('2026-10-18'));
        expect(
          (data['bins'] as Map).keys,
          unorderedEquals(['plastic', 'paper', 'trash', 'bio']),
        );
        expect(data['bins']['plastic'], equals(['2026-01-05']));
        expect(data['bins']['paper'], isEmpty);
      });

      test('should be pretty-printed with a trailing newline', () {
        final text = ScheduleCodec.encodeFile(emptyBins(), now: DateTime(2026));

        expect(text, contains('\n  "app": "trashifier"'));
        expect(text.endsWith('}\n'), isTrue);
      });

      test('should sort, dedupe and drop the time of day', () {
        final text = ScheduleCodec.encodeFile({
          TrashType.bio: [
            DateTime(2026, 5, 3, 18),
            DateTime(2026, 1, 9),
            DateTime(2026, 5, 3, 7),
            DateTime(2026, 1, 9),
          ],
        }, now: DateTime(2026));

        final data = jsonDecode(text) as Map<String, dynamic>;
        expect(data['bins']['bio'], equals(['2026-01-09', '2026-05-03']));
      });

      test('should keep only dates on or after from', () {
        final text = ScheduleCodec.encodeFile(
          {
            TrashType.paper: [
              DateTime(2026, 10, 17),
              DateTime(2026, 10, 18),
              DateTime(2026, 10, 19),
            ],
          },
          now: DateTime(2026, 10, 18),
          from: DateTime(2026, 10, 18, 23, 59),
        );

        final data = jsonDecode(text) as Map<String, dynamic>;
        expect(data['bins']['paper'], equals(['2026-10-18', '2026-10-19']));
      });

      test('should keep past dates without from', () {
        final text = ScheduleCodec.encodeFile({
          TrashType.trash: [DateTime(2001, 2, 3)],
        }, now: DateTime(2026, 10, 18));

        final data = jsonDecode(text) as Map<String, dynamic>;
        expect(data['bins']['trash'], equals(['2001-02-03']));
      });
    });

    group('decodeFile', () {
      test('should read a valid file', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'plastic': ['2026-01-05', '2026-02-02'],
            'bio': ['2026-03-01'],
          }),
        );

        expect(schedule.dates[TrashType.plastic], [
          DateTime(2026, 1, 5),
          DateTime(2026, 2, 2),
        ]);
        expect(schedule.dates[TrashType.bio], [DateTime(2026, 3, 1)]);
        expect(schedule.dates[TrashType.paper], isEmpty);
        expect(schedule.dates[TrashType.trash], isEmpty);
        expect(schedule.dates.keys, unorderedEquals(TrashType.builtIns));
        expect(schedule.skipped, equals(0));
      });

      test('should sort and remove duplicates', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'paper': ['2026-05-01', '2026-01-01', '2026-05-01', '2026-03-01'],
          }),
        );

        expect(schedule.dates[TrashType.paper], [
          DateTime(2026, 1, 1),
          DateTime(2026, 3, 1),
          DateTime(2026, 5, 1),
        ]);
        expect(schedule.skipped, equals(0));
      });

      test('should skip and count invalid entries', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'trash': [
              '2026-01-05', // valid
              '2026-1-5', // no zero padding
              '2026-02-31', // overflow
              '2026-13-01', // bad month
              '2026-00-10', // month zero
              '2026-01-00', // day zero
              '1999-12-31', // before range
              '2101-01-01', // after range
              '2100-02-29', // 2100 is not a leap year
              ' 2026-01-06', // whitespace
              '2026-01-07T00:00', // time part
              '', // empty
              20260108, // number
              null,
              true,
              ['2026-01-09'],
              {'date': '2026-01-10'},
            ],
          }),
        );

        expect(schedule.dates[TrashType.trash], [DateTime(2026, 1, 5)]);
        expect(schedule.skipped, equals(16));
      });

      test('should accept range boundaries and leap days', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'bio': ['2000-01-01', '2000-02-29', '2024-02-29', '2100-12-31'],
          }),
        );

        expect(schedule.dates[TrashType.bio], [
          DateTime(2000, 1, 1),
          DateTime(2000, 2, 29),
          DateTime(2024, 2, 29),
          DateTime(2100, 12, 31),
        ]);
        expect(schedule.skipped, equals(0));
      });

      test('should count skipped entries across bins', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'plastic': ['bad', '2026-01-01'],
            'paper': [1, 2],
            'bio': [null],
          }),
        );

        expect(schedule.total, equals(1));
        expect(schedule.skipped, equals(4));
      });

      test('should ignore unknown bin keys', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'plastic': ['2026-01-01'],
            'glass': ['2026-02-01'],
            'custom': 'not even a list',
          }),
        );

        expect(schedule.total, equals(1));
        expect(schedule.skipped, equals(0));
      });

      test('should treat a null bin as empty', () {
        final schedule = ScheduleCodec.decodeFile(
          fileJson({
            'plastic': null,
            'paper': ['2026-01-01'],
          }),
        );

        expect(schedule.dates[TrashType.plastic], isEmpty);
        expect(schedule.total, equals(1));
      });

      test('should reject text over maxFileChars before parsing', () {
        final text = ' ' * (ScheduleCodec.maxFileChars + 1);

        expect(
          () => ScheduleCodec.decodeFile(text),
          throwsScheduleError(ScheduleError.tooLarge),
        );
      });

      test('should accept a file exactly at maxFileChars', () {
        final base = fileJson({
          'plastic': ['2026-01-01'],
        });
        final text = base.padRight(ScheduleCodec.maxFileChars);

        expect(text.length, equals(ScheduleCodec.maxFileChars));
        expect(ScheduleCodec.decodeFile(text).total, equals(1));
      });

      test('should reject non-JSON as notTrashifier', () {
        for (final text in [
          '',
          'hello',
          '{',
          '{"app": "trashifier",',
          '\u0000\u0001\u0002',
          '<html></html>',
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(text),
            throwsScheduleError(ScheduleError.notTrashifier),
            reason: 'input: $text',
          );
        }
      });

      test('should reject JSON that is not a Trashifier object', () {
        for (final text in [
          '[]',
          '"trashifier"',
          '42',
          'null',
          'true',
          '{}',
          '{"bins": {"plastic": ["2026-01-01"]}}',
          fileJson({}, app: 'other'),
          fileJson({}, app: null),
          fileJson({}, app: 1),
          fileJson({}, app: ['trashifier']),
          fileJson({}, app: 'Trashifier'),
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(text),
            throwsScheduleError(ScheduleError.notTrashifier),
            reason: 'input: $text',
          );
        }
      });

      test('should reject a missing or malformed format as invalid', () {
        for (final format in [
          null,
          0,
          -1,
          1.0,
          1.5,
          '1',
          true,
          [1],
          {},
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(
              fileJson({
                'plastic': ['2026-01-01'],
              }, format: format),
            ),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'format: $format',
          );
        }
      });

      test('should reject a newer format', () {
        for (final format in [3, 99]) {
          expect(
            () => ScheduleCodec.decodeFile(
              fileJson({
                'plastic': ['2026-01-01'],
              }, format: format),
            ),
            throwsScheduleError(ScheduleError.newerVersion),
          );
        }
      });

      test('should reject bins that are not a map', () {
        for (final bins in [
          null,
          [],
          ['2026-01-01'],
          'plastic',
          1,
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(fileJson(bins)),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'bins: $bins',
          );
        }
      });

      test('should reject a known bin that is not a list', () {
        for (final value in [
          '2026-01-01',
          1,
          true,
          {'0': '2026-01-01'},
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(
              fileJson({
                'paper': ['2026-01-01'],
                'plastic': value,
              }),
            ),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'value: $value',
          );
        }
      });

      test('should reject a bin longer than maxDatesPerBin', () {
        final list = List.filled(ScheduleCodec.maxDatesPerBin + 1, 0);

        expect(
          () => ScheduleCodec.decodeFile(fileJson({'bio': list})),
          throwsScheduleError(ScheduleError.tooLarge),
        );
      });

      test('should accept a bin of exactly maxDatesPerBin', () {
        final list = [
          for (var i = 0; i < ScheduleCodec.maxDatesPerBin; i++)
            isoDay(DateTime.utc(2012, 1, 1 + i)),
        ];

        final schedule = ScheduleCodec.decodeFile(fileJson({'bio': list}));
        expect(schedule.count(TrashType.bio), ScheduleCodec.maxDatesPerBin);
      });

      test('should reject files with no valid dates as empty', () {
        for (final bins in [
          <String, Object?>{},
          {'plastic': [], 'paper': [], 'trash': [], 'bio': []},
          {
            'plastic': ['nope', '2026-02-30'],
          },
          {
            'glass': ['2026-01-01'],
          },
        ]) {
          expect(
            () => ScheduleCodec.decodeFile(fileJson(bins)),
            throwsScheduleError(ScheduleError.empty),
            reason: 'bins: $bins',
          );
        }
      });

      test('should not crash on deeply nested JSON', () {
        final deep = '${'[' * 2000}${']' * 2000}';
        final text =
            '{"app":"trashifier","format":1,"bins":{"plastic":[$deep]}}';

        expect(
          () => ScheduleCodec.decodeFile(text),
          throwsScheduleError(ScheduleError.empty),
        );
      });

      test('should only throw ScheduleFormatException for random text', () {
        final random = Random(42);
        for (var i = 0; i < 300; i++) {
          final text = String.fromCharCodes([
            for (var j = 0; j < random.nextInt(200); j++) random.nextInt(128),
          ]);
          try {
            ScheduleCodec.decodeFile(text);
          } on ScheduleFormatException {
            // Expected.
          }
        }
      });
    });

    group('encodeLink', () {
      test('should produce the documented binary layout', () {
        final link = ScheduleCodec.encodeLink({
          TrashType.paper: [
            DateTime(2000, 1, 1),
            DateTime(2000, 1, 15),
            DateTime(2000, 6, 1),
          ],
        }, from: DateTime(2000));

        // paper index 1, count 3, first day 0, gaps 14 and 138.
        expect(link, equals(linkFromBytes([1, 3, 0, 14, 138, 1])));
      });

      test('should use the trashifier://import scheme with v=1', () {
        final link = ScheduleCodec.encodeLink({
          TrashType.bio: [DateTime(2026, 10, 20)],
        }, from: DateTime(2026, 10, 18));

        final uri = Uri.parse(link);
        expect(uri.scheme, equals('trashifier'));
        expect(uri.host, equals('import'));
        expect(uri.queryParameters['v'], equals('1'));
        expect(uri.queryParameters['d'], isNot(contains('=')));
        expect(uri.queryParameters['d'], matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      });

      test('should drop dates before from, keeping from itself', () {
        final link = ScheduleCodec.encodeLink({
          TrashType.plastic: [
            DateTime(2026, 10, 17),
            DateTime(2026, 10, 18, 6),
            DateTime(2026, 10, 25),
          ],
          TrashType.paper: [DateTime(2026, 10, 1)],
        }, from: DateTime(2026, 10, 18, 20));

        final schedule = ScheduleCodec.decodeLink(link);
        expect(schedule.dates[TrashType.plastic], [
          DateTime(2026, 10, 18),
          DateTime(2026, 10, 25),
        ]);
        expect(schedule.dates[TrashType.paper], isEmpty);
      });

      test('should default from to today', () {
        final today = DateTime.now();
        final link = ScheduleCodec.encodeLink({
          TrashType.trash: [
            today.subtract(const Duration(days: 3)),
            DateTime(today.year, today.month, today.day),
            DateTime(today.year + 1, today.month, 1),
          ],
        });

        final schedule = ScheduleCodec.decodeLink(link);
        expect(schedule.count(TrashType.trash), equals(2));
        expect(
          schedule.first,
          equals(DateTime(today.year, today.month, today.day)),
        );
      });

      test('should dedupe dates within a bin', () {
        final link = ScheduleCodec.encodeLink({
          TrashType.bio: [
            DateTime(2026, 11, 2, 8),
            DateTime(2026, 11, 2, 19),
            DateTime(2026, 11, 2),
          ],
        }, from: DateTime(2026, 10, 18));

        expect(
          ScheduleCodec.decodeLink(link).dates[TrashType.bio],
          equals([DateTime(2026, 11, 2)]),
        );
      });

      test('should encode nothing when no date is upcoming', () {
        final link = ScheduleCodec.encodeLink({
          TrashType.bio: [DateTime(2020)],
        }, from: DateTime(2026, 10, 18));

        expect(link, equals('trashifier://import?v=1&d='));
        expect(
          () => ScheduleCodec.decodeLink(link),
          throwsScheduleError(ScheduleError.empty),
        );
      });

      test('should keep a realistic year of four biweekly bins short', () {
        final from = DateTime(2026, 10, 18);
        final datesByType = {
          for (final type in TrashType.builtIns)
            type: [
              for (var i = 0; i < 26; i++)
                DateTime(2026, 10, 19 + type.index + i * 14),
            ],
        };

        final link = ScheduleCodec.encodeLink(datesByType, from: from);

        expect(link.length, lessThan(300));
        final schedule = ScheduleCodec.decodeLink(link);
        expect(schedule.total, equals(104));
        for (final type in TrashType.builtIns) {
          expect(schedule.dates[type], equals(datesByType[type]));
        }
      });
    });

    group('decodeLink', () {
      test('should read a hand-built payload', () {
        final link = linkFromBytes([
          ...binBytes(0, [dayNumber(DateTime(2026, 1, 5))]),
          ...binBytes(3, [
            dayNumber(DateTime(2026, 2, 1)),
            dayNumber(DateTime(2026, 2, 15)),
          ]),
        ]);

        final schedule = ScheduleCodec.decodeLink(link);
        expect(schedule.dates[TrashType.plastic], [DateTime(2026, 1, 5)]);
        expect(schedule.dates[TrashType.bio], [
          DateTime(2026, 2, 1),
          DateTime(2026, 2, 15),
        ]);
        expect(schedule.dates[TrashType.paper], isEmpty);
        expect(schedule.dates[TrashType.trash], isEmpty);
        expect(schedule.dates.keys, unorderedEquals(TrashType.builtIns));
        expect(schedule.skipped, equals(0));
      });

      test('should accept surrounding whitespace and padded base64', () {
        final bytes = binBytes(2, [dayNumber(DateTime(2026, 3, 3))]);
        final padded = base64Url.encode(bytes);
        expect(padded, contains('='));

        final schedule = ScheduleCodec.decodeLink(
          '  trashifier://import?v=1&d=$padded\n',
        );
        expect(schedule.dates[TrashType.trash], [DateTime(2026, 3, 3)]);
      });

      test('should accept extra query parameters', () {
        final link =
            '${linkFromBytes(binBytes(0, [dayNumber(DateTime(2026, 1, 1))]))}'
            '&utm=x';

        expect(ScheduleCodec.decodeLink(link).total, equals(1));
      });

      test('should accept the last day of the range', () {
        final link = linkFromBytes(
          binBytes(0, [dayNumber(DateTime(2100, 12, 31))]),
        );

        expect(
          ScheduleCodec.decodeLink(link).first,
          equals(DateTime(2100, 12, 31)),
        );
      });

      test('should reject a date past 2100', () {
        final last = dayNumber(DateTime(2100, 12, 31));
        for (final days in [
          [last + 1],
          [last - 1, last, last + 1],
        ]) {
          expect(
            () => ScheduleCodec.decodeLink(linkFromBytes(binBytes(0, days))),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'days: $days',
          );
        }
      });

      test('should reject links over maxLinkChars', () {
        final link =
            'trashifier://import?v=1&d=${'A' * ScheduleCodec.maxLinkChars}';

        expect(
          () => ScheduleCodec.decodeLink(link),
          throwsScheduleError(ScheduleError.tooLarge),
        );
      });

      test('should reject other schemes and hosts as notTrashifier', () {
        for (final link in [
          '',
          'hello world',
          'https://import?v=1&d=AAEA',
          'https://example.com/import?v=1&d=AAEA',
          'trashifier://export?v=1&d=AAEA',
          'trashifier:import?v=1&d=AAEA',
          'trashifierx://import?v=1&d=AAEA',
          'trashifier://import.evil.com?v=1&d=AAEA',
          '{"app":"trashifier"}',
          'http://[::1',
        ]) {
          expect(
            () => ScheduleCodec.decodeLink(link),
            throwsScheduleError(ScheduleError.notTrashifier),
            reason: 'link: $link',
          );
        }
      });

      test('should reject a missing or malformed version as invalid', () {
        for (final query in [
          'd=AAEA',
          'v=&d=AAEA',
          'v=one&d=AAEA',
          'v=0&d=AAEA',
          'v=-1&d=AAEA',
          'v=1.0&d=AAEA',
        ]) {
          expect(
            () => ScheduleCodec.decodeLink('trashifier://import?$query'),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'query: $query',
          );
        }
      });

      test('should reject a newer version', () {
        expect(
          () => ScheduleCodec.decodeLink(
            linkFromBytes(binBytes(0, [9000]), version: '3'),
          ),
          throwsScheduleError(ScheduleError.newerVersion),
        );
      });

      test('should reject bad base64 as invalid', () {
        for (final d in ['!!!!', 'A', 'AAAAA', 'AA*A', 'AA AA', '+/+/']) {
          expect(
            () => ScheduleCodec.decodeLink('trashifier://import?v=1&d=$d'),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'd: $d',
          );
        }
      });

      test('should reject truncated payloads', () {
        final full = binBytes(1, [
          dayNumber(DateTime(2026, 1, 1)),
          dayNumber(DateTime(2026, 1, 15)),
          dayNumber(DateTime(2026, 1, 29)),
        ]);
        for (var length = 1; length < full.length; length++) {
          expect(
            () => ScheduleCodec.decodeLink(
              linkFromBytes(full.sublist(0, length)),
            ),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'length: $length',
          );
        }
      });

      test('should reject a zero gap', () {
        final day = dayNumber(DateTime(2026, 1, 1));

        expect(
          () => ScheduleCodec.decodeLink(
            linkFromBytes([0, ...varint(2), ...varint(day), 0]),
          ),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject a bin count of zero', () {
        expect(
          () => ScheduleCodec.decodeLink(linkFromBytes([0, 0])),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject a count above maxDatesPerBin', () {
        expect(
          () => ScheduleCodec.decodeLink(
            linkFromBytes([
              0,
              ...varint(ScheduleCodec.maxDatesPerBin + 1),
              ...varint(0),
            ]),
          ),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject a duplicate bin index', () {
        final day = dayNumber(DateTime(2026, 1, 1));
        for (final index in [0, 7]) {
          expect(
            () => ScheduleCodec.decodeLink(
              linkFromBytes([
                ...binBytes(index, [day]),
                ...binBytes(index, [day + 1]),
              ]),
            ),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'index: $index',
          );
        }
      });

      test('should read and ignore unknown bin indexes', () {
        final day = dayNumber(DateTime(2026, 1, 1));
        final link = linkFromBytes([
          ...binBytes(4, [day, day + 7, day + 14]),
          ...binBytes(2, [day + 3]),
          ...binBytes(255, [day]),
        ]);

        final schedule = ScheduleCodec.decodeLink(link);
        expect(schedule.total, equals(1));
        expect(schedule.dates[TrashType.trash], [DateTime(2026, 1, 4)]);
      });

      test('should reject a link with only unknown bins as empty', () {
        final link = linkFromBytes(binBytes(9, [9000]));

        expect(
          () => ScheduleCodec.decodeLink(link),
          throwsScheduleError(ScheduleError.empty),
        );
      });

      test('should reject an empty payload as empty', () {
        for (final link in [
          'trashifier://import?v=1',
          'trashifier://import?v=1&d=',
        ]) {
          expect(
            () => ScheduleCodec.decodeLink(link),
            throwsScheduleError(ScheduleError.empty),
            reason: 'link: $link',
          );
        }
      });

      test('should reject an overlong varint', () {
        // Five continuation bytes: longer than any count or day number.
        for (final count in [
          [0xFF, 0xFF, 0xFF, 0xFF, 0x01],
          [0x81, 0x80, 0x80, 0x80, 0x00],
          [0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01],
        ]) {
          expect(
            () => ScheduleCodec.decodeLink(linkFromBytes([0, ...count, 0])),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'count bytes: $count',
          );
        }
        // The same for the first day.
        expect(
          () => ScheduleCodec.decodeLink(
            linkFromBytes([0, 1, 0xFF, 0xFF, 0xFF, 0xFF, 0x01]),
          ),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject a huge first day without crashing', () {
        // 0x0FFFFFFF is the largest four-byte varint.
        expect(
          () => ScheduleCodec.decodeLink(
            linkFromBytes([0, 1, ...varint(0x0FFFFFFF)]),
          ),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject first days that overflow DateTime as invalid', () {
        // ~100M days past 2000 is outside DateTime's range; the codec lets
        // DateTime.add throw a RangeError instead of ScheduleFormatException.
        for (final day in [100000000, 104166666, 106751991]) {
          expect(
            () =>
                ScheduleCodec.decodeLink(linkFromBytes([0, 1, ...varint(day)])),
            throwsScheduleError(ScheduleError.invalid),
            reason: 'day: $day',
          );
        }
      });

      test('should never return unsorted or duplicate dates', () {
        // A gap of 213503983 days wraps the int64 microsecond count back to
        // 2000-01-01, giving a duplicate of the first date.
        final link = linkFromBytes([0, 2, 0, ...varint(213503983)]);

        try {
          final dates = ScheduleCodec.decodeLink(
            link,
          ).dates[TrashType.plastic]!;
          expect(dates.toSet().length, equals(dates.length));
        } on ScheduleFormatException catch (e) {
          expect(e.error, equals(ScheduleError.invalid));
        }
      });

      test('should never return dates before 2000', () {
        // 213503982 days wraps to 1999-12-31.
        final link = linkFromBytes([0, 1, ...varint(213503982)]);

        expect(
          () => ScheduleCodec.decodeLink(link),
          throwsScheduleError(ScheduleError.invalid),
        );
      });

      test('should reject invalid percent-encoding as invalid', () {
        // Uri.queryParameters throws FormatException for bytes that aren't
        // UTF-8; decodeLink reads them outside its try block.
        for (final link in [
          'trashifier://import?v=1&d=%FF',
          'trashifier://import?v=%C3',
        ]) {
          expect(
            () => ScheduleCodec.decodeLink(link),
            throwsA(isA<ScheduleFormatException>()),
            reason: 'link: $link',
          );
        }
      });

      test(
        'should only throw ScheduleFormatException for small random bytes',
        () {
          // Bytes below 0x80 are single-byte varints, so day numbers stay small.
          final random = Random(7);
          for (var i = 0; i < 2000; i++) {
            final bytes = [
              for (var j = 0; j < 1 + random.nextInt(40); j++)
                random.nextInt(0x80),
            ];
            try {
              final schedule = ScheduleCodec.decodeLink(linkFromBytes(bytes));
              for (final list in schedule.dates.values) {
                expect(list, equals(list.toSet().toList()..sort()));
                for (final date in list) {
                  expect(date.isBefore(ScheduleCodec.minDate), isFalse);
                  expect(date.isAfter(ScheduleCodec.maxDate), isFalse);
                }
              }
            } on ScheduleFormatException {
              // Expected for most inputs.
            }
          }
        },
      );

      test('should only throw ScheduleFormatException for random bytes', () {
        final random = Random(7);
        for (var i = 0; i < 2000; i++) {
          final bytes = [
            for (var j = 0; j < 1 + random.nextInt(40); j++)
              random.nextInt(256),
          ];
          try {
            final schedule = ScheduleCodec.decodeLink(linkFromBytes(bytes));
            for (final list in schedule.dates.values) {
              expect(list, equals(list.toSet().toList()..sort()));
              for (final date in list) {
                expect(date.isBefore(ScheduleCodec.minDate), isFalse);
                expect(date.isAfter(ScheduleCodec.maxDate), isFalse);
              }
            }
          } on ScheduleFormatException {
            // Expected for most inputs.
          }
        }
      });

      test('should only throw ScheduleFormatException for random strings', () {
        final random = Random(11);
        const alphabet =
            'abcdefghijklmnopqrstuvwxyzABCDEF0123456789-_=+/?&%:#. ';
        for (var i = 0; i < 1000; i++) {
          final d = String.fromCharCodes([
            for (var j = 0; j < random.nextInt(60); j++)
              alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ]);
          try {
            ScheduleCodec.decodeLink('trashifier://import?v=1&d=$d');
          } on ScheduleFormatException {
            // Expected.
          }
        }
      });

      test('should only throw ScheduleFormatException for random base64', () {
        final random = Random(11);
        const alphabet =
            'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_=';
        for (var i = 0; i < 1000; i++) {
          final d = String.fromCharCodes([
            for (var j = 0; j < random.nextInt(60); j++)
              alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ]);
          try {
            ScheduleCodec.decodeLink('trashifier://import?v=1&d=$d');
          } on ScheduleFormatException {
            // Expected.
          } on RangeError {
            // Known bug in _dateFromNumber, covered by a skipped test above.
          }
        }
      });
    });

    group('round trips', () {
      final datesByType = {
        TrashType.plastic: [
          // Leap days.
          DateTime(2000, 2, 29),
          DateTime(2024, 2, 29),
          DateTime(2028, 2, 29),
          DateTime(2096, 2, 29),
        ],
        TrashType.paper: [
          // Around EU and US DST changes, with times near midnight.
          DateTime(2026, 3, 8, 23, 30),
          DateTime(2026, 3, 29, 0, 30),
          DateTime(2026, 3, 29, 23, 59),
          DateTime(2026, 3, 30),
          DateTime(2026, 10, 25, 1, 30),
          DateTime(2026, 10, 26),
          DateTime(2026, 11, 1, 2),
        ],
        TrashType.trash: [DateTime(2000, 1, 1), DateTime(2100, 12, 31)],
        TrashType.bio: <DateTime>[],
      };

      final expected = {
        TrashType.plastic: [
          DateTime(2000, 2, 29),
          DateTime(2024, 2, 29),
          DateTime(2028, 2, 29),
          DateTime(2096, 2, 29),
        ],
        TrashType.paper: [
          DateTime(2026, 3, 8),
          DateTime(2026, 3, 29),
          DateTime(2026, 3, 30),
          DateTime(2026, 10, 25),
          DateTime(2026, 10, 26),
          DateTime(2026, 11, 1),
        ],
        TrashType.trash: [DateTime(2000, 1, 1), DateTime(2100, 12, 31)],
        TrashType.bio: <DateTime>[],
      };

      test('should survive a file round trip', () {
        final text = ScheduleCodec.encodeFile(
          datesByType,
          now: DateTime(2026, 10, 18),
        );
        final schedule = ScheduleCodec.decodeFile(text);

        expect(schedule.dates, equals(expected));
        expect(schedule.skipped, equals(0));
      });

      test('should survive a link round trip', () {
        final link = ScheduleCodec.encodeLink(
          datesByType,
          from: DateTime(2000),
        );
        final schedule = ScheduleCodec.decodeLink(link);

        expect(schedule.dates, equals(expected));
      });

      test('should survive a link round trip of every day for a year', () {
        // Covers both DST changes; each calendar day must appear once.
        final days = [for (var i = 0; i < 365; i++) DateTime(2026, 1, 1 + i)];
        expect(days.toSet().length, equals(365));

        final link = ScheduleCodec.encodeLink({
          TrashType.bio: days,
        }, from: DateTime(2026));

        expect(ScheduleCodec.decodeLink(link).dates[TrashType.bio], days);
      });

      test('should round trip a file with every bin daily for three years', () {
        final full = {
          for (final type in TrashType.builtIns)
            type: [for (var i = 0; i < 1096; i++) DateTime(2026, 1, 1 + i)],
        };

        final text = ScheduleCodec.encodeFile(full, now: DateTime(2026));
        expect(text.length, lessThanOrEqualTo(ScheduleCodec.maxFileChars));

        final schedule = ScheduleCodec.decodeFile(text);
        expect(schedule.dates, equals(full));
      });

      test('should round trip random schedules through both formats', () {
        final random = Random(2026);
        for (var run = 0; run < 50; run++) {
          final input = {
            for (final type in TrashType.builtIns)
              type: [
                for (var i = 0; i < random.nextInt(30); i++)
                  DateTime(
                    2000 + random.nextInt(100),
                    1,
                    1 + random.nextInt(366),
                  ),
              ],
          };
          final expected = {
            for (final type in TrashType.builtIns)
              type: (input[type]!.toSet().toList()..sort()),
          };
          if (expected.values.every((l) => l.isEmpty)) continue;

          final fromFile = ScheduleCodec.decodeFile(
            ScheduleCodec.encodeFile(input, now: DateTime(2026)),
          );
          expect(fromFile.dates, equals(expected), reason: 'file run $run');

          final fromLink = ScheduleCodec.decodeLink(
            ScheduleCodec.encodeLink(input, from: DateTime(2000)),
          );
          expect(fromLink.dates, equals(expected), reason: 'link run $run');
        }
      });
    });

    group('custom bins (format 2)', () {
      const glass = TrashType(
        id: 'cglass1',
        slot: 4,
        position: 4,
        customName: 'Glass',
        color: 5,
        icon: 6,
      );
      const metal = TrashType(
        id: 'cmetal1',
        slot: 7,
        position: 5,
        customName: 'Metal',
        color: 11,
        icon: 15,
      );

      Map<String, Object?> entry(
        Object? id, {
        Object? name = 'Glass',
        Object? color = 5,
        Object? icon = 6,
        Object? dates = const ['2026-01-05'],
      }) => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'dates': dates,
      };

      String file2(Object? bins) => fileJson(bins, format: 2);

      List<int> customBytes(
        String name,
        List<int> days, {
        int color = 5,
        int icon = 6,
        int? length,
      }) {
        final bytes = utf8.encode(name);
        return [
          0x10,
          color,
          icon,
          length ?? bytes.length,
          ...bytes,
          ...varint(days.length),
          ...varint(days.first),
          for (var i = 1; i < days.length; i++)
            ...varint(days[i] - days[i - 1]),
        ];
      }

      TrashType customIn(Schedule schedule, String id) =>
          schedule.dates.keys.firstWhere((type) => type.id == id);

      group('encodeFile', () {
        test('writes format 1 when only built-ins are in the map', () {
          final text = ScheduleCodec.encodeFile({
            TrashType.plastic: [DateTime(2026, 1, 5)],
            TrashType.paper.copyWith(customName: 'Cardboard'): [
              DateTime(2026, 2, 5),
            ],
          }, now: DateTime(2026));
          final data = jsonDecode(text) as Map<String, dynamic>;
          expect(data['format'], 1);
          expect(data['bins'], isA<Map<String, dynamic>>());
          expect(data['bins']['paper'], ['2026-02-05']);
        });

        test('writes format 2 with name, color and icon of custom bins', () {
          final text = ScheduleCodec.encodeFile({
            TrashType.plastic: [DateTime(2026, 1, 5)],
            glass: [DateTime(2026, 3, 1), DateTime(2026, 2, 1)],
          }, now: DateTime(2026));
          final data = jsonDecode(text) as Map<String, dynamic>;
          expect(data['format'], 2);
          expect(data['bins'], [
            {
              'id': 'plastic',
              'dates': ['2026-01-05'],
            },
            {
              'id': 'cglass1',
              'name': 'Glass',
              'color': 5,
              'icon': 6,
              'dates': ['2026-02-01', '2026-03-01'],
            },
          ]);
        });

        test('only shares dates from the given day on', () {
          final text = ScheduleCodec.encodeFile(
            {
              glass: [DateTime(2026, 1, 1), DateTime(2026, 6, 1)],
            },
            now: DateTime(2026, 3, 1),
            from: DateTime(2026, 3, 1, 15),
          );
          final data = jsonDecode(text) as Map<String, dynamic>;
          expect((data['bins'] as List).single['dates'], ['2026-06-01']);
        });
      });

      group('decodeFile', () {
        test('round-trips custom bins after the four built-ins', () {
          final input = {
            glass: [DateTime(2026, 2, 1), DateTime(2026, 3, 1)],
            TrashType.bio: [DateTime(2026, 1, 9)],
            metal: [DateTime(2026, 4, 4)],
          };
          final schedule = ScheduleCodec.decodeFile(
            ScheduleCodec.encodeFile(input, now: DateTime(2026)),
          );

          expect(schedule.dates.keys.map((t) => t.id), [
            'plastic',
            'paper',
            'trash',
            'bio',
            'cglass1',
            'cmetal1',
          ]);
          expect(schedule.dates[TrashType.bio], [DateTime(2026, 1, 9)]);
          expect(schedule.dates[TrashType.plastic], isEmpty);
          expect(schedule.dates[glass], input[glass]);
          expect(schedule.dates[metal], input[metal]);
          final readGlass = customIn(schedule, 'cglass1');
          expect(readGlass.customName, 'Glass');
          expect(readGlass.color, 5);
          expect(readGlass.icon, 6);
          expect(readGlass.isBuiltIn, isFalse);
          final readMetal = customIn(schedule, 'cmetal1');
          expect(readMetal.color, 11);
          expect(readMetal.icon, 15);
          expect(schedule.total, 4);
        });

        test('cleans names and accepts entries without dates', () {
          final schedule = ScheduleCodec.decodeFile(
            file2([
              entry('cglass', name: '  Glass\u0007  bottles  '),
              {'id': 'paper'},
              {
                'id': 'plastic',
                'dates': ['2026-01-01', 'nope'],
              },
              entry('clong', name: 'y' * 40, dates: const <String>[]),
            ]),
          );
          expect(customIn(schedule, 'cglass').customName, 'Glass bottles');
          expect(customIn(schedule, 'clong').customName, 'y' * 24);
          expect(schedule.count(TrashType.paper), 0);
          expect(schedule.count(TrashType.plastic), 1);
          expect(schedule.skipped, 1);
        });

        test('rejects a broken bins list', () {
          final cases = <String, Object?>{
            'map instead of list': {
              'plastic': ['2026-01-01'],
            },
            'not a list': 'bins',
            'entry not a map': [
              entry('cglass'),
              ['cmetal'],
            ],
            'duplicate custom id': [entry('cglass'), entry('cglass')],
            'duplicate built-in id': [
              {
                'id': 'bio',
                'dates': ['2026-01-01'],
              },
              {
                'id': 'bio',
                'dates': ['2026-01-02'],
              },
            ],
            'unknown id': [entry('glass')],
            'id not a string': [entry(4)],
            'missing name': [entry('cglass', name: null)],
            'blank name': [entry('cglass', name: ' \t ')],
            'name not a string': [entry('cglass', name: 42)],
            'color too big': [entry('cglass', color: 12)],
            'negative color': [entry('cglass', color: -1)],
            'color not an int': [entry('cglass', color: '5')],
            'icon too big': [entry('cglass', icon: 16)],
            'icon missing': [entry('cglass', icon: null)],
            'dates not a list': [entry('cglass', dates: '2026-01-01')],
            'more than ten bins': [for (var i = 0; i < 11; i++) entry('c$i')],
          };
          cases.forEach((reason, bins) {
            expect(
              () => ScheduleCodec.decodeFile(file2(bins)),
              throwsScheduleError(ScheduleError.invalid),
              reason: reason,
            );
          });
        });

        test('accepts ten bins', () {
          final schedule = ScheduleCodec.decodeFile(
            file2([for (var i = 0; i < 10; i++) entry('c$i')]),
          );
          expect(schedule.dates.length, 14);
          expect(schedule.total, 10);
        });

        test('rejects a format 1 file with a bins list', () {
          expect(
            () => ScheduleCodec.decodeFile(fileJson([entry('cglass')])),
            throwsScheduleError(ScheduleError.invalid),
          );
        });

        test('reports a format 2 file without dates as empty', () {
          expect(
            () => ScheduleCodec.decodeFile(
              file2([entry('cglass', dates: const <String>[])]),
            ),
            throwsScheduleError(ScheduleError.empty),
          );
        });
      });

      group('encodeLink', () {
        final from = DateTime(2026, 1, 1);

        test('stays v=1 when only built-ins have upcoming dates', () {
          final link = ScheduleCodec.encodeLink({
            TrashType.plastic: [DateTime(2026, 1, 5)],
            // Past only: left out, so the link stays readable by v1 apps.
            glass: [DateTime(2025, 12, 1)],
          }, from: from);
          expect(link, startsWith('trashifier://import?v=1&d='));
          final schedule = ScheduleCodec.decodeLink(link);
          expect(schedule.dates.keys, equals(TrashType.builtIns));
        });

        test('writes v=2 and round-trips custom bins', () {
          final link = ScheduleCodec.encodeLink({
            TrashType.paper: [DateTime(2026, 1, 7)],
            glass: [DateTime(2026, 1, 5), DateTime(2026, 2, 2)],
            metal: [DateTime(2026, 3, 3)],
          }, from: from);
          expect(link, startsWith('trashifier://import?v=2&d='));

          final schedule = ScheduleCodec.decodeLink(link);
          expect(schedule.dates.keys.map((t) => t.id), [
            'plastic',
            'paper',
            'trash',
            'bio',
            'cq1',
            'cq2',
          ]);
          expect(schedule.dates[TrashType.paper], [DateTime(2026, 1, 7)]);
          final first = customIn(schedule, 'cq1');
          expect(first.customName, 'Glass');
          expect(first.color, 5);
          expect(first.icon, 6);
          expect(schedule.dates[first], [
            DateTime(2026, 1, 5),
            DateTime(2026, 2, 2),
          ]);
          final second = customIn(schedule, 'cq2');
          expect(second.customName, 'Metal');
          expect(second.color, 11);
          expect(second.icon, 15);
          expect(schedule.dates[second], [DateTime(2026, 3, 3)]);
        });

        test('keeps multibyte names intact', () {
          for (final name in [
            'Sklo 🍾',
            'Bioabfälle',
            'ž' * 24,
            '🍾' * 24,
            '日本語のごみ',
          ]) {
            final link = ScheduleCodec.encodeLink({
              glass.copyWith(customName: name): [DateTime(2026, 1, 5)],
            }, from: from);
            final schedule = ScheduleCodec.decodeLink(link);
            expect(customIn(schedule, 'cq1').customName, name, reason: name);
          }
        });

        test('handles names whose characters take many bytes', () {
          // 24 user-perceived characters, each a 25-byte emoji sequence:
          // cleanName cuts them to fit TrashType.maxNameBytes.
          const one = '👨‍👩‍👧‍👦';
          final family = one * 24;
          final cleaned = TrashType.cleanName(family)!;
          expect(cleaned, one * 3);
          expect(
            utf8.encode(cleaned).length,
            lessThanOrEqualTo(TrashType.maxNameBytes),
          );

          late String link;
          expect(
            () => link = ScheduleCodec.encodeLink({
              glass.copyWith(customName: family): [DateTime(2026, 1, 5)],
            }, from: from),
            returnsNormally,
          );
          final schedule = ScheduleCodec.decodeLink(link);
          expect(customIn(schedule, 'cq1').customName, cleaned);
          expect(schedule.dates[customIn(schedule, 'cq1')], [
            DateTime(2026, 1, 5),
          ]);
        });
      });

      group('decodeLink', () {
        test('reads a hand-built v2 payload', () {
          final day = dayNumber(DateTime(2026, 4, 1));
          final link = linkFromBytes([
            ...binBytes(1, [day]),
            ...customBytes('Glas', [day, day + 7], color: 9, icon: 12),
          ], version: '2');

          final schedule = ScheduleCodec.decodeLink(link);
          final custom = customIn(schedule, 'cq1');
          expect(custom.customName, 'Glas');
          expect(custom.color, 9);
          expect(custom.icon, 12);
          expect(schedule.dates[custom], [
            DateTime(2026, 4, 1),
            DateTime(2026, 4, 8),
          ]);
          expect(schedule.dates[TrashType.paper], [DateTime(2026, 4, 1)]);
        });

        test('reads a v1 link in a v2 app', () {
          final link = linkFromBytes(binBytes(3, [9000]));
          final schedule = ScheduleCodec.decodeLink(link);
          expect(schedule.dates.keys, equals(TrashType.builtIns));
          expect(schedule.count(TrashType.bio), 1);
        });

        test('rejects a custom record in a v1 link', () {
          expect(
            () => ScheduleCodec.decodeLink(
              linkFromBytes(customBytes('Glass', [9000])),
            ),
            throwsScheduleError(ScheduleError.invalid),
          );
        });

        test('rejects broken custom records', () {
          final cases = <String, List<int>>{
            'bad UTF-8': [0x10, 5, 6, 2, 0xC3, 0x28, 1, ...varint(9000)],
            'lone continuation byte': [0x10, 5, 6, 1, 0x80, 1, ...varint(9000)],
            'empty name': [0x10, 5, 6, 0, 1, ...varint(9000)],
            'blank name': customBytes('   ', [9000]),
            'control characters only': customBytes('\u0001\u0002', [9000]),
            'color out of range': customBytes('Glass', [9000], color: 12),
            'icon out of range': customBytes('Glass', [9000], icon: 16),
            'name longer than the payload': customBytes('Glass', [
              9000,
            ], length: 200),
            'truncated after the tag': [0x10, 5],
            'no dates': [0x10, 5, 6, 1, 0x41, 0],
          };
          cases.forEach((reason, bytes) {
            expect(
              () =>
                  ScheduleCodec.decodeLink(linkFromBytes(bytes, version: '2')),
              throwsScheduleError(ScheduleError.invalid),
              reason: reason,
            );
          });
        });

        test('rejects more than ten custom records', () {
          final day = dayNumber(DateTime(2026, 4, 1));
          final bytes = [
            for (var i = 0; i < 11; i++) ...customBytes('Bin $i', [day]),
          ];
          expect(
            () => ScheduleCodec.decodeLink(linkFromBytes(bytes, version: '2')),
            throwsScheduleError(ScheduleError.invalid),
          );
          final ten = [
            for (var i = 0; i < 10; i++) ...customBytes('Bin $i', [day]),
          ];
          expect(
            ScheduleCodec.decodeLink(
              linkFromBytes(ten, version: '2'),
            ).dates.length,
            14,
          );
        });

        test('custom records with the same name stay separate', () {
          final day = dayNumber(DateTime(2026, 4, 1));
          final schedule = ScheduleCodec.decodeLink(
            linkFromBytes([
              ...customBytes('Glass', [day]),
              ...customBytes('Glass', [day + 1]),
            ], version: '2'),
          );
          expect(schedule.dates.keys.where((t) => !t.isBuiltIn).length, 2);
          expect(schedule.total, 2);
        });
      });

      test('merge keeps custom bins from both maps', () {
        final merged = ScheduleCodec.merge(
          {
            glass: [DateTime(2026, 1, 1)],
          },
          {
            glass.copyWith(customName: 'Renamed'): [DateTime(2026, 1, 2)],
            metal: [DateTime(2026, 1, 3)],
          },
        );
        expect(merged[glass], [DateTime(2026, 1, 1), DateTime(2026, 1, 2)]);
        expect(merged[metal], [DateTime(2026, 1, 3)]);
      });
    });

    group('merge', () {
      test('should union, dedupe and sort per bin', () {
        final merged = ScheduleCodec.merge(
          {
            TrashType.plastic: [DateTime(2026, 3, 1), DateTime(2026, 1, 1)],
            TrashType.paper: [DateTime(2026, 2, 2)],
          },
          {
            TrashType.plastic: [DateTime(2026, 2, 1), DateTime(2026, 1, 1, 9)],
            TrashType.bio: [DateTime(2026, 4, 4)],
          },
        );

        expect(merged[TrashType.plastic], [
          DateTime(2026, 1, 1),
          DateTime(2026, 2, 1),
          DateTime(2026, 3, 1),
        ]);
        expect(merged[TrashType.paper], [DateTime(2026, 2, 2)]);
        // Only bins in either map are in the result.
        expect(merged.containsKey(TrashType.trash), isFalse);
        expect(merged[TrashType.bio], [DateTime(2026, 4, 4)]);
        expect(
          merged.keys,
          unorderedEquals([TrashType.plastic, TrashType.paper, TrashType.bio]),
        );
      });

      test('should not modify its inputs', () {
        final current = {
          TrashType.bio: [DateTime(2026, 5, 1)],
        };
        final incoming = {
          TrashType.bio: [DateTime(2026, 4, 1)],
        };

        ScheduleCodec.merge(current, incoming);

        expect(current[TrashType.bio], [DateTime(2026, 5, 1)]);
        expect(incoming[TrashType.bio], [DateTime(2026, 4, 1)]);
      });

      test('should merge empty maps into an empty map', () {
        expect(ScheduleCodec.merge({}, {}), isEmpty);
        expect(ScheduleCodec.merge(emptyBins(), {}), equals(emptyBins()));
      });
    });
  });
}
