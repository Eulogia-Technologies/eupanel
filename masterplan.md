You are a senior software architect and full-stack engineer.

I want you to build a production-ready project called **EuPanel**.

## What EuPanel Is
EuPanel is **not** my billing website.
EuPanel is the **service/infrastructure control panel** for my hosting business, similar in spirit to Plesk, cPanel, or WHM.

Its job is to manage hosting services, servers, provisioning, automation, DNS, mail, databases, SSL, backups, monitoring, and internal operations.

My billing website is separate and will communicate with EuPanel through APIs.

## Main Goal
Build EuPanel as a clean, scalable, modular **hosting control panel**.

## Tech Stack
- **Backend:** Flint Dart
- **Frontend:** Next.js
- **Database:** MySQL
- **Architecture:** MVC on backend
- **API style:** REST JSON API
- **Authentication:** JWT or secure token-based auth for staff/admin
- **System style:** API-first and modular

## Important Product Boundary
Do **not** build EuPanel as a billing or CRM platform.

EuPanel should **not** include:
- customer billing
- invoices
- payment collection
- order checkout
- customer CRM
- customer ticketing portal
- wallet/balance logic

Those belong to my billing website.

EuPanel is strictly for **service management and infrastructure operations**.

---

# What EuPanel Must Do

## 1. Server Management
Build full server/node management features.

Features:
- add server/node
- edit server details
- assign provider type
- server grouping
- monitor CPU, RAM, disk, bandwidth
- reboot server
- service/process status
- server health checks
- command execution abstraction
- logs
- status history

Suggested fields:
- name
- hostname
- ip_address
- port
- provider_type
- operating_system
- status
- access_credentials_reference
- location
- notes
- created_at
- updated_at

---

## 2. Hosting Package Management
EuPanel should manage packages/plans used for provisioning hosting services.

Features:
- create package
- edit package
- suspend package
- define limits
- assign package type

Package types:
- shared_hosting
- reseller_hosting
- vps_plan
- custom_service

Fields:
- name
- slug
- type
- disk_limit
- bandwidth_limit
- email_limit
- database_limit
- ftp_limit
- domain_limit
- subdomain_limit
- addon_domain_limit
- parked_domain_limit
- status

---

## 3. Hosting Account / Service Management
This is a major module.

Features:
- create hosting account
- provision service
- suspend
- unsuspend
- terminate
- reset password
- change package
- change domain
- usage tracking
- resource limit tracking
- service credentials metadata
- service state history
- assigned server/node
- linked external service/provider record
- sync state from provider
- manual and automatic provisioning

Service types:
- shared hosting
- reseller hosting
- VPS
- email hosting
- future extensible service types

Fields:
- service_name
- domain
- username
- package_id
- server_id
- provider_type
- provider_reference
- provisioning_status
- status
- disk_usage
- bandwidth_usage
- metadata
- created_at
- updated_at

---

## 4. Provisioning and Automation Layer
EuPanel must support automated provisioning.

Features:
- create service from API call
- suspend service from API call
- unsuspend service from API call
- terminate service from API call
- sync usage from provider
- sync service status
- queue failed jobs
- retry logic
- job logs

Important:
My billing website will call EuPanel APIs to trigger service actions.

So build EuPanel as an **API-driven control system**.

---

## 5. DNS Management
Features:
- create zone
- delete zone
- list records
- create/update/delete records
- support:
  - A
  - AAAA
  - CNAME
  - MX
  - TXT
  - NS
  - SRV if possible
- nameserver management
- TTL
- zone validation

Tables/modules:
- dns_zones
- dns_records

---

## 6. Email Hosting Management
Features:
- create email account
- delete email account
- reset password
- set quota
- create forwarders
- autoresponders
- aliases
- mailbox usage tracking

Tables/modules:
- mail_domains
- mail_accounts
- mail_forwarders
- mail_autoresponders

---

## 7. Database Management
Features:
- create database
- delete database
- create DB user
- assign privileges
- reset password
- list databases linked to service
- remote access rule placeholders

Tables/modules:
- service_databases
- database_users
- database_permissions

---

