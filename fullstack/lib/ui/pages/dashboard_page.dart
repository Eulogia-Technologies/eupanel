import 'package:flint_ui/flint_ui.dart';

import '../components/components.dart';

class DashboardPage extends FlintComponent {
  Map<String, dynamic> props;

  DashboardPage(this.props) {
    final role = props['role']?.toString() ?? 'customer';

    _plans = ResourceController<List<FlintModelRecord>>(
      initialData: _planRecords(props['plans']),
      loader: () => FlintModelApi<FlintModelRecord>.records('/plans').list(),
      loadImmediately: true,
    );
    _subscriptions = ResourceController<List<FlintModelRecord>>(
      loader: () => FlintModelApi<FlintModelRecord>.records('/subscriptions').list(),
      loadImmediately: true,
    );

    _plansSub = _plans.state.listen((_) {
      setState(() {});
    });
    _subsSub = _subscriptions.state.listen((_) {
      setState(() {});
    });

    if (role == 'admin') {
      _users = ResourceController<List<FlintModelRecord>>(
        loader: () => FlintModelApi<FlintModelRecord>.records('/users').list(),
        loadImmediately: true,
      );
      _servers = ResourceController<List<FlintModelRecord>>(
        loader: () => FlintModelApi<FlintModelRecord>.records('/servers').list(),
        loadImmediately: true,
      );
      _jobs = ResourceController<List<FlintModelRecord>>(
        loader: () => FlintModelApi<FlintModelRecord>.records('/jobs').list(),
        loadImmediately: true,
      );

      _usersSub = _users!.state.listen((_) {
        setState(() {});
      });
      _serversSub = _servers!.state.listen((_) {
        setState(() {});
      });
      _jobsSub = _jobs!.state.listen((_) {
        setState(() {});
      });
    } else {
      _users = null;
      _servers = null;
      _jobs = null;
      _usersSub = null;
      _serversSub = null;
      _jobsSub = null;
    }
  }

  late final ResourceController<List<FlintModelRecord>> _plans;
  late final ResourceController<List<FlintModelRecord>> _subscriptions;
  late final ResourceController<List<FlintModelRecord>>? _users;
  late final ResourceController<List<FlintModelRecord>>? _servers;
  late final ResourceController<List<FlintModelRecord>>? _jobs;

  late final StateSignalSubscription _plansSub;
  late final StateSignalSubscription _subsSub;
  late final StateSignalSubscription? _usersSub;
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
    _usersSub?.call();
    _serversSub?.call();
    _jobsSub?.call();

