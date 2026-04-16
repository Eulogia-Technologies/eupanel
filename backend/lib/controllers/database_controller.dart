import 'package:backend/models/database_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class DatabaseController extends Controller {
  Future<Response> index() async {
    final records = await DatabaseModel().all();
    return res.json({
      'status': 'success',
      'data': records.map((record) => record.toMap()).toList(),
    });
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'serverId': 'required|string',
        'engine': 'required|string',
        'name': 'required|string',
        'username': 'required|string',
        'password': 'required|string|min:8',
      });

      final dbRecord = await DatabaseModel().create(body);
      final job = await JobService.enqueue(
        type: 'create_database',
        targetType: 'database',
        targetId: dbRecord?.getAttribute<String>('id'),
        serverId: body['serverId'],
        payload: {'engine': body['engine'], 'name': body['name'], 'username': body['username']},
      );

      return res.status(201).json({
        'status': 'success',
        'data': {'database': dbRecord?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> delete() async {
    try {
      final dbId = req.params['id'];
      if (dbId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing database id'});
      }

      final database = await DatabaseModel().find(dbId);
      if (database == null) {
        return res.status(404).json({'status': 'error', 'message': 'Database not found'});
      }

      final job = await JobService.enqueue(
        type: 'delete_database',
        targetType: 'database',
        targetId: dbId,
        payload: {
          'name': database.getAttribute<String>('name'),
          'engine': database.getAttribute<String>('engine'),
        },
      );

      await database.delete(dbId);
      return res.json({
        'status': 'success',
        'message': 'Database deleted successfully',
        'data': {'job': job?.toMap()}
      });
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> resetPassword() async {
    try {
      final dbId = req.params['id'];
      if (dbId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing database id'});
      }

      final database = await DatabaseModel().find(dbId);
      if (database == null) {
        return res.status(404).json({'status': 'error', 'message': 'Database not found'});
      }

      final body = await req.json();
      await Validator.validate(body, {'password': 'required|string|min:8'});

      final updated = await database.update(id: dbId, data: {'password': body['password']});
      return res.json({'status': 'success', 'data': updated?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
