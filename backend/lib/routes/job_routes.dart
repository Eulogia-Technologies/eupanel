import 'package:backend/controllers/job_controller.dart';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:backend/middlewares/agent_middleware.dart';
import 'package:flint_dart/flint_dart.dart';

class JobRoutes extends RouteGroup {
  @override
  String get prefix => '/jobs';

  @override
  List<Middleware> get middlewares => [];

  @override
  void register(Flint app) {
    // Dashboard: list all jobs (with optional ?status= / ?serverId= filters)
    app.get('/', useController(JobController.new, (c) => c.index()));
    app.get('/:id', useController(JobController.new, (c) => c.show()));

    // Agent: claim a pending job (sets it to running)
    app.patch(
      '/:id/claim',
      AgentMiddleware().handle(useController(JobController.new, (c) => c.claim())),
    );

    // Agent or dashboard: update job status + append log line
    app.patch(
      '/:id/status',
      AgentMiddleware().handle(useController(JobController.new, (c) => c.updateStatus())),
    );
  }
}
