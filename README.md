# EuPanel

A lightweight hosting control panel built on Flint Dart (backend), Next.js (frontend), and a Go agent that runs on each server. Built by [Eulogia Technologies](https://github.com/Eulogia-Technologies).

---

## What's included

| Feature | Details |
|---|---|
| **Hosting plans** | Create plans with disk, bandwidth, domain, DB, FTP limits |
| **Subscriptions** | Users subscribe to plans — system account + FTP provisioned automatically |
| **Domains** | Add domains → nginx vhost + SSL via Let's Encrypt, all automatic |
| **Databases** | MySQL database creation per subscription |
| **DNS** | PowerDNS with a full API for zone + record management |
| **FTP** | vsftpd virtual users, one per subscription |
| **phpMyAdmin** | Served at a secret URL, no public exposure |
| **File Manager** | Browser-based file manager for each hosting account |
| **Multi-role** | Admin · Reseller · Customer |

---

## Requirements

| | |
|---|---|
| **OS** | Ubuntu 22.04 LTS or 24.04 LTS |
| **RAM** | 1 GB minimum (2 GB recommended) |
| **CPU** | 1 vCPU minimum |
| **Disk** | 20 GB minimum |
| **Access** | Root SSH access |
| **Domain** | Optional — works on bare IP, domain needed for SSL |

> **Recommended VPS:** Hetzner CX22 (2 vCPU / 4 GB / €4 mo), DigitalOcean Droplet, or Contabo.

---

## Quick install

SSH into your server as root, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/install.sh | bash
```

The script will ask you a few questions, then handle everything else.

## Update

Already installed? One command updates everything — backend, frontend, and agent:

```bash
curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/update.sh | bash
```

It pulls the latest code, rebuilds only what changed, restarts all services, and shows the status. If you're already on the latest version it exits immediately without doing anything.

---

## Step-by-step walkthrough

### 1. Get a server

Spin up a fresh **Ubuntu 22.04** or **24.04** VPS. Make a note of the server's public IP address.

### 2. (Optional) Point your domain

If you want a domain name for the panel (e.g. `panel.yourdomain.com`), go to your DNS registrar and add an **A record**:

```
Type : A
Name : panel          (or @ for root domain)
Value: YOUR_SERVER_IP
TTL  : 300
```

Wait a few minutes for DNS to propagate before running the install.

> You can skip this step and use the bare IP. SSL won't be available without a domain.

### 3. SSH into your server

```bash
ssh root@YOUR_SERVER_IP
```

### 4. Run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/install.sh | sudo bash
```

The installer will ask:

| Prompt | Example answer |
|---|---|
| Panel domain | `panel.yourdomain.com` — or press Enter to use the IP |
| Admin e-mail | `you@example.com` |
| Admin username | `admin` |
| Admin password | Press Enter to auto-generate a strong password |
| Issue SSL? | `y` if you pointed a domain, `n` for IP-only |

After you confirm, everything runs automatically. It takes **3–6 minutes** depending on your server.

### 5. Save your credentials

When the install finishes, all credentials are printed on screen **and** saved to:

```
/root/eupanel-credentials.txt
```

**Copy this file somewhere safe**, then delete it from the server:

```bash
cat /root/eupanel-credentials.txt   # read it
rm /root/eupanel-credentials.txt    # then delete
```

### 6. Open the panel

| URL | What |
|---|---|
| `http://panel.yourdomain.com` | EuPanel dashboard |
| `http://panel.yourdomain.com/pma_XXXXXX/` | phpMyAdmin (secret URL from credentials) |
| `http://panel.yourdomain.com/filemanager/` | File manager |

Log in with the admin username and password from step 5.

---

## What the installer sets up

```
nginx            — reverse proxy (port 80 / 443)
PHP 8.3-FPM      — for phpMyAdmin + file manager
MariaDB          — eupanel database + PowerDNS database
phpMyAdmin       — served at a secret random URL
PowerDNS         — authoritative DNS server with HTTP API
vsftpd           — FTP server with virtual users
Certbot          — Let's Encrypt SSL + auto-renew
Go 1.22          — builds eupanel-agent
Dart SDK         — runs the Flint backend
Node.js 20       — builds + serves Next.js frontend
Tinyfilemanager  — PHP file browser
Firewall (UFW)   — opens 22, 80, 443, 21, 53, FTP passive
```

Three systemd services are created and started:

| Service | What |
|---|---|
| `eupanel-backend` | Flint Dart API on port 4054 |
| `eupanel-frontend` | Next.js dashboard on port 3000 |
| `eupanel-agent` | Go provisioning agent on localhost:7820 |

---

## After install — useful commands

**Check service status:**
```bash
systemctl status eupanel-backend
systemctl status eupanel-frontend
systemctl status eupanel-agent
```

**View live logs:**
```bash
journalctl -u eupanel-backend  -f
journalctl -u eupanel-frontend -f
journalctl -u eupanel-agent    -f
```

**Restart a service:**
```bash
systemctl restart eupanel-backend
systemctl restart eupanel-frontend
systemctl restart eupanel-agent
```

**Update EuPanel to the latest version:**
```bash
curl -fsSL https://raw.githubusercontent.com/Eulogia-Technologies/eupanel/master/update.sh | bash
```
This pulls the latest code, rebuilds the backend, frontend, and agent, then restarts all three services automatically. If already up to date it exits immediately.

**Issue SSL manually** (if you skipped it during install):
```bash
certbot --nginx -d panel.yourdomain.com
```

---

## Firewall ports

| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 21 | TCP | FTP control |
| 40000–50000 | TCP | FTP passive data |
| 53 | TCP + UDP | DNS |

The following ports are **localhost-only** (not exposed to the internet):

| Port | Service |
|---|---|
| 4054 | EuPanel backend API |
| 3000 | Next.js frontend |
| 7820 | EuPanel agent |
| 8081 | PowerDNS HTTP API |

---

## Directory layout

```
/opt/eupanel/
├── backend/          Flint Dart backend
│   ├── lib/
│   ├── .env          secrets — chmod 600
│   └── storage/
├── frontend/         Next.js dashboard
│   └── .env.local    secrets — chmod 600
└── eupanel-agent/    Go agent source

/usr/local/bin/eupanel-agent    compiled Go binary
/etc/eupanel/agent.env          agent secrets
/etc/eupanel/pma_token          phpMyAdmin secret URL token
/var/www/phpmyadmin/            phpMyAdmin files
/var/www/filemanager/           Tinyfilemanager
```

---

## Troubleshooting

**Panel shows 502 Bad Gateway**

The backend or frontend service isn't running yet. Check logs:
```bash
journalctl -u eupanel-backend --no-pager -n 50
journalctl -u eupanel-frontend --no-pager -n 50
```

**"Cannot reach agent" when creating a subscription**

The agent isn't running or the secret doesn't match:
```bash
systemctl status eupanel-agent
# check secret matches in both:
cat /etc/eupanel/agent.env
cat /opt/eupanel/backend/.env | grep AGENT_SECRET
```

**SSL certificate failed during install**

Your domain's A record either isn't set or hasn't propagated yet. Wait a few minutes then run:
```bash
certbot --nginx -d panel.yourdomain.com
```

**Forgot admin password**

Reset it directly in MariaDB:
```bash
mysql -u root eupanel
```
```sql
UPDATE users SET password = '<new_hash>' WHERE email = 'you@example.com';
```

**FTP connection refused**

Make sure vsftpd is running and UFW allows port 21:
```bash
systemctl status vsftpd
ufw status
```

---

## Architecture overview

```
Browser
  │
  ▼
nginx (80/443)
  ├── /api/*        → Flint Dart backend  :4054
  ├── /             → Next.js frontend    :3000
  ├── /pma_xxxxx/   → phpMyAdmin          (PHP-FPM)
  └── /filemanager/ → Tinyfilemanager     (PHP-FPM)

Flint Dart backend
  ├── MariaDB         (eupanel database)
  ├── PowerDNS API    (localhost:8081)
  └── eupanel-agent   (localhost:7820)
        ├── useradd / userdel    (system users)
        ├── vsftpd virtual users (FTP accounts)
        ├── nginx vhost files    (site provisioning)
        └── certbot              (SSL certificates)
```

---

## License

MIT — see [LICENSE](LICENSE).

Built by [Eulogia Technologies](https://github.com/Eulogia-Technologies).
