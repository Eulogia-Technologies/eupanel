import 'dart:io';

import 'package:backend/services/internal_command_service.dart';
import 'package:backend/services/nginx_service.dart';

class SslService {
  final String certbotBin;
  final InternalCommandService _commands;

  /// [agentBaseUrl] and [agentSecret] are accepted for older callers.
  SslService({
    String? agentBaseUrl,
    String? agentSecret,
    this.certbotBin = '/usr/bin/certbot',
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<void> issue({
    required String domain,
    required String email,
    String? rootPath,
    String phpVersion = '8.3',
  }) async {
    _validateDomain(domain);

    await _commands.run(
      certbotBin,
      [
        'certonly',
        '--nginx',
        '--non-interactive',
        '--agree-tos',
        '--email',
        email,
        '-d',
        domain,
        '-d',
        'www.$domain',
      ],
      timeout: const Duration(minutes: 5),
    );

    await NginxService(commands: _commands).enableSslVhost(
      domain: domain,
      rootPath: rootPath ?? '/var/www/$domain/public',
      phpVersion: phpVersion,
    );
  }

  Future<void> renew(String domain) async {
    _validateDomain(domain);
    await _commands.run(
      certbotBin,
      ['renew', '--cert-name', domain, '--non-interactive'],
      timeout: const Duration(minutes: 5),
    );
  }

  Future<Map<String, dynamic>> status(String domain) async {
    _validateDomain(domain);

    final certPath = '/etc/letsencrypt/live/$domain/fullchain.pem';
    if (!await File(certPath).exists()) {
      return {'domain': domain, 'status': 'none', 'expiry': null};
    }

    final result = await _commands.run(
      'openssl',
      ['x509', '-enddate', '-noout', '-in', certPath],
      throwOnError: false,
    );

    if (!result.succeeded) {
      return {'domain': domain, 'status': 'unknown', 'expiry': null};
    }

    final line = result.stdout.trim();
    final expiryText = line.contains('=') ? line.split('=').last.trim() : '';
    final expiry = _parseOpenSslDate(expiryText);
    if (expiry == null) {
      return {'domain': domain, 'status': 'unknown', 'expiry': null};
    }
    final now = DateTime.now().toUtc();

    var status = 'valid';
    if (expiry.isBefore(now)) {
      status = 'expired';
    } else if (expiry.isBefore(now.add(const Duration(days: 30)))) {
      status = 'expiring_soon';
    }

    return {
      'domain': domain,
      'status': status,
      'expiry': expiry.toIso8601String(),
    };
  }

  void _validateDomain(String domain) {
    final valid = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]{0,252}[a-zA-Z0-9]$');
    if (!valid.hasMatch(domain) || domain.contains('..')) {
      throw SslException('Invalid domain: $domain');
    }
  }

  DateTime? _parseOpenSslDate(String value) {
    final match = RegExp(
      r'^([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(\d{4})\s+GMT$',
    ).firstMatch(value);
    if (match == null) return null;

    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final month = months[match.group(1)];
    if (month == null) return null;

    return DateTime.utc(
      int.parse(match.group(6)!),
      month,
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }
}

class SslException implements Exception {
  final String message;
  SslException(this.message);

  @override
  String toString() => message;
}
