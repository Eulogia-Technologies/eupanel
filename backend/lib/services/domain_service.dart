import 'package:backend/models/domain_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/services/domain_provisioning_service.dart';
import 'package:backend/services/plan_service.dart';

/// Handles domain CRUD, validation, and provisioning orchestration.
class DomainService {
  final DomainProvisioningService _provisioning = DomainProvisioningService();

  /// Adds a domain to a subscription and provisions nginx + SSL.
  ///
  /// [userId]       — the requesting user's id (for ownership check)
  /// [subscriptionId] — which subscription this domain belongs to
  /// [domain]       — e.g. "example.com"
  /// [adminEmail]   — used for certbot SSL registration
  Future<Map<String, dynamic>> create({
    required String userId,
    required String subscriptionId,
    required String domain,
    required String adminEmail,
  }) async {
    // 1. Validate domain format
    final cleanDomain = domain.trim().toLowerCase();
    if (!_isValidDomain(cleanDomain)) {
      throw ValidationException({'domain': ['Invalid domain format. Use example.com or sub.example.com']});
    }

    // 2. Check subscription exists and user owns it
    final sub = await Subscription().find(subscriptionId);
    if (sub == null) {
      throw NotFoundException('Subscription not found.');
    }
    if (sub.userId != userId) {
      throw NotFoundException('Subscription not found.');
    }
    if (sub.status != 'active') {
      throw ValidationException({'subscription_id': ['Subscription is not active. Provision it first.']});
    }

    // 3. Check domain doesn't already exist globally
    final existing = await Domain().whereSimple('domain', cleanDomain);
    if (existing.isNotEmpty) {
      throw ValidationException({'domain': ['This domain is already registered.']});
    }

    // 4. Root path comes from the subscription's home directory
    final rootPath = '${sub.homeDirectory ?? '/home/${sub.systemUsername}'}/public_html';

    // 5. Create domain record (starts as pending)
    final domainRecord = await Domain().create({
      'subscription_id': subscriptionId,
      'domain': cleanDomain,
      'root_path': rootPath,
      'status': 'pending',
      'ssl_status': 'pending',
    });

    if (domainRecord == null) {
      throw Exception('Failed to create domain record.');
    }

    final domainId = domainRecord.toMap()['id'].toString();

    // 6. Provision: nginx + SSL
    try {
      await _provisioning.provision(
        domainId: domainId,
        adminEmail: adminEmail,
      );
    } catch (e) {
      // Provisioning failure was already logged to the domain record
      // Return the current state so the caller can report it
    }

    final updated = await Domain().find(domainId);
    return updated?.toMap() ?? domainRecord.toMap();
  }

  /// Lists all domains for a subscription.
  Future<List<Map<String, dynamic>>> listForSubscription({
    required String subscriptionId,
    required String userId,
  }) async {
    // Verify ownership
    final sub = await Subscription().find(subscriptionId);
    if (sub == null || sub.userId != userId) {
      throw NotFoundException('Subscription not found.');
    }

    final domains = await Domain().whereSimple('subscription_id', subscriptionId);
    return domains.map((d) => d.toMap()).toList();
  }

  /// Lists ALL domains (admin view).
  Future<List<Map<String, dynamic>>> listAll() async {
    final domains = await Domain().all();
    return domains.map((d) => d.toMap()).toList();
  }

  /// Returns a single domain — enforces ownership unless admin.
  Future<Map<String, dynamic>?> findById(String id, {String? ownerId}) async {
    final domainRecord = await Domain().find(id);
    if (domainRecord == null) return null;

    if (ownerId != null) {
      final sub = await Subscription().find(domainRecord.subscriptionId!);
      if (sub == null || sub.userId != ownerId) {
        throw NotFoundException('Domain not found.');
      }
    }

    return domainRecord.toMap();
  }

  /// Deletes a domain and removes its nginx config from the server.
  Future<void> delete(String id, {String? ownerId}) async {
    final domainRecord = await Domain().find(id);
    if (domainRecord == null) throw NotFoundException('Domain not found.');

    if (ownerId != null) {
      final sub = await Subscription().find(domainRecord.subscriptionId!);
      if (sub == null || sub.userId != ownerId) {
        throw NotFoundException('Domain not found.');
      }
    }

    // Remove from server first
    await _provisioning.deprovision(id);

    // Then remove record
    await domainRecord.delete(id);
  }

  // ── Domain validation ─────────────────────────────────────────────────────

  bool _isValidDomain(String domain) {
    if (domain.isEmpty || domain.length > 253) return false;

    // Strip leading www. for validation
    final check = domain.startsWith('www.') ? domain.substring(4) : domain;

    // Must have at least one dot
    if (!check.contains('.')) return false;

    // RFC 1123 hostname regex
    final regex = RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$',
    );
    return regex.hasMatch(domain);
  }
}
