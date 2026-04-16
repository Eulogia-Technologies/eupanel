import 'package:backend/controllers/ssl_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class SslRoutes extends RouteGroup {
  @override
  String get prefix => '/ssl';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    app.get('/certificates', useController(SslController.new, (c) => c.index()));
    app.post(
      '/issue',
      AuthMiddleware().handle(useController(SslController.new, (c) => c.issue())),
    );
  }
}
