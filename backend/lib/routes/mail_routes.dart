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
    app.get('/', useController(MailController.new, (c) => c.index()));
    app.post(
      '/',
      AuthMiddleware().handle(useController(MailController.new, (c) => c.create())),
    );
    app.delete(
      '/:id',
      AuthMiddleware().handle(useController(MailController.new, (c) => c.delete())),
    );
  }
}

