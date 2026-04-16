import 'dart:convert';
import 'dart:io';

import 'package:backend/models/git_deploy_model.dart';
import 'package:backend/models/github_token_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:flint_dart/flint_dart.dart';

/// Handles all GitHub API interactions:
///   - OAuth token exchange
///   - Listing repos
///   - Creating / deleting webhooks
///   - Triggering deploys via the eupanel-agent
class GithubService {
  final String clientId;
  final String clientSecret;
  final String panelBaseUrl; // e.g. https://panel.example.com

  GithubService({
    required this.clientId,
    required this.clientSecret,
    required this.panelBaseUrl,
  });

  // ── OAuth ──────────────────────────────────────────────────────────────────

  /// Returns the GitHub OAuth authorisation URL to redirect the user to.
  String authorizeUrl(String state) {
    final params = {
      'client_id': clientId,
      'redirect_uri': '$panelBaseUrl/api/github/callback',
      'scope': 'repo,user:email',
      'state': state,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://github.com/login/oauth/authorize?$query';
  }

  /// Exchanges an OAuth code for an access token.
  Future<String> exchangeCode(String code) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://github.com/login/oauth/access_token');
      final req = await client.postUrl(uri);
      req.headers.set('Accept', 'application/json');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
      }));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['access_token'] == null) {
        throw ValidationException({'github': ['GitHub OAuth failed: ${data['error_description'] ?? data['error']}']});
      }
      return data['access_token'].toString();
    } finally {
      client.close();
    }
  }

  /// Fetches the authenticated GitHub user's profile.
  Future<Map<String, dynamic>> getGithubUser(String accessToken) async {
    return await _githubGet('/user', accessToken);
  }

  // ── Repositories ──────────────────────────────────────────────────────────

  /// Lists all repos the token has access to (user + org repos).
  Future<List<Map<String, dynamic>>> listRepos(String accessToken) async {
    final repos = <Map<String, dynamic>>[];
    var page = 1;

    while (true) {
      final data = await _githubGet(
        '/user/repos?per_page=100&page=$page&sort=updated&affiliation=owner,collaborator',
        accessToken,
      );
      final batch = (data as List).cast<Map<String, dynamic>>();
      if (batch.isEmpty) break;
      repos.addAll(batch.map((r) => {
            'id': r['id'],
            'full_name': r['full_name'],
            'name': r['name'],
            'private': r['private'],
            'default_branch': r['default_branch'] ?? 'main',
            'clone_url': r['clone_url'],
            'html_url': r['html_url'],
            'description': r['description'],
            'updated_at': r['updated_at'],
          }));
      if (batch.length < 100) break;
      page++;
    }

    return repos;
  }

  // ── Webhooks ──────────────────────────────────────────────────────────────

  /// Registers a push webhook on the given repo. Returns the webhook ID.
  Future<String> createWebhook({
    required String repoFullName,
    required String accessToken,
    required String secret,
  }) async {
    final webhookUrl = '$panelBaseUrl/api/webhooks/github';
    final data = await _githubPost(
      '/repos/$repoFullName/hooks',
      accessToken,
      {
        'name': 'web',
        'active': true,
        'events': ['push'],
        'config': {
          'url': webhookUrl,
          'content_type': 'json',
          'secret': secret,
          'insecure_ssl': '0',
        },
      },
    );
    return data['id'].toString();
  }

  /// Removes a webhook from GitHub when a deploy is disconnected.
  Future<void> deleteWebhook({
    required String repoFullName,
    required String webhookId,
    required String accessToken,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.github.com/repos/$repoFullName/hooks/$webhookId');
      final req = await client.deleteUrl(uri);
      req.headers.set('Authorization', 'Bearer $accessToken');
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('X-GitHub-Api-Version', '2022-11-28');
      req.headers.set('User-Agent', 'EuPanel');
      await req.close();
    } finally {
      client.close();
    }
  }

  // ── Deploy ────────────────────────────────────────────────────────────────

  /// Creates a new git deploy link and registers the GitHub webhook.
  Future<Map<String, dynamic>> createDeploy({
    required String userId,
    required String subscriptionId,
    required String repoFullName,
    required String branch,
    String? domainId,
  }) async {
    // 1. Subscription must exist and belong to user
    final sub = await Subscription().find(subscriptionId);
    if (sub == null || sub.userId != userId) {
      throw NotFoundException(message: 'Subscription not found.');
    }
    if (sub.status != 'active') {
      throw ValidationException({'subscription_id': ['Subscription must be active before linking a repo.']});
    }

    // 2. Get GitHub token for this user
    final tokens = await GithubToken().whereSimple('user_id', userId);
    if (tokens.isEmpty) {
      throw ValidationException({'github': ['Connect your GitHub account first.']});
    }
    final token = tokens.first;
    final accessToken = token.accessToken!;

    // 3. Deploy path = subscription's public_html
    final deployPath = '${sub.homeDirectory ?? '/home/${sub.systemUsername}'}/public_html';

    // 4. Generate webhook secret
    final webhookSecret = _generateSecret();

    // 5. Get the clone URL from GitHub
    final repos = await listRepos(accessToken);
    final repo = repos.firstWhere(
      (r) => r['full_name'] == repoFullName,
      orElse: () => throw NotFoundException(message: 'Repository "$repoFullName" not found.'),
    );

    // 6. Register webhook on GitHub
    final webhookId = await createWebhook(
      repoFullName: repoFullName,
      accessToken: accessToken,
      secret: webhookSecret,
    );

    // 7. Create deploy record
    final deploy = await GitDeploy().create({
      'subscription_id': subscriptionId,
      'domain_id': domainId,
      'user_id': userId,
      'repo_full_name': repoFullName,
      'repo_url': repo['clone_url'],
      'branch': branch,
      'deploy_path': deployPath,
      'webhook_secret': webhookSecret,
      'webhook_id': webhookId,
      'deploy_status': 'idle',
    });

    if (deploy == null) throw Exception('Failed to create deploy record.');

    // 8. Run initial deploy immediately
    final deployId = deploy.toMap()['id'].toString();
    _runDeploy(deployId, sub.serverId).catchError((e) {
      stderr.writeln('[GitDeploy] Initial deploy warning: $e');
    });

    return deploy.toMap();
  }

  /// Deletes a deploy link and removes the GitHub webhook.
  Future<void> deleteDeploy(String deployId, String userId) async {
    final deploy = await GitDeploy().find(deployId);
    if (deploy == null || deploy.userId != userId) {
      throw NotFoundException(message: 'Deploy not found.');
    }

    // Remove webhook from GitHub (best-effort)
    if (deploy.webhookId != null) {
      final tokens = await GithubToken().whereSimple('user_id', userId);
      if (tokens.isNotEmpty) {
        try {
          await deleteWebhook(
            repoFullName: deploy.repoFullName!,
            webhookId: deploy.webhookId!,
            accessToken: tokens.first.accessToken!,
          );
        } catch (e) {
          stderr.writeln('[GitDeploy] Webhook cleanup warning: $e');
        }
      }
    }

    await deploy.delete(deployId);
  }

  /// Called by the webhook controller when GitHub fires a push event.
  Future<void> handlePush({
    required String deployId,
    required String commitSha,
    required String commitMessage,
    required String pushedBranch,
  }) async {
    final deploy = await GitDeploy().find(deployId);
    if (deploy == null) return;

    // Only deploy if push is on the tracked branch
    final trackedBranch = deploy.branch ?? 'main';
    if (pushedBranch != trackedBranch) {
      stdout.writeln('[GitDeploy] Skipping push on "$pushedBranch" (tracking "$trackedBranch")');
      return;
    }

    // Save commit info + mark deploying
    await deploy.update(id: deployId, data: {
      'deploy_status': 'deploying',
      'last_commit_sha': commitSha,
      'last_commit_msg': commitMessage.length > 497
          ? '${commitMessage.substring(0, 497)}…'
          : commitMessage,
    });

    // Get server for this subscription
    final sub = await Subscription().find(deploy.subscriptionId!);
    await _runDeploy(deployId, sub?.serverId);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Calls the agent to git clone / pull the repo into deploy_path.
  Future<void> _runDeploy(String deployId, String? serverId) async {
    final deploy = await GitDeploy().find(deployId);
    if (deploy == null) return;

    final agentUrl = await _resolveAgentUrl(serverId);
    final agentSecret = await _resolveAgentSecret(serverId);

    final client = HttpClient();
    try {
      final uri = Uri.parse('$agentUrl/git/deploy');
      final req = await client.postUrl(uri);
      req.headers.set('Authorization', 'Bearer $agentSecret');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'repo_url': deploy.repoUrl,
        'branch': deploy.branch ?? 'main',
        'deploy_path': deploy.deployPath,
      }));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (res.statusCode != 200) {
        throw Exception(data['error'] ?? 'Agent deploy failed');
      }

      await deploy.update(id: deployId, data: {
        'deploy_status': 'success',
        'last_deployed_at': DateTime.now().toIso8601String(),
        'deploy_log': data['log']?.toString(),
      });
    } catch (e) {
      await deploy.update(id: deployId, data: {
        'deploy_status': 'failed',
        'deploy_log': e.toString(),
      });
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<String> _resolveAgentUrl(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        return 'http://${server.host}:${server.agentPort ?? '7820'}';
      }
    }
    return Platform.environment['AGENT_BASE_URL'] ?? 'http://127.0.0.1:7820';
  }

  Future<String> _resolveAgentSecret(String? serverId) async {
    if (serverId != null) {
      final server = await Server().find(serverId);
      if (server != null) {
        final s = server.agentSecret;
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return Platform.environment['AGENT_SECRET'] ?? 'change-me-before-production';
  }

  String _generateSecret() {
    final bytes = List.generate(32, (_) => (DateTime.now().microsecondsSinceEpoch + _.hashCode) & 0xFF);
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ── GitHub HTTP helpers ───────────────────────────────────────────────────

  Future<dynamic> _githubGet(String path, String token) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.github.com$path');
      final req = await client.getUrl(uri);
      req.headers.set('Authorization', 'Bearer $token');
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('X-GitHub-Api-Version', '2022-11-28');
      req.headers.set('User-Agent', 'EuPanel');

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode != 200) {
        final err = jsonDecode(body);
        throw Exception('GitHub API error: ${err['message']}');
      }
      return jsonDecode(body);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _githubPost(String path, String token, Map<String, dynamic> payload) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.github.com$path');
      final req = await client.postUrl(uri);
      req.headers.set('Authorization', 'Bearer $token');
      req.headers.set('Accept', 'application/vnd.github+json');
      req.headers.set('X-GitHub-Api-Version', '2022-11-28');
      req.headers.set('User-Agent', 'EuPanel');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(payload));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('GitHub API error: ${data['message']}');
      }
      return data;
    } finally {
      client.close();
    }
  }
}
