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
    app.get('/', useController(SiteController.new, (c) => c.index()));
    app.get('/:id', useController(SiteController.new, (c) => c.show()));
    app.post(
      '/',
      AuthMiddleware().handle(useController(SiteController.new, (c) => c.create())),
    );
    app.post(
      '/subdomains',
      AuthMiddleware().handle(useController(SiteController.new, (c) => c.createSubdomain())),
    );
    app.patch(
      '/:id/runtime',
      AuthMiddleware().handle(useController(SiteController.new, (c) => c.updateRuntime())),
    );
    app.put(
      '/:id',
      AuthMiddleware().handle(useController(SiteController.new, (c) => c.update())),
    );
    app.delete(
      '/:id',
      AuthMiddleware().handle(useController(SiteController.new, (c) => c.delete())),
    );
  }
}
