# Conventions

## Branding
Product name is **BachatBuddy**. Never use KhataLock in user-facing copy.

## Database
- PostgreSQL **18** (latest stable)
- Money as integer **paise** (`bigint` columns named `*_paise`).
- Never use floats for money.
- Convert at API/UI boundaries only (`Money` helpers).
- ₹ formatting uses `en-IN` (e.g. ₹1,00,000).

## IDs
- Public primary keys are UUIDs.

## API
- Base path: `/api/v1`
- Envelope: `{ data, meta, errors }`
- Errors: `{ code, message, fields? }`
- Propagate `X-Request-Id`
- Financial POSTs accept `Idempotency-Key`

## Timezone
- Default user timezone: `Asia/Kolkata`

## Auth
- Short-lived JWT access token (Bearer)
- Rotating refresh tokens stored hashed server-side
