# BachatBuddy

**Track your money. Protect your savings. Spend with purpose.**

Indian personal-finance MVP focused on virtual Money Locks, Safe-to-Spend, and “Spent For” family tracking.

## Stack

| Layer | Tech |
|-------|------|
| API | Rails 8 modular monolith (**port 3000**) |
| Web | Next.js App Router + TypeScript + Tailwind (**port 3001**) |
| Database | **PostgreSQL 18** (**port 5432**) |
| Jobs | Redis + Sidekiq (optional locally; ActiveJob `:async` fallback) |

## Repository layout

```text
bachatbuddy/
├── backend/          # Rails API (:3000)
├── frontend/         # Next.js app (:3001)
├── bin/pg            # Project-local PostgreSQL 18 helper (:5432)
├── docker-compose.yml
├── docs/CONVENTIONS.md
└── SETUP.md
```

## Quick start

Full details: [SETUP.md](./SETUP.md) · conventions: [docs/CONVENTIONS.md](./docs/CONVENTIONS.md).

```bash
# 1. PostgreSQL 18 on :5432
./bin/pg start
# or: docker compose up -d postgres redis

# 2. API (port 3000)
cd backend
bundle install
bundle exec rails db:prepare
bundle exec rails s -p 3000

# 3. Web (port 3001, new terminal)
cd frontend
npm install
npm run dev
```

- Web: http://localhost:3001  
- API health: http://localhost:3000/health  
- Ready: http://localhost:3000/ready  

Default `DATABASE_URL`:

```bash
postgres://bachatbuddy:bachatbuddy@localhost:5432/bachatbuddy_development
```

## Product modules

Authentication, income/expenses, people (Spent For), savings goals, money locks + unlock friction, recurring expenses, Safe-to-Spend, dashboard insights, reports, in-app notifications.

## Development commands

```bash
# Backend tests
cd backend && bundle exec rspec

# Ruby style (RuboCop / Rails Omakase)
cd backend && bundle exec rubocop

# Frontend typecheck / lint
cd frontend && npx tsc --noEmit && npm run lint
```

## Important product rules

- Money is stored as **integer paise** (never floats).
- Safe-to-Spend is a **planning figure**, not a live bank balance.
- Money Lock is **virtual/behavioral** only — not a bank restriction.

## License

Private / unpublished unless otherwise noted.
