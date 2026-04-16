import 'package:backend/models/backup_model.dart';
import 'package:backend/services/job_service.dart';
import 'package:flint_dart/flint_dart.dart';

class BackupController extends Controller {
  Future<Response> index() async {
    final backups = await Backup().all();
    return res.json({
      'status': 'success',
      'data': backups.map((backup) => backup.toMap()).toList(),
    });
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {'siteId': 'required|string'});

      final backup = await Backup().create({'siteId': body['siteId'], 'status': 'pending'});
      final job = await JobService.enqueue(
        type: 'backup_site',
        targetType: 'backup',
        targetId: backup?.getAttribute<String>('id'),
        payload: {'siteId': body['siteId']},
      );

      final updatedBackup = backup == null
          ? null
          : await backup.update(
              id: backup.getAttribute<String>('id'),
              data: {'jobId': job?.getAttribute<String>('id')},
            );

      return res.status(201).json({
        'status': 'success',
        'data': {'backup': updatedBackup?.toMap(), 'job': job?.toMap()}
      });
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> restore() async {
    try {
      final backupId = req.params['id'];
      if (backupId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing backup id'});
      }

      final backup = await Backup().find(backupId);
      if (backup == null) {
        return res.status(404).json({'status': 'error', 'message': 'Backup not found'});
      }

      final job = await JobService.enqueue(
        type: 'restore_backup',
        targetType: 'backup',
        targetId: backupId,
        payload: backup.toMap(),
      );

      return res.json({'status': 'success', 'data': job?.toMap()});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
