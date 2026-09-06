# You — Application Quality Review

**Reviewed:** 3 September 2026 · branch `refactor/efficient-firestore-bugfix` · version `1.1.0+10`
**Scope:** whole project — 176 Dart files / ~38.7k LOC, 31 Cloud Functions, Firestore & Storage rules, native config
**Framing:** full technical-debt roadmap. Recommendations target the correct long-term architecture, not a launch-week patch.

---

## 1. Executive summary

You is a peer-support mental-health app for the Pakistan market: journaling (text + voice), mood tracking and insights, a moderated community forum, 1:1 volunteer chat, an AI companion ("Dodo"), soothing sounds, breathing exercises, a volunteer vetting pipeline, crisis escalation, and a freemium paywall on RevenueCat.

**The backend is in better shape than the frontend.** The recent refactor produced genuinely strong server-side work — server-enforced freemium counters, a textbook premium-audio gate, careful Firestore rules with a removed catch-all, and correct Crashlytics wiring. That work is real and the roadmap below builds on it rather than replacing it.

The problems cluster in four places:

1. **Authorisation gaps in the Firestore rules expose sensitive data.** Volunteer government-ID images, every user's mood history, and the full user directory are readable by any signed-in account. These are one-line rule fixes with outsized impact.
2. **The design system exists on paper and is bypassed in practice.** `Theme.of(context)` is called exactly once in 30,709 lines of UI code. Everything else is hand-styled, so there is no single place to change how the app looks.
3. **The app does more Firestore work than it needs to.** Thirteen of sixteen live collection listeners have no `.limit()`, streams are rebuilt inside `build()`, and one screen constructs the same view model three times.
4. **Non-functional or user-visible defects** that a test suite or CI would have caught: the signup password renders in cleartext, iOS push cannot work at all, and the volunteer presence heartbeat has never written a single record.

### Scorecard

| Area | Grade | One-line justification |
|---|:--:|---|
| Backend architecture & Cloud Functions | **B+** | All v2, secrets managed properly, `BulkWriter` used correctly. Loses points for no region pinning and one dangerous unbounded function. |
| Monetisation & entitlement | **A−** | Server-authoritative, unbypassable, restore implemented. Only real gap is offline entitlement caching. |
| Security rules (structure) | **B** | Thoughtful, well-commented, no catch-all. Undermined by six specific over-permissive rules. |
| Security rules (outcomes) | **D** | Identity documents, mood history and the user directory are effectively public to any account. |
| Data flow & read efficiency | **C−** | Good primitives built (`TtlCache`, `chunk`, cursor pagination) and then not adopted. 13 unbounded listeners. |
| State management | **C** | Consistent Stacked usage, but 185 `notifyListeners()`, god-object view models, whole-screen rebuilds. |
| Design system | **D+** | Colour tokens are genuinely good. Type, spacing, radius and elevation scales are absent or broken. |
| Rendering performance | **D** | 98 `BackdropFilter`s (35 at sigma 200, nested 3 deep), a non-virtualised animated list, no image caching. |
| Accessibility | **F** | Zero semantics, zero text-scale handling, primary navigation unusable with a screen reader. |
| UX completeness | **C−** | One error state across thirty screens. No pull-to-refresh anywhere. |
| Engineering hygiene | **D−** | Effectively zero test coverage, no CI, minimal lints, no i18n. |
| Code quality & comments | **A−** | Genuinely excellent. Comments explain *why*, security decisions are documented inline, no lint-suppression debt. |

### The ten things to fix first

| # | Issue | Severity | Effort |
|---|---|:--:|:--:|
| 1 | Volunteer ID-card URLs readable by every signed-in user | Critical | S |
| 2 | All users' mood history readable by every signed-in user | Critical | S |
| 3 | Signup password field renders in cleartext | Critical | XS |
| 4 | Arbitrary push-notification injection into any account | Critical | S |
| 5 | iOS push notifications cannot work — no entitlements at all | Critical | S |
| 6 | Live LLM API keys shipped inside the app binary, used by nothing | High | XS |
| 7 | Presence heartbeat has never written — `isOnline` is always false | High | XS |
| 8 | Chat participants can edit/delete each other's messages, add third parties | High | S |
| 9 | Progress bar overflows on every 360 dp Android device | High | XS |
| 10 | Zero effective test coverage and no CI | High | L |

Items 3, 6, 7 and 9 are one-to-five-line changes.

---

## 1a. Implementation status

Phase 1 has been implemented and verified. Updated 6 September 2026.

**Verification at time of writing:** `flutter analyze` 0 errors / 0 warnings (was 267 issues) · `flutter test` 10/10 · Firestore rules suite 42/42 · `npm run lint` (functions) clean · `flutter build apk --release` succeeds with R8 enabled.

| # | Issue | Status |
|---|---|---|
| 1 | Volunteer ID-card URLs readable by every signed-in user | **Done** — moved to `volunteer_info/{uid}/private/vetting`, owner+admin only; `migrateVettingDocs` callable added |
| 2 | All users' mood history readable | **Done** — owner+admin only, proven by test |
| 3 | Signup password in cleartext | **Done** — new `PasswordField` used by all 9 password inputs |
| 4 | Push-notification injection | **Done** — cross-user creates require a shared chat or chat request |
| 5 | iOS push non-functional | **Done** — entitlements created and wired into all three build configs |
| 6 | LLM keys in the binary | **Done in code** — ⚠️ **keys still need rotating in the Groq and Google consoles** |
| 7 | Presence heartbeat never wrote | **Done** — `_createAppUser` now delegates to `AppUser.fromJson` |
| 8 | Chat participants could edit others' messages | **Done** — messages are create-only; `participants`/`escalated` protected |
| 9 | Progress bar overflow on 360 dp | **Done** — flexes with `Expanded` |
| 10 | No test coverage, no CI | **Partly** — CI added (3 jobs); 42 rules tests + 10 model tests. Broad service/view-model coverage remains Phase 4 |

**Also completed:** `AD_ID` permission stripped · R8 + resource shrinking enabled with ProGuard rules · zenquotes.io replaced by an admin-curated `whispers/{YYYY-MM-DD}` collection · chat messages bounded to 200 and thread replies to 100 · FCM background handler moved to top level and listeners de-gated from the permission answer · 2-second splash delay removed · aggregate tampering bounded to ±1 on ratings and `membersCount` · escalation spoofing closed · dead Stacked template code deleted · two leaked `AudioPlayer`s and an undisposed controller removed · `provider` declared explicitly · eslint config aligned to the codebase (1198 pre-existing errors → 0).

### Deployment order — read before shipping

1. Run the **`migrateVettingDocs`** callable (admin-only, idempotent) to move existing ID URLs into the private subcollection.
2. **Update the admin panel** to read vetting URLs from `volunteer_info/{uid}/private/vetting` — it currently reads the public document, and that path is now empty. *This is a coordinated change across two repositories.*
3. Deploy `firestore.rules`.
4. **Revoke the Storage download tokens** on all previously uploaded ID images. The migration moves the URLs; it does not invalidate links already issued.
5. **Rotate `GROQ_API_KEY` and `GEMINI_API_KEY`.** They shipped inside every distributed build; removing them from the bundle does not retire the ones already out there.

### Known residue

- Listing volunteers still returns their full user document, including email and phone. The `list` rule now restricts results to volunteer records, which stops whole-directory dumping, but the complete fix is a `volunteers_public` projection maintained by a Cloud Function (§4.4).
- Volunteer rating aggregates are bounded to ±1 per write rather than server-computed. A determined caller could still loop. Server-side aggregation remains the real fix (§4.6).
- Cross-user notification creates cost one extra document read each. Routing them through a callable, as the freemium writes already are, is cheaper and stricter (§4.3).
- `flutter analyze` still reports 26 info-level lints, all third-party API deprecations (`stacked`, `showcaseview`) needing package migrations. CI runs with `--no-fatal-infos` until then.
- Chatbot history is still wiped on every launch while `ChatbotViewModel` retains full load/save logic. Left alone deliberately: whether to persist AI mental-health conversations on device is a product and privacy decision, not a cleanup (§5.9, §11.6).

---

## 2. What is already strong

This section is not politeness. These are decisions worth protecting during the refactor.

**Entitlement is server-authoritative and I could not find a bypass.** `BillingService` states the invariant explicitly — it never grants entitlement — and upholds it. `firestore.rules:66-70` places `subscriptionTier`, `subscription_expiry`, `subscription_source` and `welcomeChatsUsed` in `ownerForbiddenUserFields()`, so a client cannot write its own premium status. `refreshEntitlement` is deliberately grant-only so a transient REST failure cannot strip a paying user, while revocation is the webhook's job. That split is exactly right.

**The premium-audio gate is textbook.** `sound_audio/**` is `allow read: if false` in Storage. The `sounds` document is world-readable including `audio_path`, because the path is not the file. Playback goes through `getSoundAudioUrl`, which re-checks entitlement server-side and returns a one-hour signed URL. Genuinely unbypassable, and the client caches the result per sound id.

