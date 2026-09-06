# YOU — Firestore Database Schema

Reference for the **admin panel** engineer. Generated from a full audit of the Flutter client
(`lib/`), the Cloud Functions (`functions/`), the security rules (`firestore.rules`), and the
indexes (`firestore.indexes.json`). Firebase project: **`you-app-c6b1f`**.

---

## 0. Read this first — conventions & gotchas

- **Who can write what.** The Firebase **Admin SDK (Cloud Functions) bypasses all security
  rules.** Several collections/fields are **Admin‑SDK‑only** — the client (and therefore a
  client‑SDK admin panel) is *denied* by rules and must go through a Cloud Function. These are
  marked **🔒 ADMIN‑SDK ONLY** below. An admin panel using the **Admin SDK** (server side) can
  write anything; an admin panel using the **client SDK** signed in as an `admin` user is still
  bound by the rules.
- **Admin role.** `isAdmin()` in rules = the requester's own `users/{uid}.role == 'admin'`.
  Grant admin by setting that field (itself an admin/Admin‑SDK‑gated write).
- **No hard user deletes.** `users` has `allow delete: if false`. Deletion is either a
  **soft delete** (`status: 'deleted'`) or the full **`deleteMyAccount`** Cloud Function
  (removes Firestore + Storage + Auth). Don't hard‑delete user docs from the panel.
- **Mixed field casing (intentional — match exactly).** On `users/{uid}`: `subscriptionTier`
  is **camelCase**, but `subscription_expiry` and `subscription_source` are **snake_case**.
  Also `first_login_at`, `profileCompletedAt` (camelCase). The rules' owner‑write blocklist uses
  the literal keys `['subscriptionTier','subscription_expiry','subscription_source','welcomeChatsUsed']`.
- **Timezone.** All server period keys are **Asia/Karachi (PKT, UTC+5, no DST)**. Day key
  `YYYY-MM-DD`, month key `YYYY-MM`.
- **Timestamps.** `serverTimestamp()` unless noted. A few docs store an ISO‑8601 **string**
  instead (called out where it happens — `volunteer_info.createdAt`, some `mood.timestamp`).
- **Document ID schemes** (summary): `users`,`volunteer_info` → Auth **UID**; `chats` →
  **sorted participant join** `uidA_uidB`; `volunteer_blocks` → **`userId_volunteerId`**;
  `usage` → feature key; `journal_prompts` → `YYYY-MM-DD`; `daily_analytics` → `YYYY-MM-DD` (PKT);
  `app_settings` → fixed names; everything else → **auto‑ID**.

**Legend:** 🔒 = Admin‑SDK‑only write · 👤 = client‑writable (per rules) · 🛠️ = admin‑only (rules)
· `ST` = serverTimestamp · `inc` = FieldValue.increment · `arr±` = arrayUnion/arrayRemove.

---

## 1. `users/{uid}` 👤/🔒 mixed
Doc ID = Firebase Auth UID. Core profile for **all roles** (user, volunteer, admin).
**Access:** get = owner or admin · list/query = any signed‑in · create = owner or admin ·
update = admin, OR owner *except* the 🔒 entitlement fields · **delete = never** (`if false`).

| Field | Type | Meaning | Writer |
|---|---|---|---|
| `uid` | String | Mirror of Auth UID | client (signup) |
| `email` | String | Account email | client |
| `firstName` / `lastName` | String? | Name (null for a fresh volunteer until profile step) | client |
| `role` | String | `'user'` \| `'volunteer'` \| `'admin'` | client(signup) / admin (`updateUserRole`) |
| `username` | String (lowercased) | Distinct handle (users) | client |
| `phoneNumber` | String | E.164 phone (volunteers verified) | client |
| `dateOfBirth` | Timestamp | Birth date | client |
| `gender` | String | `'male'`/`'female'`/`'other'`/`'prefer not to say'` | client |
| `profilePictureUrl` | String | Cloud Storage download URL | client |
| `emailVerified` | bool | Mirror of Auth flag (admins seeded true) | client |
| `phoneVerified` | bool | Volunteer phone verified | client |
| `status` | String | Lifecycle — see **§14** (`active`,`profile_incomplete`,`pending_verification`,`verified`,`deleted`) | client / admin |
| `availabilityStatus` | String | `'online'` \| `'offline'` (volunteer presence) | client |
| `permissions` | List\<String> | Admin caps: `manage_users`,`manage_content`,`view_analytics` | admin |
| `joinedCommunities` | List\<String> (arr±) | Community IDs joined | client (`joinCommunity`) |
| `fcmToken` | String / delete | Push token; `FieldValue.delete()` on sign‑out | client |
| **`subscriptionTier`** | String | 🔒 `'free'` \| `'premium'` | **`applyEntitlement`** |
| **`subscription_expiry`** | Timestamp? | 🔒 expiry; `null` = indefinite | **`applyEntitlement`** |
| **`subscription_source`** | String? | 🔒 `'google_play'`,`'admin'`,`'promo'`… (`'admin'` never auto‑revoked) | **`applyEntitlement`** |
| **`welcomeChatsUsed`** | int | 🔒 lifetime free volunteer‑chat slots used | **`requestVolunteerChat`** (+1), refund triggers (−1) |
| `first_login_at` | ST (snake) | Anchors “days since login” gate | client (`MonetizationService`) |
| `profileCompletedAt` | ST | User finished onboarding | client |
| `createdAt` / `lastLogin` / `lastStatusChange` | ST | Timestamps | client |
| `createdBy` | String | Admin UID who created this admin | admin |
| `updatedAt`/`updatedBy`, `verifiedAt`/`verifiedBy`, `deletedAt`/`deletedBy` | ST/String | Admin action audit (role change / verify / soft‑delete) | admin |

