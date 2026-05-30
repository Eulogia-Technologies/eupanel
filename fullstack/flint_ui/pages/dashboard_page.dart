import 'package:flint_ui/flint_ui.dart';

import '../components/components.dart';

class DashboardPage extends FlintComponent {
  Map<String, dynamic> props;

  DashboardPage(this.props) {
    _plans = ResourceController<List<FlintModelRecord>>(
      initialData: _planRecords(props['plans']),
      loader: () => FlintModelApi<FlintModelRecord>.records('/plans').list(),
      loadImmediately: true,
    );
  }

  late final ResourceController<List<FlintModelRecord>> _plans;

  @override
  void updateFrom(covariant DashboardPage next) {
    props = next.props;
  }

  @override
  void willUnmount() {
    _plans.dispose();
  }

  @override
  FlintNode build() {
    final role = props['role']?.toString() ?? 'customer';
    final stats = _map(props['stats']);
    final modules = _listOfMaps(props['modules']);

    return EuPanelDashboardShell(
      className: 'app-shell',
      brand: Row(className: 'brand', children: [
        Container(className: 'brand-mark', child: Text('EP')),
        Column(children: [
          Text.strong('EuPanel'),
          Text.span('Flint fullstack'),
        ]),
      ]),
      sidebar: EuPanelDashboardSidebar(role: role),
      topbar: _topbar(role),
      children: [
        _hero(role),
        CounterDemo(),
        Grid(
          className: 'stats-grid',
          children: [
            StatCard(
                label: 'Plans',
                value: stats['plans'] ?? '0',
                trend: 'Shared hosting packages'),
            StatCard(
                label: 'Subscriptions',
                value: stats['subscriptions'] ?? '0',
                trend: 'All customer subscriptions'),
            StatCard(
                label: 'Active',
                value: stats['activeSubscriptions'] ?? '0',
                trend: 'Provisioned and running',
                tone: Tone.success),
            StatCard(
                label: 'Users',
                value: stats['users'] ?? '0',
                trend: 'Admins, resellers, customers'),
            StatCard(
                label: 'Servers',
                value: stats['servers'] ?? '0',
                trend: 'Connected agents'),
            StatCard(
                label: 'Jobs',
                value: stats['jobs'] ?? '0',
                trend: 'Queued provisioning work',
                tone: Tone.info),
          ],
        ),
        Grid(
          className: 'content-grid',
          children: [
            Panel(
              className: 'panel panel-wide',
              title: 'Modules',
              description: 'Role-aware EuPanel workspaces',
              child: Grid(
                className: 'module-grid',
                children: [
                  for (final module in modules) _moduleCard(module),
                ],
              ),
            ),
            Panel(
              className: 'panel',
              title: 'Hosting plans',
              description:
                  'Server props first, FlintDart API refresh after mount',
              actions: Button(
                className: 'secondary-button',
                child: 'Refresh',
                onPressed: (_) => _plans.refresh(silent: true),
              ),
              child: ResourceView<List<FlintModelRecord>>(
                _plans,
                (snapshot) {
                  final plans = snapshot.data ?? const <FlintModelRecord>[];
                  if (snapshot.isLoading && plans.isEmpty) {
                    return DataTable(
                      columns: _planColumns,
                      loading: true,
                    );
                  }

                  if (plans.isEmpty) {
                    return EmptyState(
                      title: snapshot.isError
                          ? 'Could not load plans'
                          : 'No plans found',
                      message: snapshot.isError
                          ? snapshot.error.toString()
                          : 'Create plans through the API or seed data to populate this panel.',
                    );
                  }

                  return Column(children: [
                    if (snapshot.isError)
                      Alert(
                        title: 'Showing cached plans',
                        message: snapshot.error.toString(),
                        tone: Tone.warning,
                      ),
                    DataTable(
                      columns: _planColumns,
                      rows: [
                        for (final plan in plans) _planTableRow(plan),
                      ],
                    ),
                  ]);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  static const _planColumns = [
    TableColumn(key: 'name', label: 'Plan'),
    TableColumn(key: 'resources', label: 'Resources'),
    TableColumn(key: 'price', label: 'Price'),
  ];

  FlintNode _topbar(String role) {
    return Topbar(
      className: 'topbar',
      title: 'Hosting Control Center',
      subtitle: 'EuPanel $role',
      actions: Link(
        href: '/docs',
        className: 'secondary-button',
        child: 'API Docs',
      ),
    );
  }

  FlintNode _hero(String role) {
    return Section(className: 'hero', children: [
      Column(className: 'hero-copy', children: [
        Text.h2('Hosting Operations Dashboard'),
        Text.p(
          'Plans, subscriptions, users, servers, and provisioning work in one EuPanel control surface.',
        ),
      ]),
      Wrap(className: 'hero-actions', gap: 10, children: [
        Link(
          href: '/dashboard/admin',
          className: 'primary-button',
          child: 'Admin view',
        ),
        Link(
          href: '/dashboard/reseller',
          className: 'secondary-button',
          child: 'Reseller view',
        ),
      ]),
    ]);
  }

  FlintNode _moduleCard(Map<String, dynamic> module) {
    return Link(
      href: module['href']?.toString() ?? '#',
      className: 'module-card',
      children: [
        Text.h3(module['title']?.toString() ?? 'Module'),
        Text.p(module['body']?.toString() ?? ''),
      ],
    );
  }

  TableRowData _planTableRow(FlintModelRecord plan) {
    return TableRowData(cells: {
      'name': plan.string('name') ?? 'Hosting Plan',
      'resources':
          'Disk ${plan['disk_limit'] ?? plan['disk'] ?? '-'} / Bandwidth ${plan['bandwidth_limit'] ?? plan['bandwidth'] ?? '-'}',
      'price': plan.string('price') ?? '0',
    });
  }

  List<FlintModelRecord> _planRecords(Object? value) {
    return _listOfMaps(value).map(FlintModelRecord.new).toList();
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
