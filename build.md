# Eupanel Build Guide

## Prerequisites

### Backend (FlintDart)
- Dart SDK `^3.2.0`
- Git (for dependency overrides)

### Frontend (Next.js)
- Node.js `>=18`
- npm or compatible package manager

### Infrastructure
- Linux server (Ubuntu recommended)
- Nginx
- MySQL / MariaDB or PostgreSQL
- PowerDNS
- Certbot (Let's Encrypt)

---

## Project Structure

```
eupanel/
├── backend/     # FlintDart Core API
├── frontend/    # Next.js Dashboard
└── masterplan.md
```

---

## Backend

### Install dependencies

```bash
cd backend
dart pub get
```

### Run (development)

```bash
dart run bin/server.dart
```

### Compile (production)

```bash
dart compile exe bin/server.dart -o eupanel-core
./eupanel-core
```

---

## Frontend

### Install dependencies

```bash
cd frontend
npm install
```

### Run (development)

```bash
npm run dev
```

### Build (production)

```bash
npm run build
npm run start
```

---

## Eupanel Agent

The agent is installed on every managed server.

### Install

```bash
# On the target server
dart compile exe agent/bin/agent.dart -o eupanel-agent
sudo mv eupanel-agent /usr/local/bin/eupanel-agent
```

### Run as systemd service

Create `/etc/systemd/system/eupanel-agent.service`:

```ini
[Unit]
Description=Eupanel Agent
After=network.target

[Service]
ExecStart=/usr/local/bin/eupanel-agent
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable eupanel-agent
sudo systemctl start eupanel-agent
```

---

## Environment Variables

### Backend

| Variable         | Description                        |
|------------------|------------------------------------|
| `DB_HOST`        | Database host                      |
| `DB_PORT`        | Database port                      |
| `DB_NAME`        | Database name                      |
| `DB_USER`        | Database user                      |
| `DB_PASS`        | Database password                  |
| `JWT_SECRET`     | Secret for JWT token signing       |
| `PDNS_API_URL`   | PowerDNS API URL                   |
| `PDNS_API_KEY`   | PowerDNS API key                   |
| `AGENT_SECRET`   | Shared secret for agent auth       |

### Frontend

| Variable              | Description              |
|-----------------------|--------------------------|
| `NEXT_PUBLIC_API_URL` | URL of the backend API   |

---

## Database Setup

```sql
-- Create eupanel database and user
CREATE DATABASE eupanel;
CREATE USER 'eupanel'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON eupanel.* TO 'eupanel'@'localhost';
FLUSH PRIVILEGES;
```

Run migrations:

```bash
cd backend
dart run bin/migrate.dart
```

---

## Nginx (Frontend Reverse Proxy)

```nginx
server {
    listen 80;
    server_name panel.eucloudhost.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```nginx
server {
    listen 80;
    server_name api.eucloudhost.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Issue SSL:

```bash
sudo certbot --nginx -d panel.eucloudhost.com -d api.eucloudhost.com
```

---

## Job Queue

All operations (site creation, SSL, DNS, backups) run as background jobs with the following statuses:

```
pending → running → success | failed
```

Job logs are stored per job in the database.

---

## Development Phases

| Phase | Status      | Description                                      |
|-------|-------------|--------------------------------------------------|
| 1     | In progress | MVP — Auth, servers, sites, SSL, DNS, databases  |
| 2     | Planned     | Node.js, Dart, Python runtime support            |
| 3     | Planned     | Hosting plans, reseller, monitoring, clustering  |
