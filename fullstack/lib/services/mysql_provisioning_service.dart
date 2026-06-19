import 'package:backend/services/internal_command_service.dart';

class MysqlProvisioningService {
  final InternalCommandService _commands;

  const MysqlProvisioningService({
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<void> createDatabaseAndUser({
    required String database,
    required String username,
    required String password,
    String host = 'localhost',
  }) async {
    _validateIdentifier(database, 'database');
    _validateIdentifier(username, 'username');
    _validateHost(host);

    final escapedPassword = _sqlString(password);
    final escapedHost = _sqlString(host);

    await _commands.mysqlRootQuery('''
CREATE DATABASE IF NOT EXISTS `${_escapeIdentifier(database)}`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE OR REPLACE USER `${_escapeIdentifier(username)}`@$escapedHost
  IDENTIFIED BY $escapedPassword;
GRANT ALL PRIVILEGES ON `${_escapeIdentifier(database)}`.*
  TO `${_escapeIdentifier(username)}`@$escapedHost;
FLUSH PRIVILEGES;
''');
  }

  Future<void> resetPassword({
    required String username,
    required String password,
    String host = 'localhost',
  }) async {
    _validateIdentifier(username, 'username');
    _validateHost(host);

    await _commands.mysqlRootQuery('''
ALTER USER `${_escapeIdentifier(username)}`@${_sqlString(host)}
  IDENTIFIED BY ${_sqlString(password)};
FLUSH PRIVILEGES;
''');
  }

  Future<void> dropDatabaseAndUser({
    required String database,
    required String username,
    String host = 'localhost',
  }) async {
    _validateIdentifier(database, 'database');
    _validateIdentifier(username, 'username');
    _validateHost(host);

    await _commands.mysqlRootQuery('''
DROP DATABASE IF EXISTS `${_escapeIdentifier(database)}`;
DROP USER IF EXISTS `${_escapeIdentifier(username)}`@${_sqlString(host)};
FLUSH PRIVILEGES;
''');
  }

  Future<String> query(String sql) => _commands.mysqlRootQuery(sql);

  void _validateIdentifier(String value, String label) {
    final valid = RegExp(r'^[A-Za-z0-9_]{1,64}$');
    if (!valid.hasMatch(value)) {
      throw MysqlProvisioningException(
        'Invalid MySQL $label "$value". Use letters, numbers, and underscores only.',
      );
    }
  }

  void _validateHost(String value) {
    final valid = RegExp(r'^[A-Za-z0-9_.%:-]{1,255}$');
    if (!valid.hasMatch(value)) {
      throw MysqlProvisioningException('Invalid MySQL host "$value".');
    }
  }

  String _escapeIdentifier(String value) => value.replaceAll('`', '``');

  String _sqlString(String value) => "'${value.replaceAll("'", "''")}'";
}

class MysqlProvisioningException implements Exception {
  final String message;
  MysqlProvisioningException(this.message);

  @override
  String toString() => message;
}
