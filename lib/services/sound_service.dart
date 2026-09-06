import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:you_app/models/sound_track.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Reads the admin-authored `sounds` collection and resolves playable audio URLs.
///
/// The app never writes here — the admin panel owns the CRUD. Two things are
/// deliberately split:
///   • the **cover** is a plain public download URL on the doc, rendered directly;
///   • the **audio** is only an object path. Clients cannot read the Storage
///     object, so a premium sound's mp3 is unobtainable without going through
///     [getPlaybackUrl], which verifies entitlement server-side.
class SoundService with FirestoreServiceMixin {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// The sounds the admin has published, in their chosen order.
  ///
  /// Backed by the `sounds` composite index (`active` ASC, `order` ASC). Docs
  /// without audio are dropped — the admin panel creates the doc first and
  /// uploads the file second, so a card can briefly exist with nothing to play.
  Stream<List<SoundTrack>> streamSounds({int limit = 50}) {
    return db
        .collection('sounds')
        .where('active', isEqualTo: true)
        .orderBy('order')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SoundTrack.fromMap(d.data(), d.id))
            .where((t) => t.isPlayable)
            .toList());
  }

  /// A short-lived signed URL for [soundId]'s audio.
  ///
  /// Throws [FirebaseFunctionsException] with code `permission-denied` when the
  /// sound is premium and the caller isn't — the caller should have shown the
  /// paywall before ever getting here, so treat that as a bug-or-tamper path.
  Future<String> getPlaybackUrl(String soundId) async {
    final result = await _functions
        .httpsCallable('getSoundAudioUrl')
        .call({'soundId': soundId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('getSoundAudioUrl returned no url for $soundId');
    }
    return url;
  }

  /// Where [soundId]'s audio is cached on disk.
  ///
  /// Keyed by **sound id, not URL** — that's the whole point. The signed URL
  /// rotates every hour, so a URL-keyed cache would re-download the file (up to
  /// ~15 MB) on every session. `just_audio`'s LockCachingAudioSource fills this
  /// file on the first play; every play after that is offline and skips the
  /// callable entirely.
  Future<File> cacheFileFor(String soundId) async {
    final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/sound_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$soundId.mp3');
  }
}
