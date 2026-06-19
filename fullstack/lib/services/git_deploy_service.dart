import 'dart:io';

import 'package:backend/services/internal_command_service.dart';

class LocalGitDeployResult {
  final String log;
  final bool cloned;

  const LocalGitDeployResult({required this.log, required this.cloned});
}

class LocalGitDeployService {
  final InternalCommandService _commands;

  const LocalGitDeployService({
    InternalCommandService commands = const InternalCommandService(),
  }) : _commands = commands;

  Future<LocalGitDeployResult> deploy({
    required String repoUrl,
    required String branch,
    required String deployPath,
  }) async {
    if (repoUrl.isEmpty || branch.isEmpty || deployPath.isEmpty) {
      throw GitDeployException('repoUrl, branch, and deployPath are required.');
    }
    _validateBranch(branch);

    await Directory(File(deployPath).parent.path).create(recursive: true);

    final logs = <String>[];
    final gitDir = Directory('$deployPath/.git');
    final alreadyCloned = await gitDir.exists();

    if (!alreadyCloned) {
      logs.add('Cloning $repoUrl (branch: $branch) into $deployPath');
      final result = await _commands.run(
          'git',
          [
            'clone',
            '--branch',
            branch,
            '--single-branch',
            '--depth',
            '1',
            repoUrl,
            deployPath,
          ],
          timeout: const Duration(minutes: 5));
      if (result.combinedOutput.isNotEmpty) logs.add(result.combinedOutput);
    } else {
      logs.add('Pulling latest from origin/$branch in $deployPath');

      var result = await _commands.run(
        'git',
        ['fetch', 'origin', branch],
        workingDirectory: deployPath,
        timeout: const Duration(minutes: 3),
      );
      if (result.combinedOutput.isNotEmpty) logs.add(result.combinedOutput);

      result = await _commands.run(
        'git',
        ['checkout', branch],
        workingDirectory: deployPath,
        throwOnError: false,
      );
      if (result.combinedOutput.isNotEmpty) logs.add(result.combinedOutput);

      result = await _commands.run(
        'git',
        ['reset', '--hard', 'origin/$branch'],
        workingDirectory: deployPath,
      );
      if (result.combinedOutput.isNotEmpty) logs.add(result.combinedOutput);

      result = await _commands.run(
        'git',
        ['clean', '-fd'],
        workingDirectory: deployPath,
        throwOnError: false,
      );
      if (result.combinedOutput.isNotEmpty) logs.add(result.combinedOutput);
    }

    final chown = await _commands.run(
      'chown',
      ['-R', 'www-data:www-data', deployPath],
      throwOnError: false,
    );
    if (chown.combinedOutput.isNotEmpty) logs.add(chown.combinedOutput);

    return LocalGitDeployResult(
      log: logs.join('\n'),
      cloned: !alreadyCloned,
    );
  }

  void _validateBranch(String branch) {
    final valid = RegExp(r'^[a-zA-Z0-9._/-]{1,100}$');
    if (!valid.hasMatch(branch)) {
      throw GitDeployException('Invalid branch name: $branch');
    }
  }
}

class GitDeployException implements Exception {
  final String message;
  GitDeployException(this.message);

  @override
  String toString() => message;
}
