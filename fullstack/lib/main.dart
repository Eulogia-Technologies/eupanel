import 'package:flint_dart/flint_dart.dart';
import 'package:backend/config/app_config.dart';
import 'package:backend/routes/app_routes.dart';

void main() {
  final app = Flint(
    withDefaultMiddleware: true,
    autoConnectDb: true,
    enableSwaggerDocs: true,
  );

  app.use(StaticFileMiddleware());

  // Mount the main AppRoutes
  app.routes(AppRoutes());

  // Start the server
  app.listen(port: AppConfig.appPort, hotReload: !AppConfig.isProduction);
}
