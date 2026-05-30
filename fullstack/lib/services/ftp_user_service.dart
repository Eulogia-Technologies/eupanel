import 'dart:convert';
import 'dart:io';

import 'package:backend/services/system_user_service.dart';

/// FTP credentials returned by the agent at creation time.
/// The password is only available once — store it immediately.
class FtpCredentials {
  final String username;
  final String password;
  const FtpCredentials({required this.username, required this.password});
}

/// Calls the EuPanel Agent to create/delete FTP users.
class FtpUserService {
  final String agentBaseUrl;
  final String agentSecret;

  FtpUserService({required this.agentBaseUrl, required this.agentSecret});

  /// Creates an FTP user tied to a home directory.
  /// Returns [FtpCredentials] with the username and one-time plaintext password.
  Future<FtpCredentials> create({
    required String username,
    required String homeDirectory,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/ftp-users');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'username': username,
        'home_directory': homeDirectory,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 201) {
        throw ProvisioningException(
          'Agent failed to create FTP user "$username": '
          '${data['error'] ?? body}',
        );
      }

      return FtpCredentials(
        username: data['username']?.toString() ?? username,
        password: data['password']?.toString() ?? '',
      );
    } on SocketException catch (e) {
      throw ProvisioningException(
        'Cannot reach agent at $agentBaseUrl — is the agent running? $e',
      );
    } finally {
      client.close();
    }
  }

  /// Deletes an FTP user via the agent.
  Future<void> delete(String username) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/ftp-users/$username');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');

      final response = await request.close();
      await response.drain();

      if (response.statusCode != 200 && response.statusCode != 404) {
        throw ProvisioningException(
          'Agent failed to delete FTP user "$username" '
          '(HTTP ${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      stderr.writeln('[FtpUserService] Rollback warning: $e');
    } finally {
      client.close();
    }
  }
}
