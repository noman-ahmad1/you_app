import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/services/moderation_service.dart';

/// applyConfigDocument moved out of main.dart; these pin that both document
/// shapes still apply exactly as before.
void main() {
  ModerationResult check(ModerationService s, String text) =>
      s.inspect(text, context: ModerationContext.chat);

  test('new per-category shape replaces lists and records the version', () {
    final s = ModerationService()
      ..applyConfigDocument({
        'hate': ['zorblax'],
        'version': 7,
      });
    expect(s.configVersion, 7);
    expect(check(s, 'you are a zorblax').categories,
        contains(ModerationCategory.hate));
  });

  test('legacy bannedKeywords hard-blocks', () {
    final s = ModerationService()
      ..applyConfigDocument({
        'bannedKeywords': ['quuxword']
      });
    final r = check(s, 'quuxword here');
    expect(r.isBlocked, isTrue);
    expect(r.categories, contains(ModerationCategory.banned));
  });

  test('legacy enabled:false is the kill-switch', () {
    final s = ModerationService()
      ..applyConfigDocument({
        'bannedKeywords': ['quuxword']
      })
      ..applyConfigDocument({'enabled': false});
    expect(check(s, 'quuxword').isClean, isTrue);
  });

  test('a document with neither shape changes nothing', () {
    final s = ModerationService()..applyConfigDocument({'unrelated': 1});
    expect(s.configVersion, 0);
    expect(check(s, 'hello there').isClean, isTrue);
  });
}
