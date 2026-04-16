import 'package:backend/models/dns_record_model.dart';
import 'package:backend/models/dns_zone_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class DnsController extends Controller {
  Future<Response> listZones() async {
    final zones = await DnsZone().all();
    return res.json({'status': 'success', 'data': zones.map((z) => z.toMap()).toList()});
  }

  Future<Response> createZone() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {'domain': 'required|string|min:3|max:255'});

      final zone = await DnsZone().create({'domain': body['domain'], 'status': 'active'});
      final job = await JobService.enqueue(
        type: 'create_dns_zone',
        targetType: 'dns_zone',
        targetId: zone?.getAttribute<String>('id'),
        payload: {'domain': body['domain']},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'zone': zone?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> listRecords() async {
    final zoneId = req.params['zoneId'];
    if (zoneId == null) {
      return res.status(400).json({'status': 'error', 'message': 'Missing zone id'});
    }

    final records = await DnsRecord().whereSimple('zoneId', zoneId);
    return res.json({'status': 'success', 'data': records.map((r) => r.toMap()).toList()});
  }

  Future<Response> createRecord() async {
    try {
      final zoneId = req.params['zoneId'];
      if (zoneId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing zone id'});
      }

      final body = await req.json();
      await Validator.validate(body, {
        'name': 'required|string',
        'type': 'required|string',
        'content': 'required|string',
        'ttl': 'integer',
        'priority': 'integer',
      });

      final record = await DnsRecord().create({
        'zoneId': zoneId,
        'name': body['name'],
        'type': body['type'],
        'content': body['content'],
        'ttl': body['ttl'] ?? 3600,
        'priority': body['priority'],
      });

      return res.status(201).json({'status': 'success', 'data': record?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
