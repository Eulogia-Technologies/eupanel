# EuPanel Project Status

## What This App Is Meant For

EuPanel is a hosting control panel for Eulogia Technologies. It is meant to manage the technical side of a hosting business: servers, hosting plans, subscriptions, websites, domains, DNS, SSL, databases, mail, backups, jobs, deployments, and server-side provisioning.

EuPanel is not meant to be the billing website. Billing, invoices, payments, checkout, wallet logic, CRM, and support tickets should live in a separate billing/customer website. That billing website should call EuPanel through APIs when it needs to create, suspend, unsuspend, or terminate hosting services.

The intended architecture is:

- Backend: Flint Dart fullstack app on port `4054`
- Frontend: Flint Web UI source inside `fullstack/flint_ui`, compiled to `fullstack/public/main.dart.js`
- Native provisioning: Flint Dart services run server commands through `InternalCommandService`
- Database: MySQL/MariaDB through Flint models
- System services: nginx, PHP-FPM, MariaDB, PowerDNS, vsftpd, Certbot, phpMyAdmin, Tinyfilemanager

The big idea is that the backend stores the control panel data and exposes APIs, while Flint Dart services perform server-level actions like creating Linux users, FTP users, nginx virtual hosts, SSL certificates, and git deployments.

## What Is Already Done

### Repository Structure

The project already has the main three-part structure:

- `fullstack/` contains the Flint Dart API, Flint Web UI pages, and public assets.
- `install.sh` installs the full stack on Ubuntu.
- `update.sh` updates the backend, Flint Web UI bundle, service.
- `README.md` explains installation, services, ports, and architecture.
- `masterplan.md` describes the long-term product direction.

### Backend

The backend is already scaffolded and running through `fullstack/lib/main.dart`.

Implemented route groups include:

- Auth: `/auth`
- Users: `/users`
- Plans: `/plans`
- Subscriptions: `/subscriptions`
- Domains: `/domains`
- Servers: `/servers`
- Sites: `/sites`
- Runtimes: `/runtimes`
- Databases: `/databases`
- DNS: `/dns`
- SSL: `/ssl`
- Jobs: `/jobs`
- Backups: `/backups`
- Mail: `/mail`
- GitHub integration: `/github`
- Webhooks: `/webhooks`
- System update: `/admin/system`

Models are registered for users, plans, subscriptions, domains, servers, sites, runtimes, databases, SSL certificates, DNS zones, DNS records, jobs, backups, mail accounts, GitHub tokens, and git deployments.

The backend has working controller/service logic for:

- Registering and logging in users.
- Seeding demo users.
- Creating, listing, updating, and deleting plans.
- Creating subscriptions.
- Provisioning subscriptions through Flint Dart native command services.
- Cancelling/deprovisioning subscriptions.
- Managing domain records in the panel database.
- Managing sites and subdomains.
- Creating jobs for async operations.
- Managing servers and server heartbeats.
- Creating database records and database jobs.
- Creating DNS zones and DNS records.
- Creating SSL certificate records and SSL jobs.
- Creating backup records and backup/restore jobs.
- Creating mail account records and mail jobs.
- Connecting GitHub and creating deployment records.
- Triggering self-update flow through the system endpoint.

### Provisioning

Subscription provisioning already exists at a basic level.

When a subscription is created, the backend:

- Validates the selected plan.
- Generates a Linux-safe system username.
- Creates a subscription record.
- Calls the local Dart provisioning services.
- Creates a Linux system user.
- Creates an FTP user.
- Marks the subscription as active if provisioning succeeds.
- Rolls back the system user if provisioning fails.

The Flint Dart native command services currently support:

- Health check.
- Domain creation and deletion.
- nginx virtual host generation and reload.
- SSL issue, renew, and status.
- System information and disk usage.
- Linux system user creation/deletion.
- FTP user creation/deletion.
- Git deployment.

### Flint Web UI

The dashboard UI now lives inside the Flint backend as a Flint Web UI app.

Existing screens include:

- Login page.
- Admin dashboard.
- Customer dashboard.
- Websites and domains.
- Domains.
- DNS settings.
- Mail.
- Databases.
- SSL certificates.
- Backups.
- Servers.
- Runtimes.
- Jobs.
- Plans.
- Subscriptions.
- Customers.
- GitHub deployments.
- System overview surfaces.

