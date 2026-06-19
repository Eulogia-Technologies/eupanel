# Subscription-Based Hosting Login Plan

## Goal

EuPanel should work like a real hosting control panel: every hosting subscription gets its own generated EuPanel login.

If one person owns 20 hosting packages, they can have 20 separate hosting logins, one per subscription. This keeps each hosting account isolated and makes it easy for a developer, reseller, or billing system to create hosting for a client and send only that subscription's login details.

## Core Idea

There are two kinds of users involved:

- Creator user: the admin, developer, reseller, or billing integration user who creates the hosting subscription.
- Subscription user: the generated EuPanel user that logs into one specific hosting subscription.

The subscription user is created automatically from the domain.

Example:

```text
Domain: example.com

Generated panel login:
Username: examplecom
Password: generated secure password

Hosting subscription:
System user: examplecom
FTP user: examplecom_ftp
Home: /home/examplecom
```

If the generated username already exists, EuPanel should append a number:

```text
examplecom001
examplecom002
examplecom003
```

## Data Model Changes

### `subscriptions`

Add:

```text
created_by_user_id
  The admin, developer, reseller, or integration user that created the subscription.

primary_domain
  The domain used to generate the subscription login and first website.

panel_username
  The generated EuPanel login username for this subscription.
```

Keep:

```text
user_id
  The generated subscription user who owns/logs into this one hosting account.

plan_id
server_id
system_username
ftp_username
ftp_password
home_directory
status
provisioning_status
provisioning_log
```

Do not store the generated panel password in plaintext long term. Return it once in the API response.

### `users`

Use the existing `users` table.

For generated subscription users:

```text
name: example.com
email: optional contact email or generated fallback
password: hashed generated password
role: customer
```

## Create Subscription Flow

Request:

```json
{
  "plan_id": "PLAN_ID",
  "domain": "example.com",
  "contact_email": "client@example.com"
}
```

Flow:

1. Validate the authenticated creator user.
2. Validate `plan_id`.
3. Validate `domain`.
4. Generate a unique panel username from the domain.
5. Generate a secure panel password.
6. Create the subscription user in `users`.
7. Create the subscription record:

```text
user_id = generated subscription user id
created_by_user_id = authenticated creator user id
primary_domain = example.com
panel_username = examplecom
system_username = examplecom
ftp_username = examplecom_ftp
home_directory = /home/examplecom
status = pending
provisioning_status = pending
```

8. Provision the hosting account:

```text
Linux system user
public_html directory
FTP user
FTP password
```

9. Create the domain record:

```text
subscription_id = created subscription id
domain = example.com
root_path = /home/examplecom/public_html
```

10. Provision the domain:

```text
nginx vhost
SSL certificate
```

11. Return credentials once.

Response:

```json
{
  "status": "success",
  "data": {
    "subscription": {},
    "domain": {},
    "panel_login": {
      "url": "https://panel.example.com",
      "username": "examplecom",
      "password": "GeneratedPanelPassword"
    },
    "ftp": {
      "username": "examplecom_ftp",
      "password": "GeneratedFtpPassword",
      "host": "example.com"
    }
  }
}
```

## Login And Permissions

### Generated Subscription User

When a generated subscription user logs in, they should only see:

```text
subscriptions.user_id = current_user.id
```

They should not see other subscriptions owned by the same billing customer, developer, or reseller.

### Developer Or Reseller

When a developer or reseller logs in, they should see subscriptions they created:

```text
subscriptions.created_by_user_id = current_user.id
```

### Admin

Admin can see all subscriptions.

## Billing App Integration

EuCloudHost billing should stay responsible for:

```text
checkout
payments
invoices
wallet
billing customer profile
renewals
suspension decisions
```

EuPanel should stay responsible for:

```text
hosting login generation
subscription provisioning
domain provisioning
nginx
SSL
FTP
database/server operations
```

Billing app request:

```json
{
  "plan_id": "PLAN_ID",
  "domain": "example.com",
  "contact_email": "client@example.com"
}
```

EuPanel response includes the generated credentials. Billing can display or email them to the client.

## Why This Is Better

- Each hosting account is isolated.
- A customer can have many hosting packages with separate logins.
- A developer can create hosting for clients without exposing all their subscriptions.
- Billing and hosting stay separated.
- EuPanel behaves like a real hosting control panel.

## Implementation Steps

1. Done: Add `created_by_user_id`, `primary_domain`, and `panel_username` to the `Subscription` model.
2. Done: Add `username` to the `User` model.
3. Done: Create a `HostingUsernameService` that generates safe unique usernames from domains.
4. Done: Create a secure password generator service.
5. Done: Change subscription creation to require `domain`.
6. Done: Create the generated `User` during subscription creation.
7. Done: Store the generated user as `subscriptions.user_id`.
8. Done: Store the creator as `subscriptions.created_by_user_id`.
9. Done: Provision system user and FTP user from the generated username.
10. Done: Automatically create and provision the domain after subscription provisioning succeeds.
11. Done: Return panel and FTP credentials once in the API response.
12. Done: Update list/show permission logic for generated customer, creator/reseller, and admin views.
13. Done: Update the UI subscription form to require a domain and show generated credentials after creation.
14. Done: Update login so generated accounts can sign in with username or existing users can sign in with email.
15. Next: Update billing API documentation for EuCloudHost.
16. Next: Add a migration/backfill path for existing production databases if Flint does not auto-sync new columns in the target deployment.
