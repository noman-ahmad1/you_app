# "You" App — Backend Reference for the Angular Admin Panel

> Hand this to the Claude working on the **Angular admin panel**. It documents the existing Firebase backend of the "You" mental-health / peer-support mobile app (built in Flutter) so the admin panel can be built against the **same Firestore database, Auth, Storage, and Cloud Functions**. The admin panel does NOT share code with the Flutter app — everything it needs is below.

---

## 1. Platform & stack

- **Backend:** Firebase — **Authentication** (email/password, Google, phone OTP), **Cloud Firestore** (primary DB), **Cloud Storage** (images), **Cloud Messaging/FCM** (push), **Cloud Functions** (Node, `firebase-functions/v2`), **Firebase Analytics + Crashlytics**.
- Use the **same Firebase project** as the mobile app (same `google-services`/web config). For Angular, use the **Firebase JS SDK v9+ (modular)** or AngularFire.
- Firestore security is enforced by `firestore.rules` in the mobile repo; admin actions require an **admin-role** account (see §3). Make sure the rules allow admin reads/writes for the collections the panel touches.

App domain in one line: regular **users** track mood/journal, chat with an AI bot ("Dodo"), post in **communities**, and request 1-on-1 chats with **volunteers**. **Volunteers** apply, get **approved by an admin**, then take chat requests. Admins manage everything.

---

## 2. Firestore collections at a glance

| Path | Type | Purpose |
|---|---|---|
| `users/{uid}` | doc | Core account for every user/volunteer/admin. `uid` = Firebase Auth UID. |
| `users/{uid}/notifications/{id}` | subcol | In-app notifications; **writing one triggers an FCM push** (Cloud Function). |
| `users/{uid}/journal/{id}` | subcol | Private journal entries (**sensitive content**). |
| `volunteer_info/{uid}` | doc | Volunteer application + verification docs + stats. Doc ID **== user uid**. |
| `volunteer_info/{uid}/reviews/{id}` | subcol | Reviews left for a volunteer after a chat. |
| `mood/{id}` | col | Mood log entries (top-level, filtered by `userId`). |
| `chat_requests/{id}` | col | User→volunteer chat requests. |
| `chats/{chatId}` | doc | 1-on-1 chat room. `chatId` = the two UIDs **sorted** and joined with `_`. |
| `chats/{chatId}/messages/{id}` | subcol | Messages (**sensitive content**). |
| `communities/{communityId}` | col | Community/forum definitions. |
| `posts/{id}` | col | Community posts (has `communityId`). |
| `posts/{postId}/replies/{id}` | subcol | Replies to a post. |
| `app_settings/global_config` | doc | Global feature flags (subscription gate). |

All `createdAt`/`timestamp` fields are Firestore **Timestamp** objects written with `serverTimestamp()`. In JS read them with `.toDate()`.

---

## 3. Auth & admin access model

- Admin logs in with **email/password** (Firebase Auth). Their `users/{uid}` doc must have `role: "admin"`.
- **Roles** live in `users/{uid}.role`: `"user"`, `"volunteer"`, `"admin"`.
- **Granular admin permissions** in `users/{uid}.permissions` (array of strings): `"manage_users"`, `"manage_content"`, `"view_analytics"`. Gate panel sections on these.
- **First admin must be seeded manually** (there is no public admin signup). Create the Auth user in the Firebase console, then create/edit its `users/{uid}` doc with `role: "admin"` and the permissions array. The mobile app's `createAdminUser` lets an existing admin create more admins (writes a `users` doc with `role: "admin"`, `emailVerified: true`, `permissions`, `createdBy`).
- The admin panel should **verify `role == "admin"`** after login before showing anything.

---

## 4. Collection schemas (exact field names & types)

### 4.1 `users/{uid}`
| Field | Type | Notes |
|---|---|---|
| `uid` | string | == doc id / Auth UID |
| `email` | string | |
| `firstName`, `lastName` | string | may be empty for new volunteers |
| `role` | string | `"user"` \| `"volunteer"` \| `"admin"` |
| `status` | string | lifecycle — see §5. Values seen: `"active"`, `"profile_incomplete"`, `"pending_verification"`, `"verified"`, `"deleted"` |
| `availabilityStatus` | string | `"online"` \| `"offline"` (volunteer toggles in-app) |
| `emailVerified` | bool | |
| `phoneVerified` | bool | volunteers verify phone via OTP |
| `phoneNumber` | string? | |
| `gender` | string? | `"Male"` \| `"Female"` \| `"Other"` \| `"Prefer not to say"` |
| `dateOfBirth` | Timestamp? | |
| `username` | string? | unique for users |
| `profilePictureUrl` | string? | Storage URL |
| `permissions` | array<string>? | admin only |
| `fcmToken` | string? | for push; deleted on sign-out |
| `joinedCommunities` | array<string> | community IDs the user joined |
| `createdAt` | Timestamp | |
| `lastLogin` | Timestamp | updated on each login |
| `first_login_at` | Timestamp | set once by the monetization tracker (note: snake_case) |
| admin audit fields | — | `verifiedAt`, `verifiedBy`, `deletedAt`, `deletedBy`, `updatedAt`, `updatedBy`, `createdBy`, `lastStatusChange` (written by admin/volunteer actions) |

