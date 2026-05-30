import 'package:backend/controllers/dns_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class DnsRoutes extends RouteGroup {
  @override
  String get prefix => '/dns';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    final auth = AuthMiddleware();

    app.get('/zones', auth.handle(useController(DnsController.new, (c) => c.listZones())));
    app.post(
      '/zones',
      auth.handle(useController(DnsController.new, (c) => c.createZone())),
    );
    app.get('/zones/:zoneId/records', auth.handle(useController(DnsController.new, (c) => c.listRecords())));
    app.post(
      '/zones/:zoneId/records',
      auth.handle(useController(DnsController.new, (c) => c.createRecord())),
    );
  }
}
