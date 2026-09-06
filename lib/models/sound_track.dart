/// A soothing sound, authored by an admin in the `sounds` Firestore collection.
///
/// Both the cover and the audio live in Cloud Storage. Note the asymmetry:
/// [coverPhoto] is a public **download URL** (rendered directly), while
/// [audioPath] is the Storage **object path** — never a URL. The audio object is
/// unreadable by clients; playback goes through the `getSoundAudioUrl` callable,
/// which checks entitlement and returns a short-lived signed URL. That is what
/// makes [isPremium] a real gate rather than a badge.
class SoundTrack {
  /// Firestore document id — also the Storage folder name for this sound's
  /// cover/audio, and the key of its on-disk audio cache.
  final String id;
  final String title;
  final String subtitle;

  /// Public download URL of the cover image. Empty when the admin hasn't
  /// uploaded one — callers fall back to a bundled placeholder.
  final String coverPhoto;

  /// Storage object path, e.g. `sound_audio/<id>/calm.mp3`.
  final String audioPath;

  final bool isPremium;
  final int order;

  /// Optional; lets the card show a length before playback starts.
  final int? durationMs;

  const SoundTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverPhoto,
    required this.audioPath,
    this.isPremium = false,
    this.order = 0,
    this.durationMs,
  });

  /// Tolerant of a half-filled doc: the admin panel creates the document first
  /// and uploads the files second, so every field falls back rather than throws.
  factory SoundTrack.fromMap(Map<String, dynamic> map, String id) {
    return SoundTrack(
      id: id,
      title: (map['title'] as String?)?.trim() ?? 'Untitled',
      subtitle: (map['subtitle'] as String?)?.trim() ?? '',
      coverPhoto: (map['cover_photo'] as String?)?.trim() ?? '',
      audioPath: (map['audio_path'] as String?)?.trim() ?? '',
      isPremium: map['is_premium'] == true,
      order: (map['order'] as num?)?.toInt() ?? 0,
      durationMs: (map['duration_ms'] as num?)?.toInt(),
    );
  }

  /// False in the window where the admin has created the doc but not yet
  /// uploaded the audio. Such a sound is unplayable, so it's filtered out of
  /// the list rather than shown as a card that fails on tap.
  bool get isPlayable => audioPath.isNotEmpty;

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);
}
