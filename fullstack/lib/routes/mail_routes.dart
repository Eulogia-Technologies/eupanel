import 'package:backend/controllers/mail_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class MailRoutes extends RouteGroup {
  @override
  String get prefix => '/mail';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    app.get('/', auth.handle(useController(MailController.new, (c) => c.index())));
    app.post(
      '/',
      auth.handle(useController(MailController.new, (c) => c.create())),
    );
    app.delete(
      '/:id',
      auth.handle(useController(MailController.new, (c) => c.delete())),
    );
  }
}
