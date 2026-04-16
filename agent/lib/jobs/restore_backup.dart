import 'base_job.dart';
import '../api_client.dart';

class RestoreBackupJob extends BaseJob {
  RestoreBackupJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final filePath = payload['filePath'] as String?;
    final domain = payload['domain'] as String?;

    if (filePath == null) {
      await api.failJob(jobId, log: 'Missing filePath in payload');
      return;
    }

    try {
      // Restore to web root or a temp directory
      final restoreTarget = domain != null ? '/var/www/$domain' : '/var/www';

      await shell('mkdir -p $restoreTarget');
      await shell('tar -xzf $filePath -C $restoreTarget --strip-components=2');
      await shell('chown -R www-data:www-data $restoreTarget');

      await api.completeJob(jobId,
          log: 'Backup restored from $filePath to $restoreTarget');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