### 4.2 `volunteer_info/{uid}` (doc id == user uid)
| Field | Type | Notes |
|---|---|---|
| `uid` | string | |
| `idCardUrl`, `idCardBackUrl` | string | Storage URLs (gov ID) |
| `studentIdUrl`, `studentIdBackUrl` | string | Storage URLs (student ID) |
| `currentLevelOfStudy` | string? | |
| `institutionName` | string? | |
| `graduationYear` | string? | |
| `tags` | array<string> | volunteer's support topics/specialties |
| `agreementAccepted` | bool | |
| `status` | string | set to `"pending_verification"` on submit (see §5 caveat) |
| `createdAt` | Timestamp | |
| `completedChats` | int | stat |
| `averageRating` | double | stat (0.0 if none) |
| `totalReviews` | int | stat |

**`volunteer_info/{uid}/reviews/{id}`:** `{ userId: string, rating: double, comment: string, createdAt: Timestamp }`. Adding a review runs in a transaction that also recomputes `averageRating`, `totalReviews`, `completedChats` on the parent doc.

### 4.3 `mood/{id}` (top-level)
| Field | Type | Notes |
|---|---|---|
| `userId` | string | owner |
| `moodLabel` | string | one of: `Energized, Joyful, Blessed, Happy, Neutral, Sad, Restless, Anxious, Angry` |
| `timestamp` | Timestamp | server time |
| `extraField` | any? | optional/nullable; **may contain sensitive notes — treat as private** |

(The app derives an emoji asset + `dateOnly` from `moodLabel`/`timestamp` at read time; those are **not stored**.)

### 4.4 `users/{uid}/journal/{id}` — **sensitive**
`{ userId: string, title: string, content: string, label: "personal"|"work", timestamp: Timestamp }`. Do **not** surface journal `title`/`content` in admin analytics or moderation UIs (mental-health privacy). At most show counts.

### 4.5 `chat_requests/{id}`
| Field | Type | Notes |
|---|---|---|
| `requesterId` | string | the user asking |
| `requesterName` | string | |
| `requesterAvatarUrl` | string? | |
| `volunteerId` | string | target volunteer |
| `status` | string | `"pending"` → `"accepted"` \| `"declined"` \| `"completed"` |
| `createdAt` | Timestamp | |
| `topic` | string? | |

### 4.6 `chats/{chatId}` (chatId = sorted uids joined by `_`)
`{ status: "active"|"completed", participants: array<uid>, participantInfo: { <uid>: {name, avatarUrl} }, createdAt: Timestamp, lastMessage: {text, senderId, timestamp} | null, participantsActivity: { <uid>: bool } }`.
**`chats/{chatId}/messages/{id}`:** `{ senderId: string, text: string, timestamp: Timestamp }` — **sensitive content; don't expose in admin UI.**

### 4.7 `posts/{id}` and `posts/{postId}/replies/{id}`
Post: `{ communityId, authorId, authorUsername, content, createdAt, likeCount:int, replyCount:int, mentionedUsers:array, likedBy:array<uid> }`.
Reply: `{ postId, authorId, authorUsername, content, createdAt, mentionedUsers:array, likedBy:array<uid>, likeCount:int }`.
These are the surfaces for **content moderation** (delete post/reply, etc.).

### 4.8 `communities/{communityId}`
Fields read by the app: `name` (string), `description` (string), `membersCount` (int), `imageAsset` (string, a bundled asset name — used as fallback), `cover_photo` (string URL — **note snake_case**, unlike other fields). `postsToday` is referenced but currently unused. **There is no in-app create/edit of communities** — they are seeded/managed externally, so **community CRUD is a natural admin-panel feature**. The mobile app only `increment`s `membersCount` when a user joins.
⚠️ The app does **gender-restricted visibility by community _name_** (client-side): `Women's Emotional Wellness` & `New Mothers Support` → Female; `Men's Mental Health` → Male; `Beyond Binary Support` → Other/Prefer-not-to-say; everything else → everyone. If the admin panel renames/creates these, keep names consistent or the mobile filter breaks. (Consider adding an explicit `allowedGenders` array field and updating the app later.)

