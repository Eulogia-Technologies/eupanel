import 'package:backend/config/app_config.dart';
import 'package:flint_dart/flint_dart.dart';

/// Accepts requests that carry either:
///   - A valid user JWT (Authorization: Bearer <token>)
///   - The shared agent secret (X-Agent-Secret: <secret>)
///
/// This lets the Eupanel Agent update job status without a user account,
/// while still allowing the dashboard to do the same via its JWT.
class AgentMiddleware extends Middleware {
  @override
  Handler handle(Handler next) {
    return (Context ctx) async {
      final req = ctx.req;
      final res = ctx.res;
      if (res == null) return null;

      // Accept agent secret header
      final agentSecret = AppConfig.agentSecret;
      final headerSecret = req.headers['x-agent-secret'];
      if (agentSecret.isNotEmpty && headerSecret == agentSecret) {
        return await next(ctx);
      }

      // Fall back to JWT user auth
      final user = await req.user;
      if (user != null) {
        return await next(ctx);
      }

      return res.status(401).json({
        'status': 'error',
        'message': 'Unauthorized: provide a valid JWT or X-Agent-Secret header',
      });
    };
  }
}
