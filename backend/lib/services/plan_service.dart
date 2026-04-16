import 'package:backend/models/plan_model.dart';

/// Handles all business logic around hosting plans.
/// Controllers should never query Plan directly — always go through here.
class PlanService {
  /// Returns all plans (admin view — all statuses).
  Future<List<Map<String, dynamic>>> listAll() async {
    final plans = await Plan().all();
    return plans.map((p) => p.toMap()).toList();
  }

  /// Returns only active plans (customer-facing).
  Future<List<Map<String, dynamic>>> listActive() async {
    final plans = await Plan().whereSimple('status', 'active');
    return plans.map((p) => p.toMap()).toList();
  }

  /// Returns a single plan by id or null.
  Future<Map<String, dynamic>?> findById(String id) async {
    final plan = await Plan().find(id);
    return plan?.toMap();
  }

  /// Creates a new plan. Throws on validation failure.
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    _validatePlanData(data);

    final plan = await Plan().create({
      'name': data['name'].toString().trim(),
      'description': data['description']?.toString().trim(),
      'disk_limit': _parseInt(data['disk_limit'], 'disk_limit'),
      'bandwidth_limit': _parseInt(data['bandwidth_limit'], 'bandwidth_limit'),
      'ftp_accounts_limit': _parseInt(data['ftp_accounts_limit'] ?? 1, 'ftp_accounts_limit'),
      'database_limit': _parseInt(data['database_limit'] ?? 1, 'database_limit'),
      'domain_limit': _parseInt(data['domain_limit'] ?? 1, 'domain_limit'),
      'price': data['price'] != null ? double.tryParse(data['price'].toString()) : null,
      'status': data['status']?.toString() ?? 'active',
    });

    if (plan == null) {
      throw Exception('Failed to create plan — database returned null.');
    }
    return plan.toMap();
  }

  /// Updates an existing plan. Only updates provided fields.
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    final plan = await Plan().find(id);
    if (plan == null) throw NotFoundException('Plan not found.');

    final updateData = <String, dynamic>{};
    if (data.containsKey('name')) updateData['name'] = data['name'].toString().trim();
    if (data.containsKey('description')) updateData['description'] = data['description'];
    if (data.containsKey('disk_limit')) updateData['disk_limit'] = _parseInt(data['disk_limit'], 'disk_limit');
    if (data.containsKey('bandwidth_limit')) updateData['bandwidth_limit'] = _parseInt(data['bandwidth_limit'], 'bandwidth_limit');
    if (data.containsKey('ftp_accounts_limit')) updateData['ftp_accounts_limit'] = _parseInt(data['ftp_accounts_limit'], 'ftp_accounts_limit');
    if (data.containsKey('database_limit')) updateData['database_limit'] = _parseInt(data['database_limit'], 'database_limit');
    if (data.containsKey('domain_limit')) updateData['domain_limit'] = _parseInt(data['domain_limit'], 'domain_limit');
    if (data.containsKey('price')) updateData['price'] = data['price'] != null ? double.tryParse(data['price'].toString()) : null;
    if (data.containsKey('status')) {
      _validateStatus(data['status'].toString());
      updateData['status'] = data['status'].toString();
    }

    if (updateData.isEmpty) throw Exception('No valid fields provided for update.');

    await plan.update(id: id, data: updateData);
    final updated = await Plan().find(id);
    return updated!.toMap();
  }

  /// Deletes a plan. Throws if plan has active subscriptions.
  Future<void> delete(String id) async {
    final plan = await Plan().find(id);
    if (plan == null) throw NotFoundException('Plan not found.');
    await plan.delete(id);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _validatePlanData(Map<String, dynamic> data) {
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      throw ValidationException({'name': ['Plan name is required.']});
    }
    if (data['disk_limit'] == null) {
      throw ValidationException({'disk_limit': ['Disk limit is required.']});
    }
    if (data['bandwidth_limit'] == null) {
      throw ValidationException({'bandwidth_limit': ['Bandwidth limit is required.']});
    }
    _validateStatus(data['status']?.toString() ?? 'active');
  }

  void _validateStatus(String status) {
    const allowed = ['active', 'inactive'];
    if (!allowed.contains(status)) {
      throw ValidationException({'status': ['Status must be active or inactive.']});
    }
  }

  int _parseInt(dynamic value, String field) {
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed < 0) {
      throw ValidationException({field: ['$field must be a non-negative integer.']});
    }
    return parsed;
  }
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final Map<String, List<String>> errors;
  ValidationException(this.errors);
  @override
  String toString() => errors.toString();
}
