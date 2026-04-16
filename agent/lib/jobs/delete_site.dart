import 'base_job.dart';
import '../api_client.dart';

class DeleteSiteJob extends BaseJob {
  DeleteSiteJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final domain = payload['domain'] as String?;
    if (domain == null) {
      await api.failJob(jobId, log: 'Missing domain in payload');
      return;
    }

    try {
      // Remove Nginx config and disable site
      await shell('rm -f /etc/nginx/sites-enabled/$domain.conf');
      await shell('rm -f /etc/nginx/sites-available/$domain.conf');

      // Reload Nginx
      await shell('nginx -t && systemctl reload nginx');

      // Archive web root before deleting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await shell('mkdir -p /var/backups/eupanel/deleted');
      await shell(
          'tar -czf /var/backups/eupanel/deleted/$domain-$timestamp.tar.gz '
          '/var/www/$domain 2>/dev/null || true');

      // Remove web root
      await shell('rm -rf /var/www/$domain');

      await api.completeJob(jobId, log: 'Site $domain deleted');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
