import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:you_app/models/model_codec.dart';

import 'app_log.dart';

/// Shared Firestore access + uniform error handling for services.
///
/// Mix this into a service to get a [db] handle and the [guard] wrapper, which
/// centralises logging and the rethrow-vs-fail-soft policy:
///   * Mutations should use the default (`rethrowError: true`) so callers /
///     viewmodels keep surfacing failures to the user.
///   * Reads used purely as UI fallbacks should pass `rethrowError: false`
///     with a [fallback] value to preserve fail-open behaviour.
mixin FirestoreServiceMixin {
  FirebaseFirestore get db => FirebaseFirestore.instance;

  /// Translates backend-neutral model values into Firestore ones before a
  /// write. Today that means [ServerTimestamp] → `FieldValue.serverTimestamp()`.
  /// Every write of a model's `toJson`/`toFirestore` map must go through this.
  static Map<String, dynamic> encode(Map<String, dynamic> data) {
    Object? convert(Object? v) {
      if (v is ServerTimestamp) return FieldValue.serverTimestamp();
      if (v is Map<String, dynamic>) return encode(v);
      return v;
    }

    return data.map((k, v) => MapEntry(k, convert(v)));
  }

  /// Splits [items] into chunks of at most [size]. Useful for `whereIn`
  /// (max 30 values) and batched writes (max 500 ops).
  static List<List<T>> chunk<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      chunks.add(
          items.sublist(i, i + size > items.length ? items.length : i + size));
    }
    return chunks;
  }

  /// Runs [op] with consistent logging. Rethrows by default; pass
  /// `rethrowError: false` (with an optional [fallback]) to fail soft.
  Future<T?> guard<T>(
    Future<T> Function() op, {
    required String context,
    bool rethrowError = true,
    T? fallback,
  }) async {
    try {
      return await op();
    } on FirebaseException catch (e) {
      AppLog.firebase(context, '${e.code} - ${e.message}');
      if (rethrowError) rethrow;
      return fallback;
    } catch (e, s) {
      AppLog.error(context, e, s);
      if (rethrowError) rethrow;
      return fallback;
    }
  }
}
