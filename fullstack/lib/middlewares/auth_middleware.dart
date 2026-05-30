import 'package:flint_dart/flint_dart.dart';
import 'package:backend/models/user_model.dart';

class AuthMiddleware extends Middleware {
  final List<String> allowedRoles;

  AuthMiddleware({this.allowedRoles = const []});

  @override
  Handler handle(Handler next) {
    return (Context ctx) async {
      final req = ctx.req;
      final res = ctx.res;
      if (res == null) return null;

      final user = await req.user;
      if (user == null) {
        return res.status(401).json({"status": "error", "message": "Unauthorized"});
      }

      final effectiveUser = await _withRole(user);
      req.set('user', effectiveUser);

      if (allowedRoles.isNotEmpty) {
        final role = effectiveUser['role']?.toString().toLowerCase();
        final accepted = allowedRoles.map((r) => r.toLowerCase()).toList();
        if (role == null || !accepted.contains(role)) {
          return res.status(403).json({"status": "error", "message": "Forbidden"});
        }
      }

      return await next(ctx);
    };
  }

  Future<Map<String, dynamic>> _withRole(Map<String, dynamic> tokenUser) async {
    if (tokenUser['role'] != null) return tokenUser;

    final id = tokenUser['id']?.toString();
    if (id != null && id.isNotEmpty) {
      final user = await User().find(id);
      if (user != null) return user.toMap();
    }

    final email = tokenUser['email']?.toString();
    if (email != null && email.isNotEmpty) {
      final users = await User().whereSimple('email', email);
      if (users.isNotEmpty) return users.first.toMap();
    }

    return tokenUser;
  }
}
