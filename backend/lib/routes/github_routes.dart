import 'package:backend/controllers/github_controller.dart';
import 'package:flint_dart/flint_dart.dart';

class GithubRoutes extends RouteGroup {
  @override
  String get prefix => '/github';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    // OAuth
    app.get('/connect',    useController(GithubController.new, (c) => c.connect()));
    app.get('/callback',   useController(GithubController.new, (c) => c.callback()));
    app.get('/status',     useController(GithubController.new, (c) => c.status()));
    app.delete('/disconnect', useController(GithubController.new, (c) => c.disconnect()));

    // Repos
    app.get('/repos', useController(GithubController.new, (c) => c.repos()));

    // Auto-deploys
    app.get('/deploys',        useController(GithubController.new, (c) => c.listDeploys()));
    app.post('/deploys',       useController(GithubController.new, (c) => c.createDeploy()));
    app.delete('/deploys/:id', useController(GithubController.new, (c) => c.deleteDeploy()));
  }
}
