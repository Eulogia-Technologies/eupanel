import 'dart:convert';
import 'dart:io';

/// Calls the EuPanel Agent to create/delete Linux system users.
/// The agent handles all privileged operations on the server.
class SystemUserService {
  final String agentBaseUrl;
  final String agentSecret;

  SystemUserService({required this.agentBaseUrl, required this.agentSecret});

  /// Creates a Linux system user via the agent.
  /// Returns the home directory path on success.
  /// Throws [ProvisioningException] on failure.
  Future<String> create({
    required String username,
    String? phpVersion,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/system-users');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'username': username,
        'php_version': phpVersion ?? '8.3',
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 201) {
        throw ProvisioningException(
          'Agent failed to create system user "$username": '
          '${data['error'] ?? body}',
        );
      }

      return data['home_directory']?.toString() ??
          '/home/$username';
    } on SocketException catch (e) {
      throw ProvisioningException(
        'Cannot reach agent at $agentBaseUrl — is the agent running? $e',
      );
    } finally {
      client.close();
    }
  }

  /// Deletes a Linux system user via the agent.
  /// Used during rollback if later provisioning steps fail.
  Future<void> delete(String username) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/system-users/$username');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');

      final response = await request.close();
      await response.drain();

      if (response.statusCode != 200 && response.statusCode != 404) {
        throw ProvisioningException(
          'Agent failed to delete system user "$username" '
          '(HTTP ${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      // Log but don't throw during rollback — best effort cleanup
      stderr.writeln('[SystemUserService] Rollback warning: $e');
    } finally {
      client.close();
    }
  }
}

class ProvisioningException implements Exception {
  final String message;
  ProvisioningException(this.message);
  @override
  String toString() => message;
}