## 8. SSL Management
Features:
- install SSL
- issue Let's Encrypt certificates
- renew SSL
- upload custom SSL
- assign SSL to domain/service
- certificate status tracking
- expiry monitoring

Tables/modules:
- ssl_certificates
- ssl_events

---

## 9. File and Web Management
Features:
- document root settings
- PHP version settings placeholder
- file manager abstraction placeholder
- cron jobs
- web config metadata
- application deployment metadata

Tables/modules:
- web_configs
- cron_jobs
- app_deployments

---

## 10. Backups
Features:
- create backup
- schedule backups
- restore backup
- list backup history
- remote storage abstraction
- per-service and per-server backups
- backup job logs

Tables/modules:
- backups
- backup_jobs
- backup_destinations

---

## 11. Monitoring and Alerts
Features:
- monitor node health
- monitor service health
- monitor disk usage
- monitor RAM
- monitor CPU
- monitor uptime
- alerting system
- incident/event logs
- threshold rules
- abuse/flag placeholders

Tables/modules:
- monitoring_metrics
- alerts
- alert_rules
- incidents
- health_checks

---

## 12. Admin and Staff Access
EuPanel is mainly for internal operations, so build secure staff/admin access.

Roles:
- super_admin
- sysadmin
- support_staff
- operations_staff

Features:
- admin login
- secure session/token handling
- permissions
- audit logs
- action history
- staff activity tracking

Use permission-based authorization, not role-only checks.

---

## 13. API Integration Layer
This is extremely important.

EuPanel must be built with provider adapters/interfaces so it can work with different backends.

Create interfaces like:
- HostingProviderInterface
- DnsProviderInterface
- MailProviderInterface
- SSLProviderInterface
- BackupProviderInterface
- MonitoringProviderInterface

Initial implementations:
- LocalLinuxHostingProvider
- PleskHostingProvider
- MockHostingProvider

Initial DNS implementations:
- LocalDnsProvider
- MockDnsProvider

The code must not tightly couple business logic to one provider.

I want a provider/adapter pattern so I can plug in Plesk or other systems later.

---

# Architectural Rules

## Backend Architecture
Use clean MVC with proper separation:
- models
- controllers
- services
- repositories if useful
- validators/request objects
- middleware
- policies/permissions
- jobs
- events
- mail
- utils/providers

Rules:
- controllers must stay thin
- business logic must stay in services
- provider logic must stay in adapters/providers
- validation must not be buried in controllers
- responses must be consistent JSON
- centralized exception handling
- pagination/filtering/search for list endpoints
- audit logging for sensitive actions
- secure credential handling
- do not expose secrets in responses

---

## Frontend Architecture
Use Next.js to build the EuPanel interface.

Frontend must include:
- admin login page
- overview dashboard
- server management pages
- package management pages
- service/account pages
- DNS pages
- email management pages
- database management pages
- SSL pages
- backup pages
- monitoring pages
- staff/role pages
- settings pages

Requirements:
- responsive SaaS-style UI
- reusable table components
- reusable form components
- sidebar layout
- role-aware navigation
- loading states
- empty states
- error states
- API client abstraction

Style direction:
- modern
- clean
- serious hosting platform look
- similar quality level to commercial hosting dashboards

---

# Database Design

Create a normalized MySQL schema for at least these tables:

- admins
- roles
- permissions
- role_permissions
- admin_roles
- servers
- server_groups
- server_metrics
- server_logs
- hosting_packages
- services
- service_status_logs
- service_usage_logs
- provider_accounts
- provisioning_jobs
- provisioning_job_logs
- dns_zones
- dns_records
- mail_domains
- mail_accounts
- mail_forwarders
- mail_autoresponders
- service_databases
- database_users
- database_permissions
- ssl_certificates
- ssl_events
- web_configs
- cron_jobs
- backups
- backup_jobs
- backup_destinations
- monitoring_metrics
- alerts
- alert_rules
- incidents
- audit_logs
- settings
- api_clients
- api_tokens
- webhooks

For each table define:
- columns
- types
- indexes
- foreign keys
- constraints
- relationship notes

---

# API Design

Create RESTful API endpoints for all major modules.

Examples:

