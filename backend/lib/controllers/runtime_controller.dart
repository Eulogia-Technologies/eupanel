import 'package:backend/models/site_runtime_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class RuntimeController extends Controller {
  Future<Response> index() async {
    final runtimes = await SiteRuntime().all();
    return res.json({
      'status': 'success',
      'data': runtimes.map((runtime) => runtime.toMap()).toList(),
    });
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'siteId': 'required|string',
        'runtime': 'required|string',
        'version': 'required|string',
        'startCommand': 'required|string',
        'port': 'required|integer',
        'serviceName': 'required|string',
      });

      final runtime = await SiteRuntime().create(body);
      return res.status(201).json({'status': 'success', 'data': runtime?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> restart() async {
    try {
      final runtimeId = req.params['id'];
      final runtime = runtimeId == null ? null : await SiteRuntime().find(runtimeId);
      if (runtime == null) {
        return res.status(404).json({'status': 'error', 'message': 'Runtime not found'});
      }

      final job = await JobService.enqueue(
        type: 'restart_runtime',
        targetType: 'site_runtime',
        targetId: runtimeId,
        payload: runtime.toMap(),
      );

      return res.json({'status': 'success', 'data': job?.toMap()});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
