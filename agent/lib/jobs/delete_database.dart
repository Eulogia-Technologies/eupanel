import 'base_job.dart';
import '../api_client.dart';

class DeleteDatabaseJob extends BaseJob {
  DeleteDatabaseJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final engine = (payload['engine'] as String? ?? 'mysql').toLowerCase();
    final name = payload['name'] as String?;

    if (name == null) {
      await api.failJob(jobId, log: 'Missing name in payload');
      return;
    }

    try {
      if (engine == 'mysql' || engine == 'mariadb') {
        await shell("mysql -u root -e \"DROP DATABASE IF EXISTS \\`$name\\`;\"");
      } else if (engine == 'postgres' || engine == 'postgresql') {
        await shell("sudo -u postgres psql -c \"DROP DATABASE IF EXISTS $name;\"");
      } else {
        await api.failJob(jobId, log: 'Unsupported engine: $engine');
        return;
      }

      await api.completeJob(jobId, log: 'Database $name dropped');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
