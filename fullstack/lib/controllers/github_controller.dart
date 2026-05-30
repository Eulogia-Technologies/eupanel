import 'dart:convert';
import 'dart:io';

import 'package:backend/models/github_token_model.dart';
import 'package:backend/models/git_deploy_model.dart';
import 'package:backend/services/github_service.dart';
import 'package:flint_dart/flint_dart.dart';

class GithubController extends Controller {
  GithubService get _svc => GithubService(
        clientId: Platform.environment['GITHUB_CLIENT_ID'] ?? '',
        clientSecret: Platform.environment['GITHUB_CLIENT_SECRET'] ?? '',
        panelBaseUrl: Platform.environment['PANEL_BASE_URL'] ?? 'http://localhost:4054',
      );

  /// GET /github/connect
  /// Redirects user to GitHub OAuth authorisation page.
  Future<Response> connect() async {
    final user = await req.user;
    if (user == null) return _unauthorized();

    // state = base64(userId) — verified in callback
    final state = base64Url.encode(utf8.encode(user['id'].toString()));
    final url = _svc.authorizeUrl(state);

    return res.redirect(url);
  }

  /// GET /github/callback?code=XXX&state=XXX
  /// GitHub redirects here after the user authorises.
  Future<Response> callback() async {
    final code  = req.query['code'];
    final state = req.query['state'];

    if (code == null || state == null) {
      return res.status(400).json({'status': 'error', 'message': 'Missing code or state.'});
    }

    try {
      // Decode user id from state
      final userId = utf8.decode(base64Url.decode(base64Url.normalize(state)));

      // Exchange code → token
      final accessToken = await _svc.exchangeCode(code);

      // Fetch GitHub profile
      final profile = await _svc.getGithubUser(accessToken);

      // Upsert github_tokens row
      final existing = await GithubToken().whereSimple('user_id', userId);
      final tokenData = {
        'user_id':          userId,
        'github_user_id':   profile['id'].toString(),
        'github_username':  profile['login'].toString(),
        'github_email':     profile['email']?.toString(),
        'access_token':     accessToken,
        'avatar_url':       profile['avatar_url']?.toString(),
      };

      if (existing.isNotEmpty) {
        await existing.first.update(id: existing.first.toMap()['id'].toString(), data: tokenData);
      } else {
        await GithubToken().create(tokenData);
      }

      // Redirect back to dashboard
      final frontendUrl = Platform.environment['PANEL_FRONTEND_URL'] ?? '/dashboard';
      return res.redirect('$frontendUrl?github=connected');
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// GET /github/status
  /// Returns whether the current user has a connected GitHub account.
  Future<Response> status() async {
    final user = await req.user;
    if (user == null) return _unauthorized();

    final tokens = await GithubToken().whereSimple('user_id', user['id'].toString());
    if (tokens.isEmpty) {
      return res.json({'connected': false});
    }
    final t = tokens.first;
    return res.json({
      'connected': true,
      'github_username': t.githubUsername,
      'avatar_url': t.avatarUrl,
    });
  }

  /// GET /github/repos
  /// Lists GitHub repos for the authenticated user.
  Future<Response> repos() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final tokens = await GithubToken().whereSimple('user_id', user['id'].toString());
      if (tokens.isEmpty) {
        return res.status(422).json({
          'status': 'error',
          'message': 'GitHub account not connected. Visit /api/github/connect first.',
        });
      }

      final repos = await _svc.listRepos(tokens.first.accessToken!);
      return res.json({'status': 'success', 'data': repos});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /github/disconnect
  /// Removes the stored GitHub token (does not revoke on GitHub side).
  Future<Response> disconnect() async {
    final user = await req.user;
    if (user == null) return _unauthorized();

    final tokens = await GithubToken().whereSimple('user_id', user['id'].toString());
    for (final t in tokens) {
      await t.delete(t.toMap()['id'].toString());
    }
    return res.json({'status': 'success', 'message': 'GitHub account disconnected.'});
  }

  // ── Deploy endpoints ──────────────────────────────────────────────────────

  /// GET /github/deploys
  /// Lists all deploy links for the current user.
  Future<Response> listDeploys() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final isAdmin = user['role']?.toString() == 'admin';
      final List<GitDeploy> deploys;
      if (isAdmin) {
        deploys = await GitDeploy().all();
      } else {
        deploys = await GitDeploy().whereSimple('user_id', user['id'].toString());
      }

      return res.json({'status': 'success', 'data': deploys.map((d) => _sanitize(d.toMap())).toList()});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// POST /github/deploys
  /// Body: { subscription_id, repo_full_name, branch, domain_id? }
  Future<Response> createDeploy() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final body = await req.json();
      await Validator.validate(body, {
        'subscription_id': 'required|string',
        'repo_full_name':  'required|string',
        'branch':          'string',
      });

      final deploy = await _svc.createDeploy(
        userId:         user['id'].toString(),
        subscriptionId: body['subscription_id'].toString(),
        repoFullName:   body['repo_full_name'].toString(),
        branch:         body['branch']?.toString() ?? 'main',
        domainId:       body['domain_id']?.toString(),
      );

      return res.status(201).json({'status': 'success', 'data': _sanitize(deploy)});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /github/deploys/:id
  Future<Response> deleteDeploy() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final id = req.params['id']!;
      await _svc.deleteDeploy(id, user['id'].toString());
      return res.json({'status': 'success', 'message': 'Deploy link removed.'});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Strip webhook_secret from API responses — keep it server-side only.
  Map<String, dynamic> _sanitize(Map<String, dynamic> d) {
    final copy = Map<String, dynamic>.from(d);
    copy.remove('webhook_secret');
    return copy;
  }

  Future<Response> _unauthorized() =>
      res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
}
