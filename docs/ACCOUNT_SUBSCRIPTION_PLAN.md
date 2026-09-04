# Account & Subscription Plan

PackageHub is local-first and privacy-first.

## Free

- No login required
- Screenshot OCR
- Multi-credential recognition
- Review and edit
- Station Map
- Identity Hub
- Mark one credential as picked up
- Edit or delete one credential
- Basic history
- Up to 3 active pickup credentials at once

## Pro

- Unlimited active pickup credentials
- Batch management: mark picked up and delete
- Future advanced local management capabilities
- Future custom stations and station rules

Cloud Sync is not promised in the first version.

## Account and subscription

- Free does not require a PackageHub Account.
- Pro will require a PackageHub Account when paid subscriptions launch.
- One Apple subscription binds to one `PackageHub user_id`.
- Pro supports at most 2 active PackageHub devices.
- Family Sharing is disabled in the first version.

## Future backend

The future backend will contain `users`, `subscriptions`, `devices`, and `sessions`.
`original_transaction_id` is unique. `installation_id` will be a random UUID
stored in Keychain. PackageHub will not use IMEI, serial number, IDFA, or a
hardware fingerprint.

## Offline entitlement

Future backend-issued entitlements may allow a short offline grace period of
24–72 hours.

## Phase 3 — PackageHub Account foundation

Phase 3 introduces a backend-owned PackageHub account. Native iOS `AuthenticationServices` returns the Apple credential through `packagehub/apple_sign_in`; Flutter exchanges it with the backend after obtaining a single-use challenge. The backend verifies the Apple JWT (signature, issuer, audience, expiry, and nonce), uses `apple_subject` as the stable Apple mapping, and creates a UUID `users.id` as the PackageHub identity.

The backend uses TypeScript, Fastify, PostgreSQL, explicit SQL, `jose`, AES-256-GCM encrypted Apple refresh credentials, opaque rotated refresh sessions, and 15-minute access JWTs. A random installation UUID is stored in Keychain and associates a device row; Phase 3 registers and lists devices but does not enforce the future two-device Pro limit. Logout and account deletion preserve local SQLite pickup data.

## Phase 4 — StoreKit 2 client entitlement (IN PROGRESS)

Phase 4 uses a native StoreKit 2 bridge through `packagehub/storekit` and
`packagehub/storekit_events`. Product metadata comes from Apple's
`Product.products(for:)`, including localized `displayPrice`; the product ID
source of truth is `StoreKitProductIds.pro`, configurable with
`PACKAGEHUB_PRO_PRODUCT_ID`.

Purchases require a signed-in PackageHub account. The stable UUID returned by
`GET /v1/me/storekit-context` is passed to StoreKit as `appAccountToken`, and
only verified transactions whose token and product match can produce local Pro
entitlement. This is temporary Phase 4 client authority, not the final
anti-sharing or account entitlement authority. Phase 5 will introduce backend
subscription entitlement and reconciliation.

Current entitlements and one native transaction listener drive observable
repository state. `AppStore.sync()` is called only after explicit Restore
Purchases. Phase 4 adds no subscription tables, transaction history, server
notifications, server API reconciliation, or two-device enforcement.

Debug builds expose a non-persistent StoreKit / Free / Pro entitlement override
at the bottom of SubscriptionPage. It affects only the entitlement and
existing Pro feature gates; it never creates products or transactions.

For local StoreKit testing, create an Xcode StoreKit Configuration File named
`PackageHub.storekit`, add one Auto-Renewable Subscription in a subscription
group, and use the product ID `com.charm1ng.packagehub.pro.monthly`. Configure
a clearly development-only price, then select the file under the Runner
scheme's Run > Options > StoreKit Configuration. The app still calls native
StoreKit APIs; it does not parse this file. No configuration file is checked
in yet because it has not been generated and manually verified in Xcode.

Phase 4 code is complete when automated checks pass. Xcode StoreKit Testing
and Sandbox/TestFlight purchase verification remain manual pending in this
environment.

Before production release:

- [ ] Remove development StoreKit/Free/Pro override and controls
- [ ] Verify App Store Connect product IDs and production pricing metadata
- [ ] Verify sandbox/TestFlight purchase and restore flows
- [ ] Enter Phase 5 backend entitlement and device control
