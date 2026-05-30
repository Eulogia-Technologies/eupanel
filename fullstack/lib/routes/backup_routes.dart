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
    final auth = AuthMiddleware();

    app.get('/', auth.handle(useController(BackupController.new, (c) => c.index())));
    app.post(
      '/',
      auth.handle(useController(BackupController.new, (c) => c.create())),
    );
    app.post(
      '/:id/restore',
      auth.handle(useController(BackupController.new, (c) => c.restore())),
    );
  }
}