**Server reads:** `fcmToken` (push), `role`, `status`, `createdAt` (analytics counts), subscription fields (`isUserPremium`).

### 1a. `users/{uid}/notifications/{autoId}` 👤 create / owner rest
In‑app notification feed. **Access:** create = any signed‑in (so one user can notify another →
fires FCM) · read/update/delete = owner.

| Field | Type | Meaning |
|---|---|---|
| `title` / `body` | String | Headline / body (body may be a message preview) |
| `type` | String | `new_message`,`request_accepted`,`request_received`,`chat_request`,`new_reply`,`new_mention`,`broadcast` |
| `isRead` | bool | Read flag (batch‑flipped true) |
| `createdAt` | ST | Creation |
| `data` | Map | Deep‑link payload, e.g. `{chatId, route}`, `{requestId, route}`, `{postId, route}` |

Writers: client (`chat_service`, `chat_request_service`) **and** functions (`onReplyCreated`,
`handleMentions`, `requestVolunteerChat`). FCM dispatch: `onNotificationCreated` trigger.

### 1b. `users/{uid}/journal/{autoId}` 👤 owner‑only (admins CANNOT read — privacy)
`JournalEntry`. **Access:** read/write = owner only. Admins are explicitly denied.

| Field | Type | Meaning |
|---|---|---|
| `userId` | String | Owner |
| `title` / `content` | String | Entry |
| `label` | String | `'personal'` \| `'work'` |
| `type` | String | `'text'` \| `'voice'` (legacy docs may omit) |
| `audioUrl` | String | Voice audio URL (voice only) |
| `audioDurationMs` | int | Voice length (voice only) |
| `timestamp` | ST | Creation |

### 1c. `users/{uid}/usage/{feature}` 🔒 write / owner read
Freemium counters. Doc ID = `dodo` \| `community_threads` \| `community_replies`.
**Access:** read = owner · **write = false** (Admin‑SDK only).

| Field | Type | Meaning |
|---|---|---|
| `date` | String `YYYY-MM-DD` | PKT day key (`usage/dodo`) |
| `month` | String `YYYY-MM` | PKT month key (community counters) |
| `count` | int | Uses in the current period (resets when key rolls over) |

Writers: `sendDodoMessage` (dodo), `reserveMonthlyQuota` via `createCommunityPost`/`createCommunityReply`.
Premium users are never counted.

---

## 2. `chats/{chatId}` 👤 participants only (admin read‑only)
Doc ID = **`uidA_uidB`** (two UIDs sorted, joined by `_`).
**Access:** read = participant **or admin** (life‑safety review) · create/update/delete = participant.
**Admins can read but not write.**

| Field | Type | Meaning | Writer |
|---|---|---|---|
| `status` | String | `'active'` \| `'completed'` | client / `expireStaleChats` |
| `participants` | List\<String> | The two UIDs | client |
| `participantInfo` | Map\<uid,{name,avatarUrl}> | Denormalised names/avatars | client |
| `participantsActivity` | Map\<uid,bool> | Live in‑chat presence | client |
| `requestId` | String | Source `chat_requests` doc | client |
| `createdAt` | ST | Chat creation = acceptance time | client |
| `lastMessage` | Map `{text,senderId,timestamp}`? | Latest‑message preview | client |
| `endedBy` | String | `'user'`\|`'volunteer'`\|`'system'`\|`'admin'` | client / `expireStaleChats`(`system`) |
| `endedAt` | ST | End/expiry time | client / `expireStaleChats` |

**24h auto‑expiry:** `expireStaleChats` (hourly) flips active chats older than 24h to `completed`
(`endedBy:'system'`) and marks the matching request `completed`.

### 2a. `chats/{chatId}/messages/{autoId}` 👤 participants (admin read‑only)
`ChatMessage`. Ordered by `timestamp desc`.

| Field | Type | Meaning |
|---|---|---|
| `senderId` | String | Sender UID |
| `text` | String | Body (raw; recipient client blurs PII at render; server flags via `moderateChatMessage`) |
| `timestamp` | ST | Send time |

---

## 3. `chat_requests/{autoId}` 🔒 create / party read+update+delete
**Creation is Admin‑SDK‑only** (`requestVolunteerChat` — enforces the free welcome‑chat cap).
**Access:** create = **false** · read/update/delete = the requester or the volunteer party.

