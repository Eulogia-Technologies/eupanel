import 'package:flint_dart/flint_dart.dart';
import 'package:backend/controllers/subscription_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';

class SubscriptionRoutes extends RouteGroup {
  @override
  String get prefix => '/subscriptions';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    // GET /subscriptions — own subs (customer) or all (admin)
    app.get(
      '/',
      auth.handle(
        useController(SubscriptionController.new, (c) => c.index()),
      ),
    );

    // GET /subscriptions/:id
    app.get(
      '/:id',
      auth.handle(
        useController(SubscriptionController.new, (c) => c.show()),
      ),
    );

    // POST /subscriptions — create subscription + trigger provisioning
    app.post(
      '/',
      auth.handle(
        useController(SubscriptionController.new, (c) => c.create()),
      ),
    );

    // DELETE /subscriptions/:id — cancel + deprovision
    app.delete(
      '/:id',
      auth.handle(
        useController(SubscriptionController.new, (c) => c.cancel()),
      ),
    );
  }
}
