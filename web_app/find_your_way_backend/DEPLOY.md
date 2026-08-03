# Deploying Find Your Way to a VPS

Target layout on the VPS:

- Backend: git-cloned to `/root/find_your_way_backend`, run under pm2
- Frontend: built **locally** with Flutter, then `scp`'d to `/var/www/find-your-way`
- nginx serves the frontend as static files and reverse-proxies `/api` and
  `/static` to the backend, so both are on the same origin — no CORS
  configuration needed in production.

## 0. Point the domain at the VPS

DuckDNS just needs an A record update — confirm it's pointing at the
VPS's public IP:

```bash
curl "https://www.duckdns.org/update?domains=find-your-ways&token=<your-duckdns-token>&ip="
```

(DuckDNS auto-detects the IP from the request when `ip=` is left empty.)

## 1. VPS prerequisites

```bash
apt update && apt install -y nginx git
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
npm install -g pm2
apt install -y certbot python3-certbot-nginx
```

## 2. Backend — clone, install, configure, run under pm2

```bash
cd /root
git clone <backend-repo-url> find_your_way_backend
cd find_your_way_backend

npm install --omit=dev

cp .env.example .env
# Edit .env: set a real JWT_SECRET (openssl rand -hex 32), keep PORT=8999
nano .env

pm2 start ecosystem.config.js
pm2 save
pm2 startup   # follow the printed command to enable pm2 on boot
```

Verify it's up: `curl http://127.0.0.1:8999/api/health`.

## 3. Frontend — build locally, ship the build over

Build on your own machine (no Flutter install needed on the VPS), pointed
at the production API origin:

```bash
cd find_your_way
flutter build web --release \
  --dart-define=API_BASE_URL=https://find-your-ways.duckdns.org/api \
  --dart-define=ASSET_BASE_URL=https://find-your-ways.duckdns.org
```

On the VPS, create the target directory once:

```bash
mkdir -p /var/www/find-your-way
```

Then from your local machine, copy the build output over:

```bash
scp -r build/web/* root@<vps-ip-or-host>:/var/www/find-your-way/
```

## 4. nginx + HTTPS

```bash
cp /root/find_your_way_backend/deploy/nginx.find-your-way.conf /etc/nginx/sites-available/find-your-way
ln -s /etc/nginx/sites-available/find-your-way /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

certbot --nginx -d find-your-ways.duckdns.org
```

Certbot rewrites the server block to redirect HTTP → HTTPS and sets up
auto-renewal. The shipped `nginx.find-your-way.conf` already assumes
`/var/www/find-your-way` (frontend) and `/root/find_your_way_backend`
(backend) — only edit it if your paths differ.

## 5. Verify

- `https://find-your-ways.duckdns.org` loads the app shell
- Register an account, confirm destination images load (proves the
  `/static/` alias is correct)
- `pm2 logs find-your-way-api` for backend errors
- `pm2 status` should show the API as `online`

## Redeploying after changes

```bash
# Backend
/root/find_your_way_backend/update.sh

# Frontend — rebuild locally with the same --dart-define flags as step 3, then:
scp -r build/web/* root@<vps-ip-or-host>:/var/www/find-your-way/
# nginx serves the new files immediately, no reload needed.
```