**Freemium caps are enforced in server transactions.** `requestVolunteerChat`, `createCommunityPost` and `createCommunityReply` reserve the quota slot before doing the work, and the corresponding direct client creates are denied in the rules. The counters live at `users/{uid}/usage/{feature}` with `allow write: if false`.

**The self-harm moderation carve-out is correct and deliberate.** `moderation_keywords.dart:10-12` and `moderation_service.dart:112-113` both document the invariant that self-harm and suicidal phrasing must never appear in a block list, because those are crisis disclosures to escalate rather than violations to suppress. This is the single most important judgement call in a mental-health product and it was made correctly.

**Crashlytics is wired properly** — `runZonedGuarded`, `FlutterError.onError` and `PlatformDispatcher.onError` all route to Crashlytics, and `AppLog.error` records non-fatals, gated on user consent.

**Startup was correctly de-blocked.** `BillingService.configure()` and `PushNotificationService.initialise()` were moved past `runApp()` with `unawaited`, with a comment explaining the regression it fixed. `getCurrentUserRole` implements a cache-first, then bounded-server-read pattern.

**`BulkWriter` is used correctly in six Cloud Functions**, with cursor paging and an explicit comment about the 500-op `WriteBatch` cap. This is the best-engineered part of the codebase.

**Comment quality is unusually high.** Security decisions, fail-open choices and platform workarounds are explained inline. There is exactly one hand-written `// ignore:` in the entire codebase. Roughly 25 MB of MP3s were correctly moved out of the bundle to Cloud Storage.

---

## 3. Critical defects

These are verified, specific, and small to fix.

### 3.1 The signup password is displayed in cleartext

`lib/ui/views/signup/signup_view.dart:79-83` — the password field has no `obscureText`, while the confirmation field directly below it at `:85-90` does.

```dart
CustomTextField(
  controller: viewModel.passwordController,
  labelText: 'Type a password',
  keyboardType: TextInputType.visiblePassword,
),                                    // ← no obscureText
CustomTextField(
  controller: viewModel.confirmPasswordController,
  labelText: 'Confirm password',
  keyboardType: TextInputType.visiblePassword,
  obscureText: true,                  // ← masked
),
```

`CustomTextField` defaults `obscureText` to `false`. Every other password field in the app is correctly masked. On the user signup screen, the password is visible to anyone near the device.

**Fix:** add `obscureText: true`. While there, add a show/hide toggle — there is none anywhere in the app, so users on the masked fields have no way to check what they typed.

### 3.2 iOS push notifications cannot work

There is **no `ios/Runner/*.entitlements` file**, zero occurrences of `aps-environment` or `CODE_SIGN_ENTITLEMENTS` in the Xcode project, and no `UIBackgroundModes` in `Info.plist`. APNs registration fails, `getToken()` returns null, and no iOS device ever receives a notification.

Android billing being deliberately out of scope this phase is documented; iOS push being non-functional is not. If iOS is shipping, this is a launch blocker.

### 3.3 The presence heartbeat has never written a record

`auth_service.dart:391-421` `_createAppUser` is the **only** path that constructs `currentUser`. It omits three fields that `AppUser.fromJson` reads: `availabilityStatus`, `lastSeen` and `fcmToken`.

`availabilityStatus` therefore always falls back to its `'offline'` default, so `AppUser.isOnline` is **permanently false**, so `PresenceService._beat()` returns early on `!user.isOnline` every single time. The chain of consequences:

- `lastSeen` is never written for any volunteer.
- `sweepStalePresence` (a scheduled function running 48×/day) queries `lastSeen < cutoff` and can never match.
- The `users | role, availabilityStatus, lastSeen` composite index is dead weight.
- `volunteer_home_viewmodel.dart:115-127` re-reads the user document from Firestore purely to obtain `availabilityStatus`, because the model it already holds does not carry it.

**Fix:** add the three missing fields to `_createAppUser`. Better: delete `_createAppUser` entirely and call `AppUser.fromJson`, which already maps every field correctly. Two divergent deserialisers for the same document is the root cause.

### 3.4 The volunteer application progress bar overflows on 360 dp devices

`volunteer_signup_info_view.dart:68-85` builds three fixed `width: 100` bars with `horizontal: 4` margins inside `EdgeInsets.symmetric(horizontal: 25)`.

Intrinsic width = `3 × 100 + 6 × 4 = 324 dp`, plus 50 dp of padding = **374 dp required**.

| Device | Width | Result |
|---|---|---|
| Galaxy S8/S10e and most budget Android | 360 dp | **Overflow, 14 px** |
| iPhone SE (1st gen) | 320 dp | **Overflow, 54 px** |
| iPhone SE 2/3, iPhone 12 mini | 375 dp | Passes by 1 dp |

A large share of the Pakistani Android market sits at 360 dp. **Fix:** `Expanded` children in the `Row`. Note that `step_progress_indicator` is already a dependency and is used nowhere.

---

## 4. Security, privacy & safety

`firestore.rules` is 381 lines of careful, well-commented work. The catch-all that once exposed every document is gone, `ownerForbiddenUserFields()` correctly blocks privilege escalation and self-granted premium, and freemium bypasses are closed by denying client creates. All nineteen collections the client touches have a matching rule.

The failures below are specific rules, not a systemic problem — but their consequences are severe for a mental-health product.

### 4.1 Volunteer identity documents are readable by every signed-in user — Critical

`firestore.rules:174` — `match /volunteer_info/{volunteerId} { allow read: if isSignedIn(); }`

The document contains `idCardUrl`, `idCardBackUrl`, `studentIdUrl` and `studentIdBackUrl` (`volunteer_info_model.dart:7-10`). These are permanent Firebase download URLs with embedded access tokens.

`storage.rules:61-76` correctly restricts those Storage prefixes to owner and admin. But `storage.rules:15-18` **documents the very problem**: download URLs carry their own token and bypass Storage rules. The Firestore rule hands out the token, so the Storage rule is defeated. `volunteer_service.dart:20-28` fetches this document for every volunteer rendered on the home screen.

**Any signed-in user can enumerate volunteers and download their national ID and student ID images.**

**Fix (defence in depth):**
1. Split `volunteer_info` into a public projection (tags, ratings, institution) and a private `volunteer_info/{uid}/private/vetting` document restricted to owner + admin.
2. Move the vetting documents to signed URLs behind a callable, exactly as `getSoundAudioUrl` already does for premium audio — the pattern is already in the codebase and proven.
3. Revoke the existing download tokens for all uploaded ID images. Treat every currently-issued URL as compromised.

### 4.2 All mood history is readable by every signed-in user — Critical

`firestore.rules:198` — `allow read: if isSignedIn();` on `/mood/{moodId}`, while create, update and delete are correctly owner-scoped.

The schema documentation describes `extraField` as *"may contain sensitive notes — treat as private."*

The exploit is already written into the client. `mood_service.dart:93-116` `getMoodEntriesPageForAdmin()` gates on `userDoc.data()?['role'] != 'admin'` **client-side only**, then runs `db.collection('mood').orderBy('timestamp', descending: true).limit(limit)` **with no `userId` filter**. The rules permit that exact query to any authenticated caller. A patched client or a raw REST call dumps the whole population's mood history.

**Fix:** `allow read: if isSignedIn() && resource.data.userId == request.auth.uid;`. Move the admin query behind a callable. The same applies to `getAllMoodEntriesForAdmin()`, which is an unbounded full-collection read sitting in the mobile app's service layer.

### 4.3 Arbitrary push-notification injection — Critical

`firestore.rules:128` — `match /users/{userId}/notifications/{id} { allow create: if isSignedIn(); }`

`functions/index.js:147-200` (`onNotificationCreated`) reads `title`, `body` and `data` straight off the client-written document and pushes them via FCM with no sanitisation and no rate limiting.

Combined with §4.4 (the full user directory is listable), any account can enumerate every uid and send unlimited arbitrary-text push notifications to any user. For a mental-health app this is a direct harassment vector and a Play policy problem.

**Fix:** deny client creates and route notification creation through a callable that validates the sender's relationship to the recipient (chat participant, thread author) and rate-limits per sender.

### 4.4 The full user directory is listable — High

`firestore.rules:93` — `allow list: if isSignedIn();`

`get` is correctly owner/admin-scoped, but `list` returns **whole documents**, and Firestore rules cannot project fields. User documents contain `email`, `phoneNumber`, `dateOfBirth`, `gender`, `fcmToken` and `subscriptionTier`.

`user_service.dart:60-63` `getAll()` is an unbounded `collection('users').get()` in the mobile service layer, called at cold start for any admin. `streamAvailableVolunteers()` hands full `AppUser` documents — email, phone, DOB, FCM token — to every user browsing the volunteer list.

**Fix:** introduce a `volunteers_public` projection collection maintained by a Cloud Function, containing only what the discovery UI renders. Deny `list` on `users` entirely.