The UI source is in `fullstack/flint_ui/` and the compiled browser bundle is served from `fullstack/public/main.dart.js`.

### Installer and Deployment

The install and update scripts are already substantial.

The installer is intended to set up:

- nginx
- PHP 8.3-FPM
- MariaDB
- phpMyAdmin
- PowerDNS
- vsftpd
- Certbot
- Dart SDK
- Tinyfilemanager
- UFW firewall rules
- systemd service for the fullstack backend

The update script is intended to pull the latest code, rebuild the backend UI bundle, restart the backend service, and show status.

## What Is Not Done Yet

### Production Security

The app is not production-secure yet.

Important gaps:

- Some secrets have fallback values like `change-me-before-production`.
- Demo seed users expose default credentials.
- FTP and database passwords appear to be stored directly in model data.
- Role checks are basic and mostly use `admin`, `customer`, and `reseller`.
- The masterplan asks for permission-based access control, but full permissions are not implemented yet.
- Audit logs are not fully implemented.
- API token/client management for the billing website is not complete.
- Request signing and rate limiting for external integrations are not complete.

### Job Execution

The backend creates job records, but many jobs are only queued as database records.

Still needed:

- A real job runner/worker.
- Retry logic.
- Job status transitions from `pending` to `running`, `success`, or `failed`.
- Detailed job logs.
- Worker execution through Dart provider services for sites, DNS, SSL, backups, mail, and databases.
- A clear failure and rollback strategy for every job type.

### Provider Adapter Architecture

The masterplan asks for provider interfaces like:

- HostingProviderInterface
- DnsProviderInterface
- MailProviderInterface
- SSLProviderInterface
- BackupProviderInterface
- MonitoringProviderInterface

Those are not fully built yet. Current code is still mostly tied to local Linux/server-agent flows.

This means Plesk, external DNS providers, external mail systems, remote backup providers, and other future providers are not plug-and-play yet.

### DNS

DNS zones and records can be stored in the backend database, but full real DNS provisioning is not complete.

Still needed:

- PowerDNS API integration from backend or agent.
- Update/delete DNS record endpoints.
- Zone deletion.
- Validation for record types.
- Nameserver management.
- Sync between panel database and PowerDNS.

### Mail

Mail account records can be created in the backend, but real mail hosting is not complete.

Still needed:

- Actual mailbox creation on server.
- Mail domains.
- Forwarders.
- Aliases.
- Autoresponders.
- Quotas.
- Password reset flow.
- Mail usage tracking.

### Databases

Database records and jobs exist, but real database provisioning is not complete.

Still needed:

- Actual MySQL database creation.
- Database user creation.
- Privilege assignment.
- Password reset against MySQL.
- Remote access rules.
- Safe password storage.

### SSL

The Dart SSL service can issue/renew SSL using Certbot, and the backend can create SSL job records. The full job-driven SSL workflow is not finished.

Still needed:

- Job worker to call the agent.
- Renewal scheduling.
- Expiry monitoring.
- Custom SSL upload.
- Certificate event history.

### Backups

Backup records and backup/restore jobs exist, but actual backup execution is not complete.

Still needed:

- Backup engine.
- Restore engine.
- Scheduled backups.
- Remote storage destinations.
- Per-site and per-server backup policy.
- Backup integrity checks.

### Monitoring

Only basic agent health/system/disk endpoints exist.

Still needed:

- CPU, RAM, disk, bandwidth collection.
- Server health history.
- Service status checks.
- Alerts and thresholds.
- Incidents.
- Monitoring dashboard data.

### Flint Web UI Completion

The Flint Web UI dashboard has the first admin, reseller, and customer surfaces, but it still needs production polish.

Still needed:

- Confirm all dashboard routes exist for every sidebar link.
- Remove or finish placeholder screens.
- Standardize auth token handling for the Flint Web UI app.
- Add consistent loading, empty, and error states everywhere.
- Add API client abstraction instead of scattered `fetch()` calls.
- Connect every form to real backend behavior.
- Improve validation messages.
- Hide actions that are not implemented yet.

