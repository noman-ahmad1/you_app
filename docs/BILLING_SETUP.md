# YOU+ Billing Setup (RevenueCat + Google Play)

This is the manual configuration required to make the in-app YOU+ subscription work.
The code is already wired; these are the dashboard/console steps + secrets you must do.

Entitlement flow: **app purchase → RevenueCat → our Cloud Function → Firestore**. The client
never writes entitlement; the app unlocks solely from the `users/{uid}` doc, which only the
backend (Admin SDK) writes. The manual/admin grant path (`subscription_source: "admin"`) keeps
working and is never downgraded by a store event.

## 1. Google Play Console
1. Create the app's Play Console entry (or use the existing one) and complete the Payments
   profile for Pakistan (PKR).
2. Create **two auto-renewing subscription products** (each with a base plan):
   - Product ID `you_plus_monthly` — monthly base plan, price **PKR 300**.
   - Product ID `you_plus_yearly` — yearly base plan (e.g. PKR 3,000).
   - These IDs must match `lib/services/billing/billing_ids.dart`.
3. Add **License testers** (Play Console → Setup → License testing) so you can make
   test purchases without being charged.
4. Upload at least an internal-testing build (Play Billing requires the app to be on a track).

## 2. RevenueCat dashboard
1. Create a project and add the **Google Play** app; upload the Play service-account
   credentials (Play Console → API access) so RevenueCat can validate receipts.
2. Create an **Entitlement** with identifier **`you_plus`** (must match `BillingIds.entitlement`).
3. Add both Play products (`you_plus_monthly`, `you_plus_yearly`) and attach each to the
   `you_plus` entitlement.
4. Create/confirm an **Offering** (default id `default`) with a **Monthly** package
   (→ `you_plus_monthly`) and an **Annual** package (→ `you_plus_yearly`). The app reads
   `offering.monthly` / `offering.annual`.
5. Copy the **Android public SDK key** (Project → API keys, the *public* one).
6. Create a **secret (v1) API key** (Project → API keys) for server-side entitlement checks.

## 3. Webhook (RevenueCat → Cloud Function)
1. Deploy functions first (step 5) to get the HTTPS URL for `revenueCatWebhook`, e.g.
   `https://us-central1-you-app-c6b1f.cloudfunctions.net/revenueCatWebhook`.
2. RevenueCat → Project → Integrations → **Webhooks**:
   - URL: the `revenueCatWebhook` URL above.
   - **Authorization header**: set a strong random value. This exact string is what the
     function compares against `REVENUECAT_WEBHOOK_SECRET` — they must match byte-for-byte.

## 4. Client key (`.env`)
Add the RevenueCat **Android public SDK key** to the gitignored `.env` (and keep the blank
placeholder in `.env.example`):
```
REVENUECAT_ANDROID_KEY=goog_xxxxxxxxxxxxxxxxxxxx
```
Read in `lib/env.dart` as `Secrets.revenueCatAndroidKey`, configured at startup in `main.dart`.

## 5. Backend secrets + deploy
Set the two Functions secrets (v2 secret manager), then deploy:
```
firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET   # = the webhook Authorization value
firebase functions:secrets:set REVENUECAT_REST_API_KEY     # = the RevenueCat secret v1 API key
firebase deploy --only functions
```
Functions added: `revenueCatWebhook` (HTTPS) and `refreshEntitlement` (callable). No Firestore
rules changes are needed — subscription fields are already Admin-SDK-only.

## 6. Field contract (do not drift)
The backend writes these exact keys on `users/{uid}` (mixed casing is intentional and shared
by model + rules + functions):
- `subscriptionTier` — `"premium"` | `"free"` (camelCase)
- `subscription_expiry` — Firestore `Timestamp` or `null` (indefinite) (snake_case)
- `subscription_source` — `"google_play"` | `"admin"` (snake_case)

## 7. Event handling
- Grant (premium): `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `UNCANCELLATION`,
  `NON_RENEWING_PURCHASE`.
- Revoke (free): `EXPIRATION`, `REFUND` — **skipped if `subscription_source == "admin"`**.
- No-op: `CANCELLATION` (auto-renew off; still entitled until expiry), `BILLING_ISSUE` (grace).
- After purchase/restore the app also calls `refreshEntitlement`, which server-verifies via
  RevenueCat REST and writes Firestore immediately (instant unlock + self-heal for a missed
  webhook).

## 8. Verify end-to-end
- License-tester purchase of **monthly** and **yearly** each unlocks premium (via Firestore, not
  a client write); the Premium screen flips to the member block.
- Cancel auto-renew → still premium until expiry; force an `EXPIRATION`/`REFUND` → reverts to free.
- Admin-granted user (`subscription_source: "admin"`) is unaffected by an `EXPIRATION` event.
- Reinstall → "Restore purchase" re-grants premium.
- A request to `revenueCatWebhook` with a wrong/missing `Authorization` returns **401**.

> Note: Android `minSdkVersion` is raised to **24** (`android/app/build.gradle.kts`) for
> `purchases_flutter`. iOS billing is intentionally not wired this phase.