| Field | Type | Meaning | Writer |
|---|---|---|---|
| `requesterId` / `requesterName` / `requesterAvatarUrl` | String / String / String? | Requesting user | `requestVolunteerChat` |
| `volunteerId` | String | Target volunteer | `requestVolunteerChat` |
| `volunteerName` | String? | Stamped on accept | client (`acceptRequest`) |
| `status` | String | `pending`→`accepted`\|`declined`\|`completed` | server + client |
| `topic` | String? | Optional topic | `requestVolunteerChat` |
| `createdAt` | ST | Request time | `requestVolunteerChat` |
| `acceptedAt` | ST | Accept time (anchors 24h expiry) | client (`acceptRequest`) |
| `endedAt` | ST | End/expiry (gates the review prompt) | client / `expireStaleChats` |
| `userReviewed` | bool | Requester resolved the post‑chat review | client |
| `isPriority` | bool | `true` for premium requesters | `requestVolunteerChat` |
| `charged` | bool | Consumed a free welcome slot (drives refunds) | `requestVolunteerChat`; cleared by refund triggers |

**Lifecycle triggers:** `onChatRequestDeclined` / `onChatRequestDeleted` refund a `welcomeChatsUsed`
slot when a still‑`charged` pending request is declined/cancelled (accepted requests stay charged).

---

## 4. Community

### 4a. `communities/{communityId}` 🛠️ admin CRUD / 👤 join
Admin‑authored. **Access:** read = signed‑in · create/delete = admin · update = admin **or** any
signed‑in user changing **only** `membersCount` (join/leave).

| Field | Type | Meaning |
|---|---|---|
| `name` | String | Community name |
| `membersCount` | int (inc) | Member count (client increments on join) |
| `isLocked` | bool | Lock flag (streamed) |
| `allowedGenders` | List\<String> | Gender restriction (supersedes legacy name‑map) |

Subcollection `communities/{id}/messages/{msgId}` exists in rules (community group chat: `senderId`
must equal caller; author/admin edit‑delete) — currently the primary community surface is `posts`.

### 4b. `posts/{postId}` 🔒 create / author+admin edit / 👤 like
Top‑level. **Creation Admin‑SDK‑only** (`createCommunityPost` — monthly cap + free‑user mention
stripping). **Access:** read = signed‑in · create = **false** · update = author, admin, **or** an
`isOwnLikeToggle()` (toggle only your own `likedBy`/`likeCount`, ±1) · delete = author or admin.

| Field | Type | Meaning | Writer |
|---|---|---|---|
| `communityId` | String | Parent community | `createCommunityPost` |
| `authorId` | String | Author UID | `createCommunityPost` |
| `authorUsername` | String | Author handle (default `'Anonymous'`) | `createCommunityPost` |
| `content` | String | Body | `createCommunityPost` |
| `createdAt` | ST | Creation | `createCommunityPost` |
| `likeCount` | int (inc) | Likes | client like‑toggle (init 0 server) |
| `likedBy` | List\<String> (arr±) | UIDs who liked | client like‑toggle |
| `replyCount` | int (inc) | Replies | `createCommunityReply` (init 0) |
| `mentionedUsers` | List\<String> | @‑mentions (empty for free users) | `createCommunityPost` |
| `moderation` | Map `{flagged,categories,masked}` | Set when server flags content | `moderatePost` |

### 4c. `posts/{postId}/replies/{replyId}` 🔒 create / 👤 like
**Creation Admin‑SDK‑only** (`createCommunityReply`). Same access shape as posts.

| Field | Type | Meaning |
|---|---|---|
| `postId` | String | Parent post |
| `authorId` / `authorUsername` | String | Author |
| `content` | String | Body |
| `createdAt` | ST | Creation |
| `likeCount` (inc) / `likedBy` (arr±) | int / List | Likes (client‑toggled) |
| `mentionedUsers` | List\<String> | @‑mentions |
| `moderation` | Map | `{flagged,categories,masked}` (`moderateReply`) |

---

## 5. `mood/{autoId}` 👤 owner
**Access:** read = signed‑in · create/update/delete = owner (`userId == auth.uid`).

| Field | Type | Meaning |
|---|---|---|
| `userId` | String | Owner |
| `moodLabel` | String | One of 9 (`Energized`…`Angry`); emoji derived client‑side |
| `timestamp` | ST *or ISO String* | Log time (reader tolerates both) |
| `extraField` | dynamic? | Freeform extra payload |

---

## 6. `volunteer_info/{uid}` 👤 owner + rating carve‑out
Doc ID = volunteer UID. **Access:** read = signed‑in · create = owner/admin · update = owner,
admin, **or** the review‑transaction touching only `['averageRating','totalReviews','completedChats']`
· delete = never.

| Field | Type | Meaning |
|---|---|---|
| `uid` | String | Volunteer UID |
| `idCardUrl` / `idCardBackUrl` | String? | Gov‑ID card front/back (Storage URL) |
| `studentIdUrl` / `studentIdBackUrl` | String? | Student‑ID front/back (Storage URL) |
| `currentLevelOfStudy` | String? | Study level |
| `institutionName` | String? | Institution |
| `graduationYear` | String? | Grad year (stored as **String**) |
| `tags` | List\<String>? | Specialty tags (drives the listener filter) |
| `agreementAccepted` | bool | Accepted volunteer agreement |
| `status` | String | `'pending_verification'` \| `'approved'` — **note:** distinct from `users.status` (see §14) |
| `createdAt` | ST **or ISO String** | Application time (writer uses ST; model serialises ISO) |
| `completedChats` | int | Completed chats (bumped with each review) |
| `averageRating` | double | Mean star rating |
| `totalReviews` | int | Review count |

