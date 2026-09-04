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

The backend uses TypeScript, Fastify, PostgreSQL, explicit SQL, `jose`, AES-256-GCM encrypted Apple refresh credentials, opaque rotated refresh sessions, and 15-minute access JWTs. A random installation UUID is stored in Keychain and associates a device row; Phase 3 registers and lists devices but does not enforce the future two-device Pro limit. Logout and account deletion preserve local SQLite pickup data. StoreKit, subscriptions, App Store Server API, and entitlement enforcement remain future phases.
