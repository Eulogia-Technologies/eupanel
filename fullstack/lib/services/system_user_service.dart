import 'dart:io';

import 'package:backend/services/internal_command_service.dart';

class SystemUserService {
  final InternalCommandService _commands;

  /// [agentBaseUrl] and [agentSecret] are accepted for older callers.
  SystemUserService({
    String? agentBaseUrl,
    String? agentSecret,
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<String> create({
    required String username,
    String? phpVersion,
  }) async {
    _validateUsername(username);

    final homeDir = '/home/$username';

    await _commands.run('useradd', [
      '--create-home',
      '--home-dir',
      homeDir,
      '--shell',
      '/usr/sbin/nologin',
      '--comment',
      'EuPanel hosting account',
      username,
    ]);

    try {
      final publicHtml = Directory('$homeDir/public_html');
      await publicHtml.create(recursive: true);
      await _commands.run('chown', ['-R', '$username:$username', homeDir]);

      final index = File('${publicHtml.path}/index.html');
      if (!await index.exists()) {
        await index.writeAsString(
          '<!DOCTYPE html><html><head><title>$username</title></head>'
          '<body><p>Your hosting account is ready.</p></body></html>',
        );
      }

      return homeDir;
    } catch (e) {
      await delete(username);
      throw ProvisioningException(
          'Failed to prepare system user "$username": $e');
    }
  }

  Future<void> delete(String username) async {
    _validateUsername(username);

    final result = await _commands.run(
      'userdel',
      ['--remove', username],
      throwOnError: false,
    );

    // userdel exit code 6 means the user does not exist.
    if (result.exitCode != 0 && result.exitCode != 6) {
      throw ProvisioningException(
        'Failed to delete system user "$username": ${result.combinedOutput}',
      );
    }
  }

  Future<bool> exists(String username) async {
    _validateUsername(username);
    final result = await _commands.run('id', [username], throwOnError: false);
    return result.succeeded;
  }

  void _validateUsername(String username) {
    final valid = RegExp(r'^[a-z][a-z0-9_]{0,31}$');
    if (!valid.hasMatch(username)) {
      throw ProvisioningException(
        'Invalid username "$username". Use lowercase letters, numbers, and underscores; start with a letter.',
      );
    }
  }
}

class ProvisioningException implements Exception {
  final String message;
  ProvisioningException(this.message);

  @override
  String toString() => message;
}
