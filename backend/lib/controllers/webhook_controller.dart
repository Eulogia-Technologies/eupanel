import 'dart:convert';
import 'dart:io';

import 'package:backend/models/git_deploy_model.dart';
import 'package:backend/services/github_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flint_dart/flint_dart.dart';

/// Receives and verifies inbound GitHub webhook push events.
///
/// GitHub POST → POST /webhooks/github
///   Headers: X-GitHub-Event, X-Hub-Signature-256, X-GitHub-Delivery
///   Body: JSON push payload
class WebhookController extends Controller {
  GithubService get _svc => GithubService(
        clientId: Platform.environment['GITHUB_CLIENT_ID'] ?? '',
        clientSecret: Platform.environment['GITHUB_CLIENT_SECRET'] ?? '',
        panelBaseUrl: Platform.environment['PANEL_BASE_URL'] ?? 'http://localhost:4054',
      );

  /// POST /webhooks/github
  Future<Response> githubPush() async {
    try {
      final event = req.headers['x-github-event'] ?? req.headers['X-GitHub-Event'];
      if (event != 'push') {
        // Accept but ignore non-push events (ping, etc.)
        return res.json({'status': 'ok', 'message': 'Event "$event" ignored.'});
      }

      final bodyString = await req.body();
      final rawBody    = utf8.encode(bodyString);
      final signature  = req.headers['x-hub-signature-256'] ?? req.headers['X-Hub-Signature-256'] ?? '';
      final payload    = jsonDecode(bodyString) as Map<String, dynamic>;

      // Extract repo and branch from payload
      final repoFullName  = (payload['repository'] as Map?)?['full_name']?.toString() ?? '';
      final ref           = payload['ref']?.toString() ?? '';  // e.g. refs/heads/main
      final pushedBranch  = ref.replaceFirst('refs/heads/', '');
      final headCommit    = (payload['head_commit'] as Map?) ?? {};
      final commitSha     = headCommit['id']?.toString() ?? '';
      final commitMessage = headCommit['message']?.toString() ?? '';

      // Find matching deploy records
      final allDeploys = await GitDeploy().all();
      final matching = allDeploys
          .where((d) => d.repoFullName == repoFullName)
          .toList();

      if (matching.isEmpty) {
        return res.status(200).json({'status': 'ok', 'message': 'No matching deploy for $repoFullName'});
      }

      // Verify HMAC signature against each deploy's secret
      var verified = false;
      for (final deploy in matching) {
        if (_verifySignature(rawBody, deploy.webhookSecret ?? '', signature)) {
          verified = true;

          // Trigger deploy (fire-and-forget — return 200 to GitHub immediately)
          final deployId = deploy.toMap()['id'].toString();
          _svc.handlePush(
            deployId: deployId,
            commitSha: commitSha,
            commitMessage: commitMessage,
            pushedBranch: pushedBranch,
          ).catchError((e) {
            stderr.writeln('[Webhook] Deploy error for $deployId: $e');
          });
        }
      }

      if (!verified) {
        stderr.writeln('[Webhook] Signature mismatch for $repoFullName — possible forgery.');
        return res.status(403).json({'status': 'error', 'message': 'Invalid signature.'});
      }

      return res.json({'status': 'ok', 'message': 'Deploy triggered for $repoFullName @ $pushedBranch'});
    } catch (e) {
      stderr.writeln('[Webhook] Error: $e');
      // Always return 200 to GitHub so it doesn't disable the webhook
      return res.json({'status': 'error', 'message': e.toString()});
    }
  }

  // ── HMAC-SHA256 signature verification ───────────────────────────────────

  bool _verifySignature(List<int> body, String secret, String signatureHeader) {
    if (secret.isEmpty || signatureHeader.isEmpty) return false;

    try {
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(body);
      final expected = 'sha256=$digest';

      // Constant-time comparison to prevent timing attacks
      if (expected.length != signatureHeader.length) return false;
      var result = 0;
      for (var i = 0; i < expected.length; i++) {
        result |= expected.codeUnitAt(i) ^ signatureHeader.codeUnitAt(i);
      }
      return result == 0;
    } catch (_) {
      return false;
    }
  }
}
