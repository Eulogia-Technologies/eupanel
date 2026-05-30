import 'dart:convert';
import 'dart:io';

/// Calls the EuPanel Agent to manage nginx vhosts.
class NginxService {
  final String agentBaseUrl;
  final String agentSecret;

  NginxService({required this.agentBaseUrl, required this.agentSecret});

  /// Creates an nginx vhost for a domain and enables it.
  /// Returns the config file path on success.
  Future<String> createVhost({
    required String domain,
    required String rootPath,
    String phpVersion = '8.3',
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/domains');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'domain': domain,
        'root_path': rootPath,
        'php_version': phpVersion,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw NginxException(
          'Agent failed to create nginx vhost for "$domain": '
          '${data['error'] ?? body}',
        );
      }

      return '/etc/nginx/sites-available/$domain';
    } on SocketException catch (e) {
      throw NginxException('Cannot reach agent at $agentBaseUrl: $e');
    } finally {
      client.close();
    }
  }

  /// Removes the nginx vhost for a domain and reloads nginx.
  Future<void> removeVhost(String domain) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/domains/$domain');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      final response = await request.close();
      await response.drain();
      // 404 is fine — config may already be gone
    } on SocketException catch (e) {
      stderr.writeln('[NginxService] Remove warning: $e');
    } finally {
      client.close();
    }
  }

  /// Reloads nginx via the agent.
  Future<void> reload() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentBaseUrl/nginx/reload');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $agentSecret');
      request.headers.contentLength = 0;
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw NginxException('nginx reload failed: $body');
      }
    } on SocketException catch (e) {
      throw NginxException('Cannot reach agent at $agentBaseUrl: $e');
    } finally {
      client.close();
    }
  }
}

class NginxException implements Exception {
  final String message;
  NginxException(this.message);
  @override
  String toString() => message;
}
