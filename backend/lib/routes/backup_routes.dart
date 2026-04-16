import 'package:backend/controllers/backup_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class BackupRoutes extends RouteGroup {
  @override
  String get prefix => '/backups';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    app.get('/', useController(BackupController.new, (c) => c.index()));
    app.post(
      '/',
      AuthMiddleware().handle(useController(BackupController.new, (c) => c.create())),
    );
    app.post(
      '/:id/restore',
      AuthMiddleware().handle(useController(BackupController.new, (c) => c.restore())),
    );
  }
}
