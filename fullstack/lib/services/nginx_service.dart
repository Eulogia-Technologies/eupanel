import 'dart:io';

import 'package:backend/services/internal_command_service.dart';

/// Manages nginx directly from the Flint Dart backend.
class NginxService {
  final String sitesAvailableDir;
  final String nginxBin;
  final InternalCommandService _commands;

  /// [agentBaseUrl] and [agentSecret] are accepted for older callers.
  NginxService({
    String? agentBaseUrl,
    String? agentSecret,
    this.sitesAvailableDir = '/etc/nginx/sites-available',
    this.nginxBin = '/usr/sbin/nginx',
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<String> createVhost({
    required String domain,
    required String rootPath,
    String phpVersion = '8.3',
  }) async {
    _validateDomain(domain);

    final root = Directory(rootPath);
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    final index = File('$rootPath/index.html');
    if (!await index.exists()) {
      await index.writeAsString(
        '<!DOCTYPE html><html><head><title>$domain</title></head>'
        '<body><h1>$domain is live on EuPanel</h1></body></html>',
      );
    }

    final configPath = '$sitesAvailableDir/$domain.conf';
    await File(configPath).writeAsString(
      _buildVhost(
        domain: domain,
        rootPath: rootPath,
        phpVersion: phpVersion,
        ssl: false,
      ),
    );

    await _enableSite(domain);
    await reload();
    return configPath;
  }

  Future<void> removeVhost(String domain) async {
    _validateDomain(domain);

    await File('$sitesAvailableDir/$domain.conf').deleteIfExists();
    await Link(
            '${Directory(sitesAvailableDir).parent.path}/sites-enabled/$domain.conf')
        .deleteIfExists();

    try {
      await reload();
    } catch (e) {
      stderr.writeln('[NginxService] Reload warning after remove: $e');
    }
  }

  Future<void> reload() async {
    await _commands.run(nginxBin, ['-t']);
    await _commands.run(nginxBin, ['-s', 'reload']);
  }

  Future<String> enableSslVhost({
    required String domain,
    required String rootPath,
    String phpVersion = '8.3',
  }) async {
    _validateDomain(domain);

    final configPath = '$sitesAvailableDir/$domain.conf';
    await File(configPath).writeAsString(
      _buildVhost(
        domain: domain,
        rootPath: rootPath,
        phpVersion: phpVersion,
        ssl: true,
      ),
    );

    await _enableSite(domain);
    await reload();
    return configPath;
  }

  Future<bool> isRunning() async {
    final result = await _commands.run(
      'pgrep',
      ['-x', 'nginx'],
      throwOnError: false,
    );
    return result.succeeded;
  }

  Future<void> _enableSite(String domain) async {
    final enabledPath =
        '${Directory(sitesAvailableDir).parent.path}/sites-enabled/$domain.conf';
    final enabled = Link(enabledPath);
    await enabled.deleteIfExists();
    await enabled.create('$sitesAvailableDir/$domain.conf', recursive: true);
  }

  void _validateDomain(String domain) {
    final valid = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]{0,252}[a-zA-Z0-9]$');
    if (!valid.hasMatch(domain) || domain.contains('..')) {
      throw NginxException('Invalid domain: $domain');
    }
  }

  String _buildVhost({
    required String domain,
    required String rootPath,
    required String phpVersion,
    required bool ssl,
  }) {
    if (ssl) {
      return '''
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain www.$domain;

    root $rootPath;
    index index.php index.html;

    ssl_certificate     /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    access_log /var/log/nginx/$domain.access.log;
    error_log  /var/log/nginx/$domain.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$phpVersion-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
''';
    }

    return '''
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;

    root $rootPath;
    index index.php index.html;

    access_log /var/log/nginx/$domain.access.log;
    error_log  /var/log/nginx/$domain.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$phpVersion-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
''';
  }
}

extension _FileDeleteIfExists on FileSystemEntity {
  Future<void> deleteIfExists() async {
    if (await exists()) {
      await delete();
    }
  }
}

class NginxException implements Exception {
  final String message;
  NginxException(this.message);

  @override
  String toString() => message;
}
