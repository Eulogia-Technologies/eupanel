import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Thin HTTP client for talking to the Eupanel Core API.
class ApiClient {
  final String _base;
  final Map<String, String> _headers;

  ApiClient()
      : _base = AgentConfig.apiUrl.replaceAll(RegExp(r'/$'), ''),
        _headers = {
          'Content-Type': 'application/json',
          'X-Agent-Secret': AgentConfig.secret,
        };

  // ── Jobs ──────────────────────────────────────────────────────────────

  /// Fetch all pending jobs assigned to this server.
  Future<List<Map<String, dynamic>>> fetchPendingJobs() async {
    final uri = Uri.parse(
        '$_base/jobs?status=pending&serverId=${AgentConfig.serverId}');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response, 'fetchPendingJobs');
    final body = _decode(response);
    final data = body['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Claim a job (set status → running). Returns false if already claimed.
  Future<bool> claimJob(String jobId) async {
    final uri = Uri.parse('$_base/jobs/$jobId/claim');
    final response = await http.patch(uri, headers: _headers, body: '{}');
    if (response.statusCode == 409) return false; // already claimed
    _assertOk(response, 'claimJob($jobId)');
    return true;
  }

  /// Report job success with an optional log line.
  Future<void> completeJob(String jobId, {String? log}) async {
    await _updateJobStatus(jobId, 'success', log);
  }

  /// Report job failure with an optional log line.
  Future<void> failJob(String jobId, {String? log}) async {
    await _updateJobStatus(jobId, 'failed', log);
  }

  /// Append a log line to a running job without changing its status.
  Future<void> logJob(String jobId, String line) async {
    await _updateJobStatus(jobId, 'running', line);
  }

  Future<void> _updateJobStatus(
      String jobId, String status, String? logLine) async {
    final uri = Uri.parse('$_base/jobs/$jobId/status');
    final payload = jsonEncode({'status': status, 'logLine': logLine ?? ''});
    final response =
        await http.patch(uri, headers: _headers, body: payload);
    _assertOk(response, 'updateJobStatus($jobId, $status)');
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────

  Future<void> heartbeat() async {
    final uri =
        Uri.parse('$_base/servers/${AgentConfig.serverId}/heartbeat');
    final payload = jsonEncode({'agentVersion': AgentConfig.version});
    // best-effort — ignore errors
    try {
      await http.post(uri, headers: _headers, body: payload);
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  void _assertOk(http.Response response, String ctx) {
    if (response.statusCode >= 400) {
      throw StateError(
          '$ctx failed: HTTP ${response.statusCode} — ${response.body}');
    }
  }

  Map<String, dynamic> _decode(http.Response response) =>
      jsonDecode(response.body) as Map<String, dynamic>;
}
