# PostgreSQL integration tests

These tests must run against an isolated `TEST_DATABASE_URL`, never `DATABASE_URL`. The current host has no PostgreSQL client/server and no Docker runtime, so the suite is intentionally not claimed as passed. Set `TEST_DATABASE_URL`, apply the migration to that isolated database, then run `npm run test:integration`.
