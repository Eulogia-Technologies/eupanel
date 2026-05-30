import 'package:backend/models/job_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class JobController extends Controller {
  /// List jobs. Supports optional query filters:
  ///   ?status=pending
  ///   ?serverId=<id>
  Future<Response> index() async {
    final status = req.query['status'];
    final serverId = req.query['serverId'];

    List<Job> jobs;
    if (status != null && serverId != null) {
      final byStatus = await Job().whereSimple('status', status);
      jobs = byStatus.where((j) => j.getAttribute<String>('serverId') == serverId).toList();
    } else if (status != null) {
      jobs = await Job().whereSimple('status', status);
    } else if (serverId != null) {
      jobs = await Job().whereSimple('serverId', serverId);
    } else {
      jobs = await Job().all();
    }

    return res.json({
      'status': 'success',
      'data': jobs.map((job) => job.toMap()).toList(),
    });
  }

  Future<Response> show() async {
    final job = await Job().find(req.params['id']);
    if (job == null) {
      return res.status(404).json({'status': 'error', 'message': 'Job not found'});
    }
    return res.json({'status': 'success', 'data': job.toMap()});
  }

  /// Agent calls this to atomically claim a pending job (sets status → running).
  Future<Response> claim() async {
    try {
      final jobId = req.params['id'];
      if (jobId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing job id'});
      }

      final job = await Job().find(jobId);
      if (job == null) {
        return res.status(404).json({'status': 'error', 'message': 'Job not found'});
      }

      if (job.getAttribute<String>('status') != 'pending') {
        return res.status(409).json({'status': 'error', 'message': 'Job already claimed'});
      }

      final claimed = await job.update(id: jobId, data: {'status': 'running'});
      return res.json({'status': 'success', 'data': claimed?.toMap()});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> updateStatus() async {
    try {
      final jobId = req.params['id'];
      if (jobId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing job id'});
      }

      final body = await req.json();
      await Validator.validate(body, {'status': 'required|string', 'logLine': 'string'});

      final job = await JobService.setStatus(
        jobId: jobId,
        status: body['status'],
        logLine: body['logLine'],
      );

      if (job == null) {
        return res.status(404).json({'status': 'error', 'message': 'Job not found'});
      }

      return res.json({'status': 'success', 'data': job.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
