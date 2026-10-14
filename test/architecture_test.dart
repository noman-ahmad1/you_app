import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layering in docs/ARCHITECTURE.md: only lib/services/ may use
/// the backend's data SDKs. This is what keeps a future backend move a matter
/// of rewriting services rather than the whole app.
void main() {
  const dataSdks = [
    'package:cloud_firestore/',
    'package:firebase_storage/',
    'package:cloud_functions/',
    'package:firebase_auth/',
  ];

  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  List<String> offenders(Iterable<File> files, List<String> banned) => [
        for (final f in files)
          for (final line in f.readAsLinesSync())
            if (line.trimLeft().startsWith('import ') &&
                banned.any(line.contains))
              '${f.path}: ${line.trim()}',
      ];

  test('only lib/services/ imports backend data SDKs', () {
    final outsideServices = dartFiles('lib').where(
        (f) => !f.path.replaceAll(r'\', '/').startsWith('lib/services/'));
    expect(offenders(outsideServices, dataSdks), isEmpty,
        reason: 'Move this call into a service. See docs/ARCHITECTURE.md §1.');
  });

  test('models import no Firebase package at all', () {
    expect(
        offenders(
            dartFiles('lib/models'), ['package:firebase', 'package:cloud_']),
        isEmpty,
        reason: 'Models must be plain Dart. See docs/ARCHITECTURE.md §2.');
  });
}
