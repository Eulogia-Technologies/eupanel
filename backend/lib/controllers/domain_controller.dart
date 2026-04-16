import 'package:flint_dart/flint_dart.dart';
import 'package:backend/services/domain_service.dart';

class DomainController extends Controller {
  final DomainService _service = DomainService();

  /// GET /domains?subscription_id=xxx
  Future<Response> index() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();
      final subscriptionId = req.query['subscription_id'];

      List<Map<String, dynamic>> domains;

      if (isAdmin) {
        domains = await _service.listAll();
      } else if (subscriptionId != null) {
        domains = await _service.listForSubscription(
          subscriptionId: subscriptionId,
          userId: userId,
        );
      } else {
        domains = [];
      }

      return res.json({'status': 'success', 'data': domains});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// GET /domains/:id
  Future<Response> show() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final id = req.params['id']!;
      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();

      final domain = await _service.findById(id, ownerId: isAdmin ? null : userId);
      if (domain == null) {
        return res.status(404).json({'status': 'error', 'message': 'Domain not found.'});
      }

      return res.json({'status': 'success', 'data': domain});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// POST /domains
  Future<Response> create() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final body = await req.json();
      await Validator.validate(body, {
        'subscription_id': 'required|string',
        'domain': 'required|string|min:4|max:253',
      });

      final userId = user['id'].toString();
      final email = user['email']?.toString() ?? 'admin@eupanel.local';

      final domain = await _service.create(
        userId: userId,
        subscriptionId: body['subscription_id'].toString(),
        domain: body['domain'].toString(),
        adminEmail: email,
      );

      final statusCode = domain['status'] == 'active' ? 201 : 202;

      return res.status(statusCode).json({
        'status': domain['status'] == 'failed' ? 'provisioning_failed' : 'success',
        'data': domain,
        if (domain['ssl_status'] == 'failed')
          'warning': 'Domain is live on HTTP but SSL failed. See provisioning_log.',
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// DELETE /domains/:id
  Future<Response> delete() async {
    try {
      final user = await req.user;
      if (user == null) return _unauthorized();

      final id = req.params['id']!;
      final isAdmin = user['role']?.toString() == 'admin';
      final userId = user['id'].toString();

      await _service.delete(id, ownerId: isAdmin ? null : userId);

      return res.json({'status': 'success', 'message': 'Domain removed.'});
    } on NotFoundException catch (e) {
      return res.status(404).json({'status': 'error', 'message': e.message});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> _unauthorized() =>
      res.status(401).json({'status': 'error', 'message': 'Unauthorized'});
}