    _plans.dispose();
    _subscriptions.dispose();
    _users?.dispose();
    _servers?.dispose();
    _jobs?.dispose();
  }

  @override
  FlintNode build() {
    final role = props['role']?.toString() ?? 'customer';
    final path = _normalizePath(currentUri.path);

    if (path == '/dashboard/plans') {
      return PlansView(role: role, plans: _plans);
    }

    if (path == '/dashboard/subscriptions') {
      return SubscriptionsView(role: role, plans: _plans, subscriptions: _subscriptions);
    }

    if (path == '/dashboard/websites-domains') {
      return WebsitesDomainsView(role: role, subscriptions: _subscriptions);
    }

    final initialStats = _map(props['stats']);
    final plansCount = _plans.data?.length ?? initialStats['plans'] ?? 0;
    final subsCount = _subscriptions.data?.length ?? initialStats['subscriptions'] ?? 0;

    int activeSubsCount = initialStats['activeSubscriptions'] ?? 0;
    if (_subscriptions.data != null) {
      activeSubsCount = _subscriptions.data!.where((item) {
        final status = item.string('status')?.toLowerCase();
        return status == null || status == 'active';
      }).length;
    }

    final usersCount = _users?.data?.length ?? initialStats['users'] ?? 0;
    final serversCount = _servers?.data?.length ?? initialStats['servers'] ?? 1;
    final jobsCount = _jobs?.data?.length ?? initialStats['jobs'] ?? 0;

    final modules = _listOfMaps(props['modules']);

    return EuPanelDashboardShell(
      brand: Row(
        dartStyle: const DartStyle(
          alignItems: AlignItems.center,
          gap: 12,
        ),
        children: [
          Container(
            dartStyle: const DartStyle(
              display: Display.flex,
              alignItems: AlignItems.center,
              justifyContent: JustifyContent.center,
              width: 40,
              height: 40,
              radius: 12,
              background: 'linear-gradient(135deg, #06b6d4, #2563eb)',
              color: '#ffffff',
              fontWeight: 800,
              fontSize: 16,
              shadow: '0 0 16px rgba(6, 182, 212, 0.45)',
            ),
            child: Text('EP'),
          ),
          Column(
            dartStyle: const DartStyle(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: 2,
            ),
            children: [
              Text.strong(
                'EuPanel',
                dartStyle: const DartStyle(
                  color: '#ffffff',
                  fontWeight: 800,
                  fontSize: 16,
                  letterSpacing: -0.4,
                ),
              ),
              Text.span(
                'Flint control node',
                dartStyle: const DartStyle(
                  color: '#64748b',
                  fontSize: 11,
                  fontWeight: 600,
                ),
              ),
            ],
          ),
        ],
      ),
      sidebar: EuPanelDashboardSidebar(role: role),
      topbar: DashboardTopbar(role: role),
      children: [
        DashboardHero(role: role),
        CounterDemo(),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: 'repeat(2, 1fr)',
            gap: 16,
            margin: EdgeInsets.only(bottom: 24),
            md: DartStyle(
              gridTemplateColumns: 'repeat(3, 1fr)',
            ),
            lg: DartStyle(
              gridTemplateColumns: 'repeat(6, 1fr)',
            ),
          ),
          children: [
            StatCard(
              label: 'Plans',
              value: plansCount,
              trend: 'Shared hosting packages',
              icon: Container(
                dartStyle: _statIconStyle,
                child: Text('📦'),
              ),
              dartStyle: _statCardStyle,
            ),
            StatCard(
              label: 'Subscriptions',
              value: subsCount,
              trend: 'All customer subscriptions',
              icon: Container(
                dartStyle: _statIconStyle,
                child: Text('🚀'),
              ),
              dartStyle: _statCardStyle,
            ),
            StatCard(
              label: 'Active',
              value: activeSubsCount,
              trend: 'Provisioned and running',
              tone: Tone.success,
              icon: Container(
                dartStyle: _statIconStyleSuccess,
                child: Text('⚡'),
              ),
              dartStyle: _statCardStyle,
            ),
            StatCard(
              label: 'Users',
              value: usersCount,
              trend: 'Admins, resellers, customers',
              icon: Container(
                dartStyle: _statIconStyle,
                child: Text('👥'),
              ),
              dartStyle: _statCardStyle,
            ),
            StatCard(
              label: 'Servers',
              value: serversCount,
              trend: 'Connected agents',
              icon: Container(
                dartStyle: _statIconStyle,
                child: Text('🖥️'),
              ),
              dartStyle: _statCardStyle,
            ),
            StatCard(
              label: 'Jobs',
              value: jobsCount,
              trend: 'Queued provisioning work',
              tone: Tone.info,
              icon: Container(
                dartStyle: _statIconStyleInfo,
                child: Text('⚙️'),
              ),
              dartStyle: _statCardStyle,
            ),
          ],
        ),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '1fr',
            gap: 24,
            lg: DartStyle(
              gridTemplateColumns: '1.5fr 0.8fr',
            ),
          ),
          children: [
            Panel(
              title: 'Modules',
              description: 'Role-aware EuPanel workspaces',
              dartStyle: const DartStyle(
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
              ),
              child: Grid(
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gridTemplateColumns: '1fr 1fr',
                  gap: 16,
                ),
                children: [
                  for (final module in modules) DashboardModuleCard(module: module),
                ],
              ),
            ),
            Panel(
              title: 'Hosting plans',
              description:
                  'Server props first, FlintDart API refresh after mount',
              actions: Button(
                child: 'Refresh',
                tone: Tone.neutral,
                variant: ButtonVariant.soft,
                onPressed: (_) => _plans.refresh(silent: true),
              ),
              dartStyle: const DartStyle(
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

  String _normalizePath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path.isEmpty ? '/' : path;
  }

  static const _statIconStyle = DartStyle(
    display: Display.flex,
    alignItems: AlignItems.center,
    justifyContent: JustifyContent.center,
    width: 32,
    height: 32,
    radius: 8,
    background: '#f1f5f9',
    fontSize: 16,
  );

  static const _statIconStyleSuccess = DartStyle(
    display: Display.flex,
    alignItems: AlignItems.center,
    justifyContent: JustifyContent.center,
    width: 32,
    height: 32,
    radius: 8,
    background: '#ecfdf5',
    fontSize: 16,
  );

  static const _statIconStyleInfo = DartStyle(
    display: Display.flex,
    alignItems: AlignItems.center,
    justifyContent: JustifyContent.center,
    width: 32,
    height: 32,
    radius: 8,
    background: '#f0f9ff',
    fontSize: 16,
  );

  static const _statCardStyle = DartStyle(
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
}
