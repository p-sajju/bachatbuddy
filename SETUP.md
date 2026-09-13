# BachatBuddy Setup Notes

## Prerequisites

- Ruby 3.4+
- **PostgreSQL 18** (latest stable; client + server — e.g. Ubuntu package `postgresql-18`)
- Redis 7+ (optional locally — ActiveJob falls back to `:async` when Redis is down)
- Bundler (`vendor/bundle` is already present under `backend/`)

## Ports

| Service | Port |
|---------|------|
| Rails API | **3000** |
| Next.js | **3001** |
| PostgreSQL | **5432** |
| Redis (optional) | 6379 |

## Database (try in this order)

### 1. Project-local PostgreSQL 18 (recommended on this machine)

Uses binaries from `/usr/lib/postgresql/18` and data in repo `.pgdata` (gitignored).

```bash
chmod +x bin/pg
./bin/pg init    # first time only
./bin/pg start   # listens on :5432
./bin/pg status
```

`backend/.env`:

```bash
DATABASE_URL=postgres://bachatbuddy:bachatbuddy@localhost:5432/bachatbuddy_development
```

Stop with: `./bin/pg stop`

> If system Postgres already binds `:5432`, stop it first (`sudo service postgresql stop`) or use Docker Compose instead.

### 2. Docker Compose (PostgreSQL 18)

```bash
docker compose up -d postgres redis
```

Image: `postgres:18-alpine` on host port **5432**.

### 3. System Postgres 18 on localhost:5432

```bash
sudo apt install postgresql-18 postgresql-client-18
sudo -u postgres createuser -s bachatbuddy
sudo -u postgres psql -c "ALTER USER bachatbuddy WITH PASSWORD 'bachatbuddy';"
sudo -u postgres createdb -O bachatbuddy bachatbuddy_development
sudo -u postgres createdb -O bachatbuddy bachatbuddy_test
```

## Backend boot (port 3000)

```bash
cd backend
bundle exec rails db:prepare
bundle exec rails s -p 3000
```

CORS allows the Next.js origin `http://localhost:3001`.

## Frontend boot (port 3001)

```bash
cd frontend
cp .env.local.example .env.local   # NEXT_PUBLIC_API_URL=http://localhost:3000
npm install
npm run dev                        # next dev -p 3001
```

## Redis (optional locally)

Redis is **not required** for local API development. When `REDIS_URL` is unreachable,
ActiveJob stays on `:async`.

## Specs

```bash
cd backend
bundle exec rspec
```

## Health

- `GET http://localhost:3000/health` — liveness
- `GET http://localhost:3000/ready` — DB required; Redis optional
