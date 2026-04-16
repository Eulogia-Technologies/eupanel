import 'dart:io';

import 'package:backend/models/domain_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/nginx_service.dart';
import 'package:backend/services/ssl_service.dart';

/// Orchestrates the full domain provisioning flow:
///   1. Create nginx vhost via agent
///   2. Issue SSL certificate via certbot
///   3. Update domain status accordingly
///
/// Designed to be called after the domain record is created.
class DomainProvisioningService {
  /// Provisions a domain: nginx vhost + SSL.
  ///
  /// [domainId]     — the domain record id
  /// [adminEmail]   — used for certbot registration
  ///
  /// Returns true on full success (nginx + SSL).
  /// Returns false if nginx succeeded but SSL failed — domain stays live on HTTP.
  /// Throws if nginx itself fails — domain record is marked failed.
  Future<bool> provision({
    required String domainId,
    required String adminEmail,
  }) async {
    final domainRecord = await Domain().find(domainId);
    if (domainRecord == null) throw ArgumentError('Domain $domainId not found.');

    final sub = await Subscription().find(domainRecord.subscriptionId!);
    if (sub == null) throw ArgumentError('Subscription not found for domain $domainId.');

    final agentUrl = await _resolveAgentUrl(sub.serverId);
    final agentSecret = await _resolveAgentSecret(sub.serverId);

    final nginxSvc = NginxService(agentBaseUrl: agentUrl, agentSecret: agentSecret);
    final sslSvc = SslService(agentBaseUrl: agentUrl, agentSecret: agentSecret);

    // ── Step 1: Nginx vhost ───────────────────────────────────────────────────
    String nginxConfigPath;
    try {
      stdout.writeln('[DomainProvisioning] Creating nginx vhost: ${domainRecord.domain}');
      nginxConfigPath = await nginxSvc.createVhost(
        domain: domainRecord.domain!,
        rootPath: domainRecord.rootPath!,
      );

      await domainRecord.update(id: domainId, data: {
        'nginx_config_path': nginxConfigPath,
        'status': 'active',
        'provisioning_log': 'nginx: ok',
      });

      stdout.writeln('[DomainProvisioning] ✓ nginx vhost created');
    } catch (e) {
      stderr.writeln('[DomainProvisioning] ✗ nginx failed: $e');
      await domainRecord.update(id: domainId, data: {
        'status': 'failed',
        'provisioning_log': 'nginx failed: $e',
      });
      rethrow;
    }

    // ── Step 2: SSL certificate ───────────────────────────────────────────────
    try {
      stdout.writeln('[DomainProvisioning] Issuing SSL for: ${domainRecord.domain}');
      await sslSvc.issue(domain: domainRecord.domain!, email: adminEmail);

      await domainRecord.update(id: domainId, data: {
        'ssl_status': 'active',
        'provisioning_log': 'nginx: ok | ssl: ok',
      });

      stdout.writeln('[DomainProvisioning] ✓ SSL issued');
      return true;
    } catch (e) {
      // SSL failure is non-fatal — domain is still live on HTTP
      stderr.writeln('[DomainProvisioning] SSL failed (non-fatal): $e');
      await domainRecord.update(id: domainId, data: {
        'ssl_status': 'failed',
        'provisioning_log': 'nginx: ok | ssl failed: $e',
      });
      return false;
    }
  }

  /// Removes nginx config for a domain via the agent.
  Future<void> deprovision(String domainId) async {
    final domainRecord = await Domain().find(domainId);
    if (domainRecord == null) return;

    final sub = await Subscription().find(domainRecord.subscriptionId!);
    final agentUrl = await _resolveAgentUrl(sub?.serverId);
    final agentSecret = await _resolveAgentSecret(sub?.serverId);

    final nginxSvc = NginxService(agentBaseUrl: agentUrl, agentSecret: agentSecret);
    try {
      await nginxSvc.removeVhost(domainRecord.domain!);
    } catch (e) {
      stderr.writeln('[DomainProvisioning] Deprovision warning: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _resolveAgentUrl(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        final host = server.getAttribute('host') ?? 'localhost';
        final port = server.getAttribute('agent_port') ?? '7820';
        return 'http://$host:$port';
      }
    }
    final envUrl = Platform.environment['AGENT_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://127.0.0.1:7820';
  }

  Future<String> _resolveAgentSecret(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        final secret = server.getAttribute('agent_secret');
        if (secret != null && secret.toString().isNotEmpty) return secret.toString();
      }
    }
    return Platform.environment['AGENT_SECRET'] ?? 'change-me-before-production';
  }
}
