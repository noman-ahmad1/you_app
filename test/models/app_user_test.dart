import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/models/app_user.dart';

/// Regression coverage for AppUser deserialisation.
///
/// These exist because `_createAppUser` in AuthenticationService used to be a
/// second, hand-rolled mapping of the same document that silently dropped
/// `availabilityStatus`, `lastSeen` and `fcmToken` — which made `isOnline`
/// permanently false and stopped PresenceService writing any heartbeat.
void main() {
  Map<String, dynamic> doc(Map<String, dynamic> overrides) => {
        'uid': 'u1',
        'email': 'a@b.com',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'role': 'volunteer',
        ...overrides,
      };

  group('AppUser.fromJson - presence fields', () {
    test('reads availabilityStatus so isOnline can ever be true', () {
      final user = AppUser.fromJson(doc({'availabilityStatus': 'online'}));
      expect(user.availabilityStatus, 'online');
      expect(user.isOnline, isTrue);
    });

    test('defaults availabilityStatus to offline when absent', () {
      final user = AppUser.fromJson(doc({}));
      expect(user.availabilityStatus, 'offline');
      expect(user.isOnline, isFalse);
    });

    test('reads lastSeen and fcmToken', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 3, 1, 12));
      final user = AppUser.fromJson(doc({'lastSeen': ts, 'fcmToken': 'tok'}));
      // Timestamp.toDate() returns a local DateTime; compare the instant,
      // not the isUtc flag, which DateTime's == also considers.
      expect(user.lastSeen!.isAtSameMomentAs(DateTime.utc(2026, 3, 1, 12)),
          isTrue);
      expect(user.fcmToken, 'tok');
    });
  });

  group('AppUser.fromJson - hostile input', () {
    test('an unknown role degrades to user instead of throwing', () {
      // byName() would throw ArgumentError here, inside the auth stream.
      expect(AppUser.fromJson(doc({'role': 'moderator'})).role, UserRole.user);
      expect(AppUser.fromJson(doc({'role': null})).role, UserRole.user);
      expect(AppUser.fromJson(doc({'role': 42})).role, UserRole.user);
    });

    test('known roles still parse', () {
      expect(AppUser.fromJson(doc({'role': 'admin'})).role, UserRole.admin);
      expect(AppUser.fromJson(doc({'role': 'volunteer'})).role,
          UserRole.volunteer);
    });

    test('dates accept Timestamp, ISO string, or garbage', () {
      final iso = AppUser.fromJson(doc({'createdAt': '2026-03-01T12:00:00Z'}));
      expect(iso.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 3, 1, 12)),
          isTrue);

      final stamped = AppUser.fromJson(
          doc({'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 2))}));
      expect(stamped.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 1, 2)),
          isTrue);

      // Must not throw — a malformed value degrades to null.
      expect(
          AppUser.fromJson(doc({'createdAt': 'not-a-date'})).createdAt, isNull);
      expect(AppUser.fromJson(doc({'createdAt': 99})).createdAt, isNull);
    });

    test('an empty document does not throw', () {
      expect(() => AppUser.fromJson(const {}), returnsNormally);
    });
  });

  group('AppUser.isPremium', () {
    test('is false for a free tier', () {
      expect(AppUser.fromJson(doc({})).isPremium, isFalse);
    });

    test('is false once the expiry has passed', () {
      final user = AppUser.fromJson(doc({
        'subscriptionTier': 'premium',
        'subscription_expiry': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      }));
      expect(user.isPremium, isFalse);
    });

    test('is true while the expiry is in the future', () {
      final user = AppUser.fromJson(doc({
        'subscriptionTier': 'premium',
        'subscription_expiry':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      }));
      expect(user.isPremium, isTrue);
    });
  });
}