### API For Billing Website

This is a major unfinished requirement.

Still needed:

- API clients table/model.
- API token creation and rotation.
- Signed integration requests.
- Endpoints like:
  - provision service
  - suspend service
  - unsuspend service
  - terminate service
  - fetch status
  - fetch usage
- Webhooks back to the billing site.
- Rate limiting and audit logs.

## Main Risks Found

1. Password and secret handling needs urgent hardening before production.
2. Jobs are queued but not fully executed for many modules.
3. The provider/adapter layer is not yet implemented, so future integrations will be harder if this is delayed.
4. Some UI-to-API flows are still placeholders.
5. Several modules have database records before real server-level provisioning exists.
6. The app may look more complete in the UI than it actually is operationally.

## Recommended Next Steps

### Step 1: Stabilize Auth and Security

Before adding more modules, make the foundation safe.

Do this first:

- Remove unsafe default secrets.
- Make production install require strong generated secrets.
- Disable demo seed users in production.
- Hash or encrypt stored service credentials.
- Add permission tables or at least centralized policy checks.
- Add audit logs for sensitive actions.
- Standardize dashboard token storage.

### Step 2: Build the Job Worker

The next most important technical step is a real job runner.

The worker should:

- Poll pending jobs.
- Mark jobs as running.
- Call the correct service/provider/agent method.
- Write logs.
- Mark jobs as success or failed.
- Retry failed jobs when allowed.
- Support manual retry from the dashboard.

Without this, modules like database, DNS, SSL, backup, mail, and site operations will remain only partly functional.

### Step 3: Add Provider Interfaces

Create provider contracts before the app grows too large.

Start with:

- `HostingProvider`
- `DnsProvider`
- `MailProvider`
- `DatabaseProvider`
- `SslProvider`
- `BackupProvider`

Then add initial implementations:

- `LocalLinuxHostingProvider`
- `LocalPowerDnsProvider`
- `LocalMysqlProvider`
- `LocalLetsEncryptProvider`
- `MockProvider` for development

### Step 4: Finish One Complete Vertical Flow

Pick one workflow and make it production-complete from UI to backend to agent.

Best first workflow:

1. Admin creates a hosting plan.
2. Customer or admin creates a subscription.
3. Backend provisions system user and FTP user.
4. Customer adds a domain.
5. Backend/worker calls agent to create nginx vhost.
6. Customer issues SSL.
7. Backend/worker calls agent to issue certificate.
8. Dashboard shows real job status and logs.

This will prove the architecture works end to end.

### Step 5: Finish DNS, Database, Mail, and Backup One By One

After the vertical flow works, complete the modules in this order:

1. DNS with PowerDNS.
2. Databases with MySQL users and privileges.
3. SSL renewal and expiry monitoring.
4. Backups and restore.
5. Mail accounts, forwarders, aliases, and quotas.
6. Monitoring and alerts.

### Step 6: Add External Billing API

Once core service provisioning is reliable, expose a secure integration API for the separate billing website.

This API should handle:

- Provision after payment.
- Suspend overdue services.
- Unsuspend renewed services.
- Terminate cancelled services.
- Fetch service usage.
- Fetch provisioning status.
- Send webhooks back to billing.

## Suggested Build Order From Here

1. Security cleanup.
2. Job worker.
3. Provider interfaces.
4. Complete hosting subscription and domain provisioning.
5. Complete SSL job execution.
6. Complete DNS PowerDNS integration.
7. Complete MySQL database provisioning.
8. Complete backup execution.
9. Complete mail provisioning.
10. Add monitoring and alerts.
11. Add billing integration API.
12. Final Flint Web UI polish.
13. Production testing on a fresh Ubuntu VPS.
14. Write admin/user documentation.

## Current Summary

EuPanel is already a serious scaffold for a hosting control panel. It has the correct high-level direction, a Flint fullstack backend, a dashboard UI bundle, an installer, and Dart command services that can perform real server actions.

It is not finished as a production control panel yet. The next important work is not adding more screens. The next important work is making the existing flows reliable, secure, and fully connected: auth, permissions, job execution, provider adapters, and one complete provisioning workflow from dashboard to backend to server agent.


