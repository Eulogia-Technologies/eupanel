import 'package:flint_dart/flint_dart.dart';
import 'package:backend/services/plan_service.dart';
import 'package:backend/services/subscription_service.dart';

class SubscriptionController extends Controller {
  final SubscriptionService _service = SubscriptionService();

  /// GET /subscriptions
  /// Admin: all subscriptions. Customer/Reseller: own subscriptions only.
  Future<Response> index() async {
    try {
      final user = await req.user;
      if (user == null) {
        return res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
      }

      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();

      final subs = isAdmin
          ? await _service.listAll()
          : await _service.listForUser(userId);

      return res.json({'status': 'success', 'data': subs});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// GET /subscriptions/:id
  Future<Response> show() async {
    try {
      final user = await req.user;
      if (user == null) {
        return res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
      }

      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json({'status': 'error', 'message': 'Subscription id is required.'});
      }

      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();

      final sub = await _service.findById(
        id,
        ownerId: isAdmin ? null : userId,
      );

      if (sub == null) {
        return res.status(404).json({'status': 'error', 'message': 'Subscription not found.'});
      }

      return res.json({'status': 'success', 'data': sub});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// POST /subscriptions
  /// Body: { plan_id, server_id? }
  Future<Response> create() async {
    try {
      final user = await req.user;
      if (user == null) {
        return res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
      }

      final body = await req.json();

      await Validator.validate(body, {
        'plan_id': 'required|string',
      });

      final userId = user['id'].toString();
      final planId = body['plan_id'].toString();
      final serverId = body['server_id']?.toString();

      final sub = await _service.create(
        userId: userId,
        planId: planId,
        serverId: serverId,
      );

      final statusCode = sub['provisioning_status'] == 'success' ? 201 : 202;

      return res.status(statusCode).json({
        'status': sub['provisioning_status'] == 'success' ? 'success' : 'provisioning_failed',
        'data': sub,
        if (sub.containsKey('_warning')) 'warning': sub['_warning'],
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } on flint_dart_ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /subscriptions/:id — cancel subscription
  Future<Response> cancel() async {
    try {
      final user = await req.user;
      if (user == null) {
        return res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
      }

      final id = req.params['id'];
      if (id == null) {
        return res.status(400).json({'status': 'error', 'message': 'Subscription id is required.'});
      }

      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();

      await _service.cancel(id, ownerId: isAdmin ? null : userId);

      return res.json({
        'status': 'success',
        'message': 'Subscription cancelled and deprovisioned.',
      });
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}

// Re-export alias to avoid name collision with flint_dart's own ValidationException
typedef flint_dart_ValidationException = ValidationException;
