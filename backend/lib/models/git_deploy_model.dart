import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

/// Links a GitHub repo to a domain/subscription directory.
/// Each row = one active auto-deploy connection.
class GitDeploy extends Model<GitDeploy> {
  GitDeploy() : super(() => GitDeploy());

  String? get subscriptionId  => getAttribute("subscription_id");
  String? get domainId        => getAttribute("domain_id");
  String? get userId          => getAttribute("user_id");
  String? get repoFullName    => getAttribute("repo_full_name");  // e.g. "user/my-site"
  String? get repoUrl         => getAttribute("repo_url");        // clone URL
  String? get branch          => getAttribute("branch");
  String? get deployPath      => getAttribute("deploy_path");     // abs path on server
  String? get webhookSecret   => getAttribute("webhook_secret");  // HMAC secret
  String? get webhookId       => getAttribute("webhook_id");      // GitHub webhook ID (for cleanup)
  String? get deployStatus    => getAttribute("deploy_status");   // idle | deploying | success | failed
  String? get lastCommitSha   => getAttribute("last_commit_sha");
  String? get lastCommitMsg   => getAttribute("last_commit_msg");
  String? get lastDeployedAt  => getAttribute("last_deployed_at");
  String? get deployLog       => getAttribute("deploy_log");

  @override
  Table get table => Table(
        name: 'git_deploys',
        columns: [
          Column(name: 'subscription_id',  type: ColumnType.string, length: 36),
          Column(name: 'domain_id',        type: ColumnType.string, length: 36, isNullable: true),
          Column(name: 'user_id',          type: ColumnType.string, length: 36),
          Column(name: 'repo_full_name',   type: ColumnType.string, length: 200),
          Column(name: 'repo_url',         type: ColumnType.string, length: 500),
          Column(name: 'branch',           type: ColumnType.string, length: 100, defaultValue: 'main'),
          Column(name: 'deploy_path',      type: ColumnType.string, length: 500),
          Column(name: 'webhook_secret',   type: ColumnType.string, length: 64),
          Column(name: 'webhook_id',       type: ColumnType.string, length: 20, isNullable: true),
          Column(name: 'deploy_status',    type: ColumnType.string, length: 20, defaultValue: 'idle'),
          Column(name: 'last_commit_sha',  type: ColumnType.string, length: 40, isNullable: true),
          Column(name: 'last_commit_msg',  type: ColumnType.string, length: 500, isNullable: true),
          Column(name: 'last_deployed_at', type: ColumnType.timestamp, isNullable: true),
          Column(name: 'deploy_log',       type: ColumnType.text, isNullable: true),
        ],
      );
}
