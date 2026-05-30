import 'package:backend/controllers/database_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class DatabaseRoutes extends RouteGroup {
  @override
  String get prefix => '/databases';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    app.get('/', auth.handle(useController(DatabaseController.new, (c) => c.index())));
    app.post(
      '/',
      auth.handle(useController(DatabaseController.new, (c) => c.create())),
    );
    app.post(
      '/:id/reset-password',
      auth.handle(useController(DatabaseController.new, (c) => c.resetPassword())),
    );
    app.delete(
      '/:id',
      auth.handle(useController(DatabaseController.new, (c) => c.delete())),
    );
  }
}