### 4.5 Chat integrity — High

Two separate problems in the same block:

- **`firestore.rules:224-225`** — `allow write` on messages covers create, update *and* delete. The comment at `:222-223` claims messages "stay immutable evidence for escalation review", but that is only enforced against admins. Either participant can silently rewrite or delete the other's messages before a supervisor reviews an escalation.
- **`firestore.rules:215`** — `allow update` on the chat has no `affectedKeys()` constraint. A participant can write `participants: [me, victim, accomplice]`, and message reads resolve against the *current* participants array — granting an arbitrary third account read access to the entire private conversation. The same gap lets a participant clear `escalated: false`, which is the flag `hasUnresolvedEscalation` depends on, and hard-delete an escalated chat.

**Fix:** messages become create-only for participants (`allow create` + `allow update, delete: if false`). Chat updates get an `affectedKeys().hasOnly([...])` allowlist that excludes `participants` and `escalated`. Deletion becomes a soft-delete denied while `escalated == true`.

### 4.6 Client-writable aggregates — Medium

- **`firestore.rules:180-182`** lets any signed-in user write `averageRating`, `totalReviews` and `completedChats` on any volunteer, to any value. Only the key set is constrained, not the values. Separately, review creation only checks `userId == auth.uid` with no proof a chat occurred — review-bombing is open.
- **`firestore.rules:275-277`** lets any signed-in user set any community's `membersCount` to any value, and `community_service.dart:32-34` orders the "popular communities" list by exactly that field.
- **`isOwnLikeToggle()`** (`:44-57`) verifies the caller's own uid moved and that `likeCount` shifted by ±1, but never asserts `likedBy` changed *only* by that element. A caller can strip or inject other uids in the same write.
- **`escalations`** accepts unvalidated client creates with no field validation and no rate limit. The crisis triage queue can be flooded with fabricated `severity: 'critical'` reports.

**Fix:** move all four aggregates to Cloud Function maintenance and deny client writes. Validate `escalations` creates against `request.auth.uid`.

### 4.7 Live API keys ship inside the app binary — High

`pubspec.yaml` lists `.env` as a Flutter asset. Flutter assets are plain files inside the APK — recoverable with `unzip`. `.env` holds three populated values:

| Key | Used anywhere in `lib/`? |
|---|---|
| `GROQ_API_KEY` | **No** |
| `GEMINI_API_KEY` | **No** |
| `REVENUECAT_ANDROID_KEY` | Yes — and it is a *public* SDK key, safe by design |

`env.dart:15-16` declares getters for the Groq and Gemini keys with **zero call sites**. The Groq key was correctly migrated server-side — `sendDodoMessage` uses `{ secrets: [GROQ_API_KEY] }` — but the client `.env` was never cleaned up. Two live, billable secrets ship to every device for no functional benefit.

Git-ignoring `.env` does not help. The file is in the bundle.

**Fix:** delete both keys from `.env`, remove the getters, and **rotate both keys** — assume compromised if any build was distributed. Consider replacing the bundled-`.env` mechanism with `--dart-define` for the one remaining public value.

### 4.8 Safety gaps specific to a mental-health product

**No user-facing crisis surface.** Volunteer-side escalation is well built. But there is no helpline directory, no persistent "get help now" affordance, and no lifeline offered to a *user* who discloses self-harm — even though the moderation layer correctly and deliberately refuses to block such disclosures. The product detects the disclosure, routes it to a volunteer, and offers the user in crisis nothing directly. This is both an ethical gap and an app-store review expectation for health apps. See §11.1.

**Uncurated third-party content is shown to vulnerable users.** `home_viewmodel.dart:260-273` fetches the home screen's daily "whisper" live from `https://zenquotes.io/api/today` — no key, no SLA, no content review — and renders it directly, with the failure silently swallowed. A curated pattern already exists in this codebase: `journal_prompts/{YYYY-MM-DD}`, admin-authored and rule-protected. Move the whisper to it.

**`docs/SECURITY_LOGS.md:8-13` states a hard legal prerequisite** — the privacy policy must disclose IP collection — and nothing in the repository evidences that it was done.

### 4.9 Platform and build hardening

- **No R8/ProGuard.** No `isMinifyEnabled`, no `isShrinkResources`, no `proguardFiles`, no rules file. AGP defaults minification off, so the release APK is unobfuscated and unshrunk — which, combined with §4.7, makes extracting the keys trivial.
- **`AD_ID` permission is declared** for an app with no advertising. It arrives transitively via `firebase_analytics` and forces an Advertising-ID declaration in Play Data Safety for a mental-health app. Remove it with `tools:node="remove"`.
- **`journal_audio` Storage writes have no content-type or size limit** — every other prefix has both.
- **`targetSdk` is implicit** (`flutter.targetSdkVersion`), so a Flutter upgrade can silently change Play compliance. Pin it.
- **No security-rules tests.** With 381 lines of authorisation logic, `@firebase/rules-unit-testing` against the emulator is the highest-leverage test suite available — it would have caught §4.1, §4.2, §4.3, §4.4 and §4.5.

---

## 5. Data flow, Firestore efficiency & backend

The branch is named `refactor/efficient-firestore-bugfix`, and real progress was made — `limit()` was added in three places, `getMany()` batches `whereIn` in chunks of 30 with a TTL cache, and cursor pagination helpers were written. The problem is that **the good primitives were built and then not adopted**.

### 5.1 The abstraction layer is unused

`FirestoreServiceMixin.guard()` centralises logging and the rethrow-versus-fail-soft policy. It has **zero callers**. All thirteen services that mix it in hand-roll their own `try/catch`. `FirestoreServiceMixin.chunk()` has one caller. `TtlCache` has one consumer.

Similarly: `runBusyFuture` has **zero call sites** across 88 hand-rolled `setBusy(true) … finally setBusy(false)` blocks. `home_viewmodel.sendChatRequest` calls `setBusy(false)` on four separate paths — precisely the bug class `runBusyFuture` exists to prevent.

Four dead abstractions carry maintenance weight with no benefit: `guard()`, `SessionService` (62 lines, zero references), `ChatRoom` (43 lines, zero references), and the `getResponsive*FontSize` family (§7).

**Fix:** adopt or delete. Adopting `guard()` across the thirteen services is mechanical and would immediately route ~22 currently-invisible failures into Crashlytics (§5.6).

### 5.2 Thirteen of sixteen live collection listeners have no `.limit()`

| Location | Query | Consequence |
|---|---|---|
| `chat_service.dart:193-203` | `chats/{id}/messages` | **Worst.** Every message ever sent, streamed live and re-parsed on each new message. A 2,000-message chat costs 2,000 reads on open. No pagination in any chat UI. |
| `community_service.dart:106-116` | `posts/{id}/replies` | Entire thread |
| `chat_request_service.dart:42,134,147,174` | `chat_requests` ×4 | Every request the user ever sent or received, forever |
| `user_service.dart:116-125` | online volunteers | Full roster, live |
| `journal_service.dart:38-65` | `users/{uid}/journal` | Premium passes `sinceDays: null` → **entire lifetime journal**, live |
| `notifications_drawer.dart:41`, `volunteer_notifications_drawer.dart:43` | notifications | **No `where`, no `limit`** — every notification ever |

**Fix:** `.limit(50)` plus `startAfterDocument` cursor pagination. The correct pattern already exists in `user_service.getUsersPage` and `mood_service.getMoodEntriesPageForAdmin` and is used by no UI.

Note the current community pagination is **quadratic**: `loadMore()` grows `_postLimit` by 20 and re-reads the entire result set. Pages 1–5 cost 20+40+60+80+100 = **300 reads for 100 posts**.

### 5.3 Streams constructed inside `build()`

These create a **new Firestore subscription on every rebuild**, so `StreamBuilder` cancels and re-subscribes — a fresh billed read each time.

- **`home_screen.dart:913`** — `viewModel.homeAnnouncement` returns a new `.snapshots()` on every call. `HomeScreen` rebuilds on all **14** `notifyListeners()` sites in `HomeViewModel`, including every notification tick, every mood-streak tick and every volunteer roster tick.
- **`journal_view.dart:275`** — same pattern for `promptOfTheDay`.
- **`volunteer_notifications_drawer.dart:43`** — the query is built inline in `build()` and the widget is constructed non-const, so all twelve of the view model's notify calls re-subscribe an unbounded notifications query while the drawer is open.

The correct pattern is one line away in the same file: `home_viewmodel.dart:677-682` caches with `_communitiesStream ??=`. It was applied to one of the three.

### 5.4 One screen builds the same view model three times

`VolunteerHomeViewModel()` is constructed in `volunteer_home_view.dart:73`, `tabs/dashboard.dart:19` and `tabs/request.dart:191`. Its constructor unconditionally starts a user-document read plus three stream subscriptions. All three tabs are alive simultaneously inside a `Stack`.

