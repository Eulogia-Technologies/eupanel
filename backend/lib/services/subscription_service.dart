import 'package:backend/models/plan_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/plan_service.dart';
import 'package:backend/services/provisioning_service.dart';

import 'package:flint_dart/flint_dart.dart';

/// Handles subscription creation, lookup, and cancellation.
/// Delegates provisioning to ProvisioningService.
class SubscriptionService {
  final ProvisioningService _provisioning = ProvisioningService();

  /// Creates a subscription and triggers provisioning.
  ///
  /// [userId]   — the authenticated user's id
  /// [planId]   — the selected plan id
  /// [serverId] — optional: which server to provision on
  ///
  /// Returns the created subscription map.
  /// Throws [NotFoundException] or [ValidationException] on failure.
  Future<Map<String, dynamic>> create({
    required String userId,
    required String planId,
    String? serverId,
  }) async {
    // 1. Validate plan exists and is active
    final plan = await Plan().find(planId);
    if (plan == null) {
      throw NotFoundException('Plan not found.');
    }
    if (plan.status != 'active') {
      throw ValidationException({
        'plan_id': ['This plan is not available.']
      });
    }

    // 2. Check user doesn't already have an active subscription on this plan
    final existing = await Subscription().where({
      'user_id': userId,
      'plan_id': planId,
      'status': 'active',
    });
    if (existing.isNotEmpty) {
      throw ValidationException({
        'plan_id': ['You already have an active subscription to this plan.']
      });
    }

    // 3. Generate unique system username
    final systemUsername = await _generateUniqueUsername(userId);
    final ftpUsername = '${systemUsername}_ftp';

    // 4. Create subscription record (starts as pending)
    final sub = await Subscription().create({
      'user_id': userId,
      'plan_id': planId,
      'server_id': serverId,
      'system_username': systemUsername,
      'ftp_username': ftpUsername,
      'home_directory': '/home/$systemUsername',
      'status': 'pending',
      'provisioning_status': 'pending',
    });

    if (sub == null) {
      throw Exception('Failed to create subscription record.');
    }

    final subId = sub.toMap()['id'].toString();

    // 5. Trigger provisioning (async-safe — updates the record itself)
    final success = await _provisioning.provision(subId);

    // 6. Return current state
    final updated = await Subscription().find(subId);
    final result = updated?.toMap() ?? sub.toMap();

    if (!success) {
      result['_warning'] =
          'Provisioning failed. See provisioning_log for details.';
    }

    return result;
  }

  /// Returns all subscriptions for a user.
  Future<List<Map<String, dynamic>>> listForUser(String userId) async {
    final subs = await Subscription().whereSimple('user_id', userId);
    return subs.map((s) => s.toMap()).toList();
  }

  /// Returns all subscriptions (admin view).
  Future<List<Map<String, dynamic>>> listAll() async {
    final subs = await Subscription().all();
    return subs.map((s) => s.toMap()).toList();
  }

  /// Returns a single subscription — enforces ownership unless admin.
  Future<Map<String, dynamic>?> findById(
    String id, {
    String? ownerId,
  }) async {
    final sub = await Subscription().find(id);
    if (sub == null) return null;

    // Ownership check
    if (ownerId != null && sub.userId != ownerId) {
      throw NotFoundException('Subscription not found.');
    }

    return sub.toMap();
  }

  /// Cancels a subscription and deprovisions it from the server.
  Future<void> cancel(String id, {String? ownerId}) async {
    final sub = await Subscription().find(id);
    if (sub == null) throw NotFoundException('Subscription not found.');

    if (ownerId != null && sub.userId != ownerId) {
      throw NotFoundException('Subscription not found.');
    }

    if (sub.status == 'cancelled') {
      throw ValidationException({
        'status': ['Subscription is already cancelled.']
      });
    }

    await _provisioning.deprovision(id);
  }

  // ── Username generation ───────────────────────────────────────────────────

  /// Generates a unique, safe Linux-compatible username.
  /// Format: eu{short_user_id}{counter} — e.g. eu3f2a001
  Future<String> _generateUniqueUsername(String userId) async {
    // Take first 4 hex chars of the user id
    final shortId = userId.replaceAll('-', '').substring(0, 4).toLowerCase();
    var counter = 1;

    while (true) {
      final candidate = 'eu$shortId${counter.toString().padLeft(3, '0')}';
      final existing =
          await Subscription().whereSimple('system_username', candidate);
      if (existing.isEmpty) return candidate;
      counter++;
      if (counter > 999) {
        throw Exception('Could not generate unique username for user $userId');
      }
    }
  }
}
