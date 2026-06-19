import 'package:backend/models/plan_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/models/user_model.dart';
import 'package:backend/services/domain_service.dart';
import 'package:backend/services/hosting_username_service.dart';
import 'package:backend/services/password_generator_service.dart';
import 'package:backend/services/provisioning_service.dart';
import 'package:flint_dart/flint_dart.dart';

/// Handles subscription creation, lookup, and cancellation.
/// Delegates server work to the provisioning services.
class SubscriptionService {
  final ProvisioningService _provisioning = ProvisioningService();
  final DomainService _domains = DomainService();
  final HostingUsernameService _usernames = HostingUsernameService();
  final PasswordGeneratorService _passwords = PasswordGeneratorService();

  /// Creates one isolated hosting subscription login from a domain.
  ///
  /// [createdByUserId] is the admin/reseller/billing user creating the hosting.
  /// A new generated customer user becomes [Subscription.userId].
  Future<Map<String, dynamic>> create({
    required String createdByUserId,
    required String planId,
    required String domain,
    String? serverId,
    String? contactEmail,
    String? sslEmail,
  }) async {
    final cleanDomain = _normalizeDomain(domain);
    _validateDomain(cleanDomain);

    final plan = await Plan().find(planId);
    if (plan == null) {
      throw NotFoundException(message: 'Plan not found.');
    }
    if (plan.status != 'active') {
      throw ValidationException({
        'plan_id': ['This plan is not available.']
      });
    }

    final existingDomain = await Subscription().whereSimple(
      'primary_domain',
      cleanDomain,
    );
    if (existingDomain.isNotEmpty) {
      throw ValidationException({
        'domain': ['This domain already has a subscription.']
      });
    }

    final panelUsername = await _usernames.generateFromDomain(cleanDomain);
    final panelPassword = _passwords.generate();
    final ftpUsername = '${panelUsername}_ftp';

    final subscriptionUser = await User().create({
      'name': cleanDomain,
      'username': panelUsername,
      'email': '$panelUsername@hosting.local',
      'password': Hashing().hash(panelPassword),
      'role': 'customer',
    });

    if (subscriptionUser == null) {
      throw Exception('Failed to create subscription login user.');
    }

    final subscription = await Subscription().create({
      'user_id': subscriptionUser.toMap()['id'].toString(),
      'created_by_user_id': createdByUserId,
      'plan_id': planId,
      'server_id': serverId,
      'primary_domain': cleanDomain,
      'panel_username': panelUsername,
      'system_username': panelUsername,
      'ftp_username': ftpUsername,
      'home_directory': '/home/$panelUsername',
      'status': 'pending',
      'provisioning_status': 'pending',
    });

    if (subscription == null) {
      throw Exception('Failed to create subscription record.');
    }

    final subscriptionId = subscription.toMap()['id'].toString();
    final provisioned = await _provisioning.provision(subscriptionId);
    final updated = await Subscription().find(subscriptionId);
    final subscriptionMap = updated?.toMap() ?? subscription.toMap();

    Map<String, dynamic>? domainMap;
    if (provisioned) {
      domainMap = await _domains.create(
        userId: createdByUserId,
        subscriptionId: subscriptionId,
        domain: cleanDomain,
        adminEmail: sslEmail ?? contactEmail ?? 'admin@eupanel.local',
      );
    } else {
      subscriptionMap['_warning'] =
          'Provisioning failed. Domain was not created. See provisioning_log for details.';
    }

    return {
      'subscription': subscriptionMap,
      if (domainMap != null) 'domain': domainMap,
      'panel_login': {
        'username': panelUsername,
        'password': panelPassword,
      },
      'ftp': {
        'username': ftpUsername,
        'password': subscriptionMap['ftp_password'],
        'host': cleanDomain,
      },
      if (contactEmail != null && contactEmail.trim().isNotEmpty)
        'contact_email': contactEmail.trim().toLowerCase(),
      if (!provisioned) 'warning': subscriptionMap['_warning'],
    };
  }

  Future<List<Map<String, dynamic>>> listForActor({
    required String userId,
    required String role,
  }) async {
    if (role == 'admin') return listAll();

    final all = await Subscription().all();
    final visible = all.where((sub) => _canAccess(sub, userId)).toList();
    return visible.map((s) => s.toMap()).toList();
  }

  Future<List<Map<String, dynamic>>> listForUser(String userId) async {
    final subs = await Subscription().all();
    return subs
        .where((s) => _canAccess(s, userId))
        .map((s) => s.toMap())
        .toList();
  }

  Future<List<Map<String, dynamic>>> listAll() async {
    final subs = await Subscription().all();
    return subs.map((s) => s.toMap()).toList();
  }

  Future<Map<String, dynamic>?> findById(
    String id, {
    String? actorId,
  }) async {
    final sub = await Subscription().find(id);
    if (sub == null) return null;

    if (actorId != null && !_canAccess(sub, actorId)) {
      throw NotFoundException(message: 'Subscription not found.');
    }

    return sub.toMap();
  }

  Future<void> cancel(String id, {String? actorId}) async {
    final sub = await Subscription().find(id);
    if (sub == null) {
      throw NotFoundException(message: 'Subscription not found.');
    }

    if (actorId != null && !_canAccess(sub, actorId)) {
      throw NotFoundException(message: 'Subscription not found.');
    }

    if (sub.status == 'cancelled') {
      throw ValidationException({
        'status': ['Subscription is already cancelled.']
      });
    }

    await _provisioning.deprovision(id);
  }

  bool _canAccess(Subscription sub, String userId) {
    return sub.userId == userId || sub.createdByUserId == userId;
  }

  String _normalizeDomain(String domain) {
    return domain
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^https?://'), '')
        .split('/')
        .first;
  }

  void _validateDomain(String domain) {
    if (domain.isEmpty || domain.length > 253) {
      throw ValidationException({
        'domain': ['Invalid domain format. Use example.com or sub.example.com']
      });
    }

    final check = domain.startsWith('www.') ? domain.substring(4) : domain;
    final regex = RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$',
    );

    if (!check.contains('.') || !regex.hasMatch(domain)) {
      throw ValidationException({
        'domain': ['Invalid domain format. Use example.com or sub.example.com']
      });
    }
  }
}
