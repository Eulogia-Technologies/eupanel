import 'base_job.dart';
import '../api_client.dart';

class RestartRuntimeJob extends BaseJob {
  RestartRuntimeJob(ApiClient api, String jobId, Map<String, dynamic> payload)
      : super(api, jobId, payload);

  @override
  Future<void> run() async {
    final serviceName = payload['serviceName'] as String?;
    final runtime = (payload['runtime'] as String? ?? '').toLowerCase();

    if (serviceName == null || serviceName.isEmpty) {
      await api.failJob(jobId, log: 'Missing serviceName in payload');
      return;
    }

    try {
      if (runtime == 'php') {
        // PHP-FPM — reload is safer than restart (no downtime)
        await shell('systemctl reload $serviceName || systemctl restart $serviceName');
      } else {
        await shell('systemctl restart $serviceName');
      }

      // Confirm it's running
      await shell('systemctl is-active --quiet $serviceName');

      await api.completeJob(jobId, log: 'Service $serviceName restarted');
    } catch (e) {
      await api.failJob(jobId, log: e.toString());
    }
  }
}
