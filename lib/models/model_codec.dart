/// Backend-neutral helpers for model serialization.
///
/// Models must not import a backend SDK (`cloud_firestore`, `supabase`, …).
/// They read dates through [parseModelDate] and mark server-stamped fields with
/// [serverTimestamp]; the service that performs the write translates that
/// marker into the backend's own sentinel (see FirestoreServiceMixin.encode).
library;

/// Decodes a stored date into a [DateTime], or null when absent or unparseable.
///
/// Handles the shapes dates have taken in this project: [DateTime], ISO-8601
/// strings, and backend timestamp objects that expose `toDate()` — Firestore's
/// `Timestamp` does. That last one is called dynamically on purpose, so this
/// file needs no backend import and keeps working unchanged after a migration.
DateTime? parseModelDate(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  try {
    final decoded = (raw as dynamic).toDate();
    if (decoded is DateTime) return decoded;
  } catch (_) {
    // Not a timestamp-like object.
  }
  return null;
}

/// Marks a field the backend should fill with its own clock at write time.
class ServerTimestamp {
  const ServerTimestamp();
}

/// Use as a map value in a model's `toJson`: `'createdAt': serverTimestamp`.
const serverTimestamp = ServerTimestamp();
