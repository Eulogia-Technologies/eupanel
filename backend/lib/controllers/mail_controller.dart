import 'package:backend/models/mail_account_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class MailController extends Controller {
  Future<Response> index() async {
    final records = await MailAccount().all();
    return res.json({
      'status': 'success',
      'data': records.map((record) => record.toMap()).toList(),
    });
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'domain': 'required|string',
        'email': 'required|email',
        'password': 'required|string|min:8',
        'status': 'string',
        'forwardTo': 'string',
      });

      final account = await MailAccount().create({
        'siteId': body['siteId'],
        'domain': body['domain'],
        'email': body['email'],
        'password': body['password'],
        'status': body['status'] ?? 'active',
        'forwardTo': body['forwardTo'],
      });

      final job = await JobService.enqueue(
        type: 'create_mail_account',
        targetType: 'mail_account',
        targetId: account?.getAttribute<String>('id'),
        payload: {'email': body['email'], 'domain': body['domain']},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'mailAccount': account?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> delete() async {
    try {
      final accountId = req.params['id'];
      if (accountId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing mail account id'});
      }

      final account = await MailAccount().find(accountId);
      if (account == null) {
        return res.status(404).json({'status': 'error', 'message': 'Mail account not found'});
      }

      await account.delete(accountId);
      return res.json({'status': 'success', 'message': 'Mail account deleted'});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}

