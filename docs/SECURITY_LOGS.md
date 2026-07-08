# Security logs (abuse-accountability metadata)

A minimal, **disclosed** evidentiary trail so that IF a misconduct report is filed
(harassment, threats, grooming, predatory behavior), an admin can identify the actor and,
on a lawful request, cooperate with authorities. This is **safety/security metadata — NOT
analytics and NOT surveillance.**

## ⚠️ Required before shipping (manual, legal — on you)

**The app's PRIVACY POLICY must disclose that IP addresses + timestamps are collected for
safety/abuse-prevention, stored separately from analytics, retained ~90 days, and shared only
on a lawful request.** This code does not update the policy; that disclosure is your
responsibility and is a hard prerequisite for shipping.

## What is collected
One document per logged event in the isolated top-level collection **`security_logs`**:

| field | value |
|---|---|
| `uid` | the acting user |
| `role` | `'user'` \| `'volunteer'` (\| `'admin'`) at time of action |
| `ip` | **server-captured** source IP (never sent by the client) |
| `action` | `'signup'` \| `'signin'` \| `'chat_created'` \| `'message_sent'` \| `'report_filed'` |
| `timestamp` | server Timestamp |
| `retainForCase` | bool, default `false` |

**NOT collected:** GPS / device location (none, ever), message content, or any other personal
data. This never enters Firebase Analytics.

## What is NOT logged
Only the events above. No per-screen, per-read, mood, journal, or community-post logging —
enough to identify an actor in an incident, not a movement log.

## Where the IP comes from (authoritative)
The IP is read **server-side** from the request edge metadata
(`x-forwarded-for` → `rawRequest.ip`) inside Cloud Functions — never trusted from the client.
- `chat_created` is captured inside the existing `requestVolunteerChat` callable.
- `signup`, `signin`, `message_sent`, `report_filed` are captured by the generic
  **`logSecurityEvent`** callable, which the client invokes fire-and-forget at those points.
  The client sends only the coarse `action` label; uid/IP/role/timestamp are server-authoritative.

Client call sites: `auth_service.dart` (signup/signin), `chat_service.dart` (message_sent),
`escalation_service.dart` (report_filed) — all via the isolated `SecurityLogService`
(`lib/services/security_log_service.dart`), which never touches `AnalyticsService`.

## Access (admin-only)
Firestore rules deny **all** client read/write to `security_logs` (users, volunteers, and
admins alike): `match /security_logs/{docId} { allow read, write: if false; }`. Only the Admin
SDK (Cloud Functions) writes it. **Admins read it via the Firebase console / Admin SDK** during
an incident — there is no in-app UI and no client read path.

## Retention (nothing kept forever)
Scheduled function **`cleanupSecurityLogs`** (daily, 00:30 Asia/Karachi) deletes docs older than
`app_settings/global_config.security_log_retention_days` (**default 90**, fail-safe if unset/invalid),
**except** docs with `retainForCase: true`.

### Preserving logs for an open case
Admin-only callable **`flagUserLogsForCase({ uid, retain })`** sets `retainForCase` on every log
for a user (checks caller role `admin` server-side). Call with `retain: true` when a case opens to
exempt those logs from retention cleanup; `retain: false` to release them.

## Deploy
`firebase deploy --only functions,firestore:rules`. Optionally seed
`app_settings/global_config.security_log_retention_days`; otherwise 90 days is used.

## Guarantees (invariants)
- No GPS/location anywhere; no location permission or geolocation dependency.
- IP captured server-side only; the client never sends an IP.
- Isolated from analytics (separate collection, separate service).
- No client (user or volunteer) can ever read or write these logs, including their own.
- Crisis/escalation logic is unchanged — a log is only appended after an escalation succeeds.
