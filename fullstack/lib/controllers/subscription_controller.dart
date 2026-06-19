import 'package:flint_dart/flint_dart.dart';
import 'package:backend/services/subscription_service.dart';

class SubscriptionController extends Controller {
  final SubscriptionService _service = SubscriptionService();

  /// GET /subscriptions
  Future<Response> index() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final role = user['role']?.toString().toLowerCase() ?? 'customer';
      final isAdmin = role == 'admin';
      final userId = user['id'].toString();

      final subs = isAdmin
          ? await _service.listAll()
          : await _service.listForActor(userId: userId, role: role);

      return res.json({'status': 'success', 'data': subs});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// GET /subscriptions/:id
  Future<Response> show() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json(
            {'status': 'error', 'message': 'Subscription id is required.'});
      }

      final isAdmin = user['role']?.toString().toLowerCase() == 'admin';
      final userId = user['id'].toString();

      final sub = await _service.findById(id, actorId: isAdmin ? null : userId);
      if (sub == null) {
        return res
            .status(404)
            .json({'status': 'error', 'message': 'Subscription not found.'});
      }

      return res.json({'status': 'success', 'data': sub});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// POST /subscriptions
  Future<Response> create() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final body = await req.json();
      await Validator.validate(body, {
        'plan_id': 'required|string',
        'domain': 'required|string|min:4|max:253',
      });

      final userId = user['id'].toString();
      final planId = body['plan_id'].toString();
      final serverId = body['server_id']?.toString();
      final result = await _service.create(
        createdByUserId: userId,
        planId: planId,
        domain: body['domain'].toString(),
        serverId: serverId,
        contactEmail: body['contact_email']?.toString(),
        sslEmail: body['ssl_email']?.toString(),
      );

      final subscription =
          Map<String, dynamic>.from(result['subscription'] as Map);
      final statusCode =
          subscription['provisioning_status'] == 'success' ? 201 : 202;

      return res.status(statusCode).json({
        'status': subscription['provisioning_status'] == 'success'
            ? 'success'
            : 'provisioning_failed',
        'data': result,
        if (result.containsKey('warning')) 'warning': result['warning'],
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /subscriptions/:id
  Future<Response> cancel() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json(
            {'status': 'error', 'message': 'Subscription id is required.'});
      }

      final isAdmin = user['role']?.toString().toLowerCase() == 'admin';
      final userId = user['id'].toString();

      await _service.cancel(id, actorId: isAdmin ? null : userId);

      return res.json({
        'status': 'success',
        'message': 'Subscription cancelled and deprovisioned.'
      });
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> _unauthorized() =>
      res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
}