## Auth
- POST /api/auth/login
- POST /api/auth/logout
- GET /api/auth/me

## Servers
- GET /api/servers
- POST /api/servers
- GET /api/servers/:id
- PUT /api/servers/:id
- DELETE /api/servers/:id
- POST /api/servers/:id/reboot
- GET /api/servers/:id/metrics

## Packages
- GET /api/packages
- POST /api/packages
- GET /api/packages/:id
- PUT /api/packages/:id
- DELETE /api/packages/:id

## Services
- GET /api/services
- POST /api/services
- GET /api/services/:id
- PUT /api/services/:id
- POST /api/services/:id/provision
- POST /api/services/:id/suspend
- POST /api/services/:id/unsuspend
- POST /api/services/:id/terminate
- POST /api/services/:id/reset-password
- POST /api/services/:id/sync
- GET /api/services/:id/usage

## DNS
- GET /api/dns/zones
- POST /api/dns/zones
- GET /api/dns/zones/:id
- DELETE /api/dns/zones/:id
- POST /api/dns/zones/:id/records
- PUT /api/dns/records/:id
- DELETE /api/dns/records/:id

## Email
- GET /api/mail/accounts
- POST /api/mail/accounts
- PUT /api/mail/accounts/:id
- DELETE /api/mail/accounts/:id
- POST /api/mail/accounts/:id/reset-password

## Databases
- GET /api/databases
- POST /api/databases
- DELETE /api/databases/:id
- POST /api/databases/:id/users
- POST /api/database-users/:id/reset-password

## SSL
- GET /api/ssl/certificates
- POST /api/ssl/certificates/issue
- POST /api/ssl/certificates/:id/renew
- POST /api/ssl/certificates/upload

## Backups
- GET /api/backups
- POST /api/backups
- POST /api/backups/:id/restore

## Monitoring
- GET /api/monitoring/overview
- GET /api/alerts
- POST /api/alerts/:id/resolve

## Staff
- GET /api/admins
- POST /api/admins
- GET /api/roles
- GET /api/permissions

## External Billing Integration
- POST /api/integrations/services/provision
- POST /api/integrations/services/suspend
- POST /api/integrations/services/unsuspend
- POST /api/integrations/services/terminate
- GET /api/integrations/services/:id/status
- GET /api/integrations/services/:id/usage

Improve these routes if needed, but keep the system clean.

---

# External Billing Website Integration

This is a very important requirement.

My billing website is separate from EuPanel.
That billing website will call EuPanel APIs.

So design EuPanel with:
- API clients
- API tokens
- webhook verification
- request signing if useful
- rate limiting placeholders
- internal integration endpoints
- secure service action endpoints

Billing website use cases:
- create service after payment
- suspend overdue service
- unsuspend after renewal
- terminate cancelled service
- fetch service usage
- fetch provisioning status

---

# Build Order

Build this project in phases:

1. full architecture plan
2. project folder structure
3. database schema design
4. backend scaffolding
5. auth and admin roles/permissions
6. server management
7. package management
8. service management
9. provisioning and automation
10. DNS management
11. email management
12. database management
13. SSL management
14. backups
15. monitoring and alerts
16. API integration layer
17. frontend dashboard
18. documentation and setup instructions

---

# Coding Standards

Rules:
- use clear naming
- keep code modular
- avoid giant controller classes
- avoid mixing provider logic into controllers
- use service classes
- use validators/request DTOs
- write maintainable production-minded code
- use clean response transformers/resources if useful
- centralize config
- prepare env variables cleanly
- build migration files
- build seeders for default roles and permissions
- add sample mock provider implementations
- do not leave architecture vague

---

# Output Format

For each major step:
1. explain the architectural decision briefly
2. show the folder structure
3. generate the actual code files
4. explain how the parts connect
5. continue to the next step

Do not stop at theory.
Actually build the project step by step.

---

# Final Instruction

Start now with:
1. full EuPanel architecture plan
2. backend + frontend folder structure
3. database schema
4. Flint Dart backend scaffolding
5. then continue implementing module by module

Make smart assumptions where needed, state them clearly, and optimize for long-term maintainability.