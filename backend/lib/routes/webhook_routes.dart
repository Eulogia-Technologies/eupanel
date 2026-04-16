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
    // GitHub push webhook — verified via HMAC-SHA256 signature
    app.post('/github', useController(WebhookController.new, (c) => c.githubPush()));
  }
}
