import 'dart:isolate';

import 'package:backend/models/backup_model.dart';
import 'package:backend/models/git_deploy_model.dart';
import 'package:backend/models/github_token_model.dart';
import 'package:backend/models/database_model.dart';
import 'package:backend/models/dns_record_model.dart';
import 'package:backend/models/dns_zone_model.dart';
import 'package:backend/models/job_model.dart';
import 'package:backend/models/mail_account_model.dart';
import 'package:backend/models/domain_model.dart';
import 'package:backend/models/plan_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/site_model.dart';
import 'package:backend/models/site_runtime_model.dart';
import 'package:backend/models/ssl_certificate_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:flint_dart/schema.dart';
import 'package:backend/models/user_model.dart';

void main(_, SendPort? sendPort) {
  runTableRegistry([
    User().table,
    // Phase 1
    Plan().table,
    Subscription().table,
    // Phase 2
    Domain().table,
    // Infrastructure
    Server().table,
    Site().table,
    SiteRuntime().table,
    DatabaseModel().table,
    SslCertificate().table,
    DnsZone().table,
    DnsRecord().table,
    Job().table,
    Backup().table,
    MailAccount().table,
    // GitHub integration
    GithubToken().table,
    GitDeploy().table,
  ], _, sendPort);
}
