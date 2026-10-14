# You app

Flutter (Stacked architecture) mental-health app on Firebase: Firestore, Auth,
Storage, Cloud Functions (Node 22) and FCM. Live on the Play Store.

## Architecture rules

Read `docs/ARCHITECTURE.md` before adding features. In short:

- Only `lib/services/` may import `cloud_firestore`, `firebase_storage`,
  `cloud_functions` or `firebase_auth`. View models catch `ServiceException`,
  never Firebase exception types. Enforced by `test/architecture_test.dart`.
- Models are plain Dart: dates via `parseModelDate`, server times via the
  `serverTimestamp` marker, which services pass through
  `FirestoreServiceMixin.encode`.
- Design new collections flat and relational (top-level collections, ID
  references, no unbounded arrays or user-keyed maps).
- Cloud Functions: business rules in pure modules with tests; `index.js` only
  wires triggers and I/O.
- Changes old builds can't survive go through the `app_settings/app_version`
  gate first.

Schema reference: `docs/FIRESTORE_SCHEMA.md`.

## Commands

```bash
flutter analyze --no-fatal-infos           # must stay at 0 errors / 0 warnings
flutter test
dart run build_runner build --delete-conflicting-outputs   # after editing lib/app/app.dart
(cd functions && npm run lint && npm test)
(cd firestore-tests && npm test)           # rules suite; needs JDK 21+ (falls back to Android Studio's JBR)
```

## Safety invariant

Self-harm and suicidal phrasing must never be blocked, by keyword moderation or
by Dodo's Gemini safety settings. Those messages are crisis disclosures to
escalate. See `lib/ui/common/moderation_keywords.dart` and `functions/dodo.js`.
