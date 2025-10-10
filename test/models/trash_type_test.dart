import 'package:flutter_test/flutter_test.dart';
import 'package:trashifier_app/models/trash_type.dart';

void main() {
  group('TrashType', () {
    test('should have all expected enum values', () {
      expect(TrashType.values.length, equals(4));
      expect(TrashType.values, contains(TrashType.plastic));
      expect(TrashType.values, contains(TrashType.paper));
      expect(TrashType.values, contains(TrashType.trash));
      expect(TrashType.values, contains(TrashType.bio));
    });

    test('should have correct string representation', () {
      expect(TrashType.plastic.toString(), equals('TrashType.plastic'));
      expect(TrashType.paper.toString(), equals('TrashType.paper'));
      expect(TrashType.trash.toString(), equals('TrashType.trash'));
      expect(TrashType.bio.toString(), equals('TrashType.bio'));
    });

    test('should be comparable', () {
      expect(TrashType.plastic == TrashType.plastic, isTrue);
      expect(TrashType.plastic == TrashType.paper, isFalse);
      expect(TrashType.paper == TrashType.paper, isTrue);
      expect(TrashType.trash == TrashType.trash, isTrue);
      expect(TrashType.bio == TrashType.bio, isTrue);
    });

    test('should have consistent hash codes', () {
      expect(TrashType.plastic.hashCode, equals(TrashType.plastic.hashCode));
      expect(TrashType.paper.hashCode, equals(TrashType.paper.hashCode));
      expect(TrashType.trash.hashCode, equals(TrashType.trash.hashCode));
      expect(TrashType.bio.hashCode, equals(TrashType.bio.hashCode));
    });
  });
}
