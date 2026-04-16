// src/routes/app_routes.dart
import 'package:flint_dart/flint_dart.dart';
import 'auth_routes.dart';
import 'backup_routes.dart';
import 'database_routes.dart';
import 'dns_routes.dart';
import 'job_routes.dart';
import 'mail_routes.dart';
import 'plan_routes.dart';
import 'runtime_routes.dart';
import 'server_routes.dart';
import 'site_routes.dart';
import 'ssl_routes.dart';
import 'subscription_routes.dart';
import 'user_routes.dart';

/// Main route group for the entire app
class AppRoutes extends RouteGroup {
  @override
  String get prefix => ''; // root

  @override
  List<Middleware> get middlewares => []; // optional global middlewares

  @override
  void register(Flint app) {
    // Home route
    app.get('/', (Context ctx) async => ctx.res?.view('welcome'));

    // Auth routes
    app.routes(AuthRoutes());

    // User routes with optional middleware
    app.routes(
      UserRoutes(),
      children: [],
    );

    app.routes(ServerRoutes());
    app.routes(SiteRoutes());
    app.routes(RuntimeRoutes());
    app.routes(DatabaseRoutes());
    app.routes(DnsRoutes());
    app.routes(SslRoutes());
    app.routes(JobRoutes());
    app.routes(BackupRoutes());
    app.routes(MailRoutes());
  }
}
