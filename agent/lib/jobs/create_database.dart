import 'base_job.dart';
import '../api_client.dart';

class CreateDatabaseJob extends BaseJob {
  CreateDatabaseJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final engine = (payload['engine'] as String? ?? 'mysql').toLowerCase();
    final name = payload['name'] as String?;
    final username = payload['username'] as String?;
    final password = payload['password'] as String?;

    if (name == null || username == null || password == null) {
      await api.failJob(jobId,
          log: 'Missing name, username, or password in payload');
      return;
    }

    try {
      if (engine == 'mysql' || engine == 'mariadb') {
        await _createMysql(name, username, password);
      } else if (engine == 'postgres' || engine == 'postgresql') {
        await _createPostgres(name, username, password);
      } else {
        await api.failJob(jobId, log: 'Unsupported engine: $engine');
        return;
      }

      await api.completeJob(jobId,
          log: 'Database $name ($engine) created for user $username');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }

  Future<void> _createMysql(
      String name, String username, String password) async {
    final safe = _escape(password);
    await shell("mysql -u root -e \"CREATE DATABASE IF NOT EXISTS \\`$name\\`;\"");
    await shell("mysql -u root -e \"CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '$safe';\"");
    await shell("mysql -u root -e \"GRANT ALL PRIVILEGES ON \\`$name\\`.* TO '$username'@'localhost';\"");
    await shell("mysql -u root -e \"FLUSH PRIVILEGES;\"");
  }

  Future<void> _createPostgres(
      String name, String username, String password) async {
    final safe = _escape(password);
    await shell("sudo -u postgres psql -c \"CREATE USER $username WITH PASSWORD '$safe';\" 2>/dev/null || true");
    await shell("sudo -u postgres psql -c \"CREATE DATABASE $name OWNER $username;\" 2>/dev/null || true");
    await shell("sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE $name TO $username;\"");
  }

  String _escape(String s) => s.replaceAll("'", "''");
}
