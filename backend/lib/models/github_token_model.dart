import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

/// Stores a user's GitHub OAuth access token.
/// One row per user (upserted on re-connect).
class GithubToken extends Model<GithubToken> {
  GithubToken() : super(() => GithubToken());

  String? get userId         => getAttribute("user_id");
  String? get githubUserId   => getAttribute("github_user_id");
  String? get githubUsername => getAttribute("github_username");
  String? get githubEmail    => getAttribute("github_email");
  String? get accessToken    => getAttribute("access_token");
  String? get avatarUrl      => getAttribute("avatar_url");

  @override
  Table get table => Table(
        name: 'github_tokens',
        columns: [
          Column(name: 'user_id',         type: ColumnType.string, length: 36, isUnique: true),
          Column(name: 'github_user_id',  type: ColumnType.string, length: 20),
          Column(name: 'github_username', type: ColumnType.string, length: 100),
          Column(name: 'github_email',    type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'access_token',    type: ColumnType.string, length: 100),
          Column(name: 'avatar_url',      type: ColumnType.string, length: 255, isNullable: true),
        ],
      );
}
