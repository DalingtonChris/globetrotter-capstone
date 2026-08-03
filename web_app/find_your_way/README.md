# Find Your Way

A travel recommendation and itinerary-planning app — Phase 1 of the
GlobeTrotter capstone project, built as a monolith: Flutter Web frontend,
Node.js/Express backend, JSON file storage.

## Run it

Start the backend first (see `find_your_way_backend/readme.md`), then:

```bash
flutter pub get
flutter run -d chrome
```

The app expects the API at `http://localhost:8999/api` (see
`lib/core/constants.dart`).

## What's here

- **Auth** — register/login with JWT, session persisted via `shared_preferences`.
- **Explore** — search, category filters, and personalized recommendations
  over destinations seeded from real Yaoundé, Cameroon locations.
- **Itineraries** — build a trip from one or more destinations, with dates
  and notes; view, and delete.
- **Profile** — travel interest preferences that feed the recommendation
  engine, and logout.

## Structure

```
lib/
  core/        theme + API base URL
  models/      User, Destination, Itinerary
  services/    HTTP client + per-resource services
  state/       AuthController (session state)
  screens/     auth, home (explore/detail), itineraries, profile
  widgets/     shared UI components
```

## Deploying

`apiBaseUrl`/`assetBaseUrl` default to `localhost:8999` for local dev but
can be overridden at build time for production:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://find-your-ways.duckdns.org/api \
  --dart-define=ASSET_BASE_URL=https://find-your-ways.duckdns.org
```

See `find_your_way_backend/DEPLOY.md` for the full VPS setup (pm2 + nginx + HTTPS).
