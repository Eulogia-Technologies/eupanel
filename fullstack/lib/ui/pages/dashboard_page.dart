import 'package:flint_ui/flint_ui.dart';

import '../components/dashboard_shell.dart';
import 'backups_page.dart';
import 'databases_page.dart';
import 'dns_page.dart';
import 'file_manager_page.dart';
import 'jobs_page.dart';
import 'mail_page.dart';
import 'overview_page.dart';
import 'plans_page.dart';
import 'servers_page.dart';
import 'ssl_page.dart';
import 'subscriptions_page.dart';
import 'websites_domains_page.dart';

class DashboardPage extends StatefulComponent {
  Map<String, dynamic> props;

  DashboardPage(this.props) {
    final role = props['role']?.toString() ?? 'customer';
    final isAdmin = role == 'admin';

    _plans = _records('/plans', initialData: _planRecords(props['plans']));
    _subscriptions = _records('/subscriptions');
    _databases = _records('/databases');
    _mail = _records('/mail');
    _backups = _records('/backups');
    _dnsZones = _records('/dns/zones');
    _sslCertificates = _records('/ssl/certificates');
    _sites = _records('/sites');

    _plansSub = _listen(_plans);
    _subsSub = _listen(_subscriptions);
    _databasesSub = _listen(_databases);
    _mailSub = _listen(_mail);
    _backupsSub = _listen(_backups);
    _dnsZonesSub = _listen(_dnsZones);
    _sslCertificatesSub = _listen(_sslCertificates);
    _sitesSub = _listen(_sites);

    if (isAdmin) {
      _servers = _records('/servers');
      _jobs = _records('/jobs');

      _serversSub = _listen(_servers!);
      _jobsSub = _listen(_jobs!);
    } else {
      _servers = null;
      _jobs = null;
      _serversSub = null;
      _jobsSub = null;
    }
  }

  late final ResourceController<List<FlintModelRecord>> _plans;
  late final ResourceController<List<FlintModelRecord>> _subscriptions;
  late final ResourceController<List<FlintModelRecord>> _databases;
  late final ResourceController<List<FlintModelRecord>> _mail;
  late final ResourceController<List<FlintModelRecord>> _backups;
  late final ResourceController<List<FlintModelRecord>> _dnsZones;
  late final ResourceController<List<FlintModelRecord>> _sslCertificates;
  late final ResourceController<List<FlintModelRecord>> _sites;
  late final ResourceController<List<FlintModelRecord>>? _servers;
  late final ResourceController<List<FlintModelRecord>>? _jobs;

  late final StateSignalSubscription _plansSub;
  late final StateSignalSubscription _subsSub;
  late final StateSignalSubscription _databasesSub;
  late final StateSignalSubscription _mailSub;
  late final StateSignalSubscription _backupsSub;
  late final StateSignalSubscription _dnsZonesSub;
  late final StateSignalSubscription _sslCertificatesSub;
  late final StateSignalSubscription _sitesSub;
  late final StateSignalSubscription? _serversSub;
  late final StateSignalSubscription? _jobsSub;

  @override
  void updateFrom(covariant DashboardPage next) {
    props = next.props;
  }

  @override
  void willUnmount() {
    _plansSub();
    _subsSub();
    _databasesSub();
    _mailSub();
    _backupsSub();
    _dnsZonesSub();
    _sslCertificatesSub();
    _sitesSub();
    _serversSub?.call();
    _jobsSub?.call();

    _plans.dispose();
    _subscriptions.dispose();
    _databases.dispose();
    _mail.dispose();
    _backups.dispose();
    _dnsZones.dispose();
    _sslCertificates.dispose();
    _sites.dispose();
    _servers?.dispose();
    _jobs?.dispose();
  }

  @override
  View build() {
    final role = props['role']?.toString() ?? 'customer';
    final path = _normalizePath(currentUri.path);

    return EuPanelDashboardShell(
      role: role,
      children: [_pageFor(path, role)],
    );
  }

  View _pageFor(String path, String role) {
    return switch (path) {
      '/dashboard/subscriptions' => SubscriptionsPage(
          role: role,
          plans: _plans,
          subscriptions: _subscriptions,
        ),
      '/dashboard/websites-domains' => WebsitesDomainsPage(
          role: role,
          subscriptions: _subscriptions,
        ),
      '/dashboard/dns' => DnsPage(zones: _dnsZones),
      '/dashboard/ssl' => SslPage(certificates: _sslCertificates),
      '/dashboard/file-manager' => FileManagerPage(sites: _sites),
      '/dashboard/databases' => DatabasesPage(databases: _databases),
      '/dashboard/mail' || '/dashboard/mails' => MailPage(mail: _mail),
      '/dashboard/backups' => BackupsPage(backups: _backups),
      '/dashboard/plans' when _canAccessAdminRoute(role) => PlansPage(
          role: role,
          plans: _plans,
        ),
      '/dashboard/servers' when _servers != null => ServersPage(
          servers: _servers,
        ),
      '/dashboard/jobs' when _jobs != null => JobsPage(
          jobs: _jobs,
        ),
      _ => OverviewPage(
          role: role,
          props: props,
          plans: _plans,
          subscriptions: _subscriptions,
          databases: _databases,
          mail: _mail,
          backups: _backups,
          dnsZones: _dnsZones,
          sslCertificates: _sslCertificates,
          sites: _sites,
          servers: _servers,
          jobs: _jobs,
        ),
    };
  }

  bool _canAccessAdminRoute(String role) =>
      role == 'admin' || role == 'reseller';

  ResourceController<List<FlintModelRecord>> _records(
    String path, {
    List<FlintModelRecord>? initialData,
  }) {
    return ResourceController<List<FlintModelRecord>>(
      initialData: initialData,
      loader: () => FlintModelApi<FlintModelRecord>.records(path).list(),
      loadImmediately: true,
    );
  }

  StateSignalSubscription _listen(
    ResourceController<List<FlintModelRecord>> resource,
  ) {
    return resource.state.listen((_) {
      setState(() {});
    });
  }

  List<FlintModelRecord> _planRecords(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      return FlintModelRecord(
        item.map((key, entryValue) => MapEntry(key.toString(), entryValue)),
      );
    }).toList();
  }

  String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path.isEmpty ? '/' : path;
  }
}
