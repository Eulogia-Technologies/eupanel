import 'dart:io';
import '../api_client.dart';

/// Base class for all job handlers.
abstract class BaseJob {
  final ApiClient api;
  final String jobId;
  final Map<String, dynamic> payload;

  BaseJob(this.api, this.jobId, this.payload);

  Future<void> run();

  /// Run a shell command, stream output to the job log, and throw on failure.
  Future<void> shell(String command, {String? workingDir}) async {
    await api.logJob(jobId, r'$ ' + command);

    final result = await Process.run(
      'bash',
      ['-c', command],
      workingDirectory: workingDir,
      runInShell: false,
    );

    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();

    if (stdout.isNotEmpty) await api.logJob(jobId, stdout);
    if (stderr.isNotEmpty) await api.logJob(jobId, 'STDERR: $stderr');

    if (result.exitCode != 0) {
      throw Exception('Command failed (exit ${result.exitCode}): $command');
    }
  }

  /// Write text to a file path.
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    await api.logJob(jobId, 'Wrote $path');
  }
}
