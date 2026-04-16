import 'package:backend/models/server_model.dart';
import 'package:flint_dart/flint_dart.dart';

class ServerController extends Controller {
  Future<Response> index() async {
    final servers = await Server().all();
    return res.json({
      'status': 'success',
      'data': servers.map((server) => server.toMap()).toList(),
    });
  }

  Future<Response> show() async {
    final server = await Server().find(req.params['id']);
    if (server == null) {
      return res.status(404).json({'status': 'error', 'message': 'Server not found'});
    }
    return res.json({'status': 'success', 'data': server.toMap()});
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'name': 'required|string|min:2|max:255',
        'host': 'required|string|min:2|max:255',
        'port': 'integer',
      });

      final server = await Server().create({
        'name': body['name'],
        'host': body['host'],
        'port': body['port'] ?? 22,
        'status': body['status'] ?? 'active',
      });

      return res.status(201).json({'status': 'success', 'data': server?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> update() async {
    try {
      final serverId = req.params['id'];
      if (serverId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing server id'});
      }

      final server = await Server().find(serverId);
      if (server == null) {
        return res.status(404).json({'status': 'error', 'message': 'Server not found'});
      }

      final body = await req.json();
      await Validator.validate(body, {
        'name': 'string|min:2|max:255',
        'host': 'string|min:2|max:255',
        'port': 'integer',
        'status': 'string',
      });

      final updateData = <String, dynamic>{};
      if (body['name'] != null) updateData['name'] = body['name'];
      if (body['host'] != null) updateData['host'] = body['host'];
      if (body['port'] != null) updateData['port'] = body['port'];
      if (body['status'] != null) updateData['status'] = body['status'];

      if (updateData.isEmpty) {
        return res.status(422).json({'status': 'error', 'message': 'No fields to update'});
      }

      final updated = await server.update(id: serverId, data: updateData);
      return res.json({'status': 'success', 'data': updated?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  /// Called by the agent on each server to report it is alive.
  /// Updates lastHeartbeatAt and agentVersion.
  Future<Response> heartbeat() async {
    try {
      final serverId = req.params['id'];
      if (serverId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing server id'});
      }

      final server = await Server().find(serverId);
      if (server == null) {
        return res.status(404).json({'status': 'error', 'message': 'Server not found'});
      }

      final body = await req.json();
      final updateData = <String, dynamic>{
        'lastHeartbeatAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'active',
      };
      if (body['agentVersion'] != null) {
        updateData['agentVersion'] = body['agentVersion'];
      }

      final updated = await server.update(id: serverId, data: updateData);
      return res.json({'status': 'success', 'data': updated?.toMap()});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> delete() async {
    try {
      final serverId = req.params['id'];
      if (serverId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing server id'});
      }

      final server = await Server().find(serverId);
      if (server == null) {
        return res.status(404).json({'status': 'error', 'message': 'Server not found'});
      }

      await server.delete(serverId);
      return res.json({'status': 'success', 'message': 'Server deleted successfully'});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
