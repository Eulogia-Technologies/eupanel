import 'dart:io';

/// Agent configuration loaded from environment variables.
///
/// Required env vars:
///   AGENT_SERVER_ID   — the ID of this server in the eupanel database
///   AGENT_API_URL     — base URL of the eupanel core API (e.g. http://panel.example.com:4054)
///   AGENT_SECRET      — shared secret used to authenticate with the core (X-Agent-Secret header)
///
/// Optional:
///   AGENT_POLL_INTERVAL_SECONDS — how often to poll for new jobs (default: 5)
///   AGENT_VERSION               — version string reported in heartbeats (default: 1.0.0)
class AgentConfig {
  AgentConfig._();

  static String get serverId => _require('AGENT_SERVER_ID');
  static String get apiUrl => _require('AGENT_API_URL');
  static String get secret => _require('AGENT_SECRET');

  static int get pollIntervalSeconds =>
      int.tryParse(_env('AGENT_POLL_INTERVAL_SECONDS', '5')) ?? 5;

  static String get version => _env('AGENT_VERSION', '1.0.0');

  static String _require(String key) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env var: $key');
    }
    return value;
  }

  static String _env(String key, String fallback) =>
      Platform.environment[key] ?? fallback;
}
