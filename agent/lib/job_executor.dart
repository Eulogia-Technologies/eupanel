import 'api_client.dart';
import 'jobs/backup_site.dart';
import 'jobs/create_database.dart';
import 'jobs/create_mail_account.dart';
import 'jobs/create_site.dart';
import 'jobs/delete_database.dart';
import 'jobs/delete_site.dart';
import 'jobs/issue_ssl.dart';
import 'jobs/restart_runtime.dart';
import 'jobs/restore_backup.dart';

/// Dispatches a job to the appropriate handler based on its type.
class JobExecutor {
  final ApiClient _api;

  JobExecutor(this._api);

  Future<void> execute(Map<String, dynamic> job) async {
    final jobId = job['id'] as String;
    final type = job['type'] as String? ?? '';
    final payload = (job['payload'] as Map<String, dynamic>?) ?? {};

    // Claim the job — another agent instance may have grabbed it first.
    final claimed = await _api.claimJob(jobId);
    if (!claimed) return;

    print('[agent] Running job $jobId ($type)');

    try {
      switch (type) {
        case 'create_site':
          await CreateSiteJob(_api, jobId, payload).run();
        case 'delete_site':
          await DeleteSiteJob(_api, jobId, payload).run();
        case 'create_database':
          await CreateDatabaseJob(_api, jobId, payload).run();
        case 'delete_database':
          await DeleteDatabaseJob(_api, jobId, payload).run();
        case 'issue_ssl':
          await IssueSslJob(_api, jobId, payload).run();
        case 'restart_runtime':
          await RestartRuntimeJob(_api, jobId, payload).run();
        case 'backup_site':
          await BackupSiteJob(_api, jobId, payload).run();
        case 'restore_backup':
          await RestoreBackupJob(_api, jobId, payload).run();
        case 'create_mail_account':
          await CreateMailAccountJob(_api, jobId, payload).run();
        default:
          await _api.failJob(jobId,
              log: 'Unknown job type: $type');
          print('[agent] Unknown job type: $type');
      }
    } catch (e, st) {
      print('[agent] Job $jobId ($type) threw: $e\n$st');
      await _api.failJob(jobId, log: 'Unhandled error: $e');
    }
  }
}
