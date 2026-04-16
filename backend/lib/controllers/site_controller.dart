import 'package:backend/models/site_model.dart';
import 'package:backend/models/site_runtime_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class SiteController extends Controller {
  Future<Response> index() async {
    final sites = await Site().all();
    return res.json({
      'status': 'success',
      'data': sites.map((site) => site.toMap()).toList(),
    });
  }

  Future<Response> show() async {
    final site = await Site().find(req.params['id']);
    if (site == null) {
      return res.status(404).json({'status': 'error', 'message': 'Site not found'});
    }
    return res.json({'status': 'success', 'data': site.toMap()});
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'serverId': 'required|string',
        'domain': 'required|string|min:3|max:255',
        'runtime': 'required|string',
        'runtimeVersion': 'required|string',
        'rootPath': 'required|string',
      });

      final site = await Site().create({
        'serverId': body['serverId'],
        'userId': body['userId'],
        'domain': body['domain'],
        'runtime': body['runtime'],
        'runtimeVersion': body['runtimeVersion'],
        'rootPath': body['rootPath'],
        'status': 'provisioning',
      });

      final job = await JobService.enqueue(
        type: 'create_site',
        targetType: 'site',
        targetId: site?.getAttribute<String>('id'),
        serverId: body['serverId'],
        payload: {'domain': body['domain'], 'runtime': body['runtime']},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'site': site?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> createSubdomain() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'serverId': 'required|string',
        'parentDomain': 'required|string|min:3|max:255',
        'subdomain': 'required|string|min:1|max:100',
      });

      final fullDomain = '${body['subdomain']}.${body['parentDomain']}';
      final site = await Site().create({
        'serverId': body['serverId'],
        'userId': body['userId'],
        'domain': fullDomain,
        'runtime': body['runtime'] ?? 'php',
        'runtimeVersion': body['runtimeVersion'] ?? '8.3.30',
        'rootPath': body['rootPath'] ?? '/var/www/$fullDomain/public',
        'status': 'provisioning',
      });

      final job = await JobService.enqueue(
        type: 'create_site',
        targetType: 'site',
        targetId: site?.getAttribute<String>('id'),
        serverId: body['serverId'],
        payload: {'domain': fullDomain, 'runtime': body['runtime'] ?? 'php'},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'site': site?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> updateRuntime() async {
    try {
      final siteId = req.params['id'];
      if (siteId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing site id'});
      }

      final site = await Site().find(siteId);
      if (site == null) {
        return res.status(404).json({'status': 'error', 'message': 'Site not found'});
      }

      final body = await req.json();
      await Validator.validate(body, {
        'runtime': 'required|string',
        'runtimeVersion': 'required|string',
      });

      final runtime = body['runtime'].toString().toLowerCase();
      final version = body['runtimeVersion'].toString();

      await site.update(id: siteId, data: {'runtime': runtime, 'runtimeVersion': version});

      final existingRuntime = (await SiteRuntime().whereSimple('siteId', siteId)).firstOrNull;
      final defaults = _runtimeDefaults(runtime);
      if (existingRuntime == null) {
        await SiteRuntime().create({
          'siteId': siteId,
          'runtime': runtime,
          'version': version,
          'startCommand': defaults['startCommand'],
          'port': defaults['port'],
          'serviceName': defaults['serviceName'],
        });
      } else {
        await existingRuntime.update(id: existingRuntime.getAttribute<String>('id'), data: {
          'runtime': runtime,
          'version': version,
          'startCommand': defaults['startCommand'],
          'port': defaults['port'],
          'serviceName': defaults['serviceName'],
        });
      }

      final job = await JobService.enqueue(
        type: 'restart_runtime',
        targetType: 'site',
        targetId: siteId,
        payload: {'runtime': runtime, 'runtimeVersion': version},
      );

      final refreshed = await Site().find(siteId);
      return res.json({
        'status': 'success',
        'data': {'site': refreshed?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> update() async {
    try {
      final siteId = req.params['id'];
      if (siteId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing site id'});
      }

      final site = await Site().find(siteId);
      if (site == null) {
        return res.status(404).json({'status': 'error', 'message': 'Site not found'});
      }

      final body = await req.json();
      await Validator.validate(body, {
        'domain': 'string|min:3|max:255',
        'status': 'string',
        'rootPath': 'string',
      });

      final updateData = <String, dynamic>{};
      if (body['domain'] != null) updateData['domain'] = body['domain'];
      if (body['status'] != null) updateData['status'] = body['status'];
      if (body['rootPath'] != null) updateData['rootPath'] = body['rootPath'];

      if (updateData.isEmpty) {
        return res.status(422).json({'status': 'error', 'message': 'No fields to update'});
      }

      final updated = await site.update(id: siteId, data: updateData);
      return res.json({'status': 'success', 'data': updated?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> delete() async {
    try {
      final siteId = req.params['id'];
      if (siteId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing site id'});
      }

      final site = await Site().find(siteId);
      if (site == null) {
        return res.status(404).json({'status': 'error', 'message': 'Site not found'});
      }

      final job = await JobService.enqueue(
        type: 'delete_site',
        targetType: 'site',
        targetId: siteId,
        payload: {'domain': site.getAttribute<String>('domain')},
      );

      await site.delete(siteId);
      return res.json({
        'status': 'success',
        'message': 'Site deleted successfully',
        'data': {'job': job?.toMap()}
      });
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Map<String, dynamic> _runtimeDefaults(String runtime) {
    switch (runtime) {
      case 'dart':
        return {
          'startCommand': 'dart run bin/server.dart',
          'port': 8080,
          'serviceName': 'dart-app'
        };
      case 'nodejs':
      case 'node':
        return {'startCommand': 'node server.js', 'port': 3001, 'serviceName': 'node-app'};
      case 'python':
        return {
          'startCommand': 'uvicorn main:app --host 127.0.0.1 --port 5001',
          'port': 5001,
          'serviceName': 'python-app'
        };
      case 'docker':
        return {'startCommand': 'docker compose up -d', 'port': 8080, 'serviceName': 'docker-app'};
      default:
        return {'startCommand': 'php-fpm', 'port': 9000, 'serviceName': 'php-fpm'};
    }
  }
}
