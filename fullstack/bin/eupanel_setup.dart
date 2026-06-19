import 'dart:io';

import 'package:backend/services/internal_command_service.dart';
import 'package:backend/services/mysql_provisioning_service.dart';
import 'package:backend/services/nginx_service.dart';
import 'package:backend/services/phpmyadmin_service.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final command = args.first;
  final options = _parseOptions(args.skip(1));

  try {
    switch (command) {
      case 'phpmyadmin':
        final token = await const PhpMyAdminService().install();
        stdout.writeln('phpMyAdmin installed at /$token/');
        break;

      case 'mysql-create':
        await MysqlProvisioningService().createDatabaseAndUser(
          database: _required(options, 'database'),
          username: _required(options, 'username'),
          password: _required(options, 'password'),
          host: options['host'] ?? 'localhost',
        );
        stdout.writeln('MySQL database and user are ready.');
        break;

      case 'mysql-drop':
        await MysqlProvisioningService().dropDatabaseAndUser(
          database: _required(options, 'database'),
          username: _required(options, 'username'),
          host: options['host'] ?? 'localhost',
        );
        stdout.writeln('MySQL database and user removed.');
        break;

      case 'mysql-password':
        await MysqlProvisioningService().resetPassword(
          username: _required(options, 'username'),
          password: _required(options, 'password'),
          host: options['host'] ?? 'localhost',
        );
        stdout.writeln('MySQL password reset.');
        break;

      case 'mysql-query':
        final output = await MysqlProvisioningService().query(
          _required(options, 'sql'),
        );
        stdout.writeln(output);
        break;

      case 'nginx-reload':
        await NginxService().reload();
        stdout.writeln('nginx config tested and reloaded.');
        break;

      case 'run':
        final executable = _required(options, 'cmd');
        final commandArgs = options['args'] == null || options['args']!.isEmpty
            ? <String>[]
            : options['args']!.split(',');
        final result = await const InternalCommandService().run(
          executable,
          commandArgs,
        );
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        break;

      default:
        stderr.writeln('Unknown command: $command');
        _printHelp();
        exitCode = 64;
    }
  } catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}

Map<String, String> _parseOptions(Iterable<String> args) {
  final options = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) {
      throw ArgumentError('Invalid option "$arg". Use --name=value.');
    }
    final parts = arg.substring(2).split('=');
    if (parts.length < 2) {
      throw ArgumentError('Invalid option "$arg". Use --name=value.');
    }
    options[parts.first] = parts.skip(1).join('=');
  }
  return options;
}

String _required(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw ArgumentError('Missing required option --$key=value');
  }
  return value;
}

void _printHelp() {
  stdout.writeln('''
EuPanel Flint Dart setup commands

Usage:
  dart run bin/eupanel_setup.dart phpmyadmin
  dart run bin/eupanel_setup.dart mysql-create --database=site_db --username=site_user --password=secret
  dart run bin/eupanel_setup.dart mysql-password --username=site_user --password=newsecret
  dart run bin/eupanel_setup.dart mysql-drop --database=site_db --username=site_user
  dart run bin/eupanel_setup.dart mysql-query --sql="SELECT VERSION();"
  dart run bin/eupanel_setup.dart nginx-reload
  dart run bin/eupanel_setup.dart run --cmd=systemctl --args=status,nginx
''');
}