### 4.9 `app_settings/global_config`
`{ is_subscription_required: bool }` (snake_case). Drives the app's subscription gate. Admin panel can toggle this. The app also reads `users/{uid}.first_login_at` to compute account age for trials.

### 4.10 `users/{uid}/notifications/{id}` — push channel
`{ title: string, body: string, type: string, isRead: bool, createdAt: Timestamp, data: { route?: string, requestId?: string, chatId?: string } }`.
`type` values in use: `"request_received"`, `"request_accepted"`, `"new_message"`. **Creating a doc here automatically sends an FCM push** to that user (Cloud Function `onNotificationCreated`). This is how the admin panel should notify a volunteer (e.g. on approval) — just write a notification doc; don't call FCM directly.

---

## 5. Volunteer approval lifecycle (the core admin workflow)

Status transitions on `users/{uid}.status`:
1. **Volunteer signs up** (email+password after phone OTP) → `role: "volunteer"`, `status: "profile_incomplete"`, `phoneVerified: true`, `emailVerified: false`.
2. **Volunteer completes profile** (uploads ID/student cards, picks tags, accepts agreement) → app updates `users/{uid}` (`firstName, lastName, dateOfBirth, gender, profilePictureUrl`, `status: "pending_verification"`) **and** creates `volunteer_info/{uid}` with `status: "pending_verification"`.
3. **Admin reviews & approves** → the mobile app's existing `verifyVolunteer` sets on `users/{uid}`: `status: "verified"`, `verifiedAt: serverTimestamp`, `verifiedBy: <adminUid>`.

**To list pending volunteers** for the approval queue, query:
`users where role == "volunteer" and status == "pending_verification"` (join each with its `volunteer_info/{uid}` doc to show the uploaded ID images, institution, tags, etc.).

**Approval action the panel should perform:** update `users/{uid}` → `{ status: "verified", verifiedAt: serverTimestamp(), verifiedBy: <adminUid> }`. For a rejection, define a convention (e.g. `status: "rejected"` + a `rejectionReason` field) — the app doesn't have one yet, so coordinate the value. Optionally also set `volunteer_info/{uid}.status` to match, and **write a notification doc** (§4.10) so the volunteer gets a push.

