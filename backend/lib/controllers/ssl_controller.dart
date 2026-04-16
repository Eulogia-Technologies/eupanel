import 'package:backend/models/ssl_certificate_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class SslController extends Controller {
  Future<Response> index() async {
    final certs = await SslCertificate().all();
    return res.json({'status': 'success', 'data': certs.map((cert) => cert.toMap()).toList()});
  }

  Future<Response> issue() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'siteId': 'required|string',
        'domain': 'required|string|min:3|max:255',
      });

      final cert = await SslCertificate().create({
        'siteId': body['siteId'],
        'domain': body['domain'],
        'provider': 'letsencrypt',
        'status': 'pending',
      });

      final job = await JobService.enqueue(
        type: 'issue_ssl',
        targetType: 'ssl_certificate',
        targetId: cert?.getAttribute<String>('id'),
        payload: {'domain': body['domain']},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'certificate': cert?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
