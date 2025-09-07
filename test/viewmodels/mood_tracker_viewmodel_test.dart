import 'package:flutter_test/flutter_test.dart';
import 'package:you_app/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('MoodTrackerViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
