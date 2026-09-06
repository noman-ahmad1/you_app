# Prompt for the admin panel's Claude Code session

Copy everything below the line into the admin panel repo's Claude Code.

---

The **You** mobile app repo has just landed a security change to `firestore.rules`
that requires a coordinated update here. One part is a **breaking read-path change**
for the admin panel: volunteer identity documents have moved.

Please work through the tasks below. Read the relevant code first and tell me what
you find before changing anything — some of this depends on how the panel is
currently structured, which I'd rather you verify than assume.

## Background — why this changed

`volunteer_info/{uid}` is readable by **every signed-in user of the mobile app**,
because the volunteer-discovery UI needs each volunteer's tags, institution and
rating. That same document also held four fields:

- `idCardUrl`
- `idCardBackUrl`
- `studentIdUrl`
- `studentIdBackUrl`

Those are Firebase Storage **download URLs with an embedded access token**. Holding
the URL is equivalent to holding the file. The Storage rules restrict those prefixes
to owner + admin, but download URLs bypass Storage rules entirely — so any ordinary
app user could read every volunteer's national ID and student ID images. For a
mental-health app whose volunteers are often students, that is the most serious
exposure in the codebase.

## Task 1 — read vetting documents from their new location (breaking)

Those four fields have moved to a private subcollection:

```
volunteer_info/{uid}/private/vetting
```

Same field names, plus a `migratedAt` server timestamp. The public
`volunteer_info/{uid}` document no longer contains them.

The new rule is:

```
match /volunteer_info/{volunteerId} {
  allow read: if isSignedIn();          // public half — unchanged

  match /private/{docId} {
    allow read, write: if isOwner(volunteerId) || isAdmin();
  }
}
```

The panel authenticates as a `role: 'admin'` user, so it retains full access — it
just needs to read one level deeper. Please:

1. Find every place the panel reads those four fields (volunteer review/verification
   screens, most likely, and possibly an export or audit view).
2. Change them to read `volunteer_info/{uid}/private/vetting`.
3. Handle the document being **absent**. Volunteers who applied before this change
   have not been migrated until Task 2 runs, and any volunteer who somehow has no
   vetting docs should render an explicit empty state rather than a blank image or a
   crash.
4. If the panel ever *writes* these URLs, write them to the subcollection too.

Do not work around this by copying the URLs back onto the public document. That
would reopen the exposure.

## Task 2 — run the data migration

The app repo added an idempotent, admin-only callable:

```
migrateVettingDocs()   // region: us-central1 (default)
```

It scans `volunteer_info`, moves any of the four fields into
`{uid}/private/vetting`, and deletes them from the public document. Returns
`{ ok: true, migrated: <n>, scanned: <n> }`. Running it twice is safe — already
migrated documents are skipped.

Please add a way to invoke it from the panel — a maintenance/admin-tools screen is
fine, or a one-off script if that fits the codebase better. Show the returned counts.

**Sequencing matters.** Run the migration *before* the new `firestore.rules` are
deployed, and deploy the panel's Task 1 change at the same time as the rules. If the
rules land first, the panel reads an empty path; if the panel change lands first, it
reads a subcollection that is not populated yet.

## Task 3 — revoke the leaked Storage tokens

The migration **moves** the URLs. It does not invalidate them. Every download URL
previously readable from the public document still works for anyone who captured it.

Please help me revoke the access tokens on all existing objects under these Storage
prefixes, which regenerates the token and breaks previously issued links:

```
volunteer_id_cards/**
volunteer_id_cards_back/**
volunteer_student_ids/**
volunteer_student_ids_back/**
```

Then update the stored URLs in `private/vetting` to the newly issued ones. Propose an
approach first (an Admin SDK script is probably right) and tell me the blast radius
before running anything — this invalidates links the panel itself may have cached.

Consider whether the panel should stop storing long-lived download URLs altogether
and instead mint short-lived **signed URLs** on demand. The app already does exactly
this for premium audio via the `getSoundAudioUrl` callable, so there is a proven
pattern in the codebase to copy.

## Task 4 — new `whispers` collection

The app's home screen shows a daily "whisper". It used to fetch this live from
`zenquotes.io` — an unreviewed third-party endpoint feeding text straight to users in
a mental-health context. It now reads an admin-authored collection instead:

```
whispers/{YYYY-MM-DD}
  text:   string   // the whisper shown on the home screen
  active: boolean  // false or missing => app falls back to its bundled default
```

Rules: `read: if isSignedIn()`, `write: if isAdmin()`.

The date key is **Asia/Karachi (UTC+5, no DST)**, not the browser's local date.
`journal_prompts/{YYYY-MM-DD}` already uses this exact convention and the panel very
likely already has an editor for it — please mirror that implementation rather than
inventing a second pattern, including how it computes the PKT date key.

## Task 5 — confirm nothing else in the panel broke

Other rules tightened in the same change. The panel should be unaffected because
every one of these keeps an `isAdmin()` branch, but please verify against the actual
code rather than trusting this list:

| Collection | What changed | Panel impact |
|---|---|---|
| `users` | `list` now requires `isAdmin()` or a query constrained to `role == 'volunteer'` | None — admins may still list everything |
| `mood` | `read` is now owner-scoped, `\|\| isAdmin()` | None |
| `users/{uid}/notifications` | `create` now needs self, admin, or a shared chat/request | None |
| `chats/{id}` | participants can no longer alter `participants` or clear `escalated`; escalated chats cannot be deleted | None — admin branch unchanged |
| `chats/{id}/messages` | now **create-only for everyone**, admins included | Only if the panel edits or deletes messages — it should not; transcripts are escalation evidence |
| `escalations` | `create` requires the caller be a named party | None — admins read and update |
| `volunteer_info` | non-admin aggregate writes bounded to ±1 | None — admin branch unchanged |
| `communities` | non-admin `membersCount` bounded to ±1 | None |

If the panel does anything that now fails, tell me — do **not** loosen the rules to
accommodate it. The mobile repo has an emulator test suite
(`firestore-tests/`, 52 assertions) that will catch a regression, and ten of those
assertions specifically pin the admin panel's access paths.

## Please also

- Point out anywhere the panel reads user PII it does not actually need to display.
- Flag any place it holds a long-lived Storage download URL for a sensitive document,
  beyond the four fields above.

If anything here contradicts what you find in the code, trust the code and tell me.
