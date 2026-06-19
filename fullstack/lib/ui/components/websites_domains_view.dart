import 'package:flint_ui/flint_ui.dart';
import 'package:universal_web/web.dart' as web;
import 'dashboard_page_topbar.dart';
import 'deploy_metric.dart';

class WebsitesDomainsView extends StatefulComponent {
  final String role;
  final ResourceController<List<FlintModelRecord>> subscriptions;

  WebsitesDomainsView({
    required this.role,
    required this.subscriptions,
  }) {
    _domains = ResourceController<List<FlintModelRecord>>(
      loader: () => FlintModelApi<FlintModelRecord>.records('/domains').list(),
      loadImmediately: true,
    );
    _gitDeploys = ResourceController<List<FlintModelRecord>>(
      loader: () =>
          FlintModelApi<FlintModelRecord>.records('/github/deploys').list(),
      loadImmediately: true,
    );
    _gitStatus = ResourceController<Map<String, dynamic>>(
      loader: () async {
        final response =
            await clientRouter.get<Map<String, dynamic>>('/github/status');
        if (response.isError) return const {'connected': false};
        return response.data ?? const {'connected': false};
      },
      loadImmediately: true,
    );
    _repos = ResourceController<List<Map<String, dynamic>>>(
      loader: () async {
        final response =
            await clientRouter.get<Map<String, dynamic>>('/github/repos');
        if (response.isError) return const [];
        final list = response.data?['data'];
        if (list is List) {
          return list
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
        return const [];
      },
      loadImmediately: false,
    );
  }

  late final ResourceController<List<FlintModelRecord>> _domains;
  late final ResourceController<List<FlintModelRecord>> _gitDeploys;
  late final ResourceController<Map<String, dynamic>> _gitStatus;
  late final ResourceController<List<Map<String, dynamic>>> _repos;

  final _domainForm = useForm({
    'subscription_id': '',
    'domain': '',
  });

  final _deployForm = useForm({
    'repo_full_name': '',
    'branch': 'main',
  });

  bool _showDomainModal = false;
  String? _domainFormError;

  bool _showDeployModal = false;
  String? _deployFormError;
  String? _activeDeployDomainId;

  @override
  void updateFrom(covariant WebsitesDomainsView next) {}

  @override
  void willUnmount() {
    _domains.dispose();
    _gitDeploys.dispose();
    _gitStatus.dispose();
    _repos.dispose();
  }

  @override
  View build() {
    final params = currentUri.queryParameters;
    if (params['github'] == 'connected' &&
        _gitStatus.data?['connected'] != true) {
      Future.microtask(() {
        _gitStatus.refresh();
      });
    }

    return Column(
      children: [
        DashboardPageTopbar(
          title: 'Websites & Domains',
          subtitle:
              'Manage domains, paths, Let\'s Encrypt SSL, and Git deployments',
          actions: Row(
            dartStyle: const DartStyle(
              display: Display.flex,
              alignItems: AlignItems.center,
              gap: 8,
            ),
            children: [
              Button(
                dartStyle: const DartStyle(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  radius: 10,
                  background: 'linear-gradient(135deg, #06b6d4, #2563eb)',
                  color: '#ffffff',
                  fontSize: 13,
                  fontWeight: 700,
                  cursor: Cursor.pointer,
                  shadow: Shadow(
                      x: 0,
                      y: 4,
                      blur: 12,
                      color: Color.rgba(37, 99, 235, 0.2)),
                  hover: DartStyle(
                    shadow: Shadow(
                        x: 0,
                        y: 6,
                        blur: 16,
                        color: Color.rgba(37, 99, 235, 0.3)),
                    transform: 'translateY(-1px)',
                  ),
                ),
                onPressed: (_) {
                  _domainForm.reset();
                  final subsList = subscriptions.data ?? [];
                  if (subsList.isNotEmpty) {
                    _domainForm.setField(
                        'subscription_id', subsList.first.string('id') ?? '');
                  }
                  _domainFormError = null;
                  _showDomainModal = true;
                  setState(() {});
                },
                child: Text('Add Website'),
              ),
              Button(
                child: 'Refresh',
                dartStyle: const DartStyle(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  radius: 10,
                  background: '#ffffff',
                  border: Border(color: Color('#cbd5e1'), width: 1),
                  color: '#475569',
                  fontSize: 13,
                  fontWeight: 700,
                  cursor: Cursor.pointer,
                  hover: DartStyle(
                    background: '#f8fafc',
                    color: '#0f172a',
                  ),
                ),
                onPressed: (_) {
                  _domains.refresh(silent: true);
                  _gitDeploys.refresh(silent: true);
                  _gitStatus.refresh(silent: true);
                },
              ),
            ],
          ),
        ),
        _buildGithubBanner(),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '1fr',
            gap: 24,
            alignItems: AlignItems.start,
          ),
          children: [
            Panel(
              title: 'Hosted Domains',
              description:
                  'Create and connect domains to your server environment.',
              dartStyle: const DartStyle(
                background: '#ffffff',
                border: Border(color: Color('#e2e8f0'), width: 1),
                radius: 16,
                padding: EdgeInsets.all(24),
                shadow: Shadow(
                  x: 0,
                  y: 4,
                  blur: 12,
                  color: Color.rgba(0, 0, 0, 0.02),
                ),
              ),
              child: ResourceView<List<FlintModelRecord>>(
                _domains,
                (snapshot) {
                  final list = snapshot.data ?? const <FlintModelRecord>[];
                  if (snapshot.isLoading && list.isEmpty) {
                    return Container(
                      dartStyle: const DartStyle(
                        padding: EdgeInsets.all(24),
                        textAlign: TextAlign.center,
                      ),
                      child: Text('Loading websites...'),
                    );
                  }

                  if (list.isEmpty) {
                    return EmptyState(
                      title: snapshot.isError
                          ? 'Could not load websites'
                          : 'No websites hosted',
                      message: snapshot.isError
                          ? snapshot.error.toString()
                          : 'Get started by adding your first website/domain mapping.',
                    );
                  }

                  final deploys =
                      _gitDeploys.data ?? const <FlintModelRecord>[];
                  final subs = subscriptions.data ?? const <FlintModelRecord>[];

                  return Column(
                    dartStyle: const DartStyle(
                      display: Display.flex,
                      flexDirection: FlexDirection.column,
                      gap: 16,
                    ),
                    children: [
                      if (snapshot.isError)
                        Alert(
                          title: 'Showing cached domains',
                          message: snapshot.error.toString(),
                          tone: Tone.warning,
                        ),
                      for (final domain in list)
                        _buildDomainPreviewCard(domain, deploys, subs),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (_showDomainModal) _buildDomainModal(),
        if (_showDeployModal) _buildDeployModal(),
      ],
    );
  }

  FlintNode _buildGithubBanner() {
    return ResourceView<Map<String, dynamic>>(
      _gitStatus,
      (snapshot) {
        final connected = snapshot.data?['connected'] == true;
        final username = snapshot.data?['github_username']?.toString() ?? '';

        if (connected) {
          return Container(
            dartStyle: const DartStyle(
              display: Display.flex,
              alignItems: AlignItems.center,
              justifyContent: JustifyContent.between,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              radius: 16,
              background: 'linear-gradient(135deg, #f0fdf4, #dcfce7)',
              border: Border(color: Color('#bbf7d0'), width: 1),
              margin: EdgeInsets.only(bottom: 24),
              shadow: Shadow(
                  x: 0, y: 4, blur: 12, color: Color.rgba(34, 197, 94, 0.05)),
            ),
            children: [
              Row(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  alignItems: AlignItems.center,
                  gap: 16,
                ),
                children: [
                  Container(
                    dartStyle: const DartStyle(
                      display: Display.flex,
                      alignItems: AlignItems.center,
                      justifyContent: JustifyContent.center,
                      width: 44,
                      height: 44,
                      radius: 12,
                      background: '#ffffff',
                      shadow: Shadow(
                          x: 0,
                          y: 2,
                          blur: 8,
                          color: Color.rgba(0, 0, 0, 0.05)),
                    ),
                    child: Text.span('🚀',
                        dartStyle: const DartStyle(fontSize: 20)),
                  ),
                  Column(
                    dartStyle: const DartStyle(
                      display: Display.flex,
                      flexDirection: FlexDirection.column,
                      gap: 2,
                    ),
                    children: [
                      Text.strong(
                        'GitHub Integration Active',
                        dartStyle: const DartStyle(
                            fontSize: 15,
                            fontWeight: 700,
                            color: Color('#14532d')),
                      ),
                      Text.span(
                        'Successfully linked to @$username. Webhooks are configured.',
                        dartStyle: const DartStyle(
                            fontSize: 13, color: Color('#166534')),
                      ),
                    ],
                  ),
                ],
              ),
              Button(
                dartStyle: const DartStyle(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  radius: 8,
                  background: '#ffffff',
                  border: Border(color: Color('#bbf7d0'), width: 1),
                  color: Color('#166534'),
                  fontSize: 12,
                  fontWeight: 700,
                  cursor: Cursor.pointer,
                  hover: DartStyle(background: '#f0fdf4'),
                ),
                onPressed: (_) => _handleGithubDisconnect(),
                child: Text('Disconnect'),
              ),
            ],
          );
        }

        return Container(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.between,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            radius: 16,
            background: 'linear-gradient(135deg, #f0f9ff, #e0f2fe)',
            border: Border(color: Color('#bae6fd'), width: 1),
            margin: EdgeInsets.only(bottom: 24),
            shadow: Shadow(
                x: 0, y: 4, blur: 12, color: Color.rgba(14, 165, 233, 0.05)),
          ),
          children: [
            Row(
              dartStyle: const DartStyle(
                display: Display.flex,
                alignItems: AlignItems.center,
                gap: 16,
              ),
              children: [
                Container(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    alignItems: AlignItems.center,
                    justifyContent: JustifyContent.center,
                    width: 44,
                    height: 44,
                    radius: 12,
                    background: '#ffffff',
                    shadow: Shadow(
                        x: 0, y: 2, blur: 8, color: Color.rgba(0, 0, 0, 0.05)),
                  ),
                  child:
                      Text.span('🐙', dartStyle: const DartStyle(fontSize: 20)),
                ),
                Column(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    flexDirection: FlexDirection.column,
                    gap: 2,
                  ),
                  children: [
                    Text.strong(
                      'Link GitHub Account',
                      dartStyle: const DartStyle(
                          fontSize: 15,
                          fontWeight: 700,
                          color: Color('#0369a1')),
                    ),
                    Text.span(
                      'Enable automated Git-to-Web deployments on your server in one click.',
                      dartStyle: const DartStyle(
                          fontSize: 13, color: Color('#075985')),
                    ),
                  ],
                ),
              ],
            ),
            Link(
              href: '/github/connect',
              dartStyle: const DartStyle(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                background: '#24292f',
                color: '#ffffff',
                fontSize: 13,
                fontWeight: 700,
                cursor: Cursor.pointer,
                shadow: Shadow(
                    x: 0, y: 4, blur: 12, color: Color.rgba(36, 41, 47, 0.2)),
              ),
              child: 'Connect GitHub',
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGithubDisconnect() async {
    final confirmed = web.window.confirm('Disconnect your GitHub account?');
    if (!confirmed) return;

    final response =
        await clientRouter.delete<Map<String, dynamic>>('/github/disconnect');
    if (response.isError) {
      web.window.alert((response.error ?? 'Failed to disconnect.').toString());
      return;
    }
    _gitStatus.refresh();
  }

  FlintNode _buildDomainPreviewCard(FlintModelRecord domain,
      List<FlintModelRecord> deploys, List<FlintModelRecord> subs) {
    final id = domain.string('id') ?? '';
    final domainName = domain.string('domain') ?? 'Domain';
    final status = domain.string('status') ?? 'pending';
    final sslStatus = domain.string('ssl_status') ?? 'pending';
    final rootPath = domain.string('root_path') ??
        domain.string('rootPath') ??
        '/var/www/$domainName/public';
    final subId = domain.string('subscription_id') ?? '';
    final disk =
        domain.string('disk_usage') ?? domain.string('diskUsage') ?? '-';
    final traffic =
        domain.string('traffic_month') ?? domain.string('trafficMonth') ?? '-';

    FlintModelRecord? sub;
    for (final s in subs) {
      if (s.string('id') == subId) {
        sub = s;
        break;
      }
    }

    FlintModelRecord? deploy;
    for (final d in deploys) {
      if (d.string('domain_id') == id) {
        deploy = d;
        break;
      }
    }

    final hasDeploy = deploy != null;
    final repoName = deploy?.string('repo_full_name') ?? '';
    final branchName = deploy?.string('branch') ?? 'main';
    final deployId = deploy?.string('id') ?? '';
    final githubConnected = _gitStatus.data?['connected'] == true;
    final statusLabel = _domainStatusLabel(status);
    final statusTone = _domainStatusTone(status);

    return Container(
      dartStyle: const DartStyle(
        padding: EdgeInsets.all(0),
        radius: 14,
        background: '#ffffff',
        border: Border(color: Color('#cbd5e1'), width: 1),
        shadow: Shadow(
          x: 0,
          y: 10,
          blur: 28,
          color: Color.rgba(15, 23, 42, 0.06),
        ),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        overflow: Overflow.hidden,
      ),
      children: [
        _domainPreviewHeader(
          domainName: domainName,
          subscriptionName: sub?.string('system_username') ?? 'Subscription',
          statusLabel: statusLabel,
          statusBg: statusTone.$1,
          statusColor: statusTone.$2,
          sslStatus: sslStatus,
        ),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '300px minmax(0, 1fr)',
            gap: 24,
            padding: EdgeInsets.all(20),
            alignItems: AlignItems.start,
          ),
          children: [
            Column(
              dartStyle: const DartStyle(
                display: Display.flex,
                flexDirection: FlexDirection.column,
                gap: 12,
              ),
              children: [
                _domainPreviewImage(domainName, statusLabel),
                _domainStatistics(
                  disk: disk,
                  traffic: traffic,
                  rootPath: rootPath,
                ),
              ],
            ),
            Column(
              dartStyle: const DartStyle(
                display: Display.flex,
                flexDirection: FlexDirection.column,
                gap: 18,
              ),
              children: [
                Row(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    gap: 28,
                    flexWrap: FlexWrap.wrap,
                  ),
                  children: [
                    _tabLabel('Dashboard', active: true),
                    _tabLabel('Hosting & DNS'),
                    _tabLabel('Mail'),
                    _tabLabel('Files & Databases'),
                    _tabLabel('Security'),
                  ],
                ),
                Grid(
                  dartStyle: const DartStyle(
                    display: Display.grid,
                    gridTemplateColumns: '1fr 1fr',
                    gap: 18,
                  ),
                  children: [
                    _toolSection('Files & Databases', [
                      _toolTile(
                          'Connection Info',
                          'FTP, database and shell credentials',
                          '/dashboard/subscriptions',
                          'CI'),
                      _toolTile('File Manager', rootPath,
                          '/dashboard/file-manager', 'FM'),
                      _toolTile(
                          'FTP Access',
                          sub?.string('ftp_username') ?? 'Provisioned user',
                          '/dashboard/subscriptions',
                          'FTP'),
                      _toolTile('Databases', 'MySQL databases and users',
                          '/dashboard/databases', 'DB'),
                      _toolTile('Backup & Restore', 'Backups for this website',
                          '/dashboard/backups', 'BR'),
                    ]),
                    _toolSection('Hosting & DNS', [
                      _toolTile(
                          'Hosting Settings',
                          'Runtime, root path and status',
                          '/dashboard/websites-domains',
                          'HS'),
                      _toolTile('DNS Settings', 'Zones and records',
                          '/dashboard/dns', 'DNS'),
                      _toolTile(
                          'SSL/TLS Certificates',
                          sslStatus == 'active'
                              ? 'Certificate active'
                              : 'Issue certificate',
                          '/dashboard/ssl',
                          'SSL'),
                      _toolTile(
                          'Mail', 'Domain mailboxes', '/dashboard/mail', 'ML'),
                      _toolTile('Website Copying', 'Copy or clone files',
                          '/dashboard/file-manager', 'CP'),
                    ]),
                    _toolSection('Dev Tools', [
                      _toolTile(
                          'Git Deployment',
                          hasDeploy
                              ? '$repoName ($branchName)'
                              : 'Connect repository',
                          '/dashboard/websites-domains',
                          'GIT'),
                      _toolTile('Runtime', domain.string('runtime') ?? 'PHP',
                          '/dashboard/file-manager', 'PHP'),
                      _toolTile('Logs', 'Provisioning and deploy logs',
                          '/dashboard/jobs', 'LOG'),
                      _toolTile('Scheduled Tasks', 'Cron and automation',
                          '/dashboard/jobs', 'CR'),
                    ]),
                    _gitDeploymentPanel(
                      hasDeploy: hasDeploy,
                      repoName: repoName,
                      branchName: branchName,
                      deployId: deployId,
                      githubConnected: githubConnected,
                      domainId: id,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Container(
          dartStyle: const DartStyle(
            display: Display.flex,
            justifyContent: JustifyContent.end,
            alignItems: AlignItems.center,
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 18),
          ),
          children: [
            Button(
              dartStyle: const DartStyle(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                background: '#ffffff',
                color: '#ef4444',
                fontSize: 13,
                fontWeight: 700,
                border: Border(color: Color('#fecaca'), width: 1),
                cursor: Cursor.pointer,
                hover: DartStyle(
                  background: '#fef2f2',
                  color: '#dc2626',
                ),
              ),
              onPressed: (_) => _handleDeleteDomain(id, domainName),
              child: Text('Delete Website'),
            ),
          ],
        ),
      ],
    );
  }

  FlintNode _domainPreviewHeader({
    required String domainName,
    required String subscriptionName,
    required String statusLabel,
    required String statusBg,
    required String statusColor,
    required String sslStatus,
  }) {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        alignItems: AlignItems.center,
        justifyContent: JustifyContent.between,
        gap: 16,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        background: '#f8fafc',
        border: Border(color: Color('#e2e8f0'), width: 1),
      ),
      children: [
        Row(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            gap: 14,
          ),
          children: [
            Container(
              dartStyle: DartStyle(
                display: Display.flex,
                alignItems: AlignItems.center,
                justifyContent: JustifyContent.center,
                width: 30,
                height: 30,
                radius: 999,
                background: _domainAvatarGradient(domainName),
                color: '#ffffff',
                fontSize: 11,
                fontWeight: 900,
              ),
              child: Text(_domainInitials(domainName)),
            ),
            Column(
              dartStyle: const DartStyle(
                display: Display.flex,
                flexDirection: FlexDirection.column,
                gap: 4,
              ),
              children: [
                Row(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    alignItems: AlignItems.center,
                    gap: 8,
                    flexWrap: FlexWrap.wrap,
                  ),
                  children: [
                    Text.strong(
                      domainName,
                      dartStyle: const DartStyle(
                        fontSize: 17,
                        fontWeight: 800,
                        color: '#0f172a',
                      ),
                    ),
                    _statusBadge(statusLabel, statusBg, statusColor),
                    _statusBadge(
                      sslStatus == 'active' ? 'SSL Secured' : 'SSL Pending',
                      sslStatus == 'active' ? '#ecfdf5' : '#fff7ed',
                      sslStatus == 'active' ? '#047857' : '#c2410c',
                    ),
                  ],
                ),
                Text.span(
                  'Subscription: $subscriptionName',
                  dartStyle: const DartStyle(
                    fontSize: 13,
                    color: '#64748b',
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          dartStyle: const DartStyle(
            display: Display.flex,
            alignItems: AlignItems.center,
            gap: 8,
            flexWrap: FlexWrap.wrap,
          ),
          children: [
            _miniIconLink('/dashboard/dns', 'DNS'),
            _miniIconLink('/dashboard/file-manager', 'Files'),
            _miniIconLink('/dashboard/mail', 'Mail'),
            _miniIconLink('/dashboard/databases', 'DB'),
            _miniIconLink('/dashboard/ssl', 'SSL'),
          ],
        ),
      ],
    );
  }

  FlintNode _domainPreviewImage(String domainName, String statusLabel) {
    return Container(
      dartStyle: const DartStyle(
        minHeight: 170,
        radius: 10,
        overflow: Overflow.hidden,
        background: 'linear-gradient(135deg, #0f172a, #172554)',
        border: Border(color: Color('#cbd5e1'), width: 1),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        justifyContent: JustifyContent.between,
        padding: EdgeInsets.all(16),
      ),
      children: [
        Text.span(
          statusLabel,
          dartStyle: const DartStyle(
            color: '#bae6fd',
            fontSize: 11,
            fontWeight: 800,
          ),
        ),
        Column(
          dartStyle: const DartStyle(
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 8,
          ),
          children: [
            Text.strong(
              domainName,
              dartStyle: const DartStyle(
                color: '#ffffff',
                fontSize: 20,
                fontWeight: 900,
              ),
            ),
            Text.span(
              'Website preview',
              dartStyle: const DartStyle(
                color: '#93c5fd',
                fontSize: 12,
                fontWeight: 700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  FlintNode _domainStatistics({
    required String disk,
    required String traffic,
    required String rootPath,
  }) {
    return Container(
      dartStyle: const DartStyle(
        padding: EdgeInsets.all(14),
        radius: 10,
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 10,
      ),
      children: [
        Text.strong(
          'Statistics',
          dartStyle: const DartStyle(
            fontSize: 15,
            fontWeight: 800,
            color: '#0f172a',
          ),
        ),
        _statLine('Disk space', disk),
        _statLine('Traffic this month', traffic),
        _statLine('Document root', rootPath),
      ],
    );
  }

  FlintNode _toolSection(String title, List<FlintNode> tools) {
    return Container(
      dartStyle: const DartStyle(
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 12,
      ),
      children: [
        Text.strong(
          title,
          dartStyle: const DartStyle(
            color: '#0f172a',
            fontSize: 15,
            fontWeight: 900,
          ),
        ),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '1fr',
            gap: 10,
          ),
          children: tools,
        ),
      ],
    );
  }

  FlintNode _toolTile(String title, String detail, String href, String icon) {
    return Link(
      href: href,
      dartStyle: const DartStyle(
        display: Display.flex,
        alignItems: AlignItems.center,
        gap: 12,
        padding: EdgeInsets.all(10),
        radius: 10,
        color: '#334155',
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
        transition: 'all 0.2s ease',
        hover: DartStyle(
          background: '#f8fafc',
          border: Border(color: Color('#bfdbfe'), width: 1),
          transform: 'translateX(2px)',
        ),
      ),
      child: Row(
        dartStyle: const DartStyle(
          display: Display.flex,
          alignItems: AlignItems.center,
          gap: 12,
        ),
        children: [
          Container(
            dartStyle: const DartStyle(
              display: Display.flex,
              alignItems: AlignItems.center,
              justifyContent: JustifyContent.center,
              width: 38,
              height: 38,
              radius: 8,
              background: '#eff6ff',
              color: '#2563eb',
              fontSize: 11,
              fontWeight: 900,
            ),
            child: Text(icon),
          ),
          Column(
            dartStyle: const DartStyle(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: 2,
            ),
            children: [
              Text.strong(
                title,
                dartStyle: const DartStyle(
                  color: '#0f172a',
                  fontSize: 13,
                  fontWeight: 800,
                ),
              ),
              Text.span(
                detail,
                dartStyle: const DartStyle(
                  color: '#64748b',
                  fontSize: 11,
                  lineHeight: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FlintNode _gitDeploymentPanel({
    required bool hasDeploy,
    required String repoName,
    required String branchName,
    required String deployId,
    required bool githubConnected,
    required String domainId,
  }) {
    return Container(
      dartStyle: const DartStyle(
        padding: EdgeInsets.all(16),
        background: '#f8fafc',
        radius: 12,
        border: Border(color: Color('#e2e8f0'), width: 1),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 12,
      ),
      children: [
        Row(
          dartStyle: const DartStyle(
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.between,
          ),
          children: [
            Text.strong(
              'GitHub Deployment',
              dartStyle: const DartStyle(
                fontSize: 14,
                fontWeight: 800,
                color: '#0f172a',
              ),
            ),
            if (hasDeploy) _statusBadge('Active', '#e0f2fe', '#0369a1'),
          ],
        ),
        if (hasDeploy)
          Row(
            dartStyle: const DartStyle(gap: 12),
            children: [
              DeployMetric(label: 'Repository', value: repoName),
              DeployMetric(label: 'Branch', value: branchName),
            ],
          )
        else
          Text.span(
            'No repository linked yet. FTP and File Manager remain available.',
            dartStyle: const DartStyle(
              color: '#64748b',
              fontSize: 12,
              lineHeight: 1.5,
            ),
          ),
        Row(
          dartStyle: const DartStyle(
            justifyContent: JustifyContent.end,
            gap: 8,
          ),
          children: [
            if (hasDeploy)
              Button(
                dartStyle: const DartStyle(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  radius: 8,
                  fontSize: 12,
                  cursor: Cursor.pointer,
                  background: '#fef2f2',
                  color: '#ef4444',
                  border: Border(color: Color('#fecaca'), width: 1),
                ),
                onPressed: (_) => _handleDisconnectGit(deployId),
                child: Text('Disconnect'),
              )
            else
              Button(
                disabled: !githubConnected,
                dartStyle: DartStyle(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  radius: 8,
                  fontSize: 12,
                  fontWeight: 700,
                  cursor: githubConnected ? Cursor.pointer : Cursor.notAllowed,
                  background: githubConnected ? '#24292f' : '#cbd5e1',
                  color: '#ffffff',
                ),
                onPressed: (_) {
                  _activeDeployDomainId = domainId;
                  _deployForm.reset();
                  _deployFormError = null;
                  _showDeployModal = true;
                  _repos.refresh(silent: true);
                  setState(() {});
                },
                child: Text(
                    githubConnected ? 'Link Repository' : 'Connect GitHub'),
              ),
          ],
        ),
      ],
    );
  }

  FlintNode _tabLabel(String label, {bool active = false}) {
    return Container(
      dartStyle: DartStyle(
        padding: const EdgeInsets.only(bottom: 8),
        color: active ? '#0f172a' : '#64748b',
        fontSize: 14,
        fontWeight: active ? 900 : 700,
      ),
      child: Text(label),
    );
  }

  FlintNode _statLine(String label, String value) {
    return Row(
      dartStyle: const DartStyle(
        justifyContent: JustifyContent.between,
        gap: 12,
      ),
      children: [
        Text.span(
          label,
          dartStyle: const DartStyle(color: '#475569', fontSize: 13),
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

  FlintNode _miniIconLink(String href, String label) {
    return Link(
      href: href,
      dartStyle: const DartStyle(
        color: '#334155',
        fontSize: 11,
        fontWeight: 800,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        radius: 8,
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
      ),
      child: label,
    );
  }

  FlintNode _statusBadge(String label, String bg, String color) {
    return Container(
      dartStyle: DartStyle(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        radius: 999,
        background: bg,
        color: color,
        fontSize: 10,
        fontWeight: 800,
        textTransform: TextTransform.uppercase,
      ),
      child: Text(label),
    );
  }

  String _domainStatusLabel(String status) {
    if (status == 'failed') return 'Failed';
    if (status == 'provisioning' || status == 'pending') return 'Provisioning';
    return 'Active';
  }

  (String, String) _domainStatusTone(String status) {
    if (status == 'failed') return ('#fef2f2', '#dc2626');
    if (status == 'provisioning' || status == 'pending') {
      return ('#fef3c7', '#d97706');
    }
    return ('#ecfdf5', '#059669');
  }

  String _domainInitials(String domain) {
    final cleaned = domain.replaceAll('www.', '').trim();
    if (cleaned.isEmpty) return 'D';
    return cleaned.substring(0, 1).toUpperCase();
  }

  String _domainAvatarGradient(String domain) {
    final code = domain.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final gradients = [
      'linear-gradient(135deg, #0ea5e9, #2563eb)',
      'linear-gradient(135deg, #14b8a6, #0f766e)',
      'linear-gradient(135deg, #f97316, #dc2626)',
      'linear-gradient(135deg, #8b5cf6, #db2777)',
    ];
    return gradients[code % gradients.length];
  }

  // ignore: unused_element
  FlintNode _buildDomainCard(FlintModelRecord domain,
      List<FlintModelRecord> deploys, List<FlintModelRecord> subs) {
    final id = domain.string('id') ?? '';
    final domainName = domain.string('domain') ?? 'Domain';
    final status = domain.string('status') ?? 'pending';
    final sslStatus = domain.string('ssl_status') ?? 'pending';
    final rootPath = domain.string('root_path') ?? '-';
    final subId = domain.string('subscription_id') ?? '';

    FlintModelRecord? sub;
    for (final s in subs) {
      if (s.string('id') == subId) {
        sub = s;
        break;
      }
    }
    final subName = sub != null
        ? (sub.string('system_username') ?? 'Subscription')
        : 'Subscription';

    FlintModelRecord? deploy;
    for (final d in deploys) {
      if (d.string('domain_id') == id) {
        deploy = d;
        break;
      }
    }

    final isFailed = status == 'failed';
    final isProvisioning = status == 'provisioning' || status == 'pending';

    String statusLabel = 'Active';
    String statusBg = '#ecfdf5';
    String statusColor = '#059669';

    if (isFailed) {
      statusLabel = 'Failed';
      statusBg = '#fef2f2';
      statusColor = '#dc2626';
    } else if (isProvisioning) {
      statusLabel = 'Provisioning';
      statusBg = '#fef3c7';
      statusColor = '#d97706';
    }

    final hasDeploy = deploy != null;
    final repoName = deploy?.string('repo_full_name') ?? '';
    final branchName = deploy?.string('branch') ?? 'main';
    final deployId = deploy?.string('id') ?? '';

    final githubConnected = _gitStatus.data?['connected'] == true;

    return Container(
      dartStyle: const DartStyle(
        padding: EdgeInsets.all(20),
        radius: 16,
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
        shadow: Shadow(
          x: 0,
          y: 4,
          blur: 12,
          spread: 0,
          color: Color.rgba(0, 0, 0, 0.05),
        ),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 16,
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
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
      ),
      children: [
        Row(
          dartStyle: const DartStyle(
            alignItems: AlignItems.center,
            justifyContent: JustifyContent.between,
          ),
          children: [
            Row(
              dartStyle: const DartStyle(
                display: Display.flex,
                alignItems: AlignItems.center,
                gap: 16,
              ),
              children: [
                Container(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    alignItems: AlignItems.center,
                    justifyContent: JustifyContent.center,
                    width: 48,
                    height: 48,
                    radius: 14,
                    background: 'linear-gradient(135deg, #eff6ff, #dbeafe)',
                    color: '#2563eb',
                  ),
                  child:
                      Text.span('🌐', dartStyle: const DartStyle(fontSize: 22)),
                ),
                Column(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    flexDirection: FlexDirection.column,
                    gap: 4,
                  ),
                  children: [
                    Row(
                      dartStyle: const DartStyle(
                        display: Display.flex,
                        alignItems: AlignItems.center,
                        gap: 8,
                      ),
                      children: [
                        Text.strong(
                          domainName,
                          dartStyle: const DartStyle(
                            fontSize: 18,
                            fontWeight: 800,
                            color: Color('#0f172a'),
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (sslStatus == 'active')
                          Container(
                            dartStyle: const DartStyle(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              radius: 6,
                              background: '#ecfdf5',
                              color: '#047857',
                              fontSize: 10,
                              fontWeight: 700,
                              textTransform: TextTransform.uppercase,
                              letterSpacing: 0.5,
                            ),
                            child: Text('SSL Secured'),
                          )
                        else
                          Container(
                            dartStyle: const DartStyle(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              radius: 6,
                              background: '#f1f5f9',
                              color: '#475569',
                              fontSize: 10,
                              fontWeight: 700,
                              textTransform: TextTransform.uppercase,
                              letterSpacing: 0.5,
                            ),
                            child: Text('HTTP Only'),
                          ),
                      ],
                    ),
                    Text.span(
                      'Linked Subscription: $subName  |  Root: $rootPath',
                      dartStyle: const DartStyle(
                        fontSize: 13,
                        color: Color('#64748b'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              dartStyle: DartStyle(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                radius: 999,
                background: statusBg,
                color: statusColor,
                fontSize: 11,
                fontWeight: 700,
                textTransform: TextTransform.uppercase,
                letterSpacing: 0.5,
              ),
              child: Text(statusLabel),
            ),
          ],
        ),
        Container(
          dartStyle: const DartStyle(
            padding: EdgeInsets.all(16),
            background: '#f8fafc',
            radius: 12,
            border: Border(color: Color('#f1f5f9'), width: 1),
            display: Display.flex,
            flexDirection: FlexDirection.column,
            gap: 12,
          ),
          children: [
            Row(
              dartStyle: const DartStyle(
                alignItems: AlignItems.center,
                justifyContent: JustifyContent.between,
              ),
              children: [
                Row(
                  dartStyle: const DartStyle(
                    alignItems: AlignItems.center,
                    gap: 8,
                  ),
                  children: [
                    Text.span('🐙', dartStyle: const DartStyle(fontSize: 16)),
                    Text.strong(
                      'GitHub Auto-Deployment',
                      dartStyle: const DartStyle(
                          fontSize: 14,
                          fontWeight: 700,
                          color: Color('#334155')),
                    ),
                    if (hasDeploy)
                      Container(
                        dartStyle: const DartStyle(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          radius: 4,
                          background: '#e0f2fe',
                          color: '#0369a1',
                          fontSize: 10,
                          fontWeight: 700,
                        ),
                        child: Text('Active'),
                      ),
                  ],
                ),
                if (hasDeploy)
                  Button(
                    dartStyle: const DartStyle(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      radius: 8,
                      fontSize: 12,
                      cursor: Cursor.pointer,
                      background: '#fef2f2',
                      color: '#ef4444',
                      border: Border(color: Color('#fecaca'), width: 1),
                      hover: DartStyle(background: '#fee2e2'),
                    ),
                    onPressed: (_) => _handleDisconnectGit(deployId),
                    child: Text('Disconnect'),
                  )
                else
                  Button(
                    disabled: !githubConnected,
                    dartStyle: DartStyle(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      radius: 8,
                      fontSize: 12,
                      fontWeight: 700,
                      cursor:
                          githubConnected ? Cursor.pointer : Cursor.notAllowed,
                      background: githubConnected ? '#24292f' : '#cbd5e1',
                      color: '#ffffff',
                      shadow: githubConnected
                          ? const Shadow(
                              x: 0,
                              y: 2,
                              blur: 6,
                              color: Color.rgba(0, 0, 0, 0.1))
                          : null,
                    ),
                    onPressed: (_) {
                      _activeDeployDomainId = id;
                      _deployForm.reset();
                      _deployFormError = null;
                      _showDeployModal = true;
                      _repos.refresh(silent: true);
                      setState(() {});
                    },
                    child: Text(githubConnected
                        ? 'Link Repository'
                        : 'Link Repository (Connect GitHub First)'),
                  ),
              ],
            ),
            if (hasDeploy)
              Row(
                dartStyle: const DartStyle(gap: 20),
                children: [
                  DeployMetric(label: 'Repository', value: repoName),
                  DeployMetric(label: 'Branch', value: branchName),
                ],
              )
            else
              Text.span(
                'No Git repository linked to this domain. Code must be uploaded manually via FTP/SFTP.',
                dartStyle: const DartStyle(
                    fontSize: 12, color: Color('#64748b'), lineHeight: 1.5),
              ),
          ],
        ),
        Row(
          dartStyle: const DartStyle(
            justifyContent: JustifyContent.end,
            alignItems: AlignItems.center,
          ),
          children: [
            Button(
              dartStyle: const DartStyle(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                radius: 10,
                background: '#ffffff',
                color: '#ef4444',
                fontSize: 13,
                fontWeight: 700,
                border: Border(color: Color('#fecaca'), width: 1),
                cursor: Cursor.pointer,
                hover: DartStyle(
                  background: '#fef2f2',
                  color: '#dc2626',
                ),
              ),
              onPressed: (_) => _handleDeleteDomain(id, domainName),
              child: Text('Delete Website'),
            ),
          ],
        ),
      ],
    );
  }

  FlintNode _buildDomainModal() {
    return Modal(
      open: _showDomainModal,
      title: 'Add New Website Mapping',
      onClose: (_) {
        _showDomainModal = false;
        setState(() {});
      },
      child: Form(
        onSubmit: _handleDomainSubmit,
        dartStyle: const DartStyle(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          gap: 16,
        ),
        children: [
          Select(
            label: 'Select Subscription *',
            name: 'subscription_id',
            value: _domainForm.string('subscription_id'),
            options: [
              for (final sub in (subscriptions.data ?? []))
                SelectOption(
                  label:
                      '${sub.string('system_username') ?? 'Subscription'} (${sub.string('id') ?? ''})',
                  value: sub.string('id') ?? '',
                ),
            ],
            onChanged: (event) {
              final val = (event as dynamic).target.value.toString();
              _domainForm.setField('subscription_id', val);
              setState(() {});
            },
            disabled: _domainForm.processing,
            selectProps: const {
              'style':
                  'border-radius: 10px; padding: 10px 12px; border: 1px solid #cbd5e1; background: #f8fafc; font-size: 14px; width: 100%;'
            },
          ),
          TextField(
            label: 'Domain Name *',
            name: 'domain',
            controller: _domainForm.controller('domain'),
            placeholder: 'e.g. my-app.com or sub.example.com',
            required: true,
            disabled: _domainForm.processing,
            inputStyle: const {
              'border-radius': '10px',
              'padding': '10px 12px',
              'border': '1px solid #cbd5e1',
              'background': '#f8fafc',
              'font-size': '14px',
            },
          ),
          if (_domainFormError != null)
            Alert(
              title: 'Adding Domain Failed',
              message: _domainFormError!,
              tone: Tone.danger,
            ),
          Row(
            dartStyle: const DartStyle(
              display: Display.flex,
              justifyContent: JustifyContent.end,
              gap: 12,
              margin: EdgeInsets.only(top: 8),
            ),
            children: [
              Button(
                onPressed: (_) {
                  _showDomainModal = false;
                  setState(() {});
                },
                dartStyle: const DartStyle(
                  minWidth: 100,
                  minHeight: 42,
                  radius: 10,
                  fontSize: 14,
                  fontWeight: 600,
                  border: Border(color: Color('#cbd5e1'), width: 1),
                  background: '#ffffff',
                  color: '#475569',
                  cursor: Cursor.pointer,
                  hover: DartStyle(
                    background: '#f1f5f9',
                  ),
                ),
                child: Text('Cancel'),
              ),
              Button(
                props: const {'type': 'submit'},
                loading: _domainForm.processing,
                disabled: _domainForm.processing,
                dartStyle: const DartStyle(
                  minWidth: 140,
                  minHeight: 42,
                  radius: 10,
                  fontSize: 14,
                  fontWeight: 700,
                  gradient: Gradients.ocean,
                  border: Border(color: Colors.blue600, width: 1),
                  shadow: Shadow(
                    x: 0,
                    y: 8,
                    blur: 16,
                    spread: -8,
                    color: Color.rgba(37, 99, 235, 0.5),
                  ),
                  cursor: Cursor.pointer,
                ),
                child: Text(
                    _domainForm.processing ? 'Provisioning...' : 'Add Website'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FlintNode _buildDeployModal() {
    return Modal(
      open: _showDeployModal,
      title: 'Link GitHub Repository',
      onClose: (_) {
        _showDeployModal = false;
        setState(() {});
      },
      child: Form(
        onSubmit: _handleDeploySubmit,
        dartStyle: const DartStyle(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          gap: 16,
        ),
        children: [
          ResourceView<List<Map<String, dynamic>>>(
            _repos,
            (snapshot) {
              final reposList = snapshot.data ?? const <Map<String, dynamic>>[];
              if (snapshot.isLoading && reposList.isEmpty) {
                return Container(
                  dartStyle: const DartStyle(
                    padding: EdgeInsets.all(12),
                    textAlign: TextAlign.center,
                  ),
                  child: Text('Loading repositories from GitHub...'),
                );
              }

              if (reposList.isEmpty) {
                return EmptyState(
                  title: 'No repositories found',
                  message: snapshot.isError
                      ? snapshot.error.toString()
                      : 'Ensure your GitHub account has public or private repositories available.',
                );
              }

              if (_deployForm.string('repo_full_name').isEmpty &&
                  reposList.isNotEmpty) {
                _deployForm.setField('repo_full_name',
                    reposList.first['full_name']?.toString() ?? '');
              }

              return Select(
                label: 'Select Repository *',
                name: 'repo_full_name',
                value: _deployForm.string('repo_full_name'),
                options: [
                  for (final repo in reposList)
                    SelectOption(
                      label: repo['full_name']?.toString() ?? 'Repo',
                      value: repo['full_name']?.toString() ?? '',
                    ),
                ],
                onChanged: (event) {
                  final val = (event as dynamic).target.value.toString();
                  _deployForm.setField('repo_full_name', val);
                  setState(() {});
                },
                disabled: _deployForm.processing,
                selectProps: const {
                  'style':
                      'border-radius: 10px; padding: 10px 12px; border: 1px solid #cbd5e1; background: #f8fafc; font-size: 14px; width: 100%;'
                },
              );
            },
          ),
          TextField(
            label: 'Deployment Branch *',
            name: 'branch',
            controller: _deployForm.controller('branch'),
            placeholder: 'e.g. main or production',
            required: true,
            disabled: _deployForm.processing,
            inputStyle: const {
              'border-radius': '10px',
              'padding': '10px 12px',
              'border': '1px solid #cbd5e1',
              'background': '#f8fafc',
              'font-size': '14px',
            },
          ),
          if (_deployFormError != null)
            Alert(
              title: 'Linking Repository Failed',
              message: _deployFormError!,
              tone: Tone.danger,
            ),
          Row(
            dartStyle: const DartStyle(
              display: Display.flex,
              justifyContent: JustifyContent.end,
              gap: 12,
              margin: EdgeInsets.only(top: 8),
            ),
            children: [
              Button(
                onPressed: (_) {
                  _showDeployModal = false;
                  setState(() {});
                },
                dartStyle: const DartStyle(
                  minWidth: 100,
                  minHeight: 42,
                  radius: 10,
                  fontSize: 14,
                  fontWeight: 600,
                  border: Border(color: Color('#cbd5e1'), width: 1),
                  background: '#ffffff',
                  color: '#475569',
                  cursor: Cursor.pointer,
                  hover: DartStyle(
                    background: '#f1f5f9',
                  ),
                ),
                child: Text('Cancel'),
              ),
              Button(
                props: const {'type': 'submit'},
                loading: _deployForm.processing,
                disabled: _deployForm.processing,
                dartStyle: const DartStyle(
                  minWidth: 140,
                  minHeight: 42,
                  radius: 10,
                  fontSize: 14,
                  fontWeight: 700,
                  gradient: Gradients.ocean,
                  border: Border(color: Colors.blue600, width: 1),
                  shadow: Shadow(
                    x: 0,
                    y: 8,
                    blur: 16,
                    spread: -8,
                    color: Color.rgba(37, 99, 235, 0.5),
                  ),
                  cursor: Cursor.pointer,
                ),
                child: Text(
                    _deployForm.processing ? 'Linking...' : 'Link Repository'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDomainSubmit(Object event) async {
    if (event is web.Event) {
      event.preventDefault();
    }

    final subId = _domainForm.string('subscription_id').trim();
    final domainName = _domainForm.string('domain').trim();

    if (subId.isEmpty || domainName.isEmpty) {
      setState(() {
        _domainFormError = 'All fields are required.';
      });
      return;
    }

    final submit = _domainForm.submit(
      (_) => clientRouter.post<Map<String, dynamic>>('/domains', body: {
        'subscription_id': subId,
        'domain': domainName,
      }),
      onSuccess: (result) {
        _domainForm.reset();
        _domains.refresh();
        setState(() {
          _domainFormError = null;
          _showDomainModal = false;
        });
      },
      onError: (error) {
        setState(() {
          _domainFormError = _friendlyError(error);
        });
      },
    );

    setState(() {
      _domainFormError = null;
    });
    await submit;
    setState(() {});
  }

  Future<void> _handleDeploySubmit(Object event) async {
    if (event is web.Event) {
      event.preventDefault();
    }

    final repo = _deployForm.string('repo_full_name').trim();
    final branch = _deployForm.string('branch').trim();
    final domainId = _activeDeployDomainId;

    if (repo.isEmpty || branch.isEmpty || domainId == null) {
      setState(() {
        _deployFormError = 'All fields are required.';
      });
      return;
    }

    FlintModelRecord? domain;
    for (final d in (_domains.data ?? <FlintModelRecord>[])) {
      if (d.string('id') == domainId) {
        domain = d;
        break;
      }
    }
    if (domain == null) {
      setState(() {
        _deployFormError = 'Domain not found.';
      });
      return;
    }
    final subId = domain.string('subscription_id') ?? '';

    final submit = _deployForm.submit(
      (_) => clientRouter.post<Map<String, dynamic>>('/github/deploys', body: {
        'subscription_id': subId,
        'repo_full_name': repo,
        'branch': branch,
        'domain_id': domainId,
      }),
      onSuccess: (result) {
        _deployForm.reset();
        _gitDeploys.refresh();
        setState(() {
          _deployFormError = null;
          _showDeployModal = false;
        });
      },
      onError: (error) {
        setState(() {
          _deployFormError = _friendlyError(error);
        });
      },
    );

    setState(() {
      _deployFormError = null;
    });
    await submit;
    setState(() {});
  }

  Future<void> _handleDeleteDomain(String id, String name) async {
    final confirmed = web.window.confirm(
        'Are you sure you want to remove the website $name? This will delete Nginx config files!');
    if (!confirmed) return;

    final response =
        await clientRouter.delete<Map<String, dynamic>>('/domains/$id');
    if (response.isError) {
      web.window
          .alert((response.error ?? 'Failed to delete domain.').toString());
      return;
    }

    _domains.refresh();
    _gitDeploys.refresh();
  }

  Future<void> _handleDisconnectGit(String deployId) async {
    final confirmed =
        web.window.confirm('Disconnect GitHub repository deployment?');
    if (!confirmed) return;

    final response = await clientRouter
        .delete<Map<String, dynamic>>('/github/deploys/$deployId');
    if (response.isError) {
      web.window.alert(
          (response.error ?? 'Failed to disconnect repository.').toString());
      return;
    }

    _gitDeploys.refresh();
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('ClientResponseException') ||
        message.contains('Exception:')) {
      return message
          .replaceFirst('Exception: ', '')
          .replaceFirst('ClientResponseException: ', '');
    }
    return message;
  }
}
