import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/models/app_notification.dart';
import 'package:you_app/models/chat_messaage_model.dart';
import 'package:you_app/models/chat_request_model.dart';
import 'package:you_app/models/chat_room_model.dart';
import 'package:you_app/models/community_post.dart';
import 'package:you_app/models/journal_model.dart';
import 'package:you_app/models/model_codec.dart';
import 'package:you_app/models/mood_model.dart';
import 'package:you_app/models/thread_reply.dart';
import 'package:you_app/models/volunteer_info_model.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Pins what the models read from — and write to — Firestore, so moving them
/// off Firestore types can't silently change the data.
void main() {
  final when = DateTime.utc(2026, 5, 1, 12);
  final ts = Timestamp.fromDate(when);

  test('ChatMessage reads a Timestamp and writes a server timestamp', () {
    final m =
        ChatMessage.fromJson({'senderId': 'a', 'text': 'hi', 'timestamp': ts});
    expect(m.timestamp!.isAtSameMomentAs(when), isTrue);
    expect(m.toJson()['timestamp'], same(serverTimestamp));
    expect(FirestoreServiceMixin.encode(m.toJson())['timestamp'],
        isA<FieldValue>());
  });

  test('ChatMessage tolerates a pending (null) server timestamp', () {
    expect(ChatMessage.fromJson({'senderId': 'a', 'text': 'hi'}).timestamp,
        isNull);
  });

  test('ChatRequest.fromMap reads id, fields and all three dates', () {
    final r = ChatRequest.fromMap('req1', {
      'requesterId': 'u',
      'requesterName': 'U',
      'volunteerId': 'v',
      'status': 'accepted',
      'createdAt': ts,
      'acceptedAt': ts,
      'endedAt': null,
      'userReviewed': true,
      'topic': 'Anxiety',
    });
    expect(r.id, 'req1');
    expect(r.status, 'accepted');
    expect(r.createdAt!.isAtSameMomentAs(when), isTrue);
    expect(r.acceptedAt!.isAtSameMomentAs(when), isTrue);
    expect(r.endedAt, isNull);
    expect(r.userReviewed, isTrue);
  });

  test('ChatRoom.fromMap', () {
    final c = ChatRoom.fromMap('c1', {
      'participants': ['a', 'b'],
      'createdAt': ts
    });
    expect(c.id, 'c1');
    expect(c.participants, ['a', 'b']);
    expect(c.createdAt!.isAtSameMomentAs(when), isTrue);
  });

  test('JournalEntry.fromMap reads; toFirestore stamps server time', () {
    final j = JournalEntry.fromMap('j1', {
      'userId': 'u',
      'title': 't',
      'content': 'c',
      'label': 'personal',
      'timestamp': ts,
    });
    expect(j.id, 'j1');
    expect(j.timestamp!.isAtSameMomentAs(when), isTrue);
    expect(FirestoreServiceMixin.encode(j.toFirestore())['timestamp'],
        isA<FieldValue>());
  });

  test('CommunityPost / ThreadReply fall back to now when createdAt is pending',
      () {
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    final p = CommunityPost.fromMap(const {}, 'p1');
    final r = ThreadReply.fromMap(const {}, 'r1');
    expect(p.createdAt.isAfter(before), isTrue);
    expect(r.createdAt.isAfter(before), isTrue);
    expect(
        CommunityPost.fromMap({'createdAt': ts}, 'p1')
            .createdAt
            .isAtSameMomentAs(when),
        isTrue);
  });

  test('VolunteerInfo reads Timestamp and legacy ISO-string createdAt', () {
    expect(
        VolunteerInfo.fromJson({'uid': 'v', 'createdAt': ts})
            .createdAt!
            .isAtSameMomentAs(when),
        isTrue);
    expect(
        VolunteerInfo.fromJson(
            {'uid': 'v', 'createdAt': '2026-05-01T12:00:00.000Z'}).createdAt,
        when);
    expect(VolunteerInfo.fromJson({'uid': 'v'}).createdAt, isNull);
  });

  group('MoodEntry timestamp formatting (unchanged behaviour)', () {
    test('Timestamp becomes an ISO string and dateOnly', () {
      final m = MoodEntry.fromFirestore(
          {'moodLabel': 'Happy', 'timestamp': ts}, 'm1');
      expect(DateTime.parse(m.timestamp).isAtSameMomentAs(when), isTrue);
      expect(m.dateOnly, m.timestamp.split('T').first);
    });
    test('a stored string is kept verbatim', () {
      final m =
          MoodEntry.fromFirestore({'timestamp': '2026-01-02T03:04:05'}, 'm1');
      expect(m.timestamp, '2026-01-02T03:04:05');
      expect(m.dateOnly, '2026-01-02');
    });
    test('a pending timestamp falls back to now', () {
      final m = MoodEntry.fromFirestore(const {}, 'm1');
      expect(m.dateOnly, DateTime.now().toIso8601String().split('T').first);
    });
  });

  group('AppNotification', () {
    test('maps fields and the routing payload', () {
      final n = AppNotification.fromMap(
          'n1',
          {
            'title': 'New Message',
            'body': 'hi',
            'type': 'new_message',
            'isRead': false,
            'data': {'chatId': 'a_b', 'route': 'chat_view'},
          },
          when);
      expect(n.title, 'New Message');
      expect(n.type, 'new_message');
      expect(n.isRead, isFalse);
      expect(n.chatId, 'a_b');
      expect(n.requestId, isNull);
      expect(n.createdAt, when);
    });
    test('uses the same defaults the drawers used', () {
      final n = AppNotification.fromMap('n1', const {}, null);
      expect(n.title, 'Notification');
      expect(n.body, '');
      expect(n.type, '');
      expect(n.isRead, isFalse);
      expect(n.data, isEmpty);
    });
  });
}