> ⚠️ **Known inconsistency to flag/decide with the product owner:** the user-facing "available volunteers" list queries `users where role=="volunteer" AND status=="active" AND availabilityStatus=="online"` — i.e. it looks for `status == "active"`, but approval sets `status == "verified"`. As written, a freshly **verified** volunteer would **not** appear to users until `status` becomes `"active"`. Meanwhile login/auth treats `status == "verified"` as "approved, allowed into the volunteer home." Decide on ONE canonical "approved & live" value (recommend making approval set `status: "active"`, or changing the app's discovery query to `"verified"`). The admin panel's approve action should write whatever value the app ends up querying. Document this with whoever owns the mobile app before shipping.

---

## 6. Other admin operations (exact writes)

- **User management** (`manage_users`): list/search `users`. Change role → update `users/{uid}.role` (+ `updatedAt`, `updatedBy`). Soft-delete → set `status: "deleted"` (+ `deletedAt`, `deletedBy`) — the mobile app uses soft-delete, not hard delete, for admin removals. (Full hard-delete of a user + all their data is only done by the user themselves in-app.)
- **Content moderation** (`manage_content`): browse `posts` / `posts/{id}/replies`, delete offending docs. Remember `replyCount`/`likeCount` are denormalized counters on the parent.
- **Communities CRUD**: create/edit/delete `communities/{id}` docs (fields in §4.8). This is admin-only territory since the app can't create them.
- **Monetization** (`view_analytics`/owner): toggle `app_settings/global_config.is_subscription_required`.
- **Reviews / volunteer quality**: read `volunteer_info/{uid}` stats (`averageRating`, `completedChats`, `totalReviews`) and the `reviews` subcollection.

---

## 7. Cloud Functions already deployed (don't duplicate)

Defined in `functions/index.js` (Node, v2). The admin panel can rely on these:
- `onNotificationCreated` — on create of `users/{uid}/notifications/{id}` → sends an FCM push to that user's `fcmToken`. **Use this to notify users/volunteers** by writing a notification doc.
- `cleanupChatroom` — on delete of `chats/{chatId}` → cleans up related data (messages, etc.).
- `onReplyCreated` — on new reply → notifies the post author.
- `onPostMention` / `onReplyMention` — handle `@mention` notifications using the `mentionedUsers` arrays.

---

## 8. Analytics — how to show it in the admin panel

**Important:** product analytics are sent to **Firebase Analytics (GA4)**, **not stored in Firestore**. The admin panel cannot read events from Firestore. Options to surface analytics:
1. **Embed** Firebase/GA4 dashboards, or link out to them (fastest).
2. **GA4 Data API** (`google-analytics-data`) from an Angular backend/Cloud Function to pull metrics into custom charts.
3. **BigQuery export** (enable GA4→BigQuery linking) and query aggregates — best for custom/admin reporting.
4. If you need live counters *in Firestore* (e.g. "posts today"), add Cloud Functions that increment aggregate docs — not currently implemented.

**Event names emitted by the app** (all parameters are metadata only — **no journal/mood/chat text is ever sent**), useful to know what's queryable in GA4/BigQuery:
`sign_up`(method, role), `login`(method), `logout`, `account_deleted`(role), `phone_otp_sent`, `phone_verified`, `journal_created`/`journal_updated`(label), `journal_deleted`, `mood_logged`(mood_label), `chatbot_message_sent`, `chatbot_response`(latency_ms), `community_post_created`(community_id), `community_reply_created`(post_id), `community_joined`(community_id), `community_post_like`(liked), `chat_request_sent`/`chat_request_accepted`/`chat_request_declined`, `chat_message_sent`, `chat_ended`, `subscription_gate`(required, days_since_login), `onboarding_completed`(tour), plus automatic `screen_view`.
**User properties** for segmentation: `role`, `gender`, `account_status`. **Crashlytics** captures crashes + handled non-fatal errors.

---

## 9. Composite indexes (Firestore)

Existing composite indexes (from `firestore.indexes.json`):
- `posts`: (`communityId` ASC, `likeCount` DESC, `createdAt` DESC) and (`communityId` ASC, `createdAt` DESC)
- `replies`: (`postId` ASC, `createdAt` ASC)
- `users`: (`role` ASC, `status` ASC, `availabilityStatus` ASC)
- `chat_requests`: (`volunteerId` ASC, `status` ASC, `createdAt` DESC), (`volunteerId` ASC, `createdAt` DESC), (`requesterId` ASC, `createdAt` DESC), (`requesterId` ASC, `volunteerId` ASC, `status` ASC)
- `mood`: (`userId` ASC, `timestamp` DESC)

**Admin panel queries will likely need NEW indexes**, e.g.:
- pending volunteers: `users` (`role` ASC, `status` ASC) — add it.
- moderation feeds, "all moods ordered by time", "all users ordered by createdAt", etc. — Firestore will print the exact "create index" link the first time each query runs; add them to `firestore.indexes.json` and deploy (`firebase deploy --only firestore:indexes`).
- For large admin lists, **paginate** with `orderBy` + `startAfter` cursors (the mobile app already has `getUsersPage` / `getMoodEntriesPageForAdmin` patterns: order by a stable field, `limit`, pass the last doc as the next cursor).

---

## 10. Gotchas & conventions

- **Privacy first (mental-health app):** never display or log journal content, mood `extraField`, or chat message text in the admin panel. Show counts/metadata only.
- **Field naming is mostly camelCase**, but a few are **snake_case**: `cover_photo` (communities), `is_subscription_required` and `first_login_at`. Match exactly.
- **`chatId` is deterministic:** `[uidA, uidB]..sort()` then `join('_')`. Useful to locate a chat for two users.
- **Counters are denormalized** (`likeCount`, `replyCount`, `membersCount`): if you delete posts/replies in moderation, decide whether to fix parent counters.
- **Soft vs hard delete:** admin user-removal = `status: "deleted"` (soft). The doc still exists.
- **Volunteer status mismatch** (`verified` vs `active`) — see §5; resolve before launch.
- **Timestamps:** write with the server timestamp sentinel; read with `.toDate()`.
- **Auth UID == `users` doc id == `volunteer_info` doc id.** Join on it.

---

## 11. Content moderation, flags & volunteer blocks (safety features)

The app now runs keyword + regex moderation on community posts/replies and 1-on-1 chat messages, blurs shared contact info (phone/social/email/URL), and writes records for the admin panel. **Cloud Functions** (`moderateChatMessage`, `moderatePost`, `moderateReply`, all in `asia-south1`) re-check delivered content authoritatively; the client writes a flag only for content it **blocked** before sending. `onPostDeleted` cascade-deletes a thread's `replies` when a post is removed.

### 11.1 `moderation_flags/{id}` — admin review queue
| Field | Type | Notes |
|---|---|---|
| `source` | string | `"chat"` \| `"post"` \| `"reply"` |
| `chatId?`/`messageId?` | string | when `source=="chat"` |
| `postId?`/`replyId?`/`communityId?` | string | when `source` is post/reply |
| `senderId` | string | author of the offending content |
| `recipientId?` | string | chat only (the other participant) |
| `text` | string | full original content (**admin-only**, sensitive) |
| `categories` | array<string> | any of `hate, violence, sexual, romance, offTopic, pii` |
| `severity` | string | `"severe"` (hate/violence/sexual) \| `"pii"` \| `"moderate"` |
| `action` | string | `"flagged"` (delivered) \| `"blocked"` (client stopped it) |
| `delivered` | bool | false for blocked attempts |
| `status` | string | `"open"` → set `"resolved"` when handled |
| `createdAt` | Timestamp | |
| `resolvedBy?`/`resolvedAt?` | — | set by admin on resolve |

Review queue query: `moderation_flags where status=="open" orderBy createdAt desc` (composite index already deployed). Resolve: set `status:"resolved"`, `resolvedBy`, `resolvedAt`.

Flagged content docs (messages/posts/replies) also gain a `moderation` map `{ flagged:true, categories:[], masked:bool }` so the app can show an "under review" state.

### 11.2 `volunteer_blocks/{userId}_{volunteerId}` — time-boxed block
Hide a specific volunteer from a specific user for a period. **Deterministic doc id** `${userId}_${volunteerId}`.
| Field | Type | Notes |
|---|---|---|
| `userId` | string | the user who won't see the volunteer |
| `volunteerId` | string | the blocked volunteer |
| `createdAt` | Timestamp | |
| `expiresAt` | Timestamp | block is active while `expiresAt > now` (e.g. now + 1 month) |
| `reason?` | string | optional admin note |
| `createdBy` | string | admin uid |

The app enforces this: blocked volunteers are excluded from the user's discovery list and new chat requests to them are refused, automatically expiring when `expiresAt` passes (index `userId` + `expiresAt` deployed). The admin panel only **creates** these.

### 11.3 Admin actions the Angular panel performs
1. **Review queue** — list/open `moderation_flags` (§11.1); open the related chat/thread.
2. **End chat immediately** — set `chats/{chatId}.status="completed"`, add `endedBy:"admin"` (+ optional `endedReason`). The app navigates both participants out with a "ended by a moderator" message.
3. **Block volunteer for a user (≥1 month)** — create `volunteer_blocks/{userId}_{volunteerId}` with `expiresAt = now + 1 month`, `createdBy = adminUid`.
4. **Delete a community thread** — delete `posts/{postId}`; the `onPostDeleted` function removes its replies.
5. **Resolve a flag** — set `status:"resolved"`, `resolvedBy/At`.
6. *(Optional)* **Tune keyword lists** without an app release — write `app_settings/moderation_config` (`{ hate:[], violence:[], sexual:[], romance:[], offTopic:[], contactIntent:[], version }`); the app + functions merge it over their bundled defaults.

### 11.4 Security-rules note
`firestore.rules` was extended (admin-only `moderation_flags`/`volunteer_blocks`/`app_settings`, plus an `isAdmin()` helper) but **NOT deployed** — the committed rules file is incomplete (it lacks rules for `users`/`chats`/`mood`/etc.), so deploying it as-is would lock the app out. Reconcile the full ruleset before any `firebase deploy --only firestore:rules`.

### ⚠️ Safety caveat (read before tuning)
Keyword matching is blunt. Critically, **self-harm / suicidal expressions are NOT moderation violations** — they are crisis disclosures that must reach a volunteer, never be blocked. The `violence` list is scoped to threats toward *others*; do not add self-referential phrases. Consider a separate, supportive crisis-detection flow later (and/or upgrade detection to an AI scorer behind the same interface).

---

### TL;DR for the admin panel
Build an Angular app on the **same Firebase project**, authenticate admins (`role=="admin"`), and primarily: (1) **approve volunteers** (`users` where `role=="volunteer"` & `status=="pending_verification"`, show their `volunteer_info` + ID images, then set the approved status + notify them via a `notifications` doc), (2) **manage users** (role/status), (3) **moderate** `posts`/`replies` via the `moderation_flags` queue (§11), (4) **end chats** / **block a volunteer for a user** / **delete threads**, (5) **CRUD communities**, (6) **toggle** `app_settings/global_config`, and (7) **show analytics** via GA4 Data API / BigQuery (not Firestore). Mind the privacy rules and the `verified`/`active` status decision.