**Net: three user-document reads and roughly nine concurrent listeners where three and one would do.** `request.dart:194-200` then calls `listenForRequests()` *again* in `onViewModelReady`, making it four.

`HomeView` does this correctly — its tabs are `ViewModelWidget<HomeViewModel>` sharing the parent view model. Apply the same shape to `VolunteerHomeView`.

### 5.5 Rebuild amplification

185 `notifyListeners()` calls against 3 `rebuildUi()` — and all three of those are in dead template code.

`AuthenticationService` is the amplifier: 35 notify calls fanning out to nine subscribers, three of which respond by issuing a Firestore read (`_refreshCapStatus`). Because `PresenceService` writes `lastSeen` to the same document every five minutes, a volunteer sitting in a community thread triggers a `usage` read every five minutes indefinitely. (Currently masked by the §3.3 bug — fixing that will *activate* this cost.)

Other specific cases:
- **`MoodTrackerViewModel.init`** runs a `Ticker` calling `notifyListeners()` **per frame at 60 Hz** to animate particles, rebuilding the entire view-model-bound subtree sixty times a second. Particles belong in an `AnimatedBuilder`/`CustomPainter` repaint.
- **`ThreadRepliesViewModel._onReplyChanged`** fires a full screen rebuild per keystroke for @-mention suggestions.
- **`toggleFilterTag`** and **`onTabTapped`** rebuild a 959-line screen for a chip toggle and a tab index. `filteredVolunteers` recomputes O(n·m) and allocates a new list on every rebuild.
- **`_computeMoodStreak`** re-parses the user's entire mood history on every stream emission to render one integer.

**Fix:** split `HomeViewModel` (908 lines, four subscriptions in its constructor, two `AudioPlayer`s, a seven-key showcase tour and a bottom-nav index) into focused view models. Denormalise `moodStreak` onto the user document via a Cloud Function.

### 5.6 Error handling is inconsistent and partly invisible

176 `try` blocks, 183 `catch` clauses. `AppLog` routes to Crashlytics correctly — but **42 `debugPrint` sites bypass it**, roughly 22 of them inside `catch` blocks. `debugPrint` compiles to nothing user-visible in release, so ~22 handled failures are invisible in production.

`ChatService` is the standout: five `catch` blocks, none using `AppLog`. Batch-delete failures and chat-deletion failures are release-invisible.

There are also **10 fully silent catches**, four of them around the audio-recording lifecycle in `new_journal_entry_viewmodel.dart` — a recording that fails to start or stop produces no signal at all.

The prevailing pattern is nullable-return-plus-swallow. Some fail-open choices are documented and defensible (`escalation_service.dart:108`); one is safety-relevant and should be reconsidered: `block_service.dart:26` returns an empty set on error, so **a block silently fails open**.

### 5.7 Memory and lifecycle leaks

| Leak | Location |
|---|---|
| Two `AudioPlayer`s never disposed — and entirely dead code | `home_viewmodel.dart:50,52`; `dispose()` at `:900-907` does not touch them |
| Five `TextEditingController`s, no `dispose()` override | `signup_viewmodel.dart:14-18` — the only view model in the codebase with controllers and no disposal |
| View model registered as `LazySingleton` with `disposeViewModel: false` | `VolunteerSignupViewModel` — `dispose()` never runs, so form state persists across signup attempts for the whole session |
| Two controllers created inside `build()`, never disposed | `edit_profile_view.dart:218`, `user_info_view.dart:25` |
| `SharedPreferences.getInstance()` called from `build()` | `home_view.dart:36`, `volunteer_home_view.dart:30` — disk I/O on every rebuild |

All eleven `AnimationController`s are correctly disposed, and most subscriptions are cancelled — the leaks above are the exceptions, not the rule.

### 5.8 Cloud Functions

All 31 functions are v2, secrets are bound via Secret Manager, and `BulkWriter` is used correctly. Three issues:

**No region pinning anywhere.** Zero `region` or `setGlobalOptions` calls, so everything deploys to `us-central1` while every schedule is `Asia/Karachi`. That is a ~250–400 ms round-trip penalty on **every** callable: Dodo message, chat request, community post, community reply, sound URL, security log. Pin to `asia-south1` (Mumbai).

> **Caveat worth stating plainly:** the *Firestore database* location cannot be changed after creation. Function region pinning is available today and is most of the win; full colocation is a new-database decision for a future migration.

**No `minInstances` or `maxInstances`.** `sendDodoMessage` pays a Node-22 cold start plus Secret Manager resolution plus the us-central1 round-trip before the Groq call even begins — the app's most latency-visible interaction. Set `minInstances: 1` on the two or three user-facing callables, and cap `maxInstances` everywhere to bound runaway cost.

**`deleteMyAccount` is the riskiest function in the codebase**: six unbounded queries, an N+1 loop over chats, sequential `recursiveDelete`s and a Storage `deleteFiles` across seven prefixes, all inside one default-timeout, 256 MB invocation. A prolific author will blow the 60-second timeout, leaving deletion half-complete — a GDPR/PDPB problem as well as a correctness one.

Smaller wins:
- **Three functions fire on every `posts` create** and three more on every reply create, each cold-starting separately and re-reading the same documents. Merging each path into one handler cuts invocations roughly 3×.
- **`getFreemiumLimits()` re-reads `app_settings/global_config` on every invocation**, while `getModerationConfig` right beside it caches for five minutes. Four separate functions read that same document uncached.
- **`moderation.js:100`** constructs `new RegExp(...)` inside a loop, per term, per call. Precompile at config load.

**Moderation is post-hoc.** `moderateChatMessage`, `moderatePost` and `moderateReply` fire *after* the document is written, so the recipient's live listener renders the message before the function removes it. The callable-write path already exists for posts and replies; extending it to chat messages would close the window.

### 5.9 Caching and offline

- **No offline story.** No `connectivity_plus`, no explicit Firestore cache tuning, no offline banner, no queued-send UX. Offline messaging exists in exactly two places in the entire app.
- **Hive is initialised on the startup critical path for a single use** — chatbot history — which `main.dart:62` then **wipes on every launch**. Meanwhile `ChatbotViewModel` has full load/save logic written as though history persists. The two contradict each other; Dodo history is always empty on launch.
- **`SessionService`** reimplements session validity that Firebase Auth already owns, and has zero references. Delete it.

### 5.10 Cold start

Roughly **two seconds of avoidable delay** before the first meaningful frame:

1. `startup_viewmodel.dart:27` — `await Future.delayed(const Duration(seconds: 2))`, a flat two-second tax on every launch, commented "for a splash screen effect".
2. `main.dart:60-62` — Hive init, open and **clear** all awaited before `runApp`, for a box whose contents are discarded.
3. `auth_service.dart:169-171` — admins `await fetchAllUsers()`, an unbounded full-collection read, before auth status resolves.
4. `auth_service.dart:106` + `:204` — the same user document is fetched twice (a `.get()` then a `.snapshots()`). One `snapshots().first` serves both.
5. `MonetizationService` construction triggers two blocking Firestore reads and a conditional write that nothing on the splash needs.

There is also a **cold-start deep-link race**: `StartupViewModel` reads `pushService.pendingNotification` after its two-second delay, but that field is only populated inside `initialise()`, which runs post-first-frame *and blocks on `requestPermission()` first*. If the OS permission dialog is showing, a notification tap that launched the app from a killed state silently goes nowhere.

---

## 6. Design system

### 6.1 The theme is defined and then bypassed

**`Theme.of(context)` appears exactly once in 30,709 lines of UI code** — `widgets.dart:563` — and that single call reads `colorScheme.onBackground`, deprecated since Flutter 3.18.

Everything else is hand-styled: **376** `GoogleFonts.` call sites, **1054** `AppColors.` references, **1315** raw `Colors.*` references. The consequences:

- The six `textTheme` slots in `app_theme.dart:22-48` are dead.
- `elevatedButtonTheme` is dead — every button passes an explicit `ButtonStyle`.
- `AppTheme.smallButton`, `mediumButton` and `largeButton` have **zero call sites**. (`largeButton` uses `horizontal: 125` padding and would overflow every phone if used.)
- `appBarTheme` is nearly dead: only two `AppBar`s exist and both override the background.

**There is no single place to change how this app looks.** That is the core design-system finding, and everything in §6 follows from it.

### 6.2 The `ColorScheme` leaks Material blue

```dart
colorScheme: ColorScheme.fromSwatch().copyWith(
  secondary: AppColors.secondary,
  surface: AppColors.background,
),
```

`ColorScheme.fromSwatch()` with no `primarySwatch` yields **Material Blue**. Only `secondary` and `surface` are overridden, so `colorScheme.primary` is `#2196F3`. Every framework widget reading it renders blue: `Switch`, `Checkbox`, `LinearProgressIndicator`, all `CircularProgressIndicator`s, and the text cursor and selection handles in all 33 text fields.

`useMaterial3` is never set while `fromSwatch()` is an M2 API — the app sits in an undefined M2/M3 blend.

