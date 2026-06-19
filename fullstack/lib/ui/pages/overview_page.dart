import 'package:flint_ui/flint_ui.dart';

import '../components/components.dart';

class OverviewPage extends StatelessComponent {
  OverviewPage({
    required this.role,
    required this.props,
    required this.plans,
    required this.subscriptions,
    required this.databases,
    required this.mail,
    required this.backups,
    required this.dnsZones,
    required this.sslCertificates,
    required this.sites,
    required this.servers,
    required this.jobs,
  });

  final String role;
  final Map<String, dynamic> props;
  final ResourceController<List<FlintModelRecord>> plans;
  final ResourceController<List<FlintModelRecord>> subscriptions;
  final ResourceController<List<FlintModelRecord>> databases;
  final ResourceController<List<FlintModelRecord>> mail;
  final ResourceController<List<FlintModelRecord>> backups;
  final ResourceController<List<FlintModelRecord>> dnsZones;
  final ResourceController<List<FlintModelRecord>> sslCertificates;
  final ResourceController<List<FlintModelRecord>> sites;
  final ResourceController<List<FlintModelRecord>>? servers;
  final ResourceController<List<FlintModelRecord>>? jobs;

  @override
  View build() {
    final initialStats = _map(props['stats']);
    final plansCount = _count(plans, initialStats['plans']);
    final subsCount = _count(subscriptions, initialStats['subscriptions']);
    final databasesCount = _count(databases, initialStats['databases']);
    final mailCount = _count(mail, initialStats['mailAccounts']);
    final backupsCount = _count(backups, initialStats['backups']);
    final dnsCount = _count(dnsZones, initialStats['dnsZones']);
    final sslCount = _count(sslCertificates, initialStats['sslCertificates']);
    final sitesCount = _count(sites, initialStats['sites']);
    final serversCount = _count(servers, initialStats['servers']);
    final jobsCount = _count(jobs, initialStats['jobs']);
    final activeSubsCount = _activeSubscriptions(initialStats);
    final modules = _listOfMaps(props['modules']);

    return Column(
      children: [
        DashboardTopbar(role: role),
        DashboardHero(role: role),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: 'repeat(2, 1fr)',
            gap: 16,
            margin: EdgeInsets.only(bottom: 24),
            md: DartStyle(gridTemplateColumns: 'repeat(4, 1fr)'),
            lg: DartStyle(gridTemplateColumns: 'repeat(8, 1fr)'),
          ),
          children: [
            _metric('Plans', plansCount, 'Packages', Tone.primary),
            _metric('Subscriptions', subsCount, 'Accounts', Tone.info),
            _metric('Sites', sitesCount, 'File roots', Tone.success),
            _metric('DNS', dnsCount, 'Zones', Tone.info),
            _metric('SSL', sslCount, 'Certificates', Tone.success),
            _metric('Databases', databasesCount, 'Provisioned', Tone.neutral),
            _metric('Mail', mailCount, 'Mailboxes', Tone.neutral),
            _metric('Backups', backupsCount, 'Restore points', Tone.warning),
          ],
        ),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '1fr',
            gap: 24,
            lg: DartStyle(gridTemplateColumns: '1.2fr 0.8fr'),
          ),
          children: [
            Panel(
              title: 'Enterprise Workspaces',
              description: 'Role-aware sections backed by live EuPanel data',
              dartStyle: _panelStyle,
              child: Grid(
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gridTemplateColumns: '1fr',
                  gap: 16,
                  md: DartStyle(gridTemplateColumns: '1fr 1fr'),
                ),
                children: [
                  for (final module in modules)
                    DashboardModuleCard(module: module),
                ],
              ),
            ),
            Panel(
              title: 'Operational Snapshot',
              description:
                  'Latest plans, subscriptions, and provisioning state',
              dartStyle: _panelStyle,
              child: Column(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  flexDirection: FlexDirection.column,
                  gap: 14,
                ),
                children: [
                  _snapshotRow('Subscription activity',
                      '$activeSubsCount active of $subsCount total'),
                  _snapshotRow(
                      'Hosted sites', '$sitesCount document roots tracked'),
                  _snapshotRow('DNS and SSL',
                      '$dnsCount zones and $sslCount certificates'),
                  _snapshotRow('Database footprint',
                      '$databasesCount databases across hosted sites'),
                  _snapshotRow('Mail service',
                      '$mailCount mailboxes and forwarding rules'),
                  _snapshotRow('Backup coverage',
                      '$backupsCount backup records tracked'),
                  if (role == 'admin')
                    _snapshotRow('Admin operations',
                        '$jobsCount jobs on $serversCount servers'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  View _metric(String label, int value, String trend, Tone tone) {
    return StatCard(
      label: label,
      value: value,
      trend: trend,
      tone: tone,
      icon: Container(
        dartStyle: _statIconStyle,
        child: Text(label.substring(0, 1)),
      ),
      dartStyle: _statCardStyle,
    );
  }

  View _snapshotRow(String label, String value) {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        justifyContent: JustifyContent.between,
        alignItems: AlignItems.center,
        gap: 16,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 12,
        background: '#f8fafc',
        border: Border(color: Color('#e2e8f0'), width: 1),
      ),
      children: [
        Text.span(
          label,
          dartStyle: const DartStyle(
            color: '#475569',
            fontSize: 13,
            fontWeight: 700,
          ),
        ),
        Text.strong(
          value,
          dartStyle: const DartStyle(
            color: '#0f172a',
            fontSize: 13,
            fontWeight: 800,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  int _activeSubscriptions(Map<String, dynamic> initialStats) {
    if (subscriptions.data == null) {
      return initialStats['activeSubscriptions'] ?? 0;
    }

    return subscriptions.data!.where((item) {
      final status = item.string('status')?.toLowerCase();
      return status == null || status == 'active';
    }).length;
  }

  int _count(
      ResourceController<List<FlintModelRecord>>? resource, Object? seed) {
    return resource?.data?.length ?? _asInt(seed);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value
          .map((key, entryValue) => MapEntry(key.toString(), entryValue));
    }
    return const {};
  }

  List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      return item
          .map((key, entryValue) => MapEntry(key.toString(), entryValue));
    }).toList();
  }
}

const _panelStyle = DartStyle(
  background: '#ffffff',
  border: Border(color: Color('#e2e8f0'), width: 1),
  radius: 16,
  padding: EdgeInsets.all(24),
  shadow: Shadow(
    x: 0,
    y: 4,
    blur: 12,
    spread: 0,
    color: Color.rgba(0, 0, 0, 0.02),
  ),
);

const _statIconStyle = DartStyle(
  display: Display.flex,
  alignItems: AlignItems.center,
  justifyContent: JustifyContent.center,
  width: 32,
  height: 32,
  radius: 8,
  background: '#f1f5f9',
  fontSize: 14,
  fontWeight: 900,
  color: '#2563eb',
);

const _statCardStyle = DartStyle(
  background: '#ffffff',
  border: Border(color: Color('#e2e8f0'), width: 1),
  radius: 16,
  padding: EdgeInsets.all(20),
  shadow: Shadow(
    x: 0,
    y: 4,
    blur: 12,
    spread: 0,
    color: Color.rgba(0, 0, 0, 0.02),
  ),
  transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
  hover: DartStyle(
    transform: 'translateY(-2px)',
    border: Border(color: Color('#bfdbfe'), width: 1),
    shadow: Shadow(
      x: 0,
      y: 12,
      blur: 24,
      spread: 0,
      color: Color.rgba(37, 99, 235, 0.05),
    ),
  ),
);
