import 'dart:async';
import 'dart:io';

/// Central place for running server-native commands from Flint Dart.
///
/// Keep privileged commands behind small service methods so failures are easy
/// to read in logs and command arguments are not hidden inside controller code.
class InternalCommandService {
  const InternalCommandService();

  Future<InternalCommandResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    Duration timeout = const Duration(seconds: 30),
    bool throwOnError = true,
  }) async {
    try {
      final process = Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: true,
        runInShell: false,
      );

      final result = await process.timeout(timeout);
      final commandResult = InternalCommandResult(
        executable: executable,
        arguments: arguments,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      );

      if (throwOnError && !commandResult.succeeded) {
        throw InternalCommandException(commandResult);
      }

      return commandResult;
    } on TimeoutException {
      throw InternalCommandTimeoutException(
        executable: executable,
        arguments: arguments,
        timeout: timeout,
      );
    } on ProcessException catch (e) {
      throw InternalCommandStartException(
        executable: executable,
        arguments: arguments,
        message: e.message,
      );
    }
  }

  /// Use this only when shell behavior is required, for example pipes or
  /// redirects. Prefer [run] for normal commands because argument lists are
  /// safer and easier to debug.
  Future<InternalCommandResult> shell(
    String command, {
    String? workingDirectory,
    Map<String, String>? environment,
    Duration timeout = const Duration(seconds: 30),
    bool throwOnError = true,
  }) {
    return run(
      '/bin/sh',
      ['-lc', command],
      workingDirectory: workingDirectory,
      environment: environment,
      timeout: timeout,
      throwOnError: throwOnError,
    );
  }

  /// Example equivalent of:
  ///   mysql -u root -sN -e "<query>"
  Future<String> mysqlRootQuery(
    String query, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final result = await run(
      'mysql',
      ['-u', 'root', '-sN', '-e', query],
      timeout: timeout,
    );

    return result.stdout.trim();
  }
}

class InternalCommandResult {
  final String executable;
  final List<String> arguments;
  final int exitCode;
  final String stdout;
  final String stderr;

  const InternalCommandResult({
    required this.executable,
    required this.arguments,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get succeeded => exitCode == 0;

  String get commandForLog =>
      ([executable, ...arguments]).map(_quoteForLog).join(' ');

  String get combinedOutput {
    final out = stdout.trim();
    final err = stderr.trim();
    if (out.isEmpty) return err;
    if (err.isEmpty) return out;
    return '$out\n$err';
  }

  static String _quoteForLog(String value) {
    if (value.isEmpty) return "''";
    if (!value.contains(RegExp(r'\s'))) return value;
    return "'${value.replaceAll("'", "'\\''")}'";
  }
}

class InternalCommandException implements Exception {
  final InternalCommandResult result;

  const InternalCommandException(this.result);

  @override
  String toString() {
    final output = result.combinedOutput;
    final suffix = output.isEmpty ? '' : ': $output';
    return 'Command failed (${result.exitCode}) ${result.commandForLog}$suffix';
  }
}

class InternalCommandTimeoutException implements Exception {
  final String executable;
  final List<String> arguments;
  final Duration timeout;

  const InternalCommandTimeoutException({
    required this.executable,
    required this.arguments,
    required this.timeout,
  });

  @override
  String toString() {
    final command = ([executable, ...arguments])
        .map(InternalCommandResult._quoteForLog)
        .join(' ');
    return 'Command timed out after ${timeout.inSeconds}s: $command';
  }
}

class InternalCommandStartException implements Exception {
  final String executable;
  final List<String> arguments;
  final String message;

  const InternalCommandStartException({
    required this.executable,
    required this.arguments,
    required this.message,
  });

  @override
  String toString() {
    final command = ([executable, ...arguments])
        .map(InternalCommandResult._quoteForLog)
        .join(' ');
    return 'Could not start command $command: $message';
  }
}
