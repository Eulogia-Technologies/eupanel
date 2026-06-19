import 'package:backend/models/plan_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/models/user_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/job_model.dart';
import 'package:backend/models/database_model.dart';
import 'package:backend/models/backup_model.dart';
import 'package:backend/models/mail_account_model.dart';
import 'package:backend/models/dns_zone_model.dart';
import 'package:backend/models/ssl_certificate_model.dart';
import 'package:backend/models/site_model.dart';
import 'package:backend/config/app_config.dart';
import 'package:flint_dart/flint_dart.dart';

class UiController {
  Response _page(
    Response res,
    String component, {
    Map<String, dynamic> props = const {},
    String title = 'EuPanel',
  }) {
    return res.page(
      component,
      title: title,
      props: props,
      script: '/main.dart.js',
      stylesheets: const ['/style.css'],
    );
  }

  Future<Response> home(Request req, Response res) async {
    if (await _hasValidUiSession(req)) {
      return res.redirect('/dashboard');
    }
    return res.redirect('/login');
  }

  Response login(Request req, Response res) {
    return _page(
      res,
      'Login',
      title: 'EuPanel Login',
      props: {
        'authBase': '/auth',
        'demoSeedEnabled': AppConfig.enableDemoSeed && !AppConfig.isProduction,
      },
    );
  }

  Future<Response> dashboard(Request req, Response res) async {
    final user = await req.user;
    if (user == null) return res.redirect('/login');

    final role = user['role']?.toString().toLowerCase() ?? 'customer';
    final section = req.params['section'];

    // Role gate admin-only sections
    final adminSections = const ['servers', 'jobs'];
    if (adminSections.contains(section) && role != 'admin') {
      return res.redirect('/dashboard');
    }

    // Role gate reseller-only sections
    if (section == 'plans' && role != 'admin' && role != 'reseller') {
      return res.redirect('/dashboard');
    }

    return _page(
      res,
      'Dashboard',
      title: 'EuPanel Dashboard',
      props: await _dashboardProps(role: role),
    );
  }

  Future<bool> _hasValidUiSession(Request req) async {
    return await req.user != null;
  }

  Future<Map<String, dynamic>> _dashboardProps({required String role}) async {
    final plans = await Plan().all();
    final subscriptions = await Subscription().all();
    final users = await User().all();
    final servers = await Server().all();
    final jobs = await Job().all();
    final databases = await DatabaseModel().all();
    final backups = await Backup().all();
    final mailAccounts = await MailAccount().all();
    final dnsZones = await DnsZone().all();
    final sslCertificates = await SslCertificate().all();
    final sites = await Site().all();

    return {
      'role': role,
      'stats': {
        'plans': plans.length,
        'subscriptions': subscriptions.length,
        'activeSubscriptions': 0,
        'users': users.length,
        'servers': servers.length,
        'jobs': jobs.length,
        'databases': databases.length,
        'backups': backups.length,
        'mailAccounts': mailAccounts.length,
        'dnsZones': dnsZones.length,
        'sslCertificates': sslCertificates.length,
        'sites': sites.length,
      },
      'modules': _modulesForRole(role),
      'plans': plans
          .map((plan) => {
                'id': plan.id?.toString(),
                'name': plan.getAttribute('name')?.toString() ?? 'Hosting Plan',
                'price': plan.getAttribute('price')?.toString() ?? '0',
                'disk': plan.getAttribute('disk_limit')?.toString() ?? '-',
                'bandwidth':
                    plan.getAttribute('bandwidth_limit')?.toString() ?? '-',
              })
          .toList(),
    };
  }

  List<Map<String, String>> _modulesForRole(String role) {
    final shared = [
      {
        'title': 'Websites & Domains',
        'body': 'Connect hosted domains, SSL, and Git deployments.',
        'href': '/dashboard/websites-domains',
      },
      {
        'title': 'DNS Zones',
        'body': 'Manage authoritative DNS zones and records.',
        'href': '/dashboard/dns',
      },
      {
        'title': 'SSL Certificates',
        'body': 'Track Let\'s Encrypt issuance for hosted websites.',
        'href': '/dashboard/ssl',
      },
      {
        'title': 'File Manager',
        'body': 'Inspect document roots and hosted site file locations.',
        'href': '/dashboard/file-manager',
      },
      {
        'title': 'Databases',
        'body': 'Create and inspect MySQL databases for subscriptions.',
        'href': '/dashboard/databases',
      },
      {
        'title': 'Backups',
        'body': 'Track backup jobs and restore points.',
        'href': '/dashboard/backups',
      },
    ];

    if (role == 'admin') {
      return [
        {
          'title': 'Servers',
          'body': 'Provisioning, agent health, runtime versions, and capacity.',
          'href': '/dashboard/servers',
        },
        {
          'title': 'Service Plans',
          'body': 'Create shared hosting plans and reseller offerings.',
          'href': '/dashboard/plans',
        },
        {
          'title': 'Jobs',
          'body': 'Provisioning queue, failed actions, and sync history.',
          'href': '/dashboard/jobs',
        },
        ...shared,
      ];
    }

    if (role == 'reseller') {
      return [
        {
          'title': 'Plans',
          'body': 'Review available hosting packages for subscriptions.',
          'href': '/dashboard/plans',
        },
        ...shared,
      ];
    }

    return [
      {
        'title': 'Subscriptions',
        'body': 'View your active hosting subscriptions and limits.',
        'href': '/dashboard/subscriptions',
      },
      ...shared,
    ];
  }
}
