import 'package:backend/controllers/runtime_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class RuntimeRoutes extends RouteGroup {
  @override
  String get prefix => '/runtimes';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    app.get('/', useController(RuntimeController.new, (c) => c.index()));
    app.post(
      '/',
      AuthMiddleware().handle(useController(RuntimeController.new, (c) => c.create())),
    );
    app.post(
      '/:id/restart',
      AuthMiddleware().handle(useController(RuntimeController.new, (c) => c.restart())),
    );
  }
}
