# Find Your Way — Backend (Phase 1: Monolith)

A single Node.js/Express REST API backing the Find Your Way travel
recommendation app. No database — all data lives in JSON files under
`src/data/`, per the Phase 1 monolith requirements.

## Run it

```bash
npm install
npm start        # http://localhost:8999
```

`.env` already contains a dev `JWT_SECRET` and `PORT=8999`.

## Endpoints

| Method | Path                        | Auth | Description                                  |
|--------|-----------------------------|------|-----------------------------------------------|
| POST   | `/api/auth/register`        | –    | Create an account, returns a JWT              |
| POST   | `/api/auth/login`           | –    | Authenticate, returns a JWT                   |
| GET    | `/api/auth/me`              | ✅   | Current user profile                          |
| PUT    | `/api/auth/preferences`     | ✅   | Update travel interest categories             |
| GET    | `/api/destinations`         | –    | Search/filter destinations (`q`, `category`)  |
| GET    | `/api/destinations/categories` | – | List distinct destination categories          |
| GET    | `/api/destinations/:id`     | –    | Destination detail                            |
| GET    | `/api/recommendations`      | opt  | Popular, or personalized if logged in         |
| GET    | `/api/itineraries`          | ✅   | List the current user's itineraries           |
| POST   | `/api/itineraries`          | ✅   | Create an itinerary                           |
| GET    | `/api/itineraries/:id`      | ✅   | Itinerary detail                              |
| DELETE | `/api/itineraries/:id`      | ✅   | Delete an itinerary                           |

Authenticated routes expect `Authorization: Bearer <token>`.

Destination photos are served statically from `/static/Destinstions/…`.

## Deploying

See [DEPLOY.md](DEPLOY.md) for VPS setup: pm2 process management
(`ecosystem.config.js`), nginx reverse proxy (`deploy/nginx.find-your-way.conf`),
and HTTPS via certbot. After the initial deploy, `./update.sh` pulls,
reinstalls, and restarts the pm2 process in one step.
