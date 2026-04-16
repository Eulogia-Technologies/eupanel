import 'dart:io';
import 'base_job.dart';
import '../api_client.dart';

class BackupSiteJob extends BaseJob {
  BackupSiteJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final siteId = payload['siteId'] as String?;
    final domain = payload['domain'] as String?;

    if (siteId == null) {
      await api.failJob(jobId, log: 'Missing siteId in payload');
      return;
    }

    final label = domain ?? siteId;
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final backupDir = '/var/backups/eupanel';
    final backupFile = '$backupDir/$label-$timestamp.tar.gz';

    try {
      await shell('mkdir -p $backupDir');

      // Backup web root
      if (domain != null) {
        await shell('tar -czf $backupFile /var/www/$domain 2>/dev/null');
      } else {
        await shell('tar -czf $backupFile /var/www 2>/dev/null');
      }

      // Get file size for reporting
      final size = await File(backupFile).length();

      await api.completeJob(jobId,
          log: 'Backup created: $backupFile (${_humanSize(size)})');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
