import 'dart:convert';
import 'dart:io';

/// Calls the EuPanel Agent to issue and manage SSL certificates via certbot.
class SslService {
  final String agentBaseUrl;
  final String agentSecret;

  SslService({required this.agentBaseUrl, required this.agentSecret});

  /// Issues an SSL certificate for a domain.
  /// [email] is required by certbot for expiry notifications.
  Future<void> issue({required String domain, required String email}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/ssl/$domain/issue');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'email': email}));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        throw SslException(
          'certbot failed for "$domain": ${data['error'] ?? body}',
        );
      }
    } on SocketException catch (e) {
      throw SslException('Cannot reach agent at $agentBaseUrl: $e');
    } finally {
      client.close();
    }
  }

  /// Checks the SSL status for a domain.
  /// Returns: { status: 'valid'|'expiring_soon'|'expired'|'none', expiry: '...' }
  Future<Map<String, dynamic>> status(String domain) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/ssl/$domain/status');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) return {'status': 'none'};
      return jsonDecode(body) as Map<String, dynamic>;
    } on SocketException {
      return {'status': 'unknown'};
    } finally {
      client.close();
    }
  }
}

class SslException implements Exception {
  final String message;
  SslException(this.message);
  @override
  String toString() => message;
}
