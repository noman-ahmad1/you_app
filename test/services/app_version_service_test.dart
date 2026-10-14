import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/services/app_version_service.dart';

/// The update gate must never lock users out by accident: anything other than
/// an explicit, valid minimum above the current build lets the app start.
void main() {
  UpdateRequirement eval(Map<String, dynamic> config,
          {int build = 10, bool ios = false}) =>
      AppVersionService.evaluate(config,
          currentBuild: build, isIOS: ios, packageName: 'com.youstartup.app');

  group('fails open', () {
    test('no config at all', () => expect(eval({}).isRequired, isFalse));
    test('minimum equal to current build', () {
      expect(eval({'min_build_android': 10}).isRequired, isFalse);
    });
    test('minimum below current build', () {
      expect(eval({'min_build_android': 9}).isRequired, isFalse);
    });
    test('junk, zero and negative minimums are ignored', () {
      for (final v in ['abc', '', 0, -5, null, true, <String, dynamic>{}]) {
        expect(eval({'min_build_android': v}).isRequired, isFalse,
            reason: '$v');
      }
    });
    test('an iOS minimum does not affect Android, and vice versa', () {
      expect(eval({'min_build_ios': 99}).isRequired, isFalse);
      expect(eval({'min_build_android': 99}, ios: true).isRequired, isFalse);
    });
  });

  group('blocks', () {
    test('when the build is below the Android minimum', () {
      final r = eval({'min_build_android': 11});
      expect(r.isRequired, isTrue);
      expect(r.storeUrl,
          'https://play.google.com/store/apps/details?id=com.youstartup.app');
    });
    test('accepts the minimum as a numeric string or double', () {
      expect(eval({'min_build_android': '11'}).isRequired, isTrue);
      expect(eval({'min_build_android': 11.0}).isRequired, isTrue);
    });
    test('uses a configured store URL and message', () {
      final r = eval({
        'min_build_android': 11,
        'update_url_android': ' https://example.com/app ',
        'update_message': 'Please update.',
      });
      expect(r.storeUrl, 'https://example.com/app');
      expect(r.message, 'Please update.');
    });
    test('iOS has no default store URL until one is configured', () {
      expect(eval({'min_build_ios': 11}, ios: true).storeUrl, isNull);
      expect(
          eval({
            'min_build_ios': 11,
            'update_url_ios': 'https://apps.apple.com/x'
          }, ios: true)
              .storeUrl,
          'https://apps.apple.com/x');
    });
  });
}
