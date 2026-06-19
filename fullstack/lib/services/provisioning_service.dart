import 'dart:io';

import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/ftp_user_service.dart';
import 'package:backend/services/system_user_service.dart';
import 'package:flint_dart/flint_dart.dart';

class ProvisioningService {
  Future<bool> provision(String subscriptionId) async {
    final sub = await Subscription().find(subscriptionId);
    if (sub == null) {
      throw ArgumentError('Subscription $subscriptionId not found.');
    }

    await sub.update(id: subscriptionId, data: {
      'provisioning_status': 'provisioning',
      'provisioning_log': null,
    });

    final systemUserSvc = SystemUserService();
    final ftpUserSvc = FtpUserService();

    String? homeDirectory;
    bool systemUserCreated = false;

    try {
      stdout.writeln(
        '[Provisioning] Creating system user: ${sub.systemUsername}',
      );
      homeDirectory = await systemUserSvc.create(username: sub.systemUsername!);
      systemUserCreated = true;

      stdout.writeln('[Provisioning] Creating FTP user: ${sub.ftpUsername}');
      final ftpCreds = await ftpUserSvc.create(
        username: sub.ftpUsername!,
        homeDirectory: homeDirectory,
      );

      await sub.update(id: subscriptionId, data: {
        'home_directory': homeDirectory,
        'ftp_password': ftpCreds.password,
        'status': 'active',
        'provisioning_status': 'success',
        'provisioning_log':
            'Provisioned at ${DateTime.now().toIso8601String()}',
      });

      stdout.writeln('[Provisioning] Subscription $subscriptionId is active.');
      return true;
    } catch (e) {
      final errorMsg = e.toString();
      stderr.writeln('[Provisioning] Failed: $errorMsg');

      if (systemUserCreated) {
        try {
          stdout.writeln('[Provisioning] Rolling back system user...');
          await systemUserSvc.delete(sub.systemUsername!);
        } catch (rollbackErr) {
          stderr.writeln('[Provisioning] Rollback warning: $rollbackErr');
        }
      }

      await sub.update(id: subscriptionId, data: {
        'status': 'pending',
        'provisioning_status': 'failed',
        'provisioning_log': errorMsg,
      });

      return false;
    }
  }

  Future<void> deprovision(String subscriptionId) async {
    final sub = await Subscription().find(subscriptionId);
    if (sub == null) return;
    if (sub.provisioningStatus != 'success') return;

    final systemUserSvc = SystemUserService();
    final ftpUserSvc = FtpUserService();

    try {
      if (sub.ftpUsername != null) await ftpUserSvc.delete(sub.ftpUsername!);
    } catch (e) {
      stderr.writeln('[Deprovisioning] FTP user removal warning: $e');
    }

    try {
      if (sub.systemUsername != null) {
        await systemUserSvc.delete(sub.systemUsername!);
      }
    } catch (e) {
      stderr.writeln('[Deprovisioning] System user removal warning: $e');
    }

    await sub.update(id: subscriptionId, data: {
      'status': 'cancelled',
      'provisioning_status': 'deprovisioned',
    });
  }
}
