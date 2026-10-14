import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Whether this install must update before it can be used.
class UpdateRequirement {
  final bool isRequired;

  /// Where the "Update now" button goes. Null on iOS until an App Store URL
  /// is configured, in which case the screen just asks the user to update.
  final String? storeUrl;

  /// Optional custom copy from the admin panel.
  final String? message;

  const UpdateRequirement({
    required this.isRequired,
    this.storeUrl,
    this.message,
  });

  static const none = UpdateRequirement(isRequired: false);
}

/// The minimum-supported-version gate.
///
/// Reads `app_settings/app_version`:
///   min_build_android / min_build_ios   int — the lowest build number allowed
///                                       (the `+N` in pubspec's `version`)
///   update_url_android / update_url_ios optional store links
///   update_message                      optional custom copy
///
/// This is the lever for any backend change that old installs can't survive —
/// a schema change, a new rules model, or a move off Firebase: raise the
/// minimum and every older build is sent to the store instead of breaking.
///
/// That document is publicly readable, unlike `global_config`: the check runs
/// at startup, before sign-in, and a signed-out user on an old build must
/// still be stopped. It holds only these non-sensitive keys.
///
/// FAIL-OPEN by design. A missing key, an offline device, a slow network or any
/// error lets the app start normally. Only an explicit "this build is below
/// the minimum" blocks, so a misconfigured or unreachable setting can never
/// lock every user out.
class AppVersionService with FirestoreServiceMixin {
  /// Bounds how long startup waits for the setting. Past this the app starts.
  static const _timeout = Duration(seconds: 3);

  Future<UpdateRequirement> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber);
      if (build == null) return UpdateRequirement.none;

      final snap = await db
          .collection('app_settings')
          .doc('app_version')
          .get()
          .timeout(_timeout);

      return evaluate(
        snap.data() ?? const {},
        currentBuild: build,
        isIOS: defaultTargetPlatform == TargetPlatform.iOS,
        packageName: info.packageName,
      );
    } catch (e) {
      AppLog.error('AppVersionService.check (failing open)', e);
      return UpdateRequirement.none;
    }
  }

  /// The pure decision, separated so it can be tested without a device.
  @visibleForTesting
  static UpdateRequirement evaluate(
    Map<String, dynamic> config, {
    required int currentBuild,
    required bool isIOS,
    required String packageName,
  }) {
    final minBuild =
        _asPositiveInt(config[isIOS ? 'min_build_ios' : 'min_build_android']);
    if (minBuild == null || currentBuild >= minBuild) {
      return UpdateRequirement.none;
    }

    final configuredUrl = _asNonEmptyString(
        config[isIOS ? 'update_url_ios' : 'update_url_android']);
    final storeUrl = configuredUrl ??
        (isIOS
            ? null
            : 'https://play.google.com/store/apps/details?id=$packageName');

    return UpdateRequirement(
      isRequired: true,
      storeUrl: storeUrl,
      message: _asNonEmptyString(config['update_message']),
    );
  }

  static int? _asPositiveInt(Object? v) {
    final n =
        v is num ? v.toInt() : (v is String ? int.tryParse(v.trim()) : null);
    return n != null && n > 0 ? n : null;
  }

  static String? _asNonEmptyString(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;
}