### 6a. `volunteer_info/{uid}/reviews/{autoId}` 👤 create (own uid) / admin edit
**Access:** read = signed‑in · create = signed‑in with `userId == auth.uid` · update/delete = admin.

| Field | Type | Meaning |
|---|---|---|
| `userId` | String | Reviewer UID |
| `rating` | double | Stars |
| `comment` | String | Text |
| `createdAt` | ST | Review time |

Written in the `addReviewAndCompleteChat` transaction (also bumps the parent aggregates and flips the
source request's `userReviewed`).

---

## 7. `escalations/{autoId}` 🛠️ admin triage / 👤 create
Unified crisis feed (supervisor dashboard listens for `status == 'open'`).
**Access:** create = signed‑in · read/update = admin · delete = never.

| Field | Type | Meaning |
|---|---|---|
| `type` | String | `'volunteer'` \| `'moderation'` |
| `chatId` | String | Related chat (always for volunteer; optional for moderation) |
| `userId` / `userName` | String | Subject user |
| `volunteerId` / `volunteerName` | String | Escalating volunteer (volunteer type) |
| `reason` | String? | Reason |
| `severity` | String | `'critical'` (volunteer default) \| `'high'` (moderation default) |
| `status` | String | `'open'` (client sets); admin resolves (`resolved`) |
| `createdAt` | ST | Creation |

---

## 8. `moderation_flags/{autoId}` 🛠️ admin queue
Admin review queue. **Client** writes only *blocked‑before‑delivery* attempts; **server** writes
*delivered* content it flags. **Access:** read/update/delete = admin · create = admin **or**
signed‑in with `senderId == auth.uid` AND `action == 'blocked'`.

| Field | Type | Meaning |
|---|---|---|
| `source` | String | `'chat'` \| `'post'` \| `'reply'` |
| `senderId` | String | Author of flagged content |
| `text` | String | Offending text (raw) |
| `categories` | List\<String> | `hate`,`violence`,`sexual`,`romance`,`offTopic`,`pii`,`banned` |
| `severity` | String | `'severe'` \| `'pii'` \| `'moderate'` |
| `action` | String | `'blocked'` (client) \| `'flagged'` (server) |
| `delivered` | bool | `false` = client‑blocked · `true` = server‑flagged after delivery |
| `status` | String | `'open'` (client) \| `'open'` (server) — review state |
| `createdAt` | ST | Flag time |
| *chat:* `chatId`,`messageId`,`recipientId` · *post:* `postId`,`communityId` · *reply:* `postId`,`replyId` | String | Source‑specific refs |

---

## 9. `volunteer_blocks/{userId}_{volunteerId}` 🛠️ admin write / owner read
Admin‑created, time‑boxed block hiding a volunteer from a user. Doc ID = **`userId_volunteerId`**.
**Access:** write = admin · read = admin or the owning user (`userId == auth.uid`).

| Field | Type | Meaning |
|---|---|---|
| `userId` | String | Blocked user |
| `volunteerId` | String | Volunteer hidden from them |
| `expiresAt` | Timestamp | Block expiry (must be future to apply) |
| `createdAt` | Timestamp | Creation |
| `reason` | String? | Optional reason |
| `createdBy` | String | Admin UID |

---

## 10. `incident_reports/{autoId}` 🛠️ admin, immutable
Clinical paper trail. **Access:** read/create = admin · update/delete = **never**. No app code
writes these — created by the admin panel/console. Field shape is admin‑defined (immutable once filed).

## 11. `broadcasts/{autoId}` 🛠️ admin, immutable
Admin push‑broadcast audit log. **Access:** read/create = admin · update/delete = **never**.
Admin‑panel‑owned (drives the `broadcast` notification type). Field shape admin‑defined.

## 12. `daily_analytics/{YYYY-MM-DD}` 🔒 write / admin read
Dashboard rollup. Doc ID = **PKT day key**. **Access:** read = admin · **write = false** (written by
`aggregateForDay` via Admin SDK).

| Field | Type | Meaning |
|---|---|---|
| `totalUsers` | int | All users |
| `totalVolunteers` | int | `role == volunteer` |
| `activeVolunteers` | int | volunteer & `status == active` |
| `pendingVolunteers` | int | volunteer & `status == pending_verification` |
| `newUsers` | int | users `createdAt` within the PKT day |
| `postsToday` | int | posts `createdAt` within the PKT day |
| `updatedAt` | ST | Rollup write time |

Written by scheduled `aggregateDailyAnalytics` (05:00 PKT, yesterday's doc) and the admin‑only
callable `runDailyAnalyticsNow` (today's doc).

## 13. `security_logs/{autoId}` 🔒 fully server‑owned
IP + timestamp safety trail. **Access:** read/write = **false for everyone** (even admins) — written
only by Admin SDK, read via console/Admin SDK. No GPS, no message content.

| Field | Type | Meaning |
|---|---|---|
| `uid` | String | Acting user |
| `role` | String | Role at action time |
| `ip` | String | Server‑captured client IP |
| `action` | String | `signup`,`signin`,`message_sent`,`report_filed`,`chat_created` |
| `retainForCase` | bool | Pins against retention cleanup |
| `timestamp` | ST | Event time |

Retention: `cleanupSecurityLogs` (00:30 PKT) deletes older than `security_log_retention_days`
(default 90) except `retainForCase == true`. Admin callable `flagUserLogsForCase` pins/unpins.

---

## 14. Enums & conventional string values

- **`users.role`** — `user` \| `volunteer` \| `admin`. (Admin power keys off the literal `'admin'`.)
- **`users.status`** — `active`, `profile_incomplete` (volunteer, pre‑profile), `pending_verification`
  (volunteer, awaiting admin approval), `verified`, `deleted` (soft delete).
  ⚠️ **Inconsistency to know:** admin `verifyVolunteer` sets `users.status`, and the app's
  pending screen redirects when it becomes `active`, while the admin‑verify path/comments also use
  `verified` — confirm the exact "approved volunteer" value in the panel and standardise. Meanwhile
  **`volunteer_info.status`** uses its own values (`pending_verification` \| `approved`). Two separate
  status fields; don't conflate.
- **`users.availabilityStatus`** — `online` \| `offline`.
- **`users.subscriptionTier`** — `free` \| `premium`. Premium is authoritative only when written by
  the backend; `isPremium = tier == 'premium' && (expiry == null || expiry > now)`.
- **`users.permissions`** — `manage_users`, `manage_content`, `view_analytics` (null ⇒ admin has all).
- **`chat_requests.status`** — `pending` \| `accepted` \| `declined` \| `completed`.
- **`chats.status`** — `active` \| `completed`; **`chats.endedBy`** — `user`\|`volunteer`\|`system`\|`admin`.
- **notification `type`** — `new_message`,`request_accepted`,`request_received`,`chat_request`,
  `new_reply`,`new_mention`,`broadcast`.
- **escalation `type`** — `volunteer`\|`moderation`; **`severity`** — `critical`\|`high`; **`status`** — `open`\|`resolved`.
- **moderation `categories`** — `hate`,`violence`,`sexual`,`romance`,`offTopic`,`pii`,`banned`;
  **`severity`** — `severe`\|`pii`\|`moderate`.

---

## 15. Config docs (`app_settings/*`) — 🛠️ admin write, signed‑in read
Fixed doc IDs. The admin panel will likely edit these.

**`app_settings/global_config`** (freemium + toggles; all fail‑open to code defaults):
| Key | Type | Default | Used by |
|---|---|---|---|
| `is_subscription_required` | bool | false | client gate |
| `dodo_daily_cap` | int | 10 | client + server (Dodo daily cap) |
| `welcome_chats` | int | 3 | server (free volunteer chats, lifetime) |
| `journal_history_days` | int | (const) | client (free journal window) |
| `mood_window_days` | int | (const) | client (free mood window) |
| `community_threads_monthly` | int | 5 | server (monthly thread cap) |
| `community_replies_monthly` | int | 30 | server (monthly reply cap) |
| `security_log_retention_days` | int | 90 | server (log retention) |

**`app_settings/moderation_config`** — `enabled` (bool), `bannedKeywords` (List\<String>). Live‑listened
by the client at startup. *(Server moderation currently uses hard‑coded lists; this doc drives the
client engine.)*

**`app_settings/home_announcement`** — `active` (bool), `message` (String). Home banner (null unless active).

**`journal_prompts/{YYYY-MM-DD}`** 🛠️ admin write, signed‑in read — `active` (bool), `text` (String).
"Prompt of the day"; doc ID is the device‑local date.

---

## 16. Composite indexes (already provisioned — query patterns available)
From `firestore.indexes.json` (all `COLLECTION` scope):

| collectionGroup | Fields | Enables |
|---|---|---|
| `users` | role, status, availabilityStatus | online + active volunteers (match list) |
| `users` | role, createdAt | admin: users of a role by signup date |
| `users` | role, status, createdAt | admin: e.g. pending volunteers oldest‑first |
| `chats` | status, createdAt↑ | admin: chats by status (active/expired queue) |
| `chat_requests` | status, volunteerId, createdAt↓ | requests by status then volunteer |
| `chat_requests` | volunteerId, status, createdAt↓ | a volunteer's inbox by status |
| `chat_requests` | volunteerId, createdAt↓ | a volunteer's request history |
| `chat_requests` | requesterId, createdAt↓ | a requester's sent history |
| `chat_requests` | requesterId, volunteerId, status | detect existing pair request |
| `posts` | communityId, likeCount↓, createdAt↓ | top posts in a community |
| `posts` | communityId, createdAt↓ | community feed (newest) |
| `replies` | postId, createdAt↑ | thread replies (oldest‑first) |
| `mood` | userId, timestamp↓ | user mood history |
| `moderation_flags` | status, createdAt↓ | moderation review queue |
| `volunteer_blocks` | userId, expiresAt↑ | a user's active blocks |
| `journal_prompts` | `__name__`↓ | prompts newest‑first |

**Not pre‑indexed** (single‑field only — new composite queries need new indexes): `escalations`,
`incident_reports`, `broadcasts`, `daily_analytics`, `security_logs`, `communities`, `volunteer_info`,
`reviews`, `notifications`, `usage`, `journal`. Also **no collection‑group indexes** (e.g. cross‑post
`replies` queries aren't provisioned).

---

## 17. Admin‑panel cheat‑sheet

- **Must go through Cloud Functions (client SDK is denied):** granting/revoking premium
  (`subscriptionTier`/`subscription_expiry`/`subscription_source`), `welcomeChatsUsed`,
  `usage/*` counters, creating `chat_requests`/`posts`/`replies`, `daily_analytics`, `security_logs`.
  If the panel runs on a **server with the Admin SDK**, it can write these directly (Admin SDK
  bypasses rules) — that's the recommended way to build admin mutations.
- **Safe client‑SDK admin reads/writes (as an `admin` user):** `users` (except entitlement fields),
  `communities` CRUD, `posts`/`replies` moderation delete, `escalations` read/resolve,
  `moderation_flags` triage, `volunteer_blocks` write, `incident_reports`/`broadcasts` create,
  `app_settings/*` + `journal_prompts` edit, `daily_analytics` read.
- **Never** hard‑delete `users` (rules forbid). Use soft delete (`status:'deleted'`) or `deleteMyAccount`.
- **Volunteer approval** flips the volunteer from `pending_verification` → **`'active'`** (see §18).
- **Cloud Storage (not Firestore) — for showing ID cards etc.** Per‑user uploads live under
  `<folder>/<uid>/…` in bucket `you-app-c6b1f.firebasestorage.app`, folders: `user_profiles`,
  `journal_audio`, `volunteer_profiles`, `volunteer_id_cards`, `volunteer_id_cards_back`,
  `volunteer_student_ids`, `volunteer_student_ids_back`. (URLs are also denormalised onto the docs.)

---

## 18. ⚠️ Admin‑panel sync — contract changes (2026‑07‑12)

Everything below is **live in the app now**. Read it before wiring the panel's buttons.

### 18.1 `users` — what the panel owns vs what the owner owns
Rules now **deny the owner** any write to: `role`, `permissions`, `subscriptionTier`,
`subscription_expiry`, `subscription_source`, `welcomeChatsUsed`, `statusReason`,
`statusChangedBy`, `lastStatusChange`.
(Before this, **any user could self‑assign `role:'admin'`** — the panel's whole permission model
rested on a field the user could write. Fixed.)

`status` is special: the owner may still set it, but **only** `active` / `profile_incomplete` /
`pending_verification`, and **only if their current status is not** `suspended` / `banned` /
`deleted`. So a suspended user cannot write their way back to `active`.

**Suspend / ban (panel):** set `status: 'suspended' | 'banned'` (+ optional **`statusReason`**,
shown verbatim to the user; + `statusChangedBy`, `lastStatusChange`). The app enforces it:
a signed‑in user is **signed out mid‑session** (chat doc listener) with a dialog carrying
`statusReason`, and sign‑in is rejected up front. Un‑suspend = set `status: 'active'`.

**Field rename:** the app's online/offline toggle now writes **`lastAvailabilityChange`**
(it used to write `lastStatusChange` and would have trampled your account‑status audit trail).

### 18.2 Volunteer status — canonical values
| meaning | `users.status` |
|---|---|
| application submitted, awaiting review | `pending_verification` |
| **approved — can accept chats, visible in discovery** | **`active`** |
| **deactivated by admin** (approved, but hidden + cannot accept) | **`verified`** |

⚠️ **Deployment ordering.** Volunteers approved by the *old* app wrote `'verified'` for "approved" —
the exact value that now means "deactivated". Run the admin‑only callable
**`migrateVolunteerStatus`** (idempotent; flips `role=='volunteer' && status=='verified'` → `'active'`)
**BEFORE** the panel starts writing `'verified'` to deactivate anyone, or the migration will silently
re‑activate them.

### 18.3 `chats.escalated` — the panel must clear it
`EscalationService` now also stamps **`escalated: true`** + `escalatedAt` on `chats/{chatId}`
whenever it creates an `escalations` doc. Reason: `escalations` is admin‑read‑only, so participants
can't query it — the app reads this mirrored flag to refuse deleting a chat that's under review.
**When you resolve an escalation, set `escalated: false` on its `chatId`**, otherwise the user can
never delete that chat. (Advisory guard only — server retention is the real guarantee.)

### 18.4 Admin on chats: **end‑chat only**
Admins may now **update** `chats/{chatId}` — set `status:'completed'`, `endedBy:'admin'`,
`endedReason`, `endedAt`; the app already renders *"This chat was ended by a moderator."*
Admins **cannot** write or delete `messages` (deliberate: transcripts stay tamper‑evident).

### 18.5 `app_settings/moderation_config` — both shapes work
Per‑category (preferred): `hate[]`, `violence[]`, `sexual[]`, `romance[]`, `offTopic[]`,
`contactIntent[]`, `version`, `enabled`. Legacy `bannedKeywords[]` still works and is treated as a
**severe** list. The **Cloud Functions now read this doc too** (5‑min cache) — previously your edits
only reached the client while the authoritative server pass used hard‑coded lists.
🚨 **Invariant: never add self‑harm phrases to any list.** Blocking them would silence users in crisis;
those phrases route to support, they are not moderated.

### 18.6 Other server‑side changes
- `createCommunityPost` / `createCommunityReply` now reject with `failed-precondition` when the
  community has **`isLocked: true`** (the client already blocked it; this closes the forged‑client hole).
- `daily_analytics/{day}` gained **`premiumUsers`**, **`newPremium`**, **`churnedPremium`** — all
  **numbers**, not strings. `newPremium`/`churnedPremium` are a *delta vs the previous day's*
  `premiumUsers` (a point‑in‑time count can't yield true cohort flow) — treat them as approximations.
- New composite index: `escalations` (`status` ASC, `createdAt` DESC) — your live feed
  (`where status=='open' orderBy createdAt desc`) **would have failed without it**.
- **Severe** auto‑moderation blocks now raise escalations (was: `violence` only; now also `banned`,
  `hate`, `sexual`). Expect more volume in the `open` feed.

### 18.7 Cloud Storage now has rules (`storage.rules`)
Previously **no rules file existed** in the repo. Uploads: owner‑only under `<prefix>/{uid}/…`.
Reads: `journal_audio` is **owner‑only — admins cannot read journals** (privacy, deliberate);
ID/student‑ID cards are **owner‑or‑admin** read; **`community_covers/{communityId}/{file}`** is
public‑read / **admin‑write** (that's where the panel uploads `cover_photo`).
⚠️ Firebase **download URLs carry an access token and bypass read rules** — any URL already handed out
stays readable.

---

## 19. `sounds/{soundId}` 🛠️ admin CRUD / signed‑in read — **Soothing Sounds**

The app's Soothing Sounds screen used to be a hardcoded list of 3 tracks shipped inside the APK.
It is now **fully admin‑managed**: this collection is the source of truth, and both the cover image
and the audio file live in Cloud Storage. Adding a sound in the panel makes it appear in every user's
app **live, with no app update**.

**Access:** read = any signed‑in user · create/update/delete = **admin only**.

| Key | Type | Req | Meaning |
|---|---|---|---|
| `title` | String | ✅ | e.g. "Nature Resonance" |
| `subtitle` | String | ✅ | short line under the title, e.g. "Ambient Water" |
| `cover_photo` | String | ✅ | **Download URL** (`getDownloadURL()`) of the image in `sound_covers/{soundId}/…` |
| `audio_path` | String | ✅ | **Storage OBJECT PATH** of the audio, e.g. `sound_audio/{soundId}/calm.mp3` |
| `is_premium` | bool | ✅ | `false` = free for everyone · `true` = YOU+ only |
| `active` | bool | ✅ | `false` hides it from the app without deleting it |
| `order` | int | ✅ | ascending sort position in the list (0, 1, 2, …) |
| `duration_ms` | int | — | optional; lets the card show a length before playback |
| `createdAt` / `updatedAt` | Timestamp | — | audit |
| `createdBy` | String | — | admin uid |

### 19.1 🚨 `cover_photo` is a URL. `audio_path` is a PATH. They are not the same thing.

This is the one mistake that will break the feature, so it's worth being blunt about:

- **`cover_photo`** → call `getDownloadURL()` after uploading and store the resulting
  `https://firebasestorage.googleapis.com/…` string. The app renders it directly.
- **`audio_path`** → store the **object path you uploaded to** (`sound_audio/<id>/<file>.mp3`).
  **Do NOT call `getDownloadURL()` for the audio and do NOT store a URL here.** The app passes this
  string to a Cloud Function, which resolves it to a signed URL. A URL in this field makes the sound
  unplayable for every user.

**Why the asymmetry?** Storage rules **deny all client reads on `sound_audio/**`**. A sound's doc is
world‑readable (it must be, to render the list), so `audio_path` is public knowledge — but the path
isn't the file. To actually play a sound the app calls **`getSoundAudioUrl({soundId})`**, which checks
`is_premium` against the caller's entitlement server‑side and returns a **1‑hour signed URL**. That's
what makes the premium lock real: a free user cannot obtain a premium sound's audio, no matter what
they read out of Firestore. (Covers are public — an image is not worth gating.)

### 19.2 CRUD flow for the panel

**Create** — order matters, because the Storage paths are keyed by the doc id:
1. `addDoc(collection('sounds'), {...})` **first**, to get the `soundId`.
2. Upload the cover to `sound_covers/{soundId}/<filename>` → `getDownloadURL()`.
3. Upload the audio to `sound_audio/{soundId}/<filename>` → keep the **path**.
4. `updateDoc` with `cover_photo` (the URL) + `audio_path` (the path).

A doc that exists without `audio_path` is simply **skipped by the app** (not shown as a broken card),
so the window between steps 1 and 4 is safe.

**Update** — re‑uploading a file to the same path replaces it. Note the app caches audio on disk keyed
by `soundId`, so a user who already played a sound keeps the **old** audio until they clear the app's
data. If you need to force a re‑download, upload under a **new filename** and update `audio_path`.

**Delete** — just delete the doc. An `onSoundDeleted` Cloud Function purges
`sound_covers/{soundId}/` and `sound_audio/{soundId}/` for you, so the panel does **not** need to
clean Storage itself (audio files are large; orphans cost real money).

**Hide instead of delete** — set `active: false`. The app only queries `active == true`.

### 19.3 Upload constraints (enforced by `storage.rules` — a violating upload is rejected)

| Prefix | Read | Write | Limits |
|---|---|---|---|
| `sound_covers/{soundId}/{file}` | **public** | admin | `image/*`, **< 5 MB** |
| `sound_audio/{soundId}/{file}` | **denied to all clients** | admin | `audio/*`, **< 30 MB** |

### 19.4 Index

The app queries `where('active','==',true).orderBy('order')`, backed by the composite index
`sounds`: `active` ASC + `order` ASC (already in `firestore.indexes.json`).

### 19.5 Seeded data

The 3 original sounds are seeded by `scripts/seed_sounds.js` with the fixed ids `nature-resonance`,
`calm-mindfulness`, `deep-focus` (`order` 0/1/2, `is_premium: false`). Sounds created in the panel get
auto‑ids — nothing depends on the id shape.

---

## 20. Volunteer presence + content deletion (latest changes)

### 20.1 `users/{uid}.lastSeen` — new field (volunteers)

| Key | Type | Written by | Meaning |
|---|---|---|---|
| `lastSeen` | Timestamp | the app (every ~5 min while alive) | last time the volunteer's app was running |
| `availabilityStatus` | String | the volunteer's toggle (+ sign-out, + the sweep if enabled) | `'online'` \| `'offline'` — **the only thing that decides discovery** |
| `lastAvailabilityChange` | Timestamp | same | when the toggle last flipped |
| `availabilityEndedBy` | String | `sweepStalePresence` only | `'presence_sweep'` when the server switched them off |

**The panel should build a "dormant volunteers" view.** This is the whole point of `lastSeen`:
a volunteer marked `availabilityStatus: 'online'` whose `lastSeen` is days old has almost certainly
forgotten they're listed. Users are being sent to them and getting no reply. Surface them
(`online AND lastSeen < now - 24h`, sorted oldest-first) so a human can nudge or switch them off.

That human judgement **is the intended fix at the current volunteer count.** Automatic expiry is
built but deliberately OFF — see below.

⚠️ Volunteers who have never run the new build have **no `lastSeen` at all**. Treat a missing
`lastSeen` as "unknown", not "dormant" — do not show them as stale.

### 20.2 `global_config.presence_expiry_enabled` — a switch you own

| Key | Type | Default | Effect |
|---|---|---|---|
| `presence_expiry_enabled` | bool | **`false`** | when `true`, `sweepStalePresence` switches dormant volunteers (`online` + `lastSeen` older than 6 h) to `offline` automatically |

**It is off on purpose, and that is a product decision.** With a small volunteer pool, auto-expiring
anyone who hasn't opened the app would empty the listeners list — and a user who opens the app and
finds NO listeners has no path to help at all. That is a worse failure than reaching a listener who
replies slowly. Turn it on when the pool is large enough to afford being strict.

**Before flipping it, read the logs.** While disabled, the sweep still runs every 30 minutes and
**logs exactly which volunteers it *would* have expired** — so you can see the real blast radius
before committing. Flipping the flag needs **no app release**: the sweep writes `availabilityStatus`,
which is the field the app's discovery query already reads.

### 20.3 Chat requests are now refused to offline volunteers

`requestVolunteerChat` re-checks the volunteer's toggle inside its transaction and throws
`failed-precondition` if they've gone offline between the list rendering and the user tapping. No
panel change — just be aware that a `chat_requests` doc can no longer be created against an offline
volunteer, so a gap in requests may simply mean nobody was online.

### 20.4 Users can now delete their own threads and replies

Authors can delete their own `posts/{postId}` and `posts/{postId}/replies/{replyId}` from the app
(the rules already allowed it; the app now exposes it).

**Two things the panel must know:**

1. **`replyCount` is now maintained on delete.** A new `onReplyDeleted` trigger decrements
   `posts/{postId}.replyCount` whenever a reply is removed — **including replies the PANEL deletes
   via the Admin SDK.** Previously the count was only ever incremented, so any reply deletion (yours
   or the author's) silently corrupted it. **Do not decrement it yourself** — you would double-count.
2. **Deleting a post still cascades** its replies via `onPostDeleted`. Unchanged, but note each
   cascaded reply now also fires `onReplyDeleted`, which no-ops safely because the parent is gone.

⚠️ Known gap, not yet handled: deleting a post/reply does **not** clean up the notifications that
referenced it (`users/{uid}/notifications/*` with `{postId, route: 'thread_detail'}`). Tapping such a
notification lands on a dead thread. `moderation_flags` are deliberately **kept** — audit trail.
