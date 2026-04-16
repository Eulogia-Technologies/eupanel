import 'dart:async';
import 'package:eupanel_agent/api_client.dart';
import 'package:eupanel_agent/config.dart';
import 'package:eupanel_agent/job_executor.dart';

Future<void> main() async {
  print('[agent] Eupanel Agent ${AgentConfig.version} starting');
  print('[agent] Server ID : ${AgentConfig.serverId}');
  print('[agent] Core API  : ${AgentConfig.apiUrl}');
  print('[agent] Poll every: ${AgentConfig.pollIntervalSeconds}s');

  final api = ApiClient();
  final executor = JobExecutor(api);

  // Heartbeat ticker — every 30 seconds
  Timer.periodic(const Duration(seconds: 30), (_) async {
    await api.heartbeat();
  });

  // First heartbeat immediately
  await api.heartbeat();

  // Job polling loop
  while (true) {
    try {
      final jobs = await api.fetchPendingJobs();
      for (final job in jobs) {
        // Execute concurrently — don't await so the loop keeps going
        unawaited(executor.execute(job));
      }
    } catch (e) {
      print('[agent] Poll error: $e');
    }
    await Future.delayed(Duration(seconds: AgentConfig.pollIntervalSeconds));
  }
}
