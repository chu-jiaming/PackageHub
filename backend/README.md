# PackageHub Account backend

TypeScript + Fastify + PostgreSQL, using explicit SQL and `jose`. Copy `.env.example` to `.env`, provide secrets through the environment, run `npm install`, apply `backend/src/db/migrations/001_account.sql` with the chosen migration runner, then `npm run dev`. `npm run typecheck` and `npm test` run validation. Production API must use HTTPS.

Manual Apple setup: enable Sign in with Apple on App ID `com.charm1ng.packagehub`, enable the Xcode target capability, create an Apple key, and configure Team ID, Key ID, client identifier, `.p8` private key, JWT secret, and encryption key. Developer Portal and provisioning changes require the owner; they are not automated here.
