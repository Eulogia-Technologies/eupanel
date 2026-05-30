import 'package:flint_dart/flint_dart.dart';
import 'package:backend/services/plan_service.dart';

/// Admin-only CRUD for hosting plans.
class PlanController extends Controller {
  final PlanService _service = PlanService();

  /// GET /plans — admin: all plans, customer: active only
  Future<Response> index() async {
    try {
      final user = await req.user;
      final isAdmin = user?['role']?.toString() == 'admin';

      final plans = isAdmin
          ? await _service.listAll()
          : await _service.listActive();

      return res.json({'status': 'success', 'data': plans});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// GET /plans/:id
  Future<Response> show() async {
    try {
      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json({'status': 'error', 'message': 'Plan id is required.'});
      }
      final plan = await _service.findById(id);
      if (plan == null) {
        return res.status(404).json({'status': 'error', 'message': 'Plan not found.'});
      }
      return res.json({'status': 'success', 'data': plan});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// POST /plans — admin only
  Future<Response> create() async {
    try {
      final body = await req.json();
      final plan = await _service.create(body);
      return res.status(201).json({'status': 'success', 'data': plan});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// PUT /plans/:id — admin only
  Future<Response> update() async {
    try {
      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json({'status': 'error', 'message': 'Plan id is required.'});
      }
      final body = await req.json();
      final plan = await _service.update(id, body);
      return res.json({'status': 'success', 'data': plan});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /plans/:id — admin only
  Future<Response> delete() async {
    try {
      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json({'status': 'error', 'message': 'Plan id is required.'});
      }
      await _service.delete(id);
      return res.json({'status': 'success', 'message': 'Plan deleted.'});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
