import 'package:flint_dart/flint_dart.dart';
import 'package:backend/controllers/domain_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';

class DomainRoutes extends RouteGroup {
  @override
  String get prefix => '/domains';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    // GET /domains?subscription_id=xxx
    app.get(
      '/domains',
      auth.handle(
        useController(DomainController.new, (c) => c.index()),
      ),
    );

    // GET /domains/:id
    app.get(
      '/domains/:id',
      auth.handle(
        useController(DomainController.new, (c) => c.show()),
      ),
    );

    // POST /domains  — create domain + provision nginx + SSL
    app.post(
      '/domains',
      auth.handle(
        useController(DomainController.new, (c) => c.create()),
      ),
    );

    // DELETE /domains/:id  — remove domain + nginx config
    app.delete(
      '/domains/:id',
      auth.handle(
        useController(DomainController.new, (c) => c.delete()),
      ),
    );
  }
}
