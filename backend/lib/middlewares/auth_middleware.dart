import 'package:flint_dart/flint_dart.dart';

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

      if (allowedRoles.isNotEmpty) {
        final role = user['role']?.toString().toLowerCase();
        final accepted = allowedRoles.map((r) => r.toLowerCase()).toList();
        if (role == null || !accepted.contains(role)) {
          return res.status(403).json({"status": "error", "message": "Forbidden"});
        }
      }

      return await next(ctx);
    };
  }
}
