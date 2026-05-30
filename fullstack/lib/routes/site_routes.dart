import 'package:backend/controllers/site_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class SiteRoutes extends RouteGroup {
  @override
  String get prefix => '/sites';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    app.get('/', auth.handle(useController(SiteController.new, (c) => c.index())));
    app.get('/:id', auth.handle(useController(SiteController.new, (c) => c.show())));
    app.post(
      '/',
      auth.handle(useController(SiteController.new, (c) => c.create())),
    );
    app.post(
      '/subdomains',
      auth.handle(useController(SiteController.new, (c) => c.createSubdomain())),
    );
    app.patch(
      '/:id/runtime',
      auth.handle(useController(SiteController.new, (c) => c.updateRuntime())),
    );
    app.put(
      '/:id',
      auth.handle(useController(SiteController.new, (c) => c.update())),
    );
    app.delete(
      '/:id',
      auth.handle(useController(SiteController.new, (c) => c.delete())),
    );
  }
}
