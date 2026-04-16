import 'dart:io';

/// Central application configuration loaded from environment variables.
///
/// Set these before starting the server, e.g. in a .env file loaded by
/// your process manager, or export them in your shell.
///
/// Example .env:
///   DB_HOST=127.0.0.1
///   DB_PORT=3306
///   DB_NAME=eupanel
///   DB_USER=eupanel
///   DB_PASS=secret
///   JWT_SECRET=change-me-in-production
///   PDNS_API_URL=http://localhost:8081
///   PDNS_API_KEY=pdns-secret
///   AGENT_SECRET=agent-secret
///   APP_PORT=4054
class AppConfig {
  AppConfig._();

  // ── Database ────────────────────────────────────────────────────────────
  static String get dbHost => _env('DB_HOST', '127.0.0.1');
  static int get dbPort => int.tryParse(_env('DB_PORT', '3306')) ?? 3306;
  static String get dbName => _env('DB_NAME', 'eupanel');
  static String get dbUser => _env('DB_USER', 'root');
  static String get dbPass => _env('DB_PASS', '');

  // ── JWT ─────────────────────────────────────────────────────────────────
  static String get jwtSecret => _env('JWT_SECRET', 'change-me-in-production');

  // ── PowerDNS ────────────────────────────────────────────────────────────
  static String get pdnsApiUrl => _env('PDNS_API_URL', 'http://localhost:8081');
  static String get pdnsApiKey => _env('PDNS_API_KEY', '');

  // ── Agent ───────────────────────────────────────────────────────────────
  static String get agentSecret => _env('AGENT_SECRET', '');

  // ── Server ──────────────────────────────────────────────────────────────
  static int get appPort => int.tryParse(_env('APP_PORT', '4054')) ?? 4054;

  // ── Storage ─────────────────────────────────────────────────────────────
  static String get storagePath => _env('STORAGE_PATH', 'storage');

  // ── Helpers ─────────────────────────────────────────────────────────────
  static bool get isProduction =>
      _env('APP_ENV', 'development') == 'production';

  static String _env(String key, String fallback) =>
      Platform.environment[key] ?? fallback;
}
