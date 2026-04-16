import 'base_job.dart';
import '../api_client.dart';

class IssueSslJob extends BaseJob {
  IssueSslJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final domain = payload['domain'] as String?;
    if (domain == null) {
      await api.failJob(jobId, log: 'Missing domain in payload');
      return;
    }

    try {
      // Derive admin email from domain (fallback to a known address)
      final email = payload['adminEmail'] as String? ?? 'admin@$domain';

      await shell(
        'certbot --nginx '
        '-d $domain -d www.$domain '
        '--non-interactive --agree-tos '
        '-m $email '
        '--redirect',
      );

      await api.completeJob(jobId,
          log: 'SSL certificate issued for $domain via Let\'s Encrypt');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
