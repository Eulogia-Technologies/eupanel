import 'dart:convert';
import 'dart:io';

import 'package:flint_dart/flint_dart.dart';

const _logFile    = '/tmp/eupanel-update.log';
const _statusFile = '/tmp/eupanel-update.status';
const _lockFile   = '/tmp/eupanel-update.lock';
const _updateScript = '/opt/eupanel/update.sh';

/// Admin-only endpoints to trigger and monitor a self-update.
///
///   POST /admin/system/update        — kick off update (detached)
///   GET  /admin/system/update-status — current status + tail of log
class SystemController extends Controller {

  // ── POST /admin/system/update ───────────────────────────────────────────────
  Future<Response> startUpdate() async {
    // Admin guard
    final user = await req.user;
    if (user?['role']?.toString() != 'admin') {
      return res.status(403).json({'status': 'error', 'message': 'Admin only.'});
    }

    // Prevent concurrent updates
    if (File(_lockFile).existsSync()) {
      return res.status(409).json({
        'status': 'error',
        'message': 'Update already in progress.',
      });
    }

    if (!File(_updateScript).existsSync()) {
      return res.status(500).json({
        'status': 'error',
        'message': 'Update script not found at $_updateScript',
      });
    }

    // Clear previous log & write running status
    File(_logFile).writeAsStringSync('');
    File(_statusFile).writeAsStringSync('running');
    File(_lockFile).writeAsStringSync('${DateTime.now().toIso8601String()}\n');

    // Spawn detached — continues running even after backend restarts
    await Process.start(
      'bash',
      [
        '-c',
        'bash $_updateScript >> $_logFile 2>&1; '
        'echo \$? > $_statusFile; '
        'rm -f $_lockFile',
      ],
      mode: ProcessStartMode.detached,
    );

    return res.json({
      'status': 'started',
      'message': 'Update started. Poll /admin/system/update-status for progress.',
    });
  }

  // ── GET /admin/system/update-status ────────────────────────────────────────
  Future<Response> updateStatus() async {
    // Admin guard
    final user = await req.user;
    if (user?['role']?.toString() != 'admin') {
      return res.status(403).json({'status': 'error', 'message': 'Admin only.'});
    }

    final logF    = File(_logFile);
    final statusF = File(_statusFile);

    final log    = logF.existsSync()    ? logF.readAsStringSync()    : '';
    final status = statusF.existsSync() ? statusF.readAsStringSync().trim() : 'idle';

    // status file contains "running", or the exit-code ("0" = success, non-zero = failed)
    final state = switch (status) {
      'running' => 'running',
      '0'       => 'success',
      'idle'    => 'idle',
      _         => 'failed',
    };

    // Return last 200 lines so the response stays small
    final lines = const LineSplitter().convert(log);
    final tail  = lines.length > 200 ? lines.sublist(lines.length - 200) : lines;

    return res.json({
      'status': state,
      'log':    tail.join('\n'),
      'lines':  lines.length,
    });
  }
}
