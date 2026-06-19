import 'dart:io';
import 'dart:math';

import 'package:backend/services/internal_command_service.dart';

class PhpMyAdminService {
  final String version;
  final String installDir;
  final String tokenFile;
  final String nginxSnippetPath;
  final String phpVersion;
  final InternalCommandService _commands;

  const PhpMyAdminService({
    this.version = '5.2.1',
    this.installDir = '/var/www/phpmyadmin',
    this.tokenFile = '/etc/eupanel/pma_token',
    this.nginxSnippetPath = '/etc/nginx/snippets/eupanel-pma.conf',
    this.phpVersion = '8.3',
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<String> install() async {
    final token = await getOrCreateToken();

    if (!await Directory(installDir).exists()) {
      await _downloadAndExtract();
    }

    await _writeConfig(token);
    await _writeNginxSnippet(token);

    await _commands.run('chown', ['-R', 'www-data:www-data', installDir]);
    return token;
  }

  Future<String> getOrCreateToken() async {
    final file = File(tokenFile);
    if (await file.exists()) {
      final existing = (await file.readAsString()).trim();
      if (existing.isNotEmpty) return existing;
    }

    await Directory(file.parent.path).create(recursive: true);
    final token = 'pma_${_randomHex(10)}';
    await file.writeAsString(token);
    await _commands.run('chmod', ['600', tokenFile]);
    return token;
  }

  Future<void> _downloadAndExtract() async {
    final tarPath = '/tmp/phpmyadmin.tar.gz';
    final url =
        'https://files.phpmyadmin.net/phpMyAdmin/$version/phpMyAdmin-$version-all-languages.tar.gz';
    final extractedDir = '/var/www/phpMyAdmin-$version-all-languages';

    await _commands.run('curl', ['-fsSL', '-o', tarPath, url],
        timeout: const Duration(minutes: 2));
    await Directory('/var/www').create(recursive: true);
    await _commands.run('tar', ['-xzf', tarPath, '-C', '/var/www'],
        timeout: const Duration(minutes: 2));

    final extracted = Directory(extractedDir);
    if (!await extracted.exists()) {
      throw PhpMyAdminException(
          'phpMyAdmin archive did not extract correctly.');
    }

    await extracted.rename(installDir);
    await File(tarPath).deleteIfExists();
  }

  Future<void> _writeConfig(String token) async {
    await Directory(installDir).create(recursive: true);

    final config = '''
<?php
\$cfg['blowfish_secret'] = '${_randomHex(32)}';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type']       = 'cookie';
\$cfg['Servers'][\$i]['host']            = '127.0.0.1';
\$cfg['Servers'][\$i]['connect_type']    = 'tcp';
\$cfg['Servers'][\$i]['compress']        = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir']   = '';
\$cfg['SendErrorReports']  = 'never';
\$cfg['ShowPhpInfo']       = false;
\$cfg['ShowServerInfo']    = false;
\$cfg['ShowChgPassword']   = true;
\$cfg['PmaAbsoluteUri']    = '/$token/';
''';

    final file = File('$installDir/config.inc.php');
    await file.writeAsString(config);
    await _commands.run('chmod', ['640', file.path]);
  }

  Future<void> _writeNginxSnippet(String token) async {
    final snippet = '''
# phpMyAdmin is exposed only through this secret path.
location = /$token {
    return 301 /$token/;
}

location /$token/ {
    alias $installDir/;
    index index.php;

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$phpVersion-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)\$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location ~ ^/$token/(libraries|setup)/ {
        deny all;
    }
}
''';

    final file = File(nginxSnippetPath);
    await Directory(file.parent.path).create(recursive: true);
    await file.writeAsString(snippet);
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

extension _FileDeleteIfExists on FileSystemEntity {
  Future<void> deleteIfExists() async {
    if (await exists()) {
      await delete();
    }
  }
}

class PhpMyAdminException implements Exception {
  final String message;
  PhpMyAdminException(this.message);

  @override
  String toString() => message;
}
