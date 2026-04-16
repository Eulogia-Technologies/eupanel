import 'dart:isolate';

import 'package:backend/models/backup_model.dart';
import 'package:backend/models/database_model.dart';
import 'package:backend/models/dns_record_model.dart';
import 'package:backend/models/dns_zone_model.dart';
import 'package:backend/models/job_model.dart';
import 'package:backend/models/mail_account_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/site_model.dart';
import 'package:backend/models/site_runtime_model.dart';
import 'package:backend/models/ssl_certificate_model.dart';
import 'package:flint_dart/schema.dart';
import 'package:backend/models/user_model.dart';

void main(_, SendPort? sendPort) {
  runTableRegistry([
    User().table,
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
  ], _, sendPort);
}