Symptomatically, the four `showDatePicker` call sites each hand-patch this with a duplicated ten-line `Theme(...)` override — **and one of them disagrees**, using `AppColors.secondary` where the other three use `AppColors.primary`.

**Fix:** `ColorScheme.fromSeed(seedColor: AppColors.primary)` with explicit role overrides, plus `useMaterial3: true`. Delete the four date-picker patches.

### 6.3 Colours are the one healthy token layer

Only **4 live raw hex values** exist outside `app_colors.dart`, and `docs/color_scheme.md` already lists them as known debt. That discipline is real and worth crediting.

The gap is **270 raw `Colors.*` references** bypassing the palette — including `Colors.purple`, `Colors.deepPurple`, `Colors.blueAccent`, `Colors.amber` and `Colors.pink`, which have no relationship to the brand. `AppColors.red` and `AppColors.green` exist, yet `Colors.red` (12×) and `Colors.green` (5×) are used instead.

The palette also lacks **semantic roles**. It is 24 literal names (`pink`, `camel`, `teal`, `darkYellow`) with no `onPrimary`, `onSurface`, `outline`, `disabled`, `success` or `warning` — so there is nothing to map onto a `ColorScheme` and nothing to invert for dark mode.

### 6.4 There is no type scale, and the helpers meant to provide one are broken

**393 hardcoded `fontSize:` literals across 37 distinct values.** Half-point sizes (`12.5`, `13.5`, `14.5`, `15.5`, `16.5`) are the signature of eyeballed values rather than a scale.

`getResponsiveSmallFontSize` through `getResponsiveMassiveFontSize` have **zero call sites** — because they are numerically wrong:

```dart
min(screenWidthFraction(context, dividedBy: 10) * ((fontSize ?? 100) / 100), max)
```

On a 400 dp-wide phone, `getResponsiveMediumFontSize` returns `min(40 × 0.16, 17)` = **6.4 pt**. Every helper returns a sub-9 pt value on any phone. Developers correctly abandoned them and hardcoded 393 sizes instead.

### 6.5 Spacing is derived from the wrong axis

```dart
static double _baseunit(BuildContext context) =>
    MediaQuery.of(context).size.height * 0.35;
```

| Token | 800 dp phone | 1280 dp tablet |
|---|---|---|
| `tiny` | 14 dp | 22 dp |
| `small` | 56 dp | 90 dp |
| `medium` | 98 dp | **157 dp** |
| `large` | 168 dp | **269 dp** |
| `massive` | 224 dp | **358 dp** |

Two structural problems, across 251 call sites:

1. **`horizontalSpaceVTiny` through `horizontalSpaceLarge` all delegate to the same height-derived unit.** Horizontal spacing scales with vertical screen size — the wrong axis — and inverts on landscape and unfolded foldables.
2. Spacing scales linearly with device height, so a tablet gets 1.6× the whitespace with no content reflow.

Alongside this sit **371 raw `EdgeInsets`** with values including `2, 4, 5, 6, 7, 8, 9, 10, 12, 15, 16, 18, 20, 22, 24` — no 4- or 8-point grid.

### 6.6 No radius or elevation tokens

**279 `BorderRadius.circular()` calls across 25 distinct values.** `23`, `27`, `22`, `26` and `28` all coexist and are visually indistinguishable — drift, not intent. Four button implementations use three different radii.

**Elevation has no system at all**: 11 `elevation:` props (nine of them `0`) against **96 hand-rolled `BoxShadow`s**. The recipe `blurRadius: 20, color: black.withAlpha(25), offset: Offset(0,4)` is copy-pasted roughly fifty times.

### 6.7 No dark mode

`darkTheme`, `themeMode` and `platformBrightness` return **zero results** across the codebase. `app_theme.dart:8` hardcodes `brightness: Brightness.light`. `AppColors.darkBackground` is defined and documented and consumed by nothing.

On a device in dark mode the app renders full-brightness light. For a product with Breathe and Soothing Sounds surfaces, used by people at 2 a.m., this is a felt omission rather than a nicety.

### 6.8 Fonts: bundled and network-fetched at the same time

`assets/fonts/` ships **16 CrimsonPro `.ttf` files (~1.7 MB)** — but `pubspec.yaml` has **no `fonts:` declaration**, only `assets/fonts/` in the asset list.

The practical effect is split:

- **`GoogleFonts.crimsonPro()` (375 call sites) does resolve from the bundle**, because `google_fonts` matches asset-manifest filenames against its API naming pattern. This works.
- **`app_theme.dart:7` `fontFamily: 'CrimsonPro'` resolves to nothing** and silently falls back to Roboto/SF, because `ThemeData.fontFamily` requires a registered `fonts:` family.
- **`GoogleFonts.config.allowRuntimeFetching` is never set to `false`**, so any variant that fails to match silently becomes a network fetch to `fonts.gstatic.com` — a first-launch-offline failure mode with no error.

Additionally, **5 files use raw `TextStyle` with no `GoogleFonts`** and will render in the fallback face next to CrimsonPro siblings — including `welcome_view.dart:105-109` and `:148-152`, the two primary CTAs on the first screen users see.

**Fix:** add a proper `fonts:` block, set `allowRuntimeFetching = false`, and route typography through `textTheme`.

### 6.9 Four competing background systems

`AppTheme.theme.scaffoldBackgroundColor` is never visible, because all 35 `Scaffold`s override the surface:

1. **A full-bleed 288 KB JPEG** on 21 screens.
2. **A verbatim 4-stop gradient** copy-pasted across 10 files.
3. **Flat colour** on 4 screens.
4. **A different JPEG** (pink) on the Dodo screen only.

Because 21 screens sit on a *photographic* ground, text contrast is not deterministic anywhere on them — it cannot be measured, so it cannot be tested.

### 6.10 `responsive_framework` is declared and never imported

Zero references. There is no breakpoint system, no max content width and no tablet layout. Because every dimension derives from raw screen size, a 10-inch tablet gets phone layouts stretched 2×, and rotating to landscape shrinks every vertical dimension by ~55% — the bottom nav drops to roughly 26 dp.

Three more declared-but-unused packages: `step_progress_indicator`, `flutter_zoom_drawer`, and `fl_chart`. `liquid_glass_renderer` is imported but its only usage is commented out. Also unused: `firebase_ai`, `google_sign_in_dartio`, `audioplayers` (superseded by `just_audio`).

---

## 7. Rendering performance & bundle

### 7.1 Blur is the dominant cost

**98 `BackdropFilter`s, 35 of them at `sigma: 200`.** A sigma of 200 is roughly 10–20× a normal frosted-glass value, and each one forces a `saveLayer` plus a full-viewport blur.

Worse, they **nest** — each nested filter re-blurs everything beneath it:

- `home_screen.dart` — three levels deep, all inside a `SingleChildScrollView`.
- `journal_card.dart` — **four sigma-200 blurs per list row**: the outer card, two `_blurChip`s and a `_blurIcon`.
- `bottom_bar.dart` — a sigma-200 blur on the **always-visible** bottom nav, sitting over an `Offstage` stack of three tabs that all remain mounted and rebuilding.

### 7.2 The journal list is the worst hotspot

It combines four antipatterns at once:

1. `journal_view.dart:114-134` puts the whole tab body in a **`SliverToBoxAdapter`** — no lazy sliver building.
2. Inside it, the tabs use `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` — **every entry is built at once**.
3. Each row is wrapped in `FadeSlideIn`, creating **one `AnimationController` plus one `Future.delayed` per row**, and using a raw `Opacity` widget (not `FadeTransition`) — a `saveLayer` per row per frame while animating.
4. All of that is the child of an **`AnimatedSwitcher`** that cross-fades the entire unbounded list on every tab change.

For a user with 100 entries: 100 eagerly-built rows × 4 nested sigma-200 blurs + 100 `Opacity` saveLayers + 100 tickers, cross-faded together.

### 7.3 No image caching, no downsampling

There is no `cached_network_image` dependency. Remote images use 7 `Image.network` and 4 `NetworkImage`. Flutter's `ImageCache` is **memory-only and process-scoped**, so every avatar re-downloads on cold start.

Worse: **zero `cacheWidth`/`cacheHeight`/`precacheImage` in the entire codebase**. Storage allows 10 MB profile uploads, so a 3000×3000 avatar is decoded at full resolution into a 56×56 slot — roughly **36 MB of ImageCache for one avatar**.

### 7.4 No render optimisations at all

`RepaintBoundary`, `itemExtent`, `prototypeItem`, `cacheExtent` and `addRepaintBoundaries` return **zero occurrences**. `Lottie` appears in 29 places, including inside community post cards and reply cards — a Lottie composition per scrolling row.

`breathe_view.dart:78-81` schedules an **empty** `addPostFrameCallback` on every build.

### 7.5 The asset bundle is 9.4 MB and largely waste

