import 'package:backend/controllers/server_controller.dart';
import 'package:backend/middlewares/agent_middleware.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class ServerRoutes extends RouteGroup {
  @override
  String get prefix => '/servers';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final adminOnly = AuthMiddleware(allowedRoles: ['admin']);

    app.get('/', adminOnly.handle(useController(ServerController.new, (c) => c.index())));
    app.get('/:id', adminOnly.handle(useController(ServerController.new, (c) => c.show())));
    app.post(
      '/',
      adminOnly.handle(
        useController(ServerController.new, (c) => c.create()),
      ),
    );
    app.put(
      '/:id',
      adminOnly.handle(
        useController(ServerController.new, (c) => c.update()),
      ),
    );
    app.delete(
      '/:id',
      adminOnly.handle(
        useController(ServerController.new, (c) => c.delete()),
      ),
    );
    // Agent heartbeat — accepts agent secret or JWT
    app.post(
      '/:id/heartbeat',
      AgentMiddleware().handle(
        useController(ServerController.new, (c) => c.heartbeat()),
      ),
    );
  }
}
