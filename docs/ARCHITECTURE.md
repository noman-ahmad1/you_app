# Architecture rules

How this codebase is layered, and the rules that keep it portable. The goal is
to stay on Firebase while keeping a future move to another backend (Supabase or
anything else) a contained job: rewrite the service layer and the trigger
wiring, not the whole app.

Two of these rules are enforced by tests. The rest are conventions that need
reviewers to hold them.

---

## 1. Only `lib/services/` talks to the backend

**Rule.** `cloud_firestore`, `firebase_storage`, `cloud_functions` and
`firebase_auth` may only be imported inside `lib/services/`.

Views, view models, widgets and models never call `FirebaseFirestore.instance`,
`httpsCallable` or `FirebaseAuth.instance`, and never handle Firestore types
(`DocumentSnapshot`, `QuerySnapshot`, `Timestamp`, `FieldValue`).

**Enforced by** `test/architecture_test.dart`, which runs in CI.

**In practice:**

- A screen needs data? Add a method to the relevant service that returns a
  plain model or a `Stream` of one. `InAppNotificationService.streamUnread`
  and `ChatService.watchChatStatus` are good examples.
- A write needs the server's clock? The service adds it, e.g.
  `UserService.completeProfile` or `VolunteerService.saveInfo(stampCreatedAt:
  true)`. View models never build `FieldValue.serverTimestamp()`.
- A view model needs to react to a specific backend error? The service catches
  the Firebase exception and rethrows `ServiceException(code)`, from
  `lib/services/base/service_exception.dart`. The view model catches
  `ServiceException` and branches on `code`. Never catch
  `FirebaseFunctionsException` or `FirebaseAuthException` outside services.
- `firebase_core`, `firebase_messaging`, `firebase_analytics` and
  `firebase_crashlytics` are platform services rather than the data backend.
  They're allowed in `main.dart` and their own services.

## 2. Models are plain Dart

**Rule.** Nothing in `lib/models/` imports a backend SDK.

**Enforced by** `test/architecture_test.dart`.

- Read dates with `parseModelDate(raw)` from `lib/models/model_codec.dart`. It
  accepts `DateTime`, ISO-8601 strings and Firestore `Timestamp` (anything with
  `toDate()`), so the same model will read Postgres data unchanged.
- Server-stamped fields in `toJson` use the neutral marker:
  `'createdAt': serverTimestamp`. The service that writes the map must pass it
  through `FirestoreServiceMixin.encode(...)`, which turns the marker into
  `FieldValue.serverTimestamp()`.
- Factories take `(String id, Map<String, dynamic> data)`, never a
  `DocumentSnapshot`. The service passes `doc.id, doc.data()`.

## 3. Design new data relationally

Firestore will store anything, but some shapes map cleanly to SQL tables and
others need a redesign to migrate. **For every new feature, pick the shape that
would also make a sensible table.** Don't restructure existing collections to
match this; it applies to new data.

| Do | Avoid | Why |
|---|---|---|
| Flat, top-level collections: `reactions/{id}` with `postId` and `userId` fields | Deep subcollections: `posts/{id}/replies/{id}/reactions/{id}` | A top-level collection is a table. Nesting has to be flattened, with foreign keys invented, during a migration |
| Reference other records by ID: `volunteerId: "abc"` | Copying whole objects into a document | IDs become foreign keys |
| A separate collection for many-to-many: `community_members/{communityId_userId}` | Unbounded arrays of IDs: `members: [uid, uid, …]` | Arrays don't index well, cap out at document size, and become join tables anyway |
| Named fields for fixed attributes | Maps keyed by user ID: `participantsActivity: {uid: true}` | Dynamic keys can't be columns |
| One type per field, every time | A field that is sometimes a `Timestamp` and sometimes a string | Columns have one type. `volunteer_info.createdAt` already has this problem |
| `serverTimestamp` for created/updated times | Device clock times | Device clocks lie |
| Deliberate, documented denormalisation for display (`requesterName` on a request) | Accidental duplication | Duplicated data must have a known owner that keeps it in sync |

Document every new collection in `docs/FIRESTORE_SCHEMA.md`, and add its rules
**with tests** in `firestore-tests/test.js`.

## 4. Cloud Functions: logic in pure modules, wiring in `index.js`

**Rule.** Business rules live in plain JavaScript modules that don't import
`firebase-admin` or `firebase-functions`. `index.js` does the triggers, reads,
writes, logging and HTTP responses, and calls the modules.

Current modules: `moderation.js`, `dodo.js`, `time.js`, `config.js`,
`entitlement.js` and `security.js`. Each has unit tests in `functions/test/`,
run by `npm test` in CI.

A pure module ports to a Supabase Edge Function or any other runtime with
little change. Only the trigger wiring has to be rewritten.

When you add a function, ask what the decision is ("is this user allowed?",
"what does this webhook mean?", "what should this notification say?"). Put that
in a module with a test, and keep only the I/O in `index.js`.

## 5. Breaking backend changes go through the version gate

`AppVersionService` (`lib/services/app_version_service.dart`) reads
`app_settings/app_version` on the splash screen:

```
min_build_android:  int     lowest allowed build (the +N in pubspec `version`)
min_build_ios:      int
update_url_android: string  optional; defaults to the Play Store listing
update_url_ios:     string  optional; iOS shows text only until this is set
update_message:     string  optional custom copy
```

Builds below the minimum see `UpdateRequiredView` and can't continue. The check
**fails open**: missing values, an offline device or any error lets the app
start normally.

**Before shipping a change older builds can't survive** (a new data shape, a
tightened rule, a backend move):

1. Ship a release that works with both the old and new backend behaviour, and
   note its build number.
2. Wait for most users to update.
3. Set `min_build_android` / `min_build_ios` to that build number.
4. Make the breaking change.

Never raise the minimum above a build that isn't live in the store yet. Users
would be sent to update to a version they can't download.
