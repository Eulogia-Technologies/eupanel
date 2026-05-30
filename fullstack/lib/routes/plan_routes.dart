import 'package:flint_dart/flint_dart.dart';
import 'package:backend/controllers/plan_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';

class PlanRoutes extends RouteGroup {
  @override
  String get prefix => '/plans';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth      = AuthMiddleware();
    final adminOnly = AuthMiddleware(allowedRoles: ['admin']);

    // GET /plans — authenticated users see active plans; admin sees all
    app.get(
      '/',
      auth.handle(
        useController(PlanController.new, (c) => c.index()),
      ),
    );

    // GET /plans/:id
    app.get(
      '/:id',
      auth.handle(
        useController(PlanController.new, (c) => c.show()),
      ),
    );

    // POST /plans — admin only
    app.post(
      '/',
      adminOnly.handle(
        useController(PlanController.new, (c) => c.create()),
      ),
    );

    // PUT /plans/:id — admin only
    app.put(
      '/:id',
      adminOnly.handle(
        useController(PlanController.new, (c) => c.update()),
      ),
    );

    // DELETE /plans/:id — admin only
    app.delete(
      '/:id',
      adminOnly.handle(
        useController(PlanController.new, (c) => c.delete()),
      ),
    );
  }
}
