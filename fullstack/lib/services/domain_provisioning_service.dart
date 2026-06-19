import 'dart:io';

import 'package:backend/models/domain_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/nginx_service.dart';
import 'package:backend/services/ssl_service.dart';
import 'package:flint_dart/flint_dart.dart';

class DomainProvisioningService {
  Future<bool> provision({
    required String domainId,
    required String adminEmail,
  }) async {
    final domainRecord = await Domain().find(domainId);
    if (domainRecord == null) {
      throw ArgumentError('Domain $domainId not found.');
    }

    final sub = await Subscription().find(domainRecord.subscriptionId!);
    if (sub == null) {
      throw ArgumentError('Subscription not found for domain $domainId.');
    }

    final nginxSvc = NginxService();
    final sslSvc = SslService();

    String nginxConfigPath;
    try {
      stdout.writeln(
        '[DomainProvisioning] Creating nginx vhost: ${domainRecord.domain}',
      );
      nginxConfigPath = await nginxSvc.createVhost(
        domain: domainRecord.domain!,
        rootPath: domainRecord.rootPath!,
      );

      await domainRecord.update(id: domainId, data: {
        'nginx_config_path': nginxConfigPath,
        'status': 'active',
        'provisioning_log': 'nginx: ok',
      });
    } catch (e) {
      stderr.writeln('[DomainProvisioning] nginx failed: $e');
      await domainRecord.update(id: domainId, data: {
        'status': 'failed',
        'provisioning_log': 'nginx failed: $e',
      });
      rethrow;
    }

    try {
      stdout.writeln(
        '[DomainProvisioning] Issuing SSL for: ${domainRecord.domain}',
      );
      await sslSvc.issue(
        domain: domainRecord.domain!,
        email: adminEmail,
        rootPath: domainRecord.rootPath,
      );

      await domainRecord.update(id: domainId, data: {
        'ssl_status': 'active',
        'provisioning_log': 'nginx: ok | ssl: ok',
      });
      return true;
    } catch (e) {
      stderr.writeln('[DomainProvisioning] SSL failed (non-fatal): $e');
      await domainRecord.update(id: domainId, data: {
        'ssl_status': 'failed',
        'provisioning_log': 'nginx: ok | ssl failed: $e',
      });
      return false;
    }
  }

  Future<void> deprovision(String domainId) async {
    final domainRecord = await Domain().find(domainId);
    if (domainRecord == null) return;

    try {
      await NginxService().removeVhost(domainRecord.domain!);
    } catch (e) {
      stderr.writeln('[DomainProvisioning] Deprovision warning: $e');
    }
  }
}
