import 'dart:io';
import 'dart:math';

import 'package:backend/services/internal_command_service.dart';
import 'package:backend/services/system_user_service.dart';

class FtpCredentials {
  final String username;
  final String password;

  const FtpCredentials({required this.username, required this.password});
}

class FtpUserService {
  static const String _vsftpdUserDir = '/etc/vsftpd/users';
  static const String _vsftpdUserFile = '/etc/vsftpd/virtual_users.txt';
  static const String _vsftpdDbFile = '/etc/vsftpd/virtual_users.db';

  final InternalCommandService _commands;

  /// [agentBaseUrl] and [agentSecret] are accepted for older callers.
  FtpUserService({
    String? agentBaseUrl,
    String? agentSecret,
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<FtpCredentials> create({
    required String username,
    required String homeDirectory,
  }) async {
    _validateUsername(username);

    final vsftpdCheck =
        await _commands.run('which', ['vsftpd'], throwOnError: false);
    if (!vsftpdCheck.succeeded) {
      throw ProvisioningException(
          'vsftpd is not installed. Run: apt install vsftpd');
    }

    final password = _randomHex(12);
    await Directory(_vsftpdUserDir).create(recursive: true);

    final confPath = '$_vsftpdUserDir/$username.conf';
    await File(confPath).writeAsString('''
local_root=$homeDirectory
write_enable=YES
download_enable=YES
''');
    await _commands.run('chmod', ['600', confPath]);

    try {
      await _addVirtualUser(username, password);
      await _reloadVsftpd();
    } catch (e) {
      await File(confPath).deleteIfExists();
      rethrow;
    }

    return FtpCredentials(username: username, password: password);
  }

  Future<void> delete(String username) async {
    _validateUsername(username);

    await File('$_vsftpdUserDir/$username.conf').deleteIfExists();
    await Directory('$_vsftpdUserDir/$username').deleteIfExists();
    await _removeVirtualUser(username);
    await _reloadVsftpd();
  }

  Future<void> _addVirtualUser(String username, String password) async {
    await Directory(File(_vsftpdUserFile).parent.path).create(recursive: true);
    final lines = await _readVirtualUserLines();
    final filtered = _withoutUser(lines, username)
      ..addAll([username, password]);

    await File(_vsftpdUserFile).writeAsString('${filtered.join('\n')}\n');
    await _commands.run('chmod', ['600', _vsftpdUserFile]);
    await _rebuildVirtualUserDb();
  }

  Future<void> _removeVirtualUser(String username) async {
    final lines = await _readVirtualUserLines();
    final filtered = _withoutUser(lines, username);
    await File(_vsftpdUserFile).writeAsString('${filtered.join('\n')}\n');
    await _commands.run('chmod', ['600', _vsftpdUserFile], throwOnError: false);
    await _rebuildVirtualUserDb(throwOnError: false);
  }

  Future<List<String>> _readVirtualUserLines() async {
    final file = File(_vsftpdUserFile);
    if (!await file.exists()) return <String>[];
    return (await file.readAsString())
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _withoutUser(List<String> lines, String username) {
    final filtered = <String>[];
    var skipNext = false;

    for (final line in lines) {
      if (skipNext) {
        skipNext = false;
        continue;
      }
      if (line == username) {
        skipNext = true;
        continue;
      }
      filtered.add(line);
    }

    return filtered;
  }

  Future<void> _rebuildVirtualUserDb({bool throwOnError = true}) async {
    final first = await _commands.run(
      'db_load',
      ['-T', '-t', 'hash', '-f', _vsftpdUserFile, _vsftpdDbFile],
      throwOnError: false,
    );
    if (first.succeeded) return;

    final second = await _commands.run(
      'db5.3_load',
      ['-T', '-t', 'hash', '-f', _vsftpdUserFile, _vsftpdDbFile],
      throwOnError: false,
    );

    if (throwOnError && !second.succeeded) {
      throw ProvisioningException(
        'Failed to rebuild vsftpd user database: ${first.combinedOutput} ${second.combinedOutput}',
      );
    }
  }

  Future<void> _reloadVsftpd() async {
    await _commands.run(
      'systemctl',
      ['reload-or-restart', 'vsftpd'],
      throwOnError: false,
    );
  }

  void _validateUsername(String username) {
    final valid = RegExp(r'^[a-z0-9_]{1,64}$');
    if (!valid.hasMatch(username)) {
      throw ProvisioningException(
        'Invalid FTP username "$username". Use lowercase letters, numbers, and underscores only.',
      );
    }
  }

  String _randomHex(int bytes) {
    final random = Random.secure();
    const chars = '0123456789abcdef';
    return List.generate(bytes, (_) {
      final value = random.nextInt(256);
      return '${chars[value >> 4]}${chars[value & 15]}';
    }).join();
  }
}

extension _DeleteIfExists on FileSystemEntity {
  Future<void> deleteIfExists() async {
    if (await exists()) {
      await delete(recursive: true);
    }
  }
}
