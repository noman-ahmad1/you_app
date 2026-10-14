import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/models/model_codec.dart';
import 'package:you_app/services/base/firestore_base.dart';

void main() {
  group('parseModelDate', () {
    final when = DateTime.utc(2026, 3, 14, 9, 30);

    test('decodes a Firestore Timestamp without the model importing Firestore',
        () {
      final parsed = parseModelDate(Timestamp.fromDate(when));
      expect(parsed!.isAtSameMomentAs(when), isTrue);
    });

    test('passes a DateTime through', () {
      expect(parseModelDate(when), when);
    });

    test('parses ISO-8601 strings (what Postgres/Supabase would return)', () {
      expect(parseModelDate('2026-03-14T09:30:00.000Z'), when);
    });

    test('returns null for null, garbage strings and non-date objects', () {
      expect(parseModelDate(null), isNull);
      expect(parseModelDate('not a date'), isNull);
      expect(parseModelDate(42), isNull);
      expect(parseModelDate(const {'seconds': 1}), isNull);
    });
  });

  group('FirestoreServiceMixin.encode', () {
    test('turns the serverTimestamp marker into FieldValue.serverTimestamp()',
        () {
      final out = FirestoreServiceMixin.encode({'createdAt': serverTimestamp});
      expect(out['createdAt'], isA<FieldValue>());
    });

    test('converts nested maps and leaves every other value untouched', () {
      final dob = DateTime(2000);
      final out = FirestoreServiceMixin.encode({
        'text': 'hi',
        'count': 3,
        'dob': dob,
        'tags': ['a'],
        'meta': {'at': serverTimestamp, 'by': 'u1'},
      });
      expect(out['text'], 'hi');
      expect(out['count'], 3);
      expect(out['dob'], dob);
      expect(out['tags'], ['a']);
      expect((out['meta'] as Map)['at'], isA<FieldValue>());
      expect((out['meta'] as Map)['by'], 'u1');
    });
  });
}