| Asset | Size |
|---|---|
| `images/soothing.jpg` | **2.6 MB** |
| `images/breathe.jpg` | **2.2 MB** |
| `images/music.jpg` | 340 KB |
| `images/background.jpg` | 281 KB |
| `icons/avatar_female.png` | 286 KB |
| `icons/avatar_binary.png` | 260 KB |
| `icons/community2.png` | 228 KB |

Two background photos account for **4.8 MB of a 9.4 MB payload**. Several "icons" are full-resolution images. Roughly 60 UI icons ship as raster PNGs where vectors would be smaller and tintable.

Also shipping: a duplicate `soothing.jpeg`, a misspelled `logo_sqaure.png`, an unreferenced `splash.svg` and `loader.lottie` — and **`.DS_Store` files bundled into the released app** (30 KB), because `pubspec.yaml` declares whole directories.

### 7.6 `const` discipline is good but unenforced

1,585 `const` tokens; `const EdgeInsets` outnumbers non-const 276 to 42. The discipline is real — but `analysis_options.yaml` includes only `flutter_lints`, which does **not** enable `prefer_const_constructors`. Nothing enforces it, so the remaining ~42 sites will never be flagged.

---

## 8. Accessibility

This is the weakest area in the product, and the finding is absolute rather than partial.

### 8.1 Zero accessibility instrumentation

Every one of the following returns **zero results** across the entire codebase:

`Semantics(` · `semanticLabel` · `ExcludeSemantics` · `MergeSemantics` · `excludeFromSemantics` · `tooltip:` · `textScaler` · `textScaleFactor` · `SemanticsService`

There are **88 `Image.asset(...)`** calls, and the primary navigation, back button, send button, like button and delete button are all **unlabelled images inside bare `GestureDetector`/`InkWell`**. A TalkBack or VoiceOver user cannot operate:

- The **entire bottom navigation** — announces nothing.
- The back/menu button in `TopBar`, present on 21 screens.
- The send button in both chat composers.
- The destructive delete button on community posts.

### 8.2 Tap targets below the 48 dp minimum

