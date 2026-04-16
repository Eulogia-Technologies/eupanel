import 'dart:io';

import 'package:backend/models/server_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/ftp_user_service.dart';
import 'package:backend/services/system_user_service.dart';

/// Orchestrates the full provisioning flow for a subscription.
///
/// Provisioning order:
///   1. Resolve agent connection details from the server record
///   2. Create Linux system user  (→ home directory + public_html created by agent)
///   3. Create FTP user tied to home directory
///   4. Mark subscription active
///
/// On any failure:
///   - Roll back completed steps in reverse order
///   - Mark subscription provisioning_status = 'failed'
///   - Record error in provisioning_log
///   - Never leave a partially broken subscription silently
class ProvisioningService {
  /// Provisions a subscription. Updates the subscription record in place.
  ///
  /// Returns true if provisioning succeeded, false if it failed.
  Future<bool> provision(String subscriptionId) async {
    final sub = await Subscription().find(subscriptionId);
    if (sub == null) {
      throw ArgumentError('Subscription $subscriptionId not found.');
    }

    // Mark as in-progress
    await sub.update(id: subscriptionId, data: {
      'provisioning_status': 'provisioning',
      'provisioning_log': null,
    });

    // Resolve agent for this subscription's server
    final agentUrl = await _resolveAgentUrl(sub.serverId);
    final agentSecret = await _resolveAgentSecret(sub.serverId);

    final systemUserSvc = SystemUserService(
      agentBaseUrl: agentUrl,
      agentSecret: agentSecret,
    );
    final ftpUserSvc = FtpUserService(
      agentBaseUrl: agentUrl,
      agentSecret: agentSecret,
    );

    String? homeDirectory;
    bool systemUserCreated = false;

    try {
      // ── Step 1: Create system user ──────────────────────────────────────
      stdout.writeln('[Provisioning] Creating system user: ${sub.systemUsername}');
      homeDirectory = await systemUserSvc.create(
        username: sub.systemUsername!,
      );
      systemUserCreated = true;

      // ── Step 2: Create FTP user ─────────────────────────────────────────
      stdout.writeln('[Provisioning] Creating FTP user: ${sub.ftpUsername}');
      await ftpUserSvc.create(
        username: sub.ftpUsername!,
        homeDirectory: homeDirectory,
      );

      // ── Step 3: Mark active ─────────────────────────────────────────────
      await sub.update(id: subscriptionId, data: {
        'home_directory': homeDirectory,
        'status': 'active',
        'provisioning_status': 'success',
        'provisioning_log': 'Provisioned at ${DateTime.now().toIso8601String()}',
      });

      stdout.writeln('[Provisioning] ✓ Subscription $subscriptionId is active.');
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      stderr.writeln('[Provisioning] ✗ Failed: $errorMsg');

      // ── Rollback ─────────────────────────────────────────────────────────
      if (systemUserCreated) {
        try {
          stdout.writeln('[Provisioning] Rolling back system user...');
          await systemUserSvc.delete(sub.systemUsername!);
        } catch (rollbackErr) {
          stderr.writeln('[Provisioning] Rollback warning: $rollbackErr');
        }
      }

      // Mark failed — keep record so admin can investigate
      await sub.update(id: subscriptionId, data: {
        'status': 'pending',
        'provisioning_status': 'failed',
        'provisioning_log': errorMsg,
      });

      return false;
    }
  }

  /// Deprovisions a subscription (removes system + FTP user from server).
  /// Call before deleting or cancelling a subscription.
  Future<void> deprovision(String subscriptionId) async {
    final sub = await Subscription().find(subscriptionId);
    if (sub == null) return;

    // Only deprovision if it was actually provisioned
    if (sub.provisioningStatus != 'success') return;

    final agentUrl = await _resolveAgentUrl(sub.serverId);
    final agentSecret = await _resolveAgentSecret(sub.serverId);

    final systemUserSvc = SystemUserService(agentBaseUrl: agentUrl, agentSecret: agentSecret);
    final ftpUserSvc = FtpUserService(agentBaseUrl: agentUrl, agentSecret: agentSecret);

    // Best-effort: log but don't throw
    try {
      if (sub.ftpUsername != null) await ftpUserSvc.delete(sub.ftpUsername!);
    } catch (e) {
      stderr.writeln('[Deprovisioning] FTP user removal warning: $e');
    }

    try {
      if (sub.systemUsername != null) await systemUserSvc.delete(sub.systemUsername!);
    } catch (e) {
      stderr.writeln('[Deprovisioning] System user removal warning: $e');
    }

    await sub.update(id: subscriptionId, data: {
      'status': 'cancelled',
      'provisioning_status': 'deprovisioned',
    });
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<String> _resolveAgentUrl(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        final host = server.getAttribute('host') ?? 'localhost';
        final port = server.getAttribute('agent_port') ?? '7820';
        return 'http://$host:$port';
      }
    }
    // Fallback: local agent (dev/single-server mode)
    final envUrl = Platform.environment['AGENT_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://127.0.0.1:7820';
  }

  Future<String> _resolveAgentSecret(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        final secret = server.getAttribute('agent_secret');
        if (secret != null && secret.toString().isNotEmpty) {
          return secret.toString();
        }
      }
    }
    // Fallback to env
    return Platform.environment['AGENT_SECRET'] ?? 'change-me-before-production';
  }
}
