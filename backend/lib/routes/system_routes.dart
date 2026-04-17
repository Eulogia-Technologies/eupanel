import 'package:backend/controllers/system_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class SystemRoutes extends RouteGroup {
  @override
  String get prefix => '/admin/system';

  @override
  List<Middleware> get middlewares => [AuthMiddleware(allowedRoles: ['admin'])];

  @override
  void register(Flint app) {
    app.post('/update',        useController(SystemController.new, (c) => c.startUpdate()));
    app.get('/update-status',  useController(SystemController.new, (c) => c.updateStatus()));
  }
}
