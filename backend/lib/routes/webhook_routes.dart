import 'package:backend/controllers/webhook_controller.dart';
import 'package:flint_dart/flint_dart.dart';

/// Inbound webhook endpoints — no auth middleware (GitHub calls these directly).
class WebhookRoutes extends RouteGroup {
  @override
  String get prefix => '/webhooks';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    // GitHub push webhook for site auto-deploys — verified via per-site HMAC secret
    app.post('/github', useController(WebhookController.new, (c) => c.githubPush()));

    // GitHub push webhook for eupanel self-update — verified via DEPLOY_WEBHOOK_SECRET
    app.post('/deploy', useController(WebhookController.new, (c) => c.selfDeploy()));
  }
}
