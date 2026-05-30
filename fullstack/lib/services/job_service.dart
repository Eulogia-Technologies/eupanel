import 'package:backend/models/job_model.dart';
import 'package:flint_dart/flint_dart.dart';

class JobService {
  static Future<Job?> enqueue({
    required String type,
    String? targetType,
    String? targetId,
    String? serverId,
    Map<String, dynamic>? payload,
  }) async {
    return Job().create({
      'type': type,
      'status': 'pending',
      'targetType': targetType,
      'targetId': targetId,
      'serverId': serverId,
      'payload': payload ?? <String, dynamic>{},
      'logs': '',
    });
  }

  static Future<Job?> setStatus({
    required String jobId,
    required String status,
    String? logLine,
  }) async {
    final job = await Job().find(jobId);
    if (job == null) return null;

    final currentLogs = (job.getAttribute<String>('logs') ?? '').trim();
    final nextLogs = logLine == null || logLine.isEmpty
        ? currentLogs
        : [currentLogs, logLine].where((entry) => entry.isNotEmpty).join('\n');

    return job.update(id: jobId, data: {'status': status, 'logs': nextLogs});
  }
}