| Element | Computed size |
|---|---|
| Bottom navigation bar (whole bar) | **39.8 dp** on a 568 dp screen |
| Bottom nav tab icon | **~29 dp** (the height constant disagrees with the bar's actual height) |
| `CustomButton` — the primary CTA on two auth screens | **36.9 dp** |
| OTP input cells | **39.8 × 41.6 dp** |
| Community post delete button | **31 dp** |
| Journal card edit affordance | **~28 × 24 dp** |
| Like button | 28 dp |
| Sound lock badge | 11 dp |

Exactly one place in the codebase acknowledges the minimum — `volunteers.dart:370-373`, which correctly cites `kMinInteractiveDimension`. There are 84 `InkWell` and 31 `GestureDetector` against only 10 `IconButton`, the one widget that would enforce 48 dp automatically.

### 8.3 Text scaling will break layouts

Because `MediaQuery.textScaler` is never read or clamped, OS font scaling (up to 200% on Android, 310% with iOS accessibility sizes) flows straight into fixed-height containers:

- **`JournalCard`** — a fixed `height * 0.195` `Column` containing an `Expanded`. **RenderFlex overflow above roughly 1.15×.**
- **`_blurChip`** — a ~24 dp box containing 16 pt text plus 4 dp of border. That is ~25 dp of content: **it clips at 1.0×**, badly at 1.3×.
- **`TopBar`** — 61 dp fixed height holding a 26 pt title plus an optional subtitle. Overflows around 1.5×.
- **Filter chip headers** use fixed `SliverPersistentHeader` extents; the text grows and the header does not.
- **Welcome CTAs** — 160 dp of horizontal padding plus 24 pt text overflow above roughly 1.2×.

Only **28 `maxLines:`** and **21 `TextOverflow`** guards exist across **393 `Text(` widgets**.

### 8.4 Contrast failures

| Pair | Ratio | Verdict |
|---|---|---|
| TopBar subtitle (`primaryVeryDark @ alpha 150` on `primary`), 13 pt — on ~9 screens | **2.03 : 1** | **Severe fail** (needs 4.5) |
| TopBar title on `primary`, 20/22 pt variants | 3.68 : 1 | Fails (passes only for the 26 pt variant) |
| White on `AppColors.primary` | 2.02 : 1 | Fail |
| `textSecondary` on `background` at 12–13 pt | 4.47 : 1 | Marginal fail |
| `white38` icon on the sounds gradient | ~1.9 : 1 | Fail |
| `primaryVeryDark` on `primary` | 7.43 : 1 | **Passes** — this pairing is safe |

Community chips render at `fontSize: 10.5`, illegible regardless of contrast.

### 8.5 No localisation

`localizationsDelegates`, `supportedLocales`, `Directionality`, `EdgeInsetsDirectional`, `AlignmentDirectional` and `TextDirection` all return **zero results**. All 393 `Text(` strings are inline English. `app_strings.dart` is three lines of unmodified Stacked template reading `'Build Great Apps!'`.

A commented-out en/**ar**/hi list in `app_constants.dart:165-181` signals RTL intent that was never implemented. For a Pakistan-first mental-health product, Urdu is not a nice-to-have — it is the difference between reaching the people this app exists for and reaching only English-comfortable urban users.

---

## 9. UX completeness

### 9.1 One error state across thirty screens

`soothing_sounds_view.dart:227-294` is the **only** screen in the app with a real error state — a `cloud_off` icon, distinct copy and a **Try again** button. It is a good implementation and should be the template.

Everywhere else:

- **`snapshot.hasError` is checked in zero of nine `StreamBuilder`s.** A dropped stream renders as a permanent empty state, indistinguishable from "you have no data."
- **`RefreshIndicator` appears zero times.** No screen can be manually refreshed. If a listener drops, the user's only recovery is force-quitting the app.
- **`FutureBuilder` appears zero times**, so async work has no built-in error channel either.
- Several view-model `onError:` callbacks swallow silently — `mood_insights_viewmodel.dart:126` is literally `onError: (_) {}`.

**Screens with no empty state:** Chatbot, MoodTracker, MoodRecommendation, Profile, Premium, Dashboard, HomeScreen, JournalDetails, NewJournalEntry, Breathe.

**Empty-state copy is missing entirely** on the three Journal tabs and on Chat — where the explanatory copy exists but is **commented out** at `chat_view.dart:145-151`. A bare animation with no explanation and no call to action.

Loading is inconsistent across five idioms: `SkeletonList` (2 screens), a bespoke sound skeleton (1), `CustomLottieLoader` (19 files), `CircularProgressIndicator` (5), and bare busy text. The skeleton components are the right answer and are used on 2 of 12 list screens.

### 9.2 Forms have no Flutter form infrastructure

`Form(`, `GlobalKey<FormState>` and `autovalidateMode` return **zero real matches**.

The consequence is concrete: **`CustomTextField` exposes a `validator:` parameter that can never fire**, because a `TextFormField` validator only runs under a `Form`. All 33 instances carry a dead validation hook.

`lib/ui/common/validators.dart` is well written — but wired into only 4 of ~12 forms. EditProfile, VolunteerEditProfile, both reset-password screens and the OTP screen are unvalidated.

Validation is instead **sequential with early return**, reported through **blocking platform dialogs**. A user with three bad fields on signup must submit, dismiss, fix, submit, dismiss, fix, submit — three modal round-trips where a `Form` would surface all three inline at once. Signup reports errors **twice** (dialog *and* inline); Login reports them only in a dialog. Same flow, two different error models.

The 74 `showDialog` call sites use the **platform default** Material dialog — no CrimsonPro, no palette, no brand. The one styled dialog variant is used exactly once.

### 9.3 No keyboard handling

`FocusNode`, `FocusScope`, `textInputAction`, `nextFocus`, `unfocus()` and `autofillHints` all return **zero results**. `resizeToAvoidBottomInset` is never set.

- Across five stacked fields on Signup the keyboard shows "done", not "next" — each field needs a manual tap.
- No tap-outside-to-dismiss anywhere.
- **No `autofillHints`**, so password managers and SMS-OTP autofill do not work on any auth screen.
- `login_view.dart:39-40` and `signup_view.dart:41-42` wrap content in `ConstrainedBox(minHeight: screenSize.height)` *inside* `SafeArea`, using the full screen height and ignoring `viewInsets`. The form is permanently scrollable by a few pixels and never settles, and the keyboard-open layout can push the submit button out of reach.

The chat surfaces are the exception and are handled well: `FloatingComposerLayout` measures the composer's real height each layout pass and feeds it back as list padding. That is a genuinely good solution, used by all four chat screens.

### 9.4 Navigation

- **Two screens are not routed at all.** `MoodRecommendationView` and `VolunteerGuidelinesView` are pushed imperatively with raw `MaterialPageRoute`/`PageRouteBuilder`, the former duplicating a fade transition that already exists in `page_transitions.dart`.
- **`pushReplacement` traps the mood flow** — Back from the recommendation screen exits the entire mood flow instead of returning to selection.
- **Nested `Navigator`s have no `observers:`**, and the analytics observer is registered only on the root navigator. **The three primary user tabs and three volunteer tabs are invisible to screen-view analytics.**
- Mixed APIs: 90 `NavigationService` calls, 33 raw `Navigator.pop`, 6 raw `MaterialPageRoute`.
- 21 routes use default Material transitions and 8 use custom ones, with no stated rule for which.

`lib/ui/shared/page_transitions.dart` is clean, well-documented and correct — it is simply under-applied.

### 9.5 Component duplication

The shared widget library is good and **under-adopted**: `PressScale` is used 3× against 115 bare tap handlers; `SkeletonList` 2× against 12 list screens; `BusyButton` is bypassed by four competing button implementations.

Near-verbatim duplicated files:

| Pair | Similarity |
|---|---|
| `reset_password_view.dart` ⟷ `volunteer_reset_password_view.dart` | **~88%** — identical structure at identical line numbers |
| `notifications_drawer.dart` ⟷ `volunteer_notifications_drawer.dart` | **~93%** |
| `volunteer_card.dart` ⟷ `user_card.dart` | shared avatar builder, dead commented chip builder |

Also duplicated: **four chat composers** (the two `_MessageInputField`s differ only in `fillColor`), **four upsell CTAs**, **eleven empty states** with divergent sizes and inconsistent copy, **16 private `_*Card` classes** (seven in one file), **seven chip implementations** with different selected colours, and the 4-stop auth gradient across 10 files.

**67 private widget classes** exist across views, none promoted to `shared/`.

### 9.6 Unremoved template boilerplate

`info_alert_dialog.dart` and `notice_sheet.dart` are **unmodified Stacked CLI templates** — an off-palette mustard `Color(0xffF6E7B0)`, a `Colors.black` CTA, `BorderRadius.circular(10)` against the app's 22–27, an emoji `'⭐️'` graphic, no `GoogleFonts`, and `maxLines: 3` truncation on the description. These are the two components that surface every error and notice in the app.

Also still in production code: `incrementCounter` / `counterLabel` in two view models, `setIndex(int value)` which ignores its argument and increments an unused counter, and e-commerce constants in `app_constants.dart:7-19` (`defaultDeliverRadius`, `defaultShippingMethod`, `defaultMakeingOrder`, `defaultSMSGateway`, and a `PKR` currency code paired with a `$` symbol).

Committed dev cruft, tracked in git: `test_layout.dart` (2 lines), `scratch/refactor.py`, `scratch/refactor_viewmodels.py`, `mentions_implementation_plan.txt`.

---

## 10. Engineering hygiene

### 10.1 Test coverage is effectively zero

There are 21 test files and 1,024 lines of test code. **Twenty of them contain no `test()` bodies** — they are untouched Stacked generator scaffolds of 11 lines each.

The **only two real tests** assert the dead template `incrementCounter()` and `showBottomSheet()` methods. And **they cannot pass**: `test_helpers.dart` registers three mocks, while `HomeViewModel` resolves `locator<AuthenticationService>()` in an instance field initialiser, so construction throws `GetIt: Object of type AuthenticationService is not registered`. The mocks file is stale by roughly thirteen services.

Nothing tests the rules-adjacent logic, entitlement gating, moderation, or the chat state machine — the four areas where a bug is most costly.

**The highest-leverage test suite is `@firebase/rules-unit-testing` against the emulator.** It would have caught five of the six critical/high security findings, and the rules are already well-structured enough to make writing it fast.

### 10.2 No CI, minimal lints

There is no `.github/` directory and no workflow of any kind — nothing gates `analyze`, `test` or `build`.

`analysis_options.yaml` is five lines: `flutter_lints` plus three excludes. That is 11 Flutter rules. Not enabled: `prefer_const_constructors`, `prefer_final_locals`, `unawaited_futures`, `avoid_dynamic_calls`, `always_declare_return_types`. No `strict-casts`, `strict-raw-types` or `strict-inference`.

The current baseline, measured: **`flutter analyze` reports 267 issues, zero of them errors** — recurring `use_super_parameters`, `deprecated_member_use` (including `withOpacity` and `dialogBackgroundColor`), unused imports, and one `use_build_context_synchronously`.

The analyzer also surfaces a **latent build risk**: `provider` is imported in three files (`volunteer_signup_info/tabs/*.dart`) but is **not declared in `pubspec.yaml`**. It resolves today only as a transitive dependency of `stacked`. If `stacked` ever drops it, the build breaks with no local change.

Credit where due: there is **exactly one hand-written `// ignore:`** in the whole codebase. There is no lint-suppression debt — the lints are simply not asking for much.

### 10.3 Model deserialisation is fragile

Twelve hand-written models across **four different serialiser naming conventions** (`fromJson`/`toJson`, `fromFirestore`, `fromMap`/`toMap`, and a `withConverter` variant). Neither `freezed` nor `json_serializable` is used.

Concrete crash risks:
- `app_user.dart:79` — `UserRole.values.byName(data['role'] ?? 'user')` **throws `ArgumentError`** on any unexpected role string, taking down the whole auth stream. No `orElse`.
- `auth_service.dart:407` — `userData?['createdAt']?.toDate()` is an unchecked dynamic invocation; a legacy ISO `String` throws inside the auth listener.
- `volunteer_info_model.dart:64,66` — `as int?` **throws if Firestore returns a double**, which it will if the admin panel writes `1.0`. The line between them correctly uses `(… as num?)?.toDouble()`.
- `chat_request_model.dart`, `chat_room_model.dart`, `journal_model.dart` — bare `data()!` and unchecked casts on non-nullable `String` fields.

**Timestamps are inconsistent.** Most models use `Timestamp` correctly, but `mood_model.dart` stores `timestamp` as an **ISO string**, and four separate consumers re-parse it back to `DateTime`. Three wrap it in `try/catch` and silently skip; one **substitutes `DateTime.now()`**, which corrupts the streak calculation on a bad row.

**Only one model implements `==`/`hashCode`.** Every Firestore snapshot therefore produces "different" objects, so no rebuild can ever be short-circuited. `CommunityPost` and `ThreadReply` are additionally **mutable** so view models can mutate them in place for optimistic likes — mutable domain models written to from the UI layer.

Six serialisers are dead (zero call sites), and `ChatRoom` (43 lines) is entirely unused while two services hand-build the chat-room map twice, with different shapes.

### 10.4 Documentation

`docs/FIRESTORE_SCHEMA.md` (682 lines), `ADMIN_PANEL_BACKEND_REPORT.md`, `docs/BILLING_SETUP.md` and `docs/SECURITY_LOGS.md` are genuinely excellent — accurate, current and detailed.

`README.md` is **two lines of Flutter template** ("A new Flutter project."). It is the first thing a new engineer opens and it says nothing. There is no `CONTRIBUTING`, no architecture overview, no local-setup guide, and no emulator instructions.

---

## 11. Feature recommendations — improving what exists

### 11.1 A crisis layer — the highest-value gap in the product

Right now the app detects a crisis disclosure, routes it to a volunteer, and offers **the person in crisis nothing directly**. If no volunteer is online, or the user closes the app, there is no path forward.

| Feature | Detail |
|---|---|
| **Persistent "Get help now"** | A always-reachable entry point — a drawer item and a long-press on the app icon shortcut. Never gated, never behind a paywall. |
| **Pakistan helpline directory** | Curated, admin-editable via a `crisis_resources` collection following the existing `journal_prompts` pattern. One-tap dial via `url_launcher` (already a dependency). Umang, Rozan, and provincial services. |
| **In-context lifeline card** | When the moderation layer detects self-harm language, show the user a warm, non-alarming card offering the helpline and a breathing exercise — *without* blocking their message. This preserves the existing, correct carve-out and adds care to it. |
| **Safety plan builder** | A private, structured document: warning signs, coping strategies, people to contact, reasons for living. Stored under the user's own journal scope. Evidence-based and high-retention. |
| **Volunteer-unavailable fallback** | When no listener is online, offer Dodo, the helpline directory and a "notify me when someone's free" option instead of an empty list. |

This is consistent with the promise already on the paywall: *"Crisis support is always free, for everyone."*

### 11.2 Journal

- **Search and tags** — the journal is the app's memory and is currently unsearchable.
- **Mood ↔ journal correlation** — surface "you tend to write about work on your low days". The data for this already exists in both collections.
- **Offline-first drafts** — Hive is already a dependency and currently does almost nothing. Entries should never be lost to a dropped connection.
- **Biometric lock** — an opt-in gate on the journal tab specifically. Users share phones.
- **Export and backup** — PDF or plaintext export of one's own entries.
- **Voice-entry transcription** — the audio is already uploaded; transcription makes it searchable.

### 11.3 Mood

- **Denormalised streak** via Cloud Function (also fixes §5.5).
- **Weekly recap** — a gentle Sunday summary, the natural re-engagement moment.
- **Trigger tagging** — attach a lightweight cause to a mood entry, which makes the Insights screen far more actionable.
- **Reminder scheduling** driven by the user's own historical logging times rather than a fixed hour.

### 11.4 Volunteer chat

- **Typing indicators and read receipts** — `PresenceService` exists and its infrastructure is already built (once §3.3 is fixed).
- **Queue position** — "you're 2nd in line, roughly 6 minutes" beats an indefinite spinner.
- **Structured post-chat feedback** — the review flow exists; add optional structured tags to feed volunteer supervision.
- **Volunteer availability scheduler** — recurring shifts rather than a manual toggle.
- **Session continuity** — let a user request the same listener again.

### 11.5 Community

- **Cursor pagination** (fixes the quadratic read pattern in §5.2).
- **Likes as a subcollection** with a counter — the current in-document array is unbounded and will hit the 1 MiB document limit on a popular post.
- **Saved threads** and **follow-a-thread notifications**.
- **In-thread report and mute** — moderation exists server-side but the user-facing affordances are thin.

### 11.6 Dodo (AI companion)

- **Stop wiping history on launch** — either persist it properly or remove the dead load/save code. Right now the app does both.
- **Streaming responses** — a cold-start callable plus a US round-trip plus Groq latency currently produces a long silent wait.
- **Server-side safety classification before display** — the highest-risk surface in the app is the one where responses are generated rather than written by a human.
- **A clear "not a therapist" frame**, restated periodically rather than only at onboarding.

### 11.7 Sounds & Breathe

- **Background playback with lock-screen controls** (`audio_service`) — a sleep-sounds feature that stops when the screen locks is not usable for its main purpose.
- **Download for offline** — the signed-URL architecture already supports this cleanly.
- **Sleep timer** and **session tracking**.
- **More breathing patterns** (4-7-8, box breathing) with haptic guidance.

---

## 12. Feature recommendations — new capabilities

| Feature | Rationale |
|---|---|
| **Urdu localisation + RTL** | The single largest reach multiplier available. A Pakistan-first mental-health app that only speaks English reaches only English-comfortable urban users. Requires the i18n work in §8.5 first. |
| **Dark mode & accessibility pass** | Ships as one project with the design-system work. Serves the 2 a.m. use case this product is built around. |
| **Guided programs** | Multi-day, structured CBT-style courses (sleep, anxiety, self-esteem). The strongest premium lever available, and a far better fit for subscription pricing than per-feature caps. |
| **Home-screen widget + smart reminders** | Mood check-in from the home screen, timed to the user's own patterns. Widgets are the highest-retention surface on both platforms. |
| **Anonymous community mode** | Stigma is a real barrier to disclosure. Let users post under a stable pseudonym while moderation retains the real uid. |
| **Data export & account portability** | A completed `deleteMyAccount` plus export closes the GDPR/PDPB posture, and it is a trust signal in this category specifically. |
| **Volunteer supervision layer** | Shift scheduling, caseload caps, burnout check-ins, supervisor 1:1s. Peer-support programs fail on volunteer attrition more often than on user acquisition. |
| **Group sessions** | Scheduled, moderated topic circles — higher volunteer leverage than 1:1 and a natural premium tier. |

---

## 13. Prioritised roadmap

### Phase 1 — Stop the bleeding (1–2 weeks)

Small, high-impact, independently testable. Most are one-to-five-line changes.

| Task | Ref |
|---|---|
| Fix the six over-permissive Firestore rules; write the emulator test suite alongside | §4.1–4.6 |
| Add `obscureText` to the signup password; add a show/hide toggle | §3.1 |
| Remove the two unused LLM keys from `.env`; **rotate both** | §4.7 |
| Add the three missing fields to `_createAppUser` — or delete it and use `AppUser.fromJson` | §3.3 |
| Fix the progress-bar overflow with `Expanded` | §3.4 |
| Add iOS push entitlements and `UIBackgroundModes` | §3.2 |
| Register the FCM background handler at top level, unconditionally | §5.10 |
| Remove the 2-second splash delay; move Hive off the critical path | §5.10 |
| Enable R8/`shrinkResources`; strip the `AD_ID` permission; pin `targetSdk` | §4.9 |
| Add `.limit(50)` to the chat-message and reply streams | §5.2 |
| Move the daily whisper to a curated `journal_prompts`-style collection | §4.8 |
| Set up CI: `flutter analyze` + `flutter test` + a release build on every PR | §10.2 |

**Exit criteria:** the emulator rules suite passes, CI is green, and no secret ships in the binary.

### Phase 2 — Data flow & cost (3–4 weeks)

| Task | Ref |
|---|---|
| Cursor pagination everywhere; kill the remaining unbounded listeners | §5.2 |
| Hoist the three `build()`-constructed streams into cached fields | §5.3 |
| Make `VolunteerHomeView` tabs share one view model | §5.4 |
| Split `HomeViewModel`; denormalise `moodStreak` | §5.5 |
| Adopt `guard()` across the 13 services; replace the 22 `debugPrint` catches | §5.1, §5.6 |
| Fix the leaks: `SignupViewModel`, the two `AudioPlayer`s, the `build()` controllers | §5.7 |
| Pin functions to `asia-south1`; add `minInstances`/`maxInstances`; cache `getFreemiumLimits` | §5.8 |
| Rewrite `deleteMyAccount` as a resumable, paged job | §5.8 |
| Standardise on `Timestamp`; add `==`/`hashCode`; make models immutable | §10.3 |
| Add `connectivity_plus`, an offline banner and offline entitlement caching | §5.9 |
| Delete the dead code: `SessionService`, `ChatRoom`, template counters, 7 unused packages | §5.1, §6.10, §9.6 |

**Exit criteria:** measured Firestore reads per session drop materially; cold start under 1.5 s on a mid-range Android device.

### Phase 3 — Design system & performance (4–6 weeks)

The largest single refactor, and the one that makes every future UI change cheap.

| Task | Ref |
|---|---|
| Build real tokens: type scale, spacing (device-independent, correct axis), radii, elevation, semantic colour roles | §6.3–6.6 |
| Rebuild `ThemeData` on `ColorScheme.fromSeed` + `useMaterial3`; route the 393 font sizes and 279 radii through it | §6.1, §6.2 |
| Add `darkTheme` + `themeMode` | §6.7 |
| Fix fonts: add the `fonts:` block, set `allowRuntimeFetching = false` | §6.8 |
| Remove the nested sigma-200 blurs; keep real blur for one or two hero moments | §7.1 |
| Rebuild the journal list: real slivers, no `shrinkWrap`, `FadeTransition` not `Opacity`, no whole-list `AnimatedSwitcher` | §7.2 |
| Add `cached_network_image` with `cacheWidth`/`cacheHeight` | §7.3 |
| Compress the asset bundle; convert icons to vectors; exclude `.DS_Store` | §7.5 |
| Consolidate duplicates: one composer, one empty state, one card shell, one chip, one avatar | §9.5 |
| Replace the two Stacked template components | §9.6 |
| Wire `responsive_framework` or remove it; add a tablet breakpoint and max content width | §6.10 |

**Exit criteria:** `Theme.of(context)` is the dominant styling path; scroll holds 60 fps on a mid-range Android device.

### Phase 4 — Reach & depth (ongoing)

| Task | Ref |
|---|---|
| Full accessibility pass: semantics, 48 dp targets, text-scale support, contrast fixes | §8 |
| i18n infrastructure, then Urdu + RTL | §8.5 |
| Proper form architecture: `Form`, focus traversal, `autofillHints`, inline errors | §9.2, §9.3 |
| Error and empty states on all 30 screens; `RefreshIndicator` on every list | §9.1 |
| The crisis layer | §11.1 |
| Existing-feature upgrades | §11.2–11.7 |
| New capabilities, starting with guided programs | §12 |
| Meaningful test coverage: services, view models, entitlement, moderation | §10.1 |

---

## 14. Closing note

The instinct to read this as a long list of failures would be the wrong one. The security rules, the entitlement architecture, the premium-audio gate, the moderation safety carve-out and the comment quality are the work of someone who thought carefully about a product where mistakes hurt real people.

The recurring pattern in this review is not carelessness — it is **good primitives built and then not adopted**. `guard()`, `TtlCache`, `SkeletonList`, `PressScale`, `BusyButton`, `page_transitions`, `runBusyFuture`, the cursor-pagination helpers and the validators are all correct, and all under-used. The highest-leverage work is not writing new abstractions. It is finishing the adoption of the ones that already exist, and putting CI in place so the next good abstraction does not drift out of use the same way.

Two things deserve immediate attention regardless of roadmap sequencing: the exposed volunteer identity documents and mood history (§4.1, §4.2), because the data is sensitive and the fix is small; and the absent user-facing crisis layer (§11.1), because it is the one gap where the product's stated purpose and its actual behaviour diverge.
