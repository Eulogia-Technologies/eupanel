import 'package:flint_ui/flint_ui.dart';
import 'package:universal_web/web.dart' as web;
import 'dashboard_page_topbar.dart';
import 'limit_metric.dart';

class PlansView extends StatefulComponent {
  final String role;
  final ResourceController<List<FlintModelRecord>> plans;

  PlansView({
    required this.role,
    required this.plans,
  });

  final _createForm = useForm({
    'name': '',
    'description': '',
    'disk_limit': '1000',
    'bandwidth_limit': '5000',
    'ftp_accounts_limit': '5',
    'database_limit': '5',
    'domain_limit': '3',
    'subdomain_limit': '10',
    'ram_limit': '512',
    'status': 'active',
  });

  String? _formError;
  bool _showModal = false;
  String? _editingPlanId;

  @override
  void updateFrom(covariant PlansView next) {}

  @override
  View build() {
    final isAdmin = role == 'admin';

    return Column(
      children: [
        DashboardPageTopbar(
          title: 'Hosting Plans & Packages',
          subtitle: isAdmin
              ? 'Manage global shared hosting and reseller plan offerings'
              : 'View available subscription packages',
          actions: Link(
            href: '/docs',
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
            child: 'API Docs',
          ),
        ),
        Grid(
          dartStyle: const DartStyle(
            display: Display.grid,
            gridTemplateColumns: '1fr',
            gap: 24,
            alignItems: AlignItems.start,
          ),
          children: [
            Panel(
              title: 'Active Service Plans',
              description: 'Configure resource quotas, capacity, and limits.',
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
              actions: Row(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  alignItems: AlignItems.center,
                  gap: 8,
                ),
                children: [
                  if (isAdmin)
                    Button(
                      dartStyle: const DartStyle(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        _editingPlanId = null;
                        _createForm.reset();
                        _formError = null;
                        _showModal = true;
                        setState(() {});
                      },
                      child: Text('Create Package'),
                    ),
                  Button(
                    child: 'Refresh',
                    dartStyle: const DartStyle(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    onPressed: (_) => plans.refresh(silent: true),
                  ),
                ],
              ),
              child: ResourceView<List<FlintModelRecord>>(
                plans,
                (snapshot) {
                  final list = snapshot.data ?? const <FlintModelRecord>[];
                  if (snapshot.isLoading && list.isEmpty) {
                    return Container(
                      dartStyle: const DartStyle(
                        padding: EdgeInsets.all(24),
                        textAlign: TextAlign.center,
                      ),
                      child: Text('Loading packages...'),
                    );
                  }

                  if (list.isEmpty) {
                    return EmptyState(
                      title: snapshot.isError
                          ? 'Could not load plans'
                          : 'No plans found',
                      message: snapshot.isError
                          ? snapshot.error.toString()
                          : (isAdmin
                              ? 'Get started by creating your first hosting package using the Create Package button above.'
                              : 'No plans have been configured yet by the system administrator.'),
                    );
                  }

                  return Column(
                    dartStyle: const DartStyle(
                      display: Display.flex,
                      flexDirection: FlexDirection.column,
                      gap: 16,
                    ),
                    children: [
                      if (snapshot.isError)
                        Alert(
                          title: 'Showing cached plans',
                          message: snapshot.error.toString(),
                          tone: Tone.warning,
                        ),
                      for (final plan in list) _buildPlanCard(plan, isAdmin),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        if (_showModal) _buildPlanModal(isAdmin),
      ],
    );
  }

  FlintNode _buildPlanCard(FlintModelRecord plan, bool isAdmin) {
    final id = plan.string('id') ?? '';
    final name = plan.string('name') ?? 'Hosting Plan';
    final desc = plan.string('description') ?? '';
    final status = plan.string('status') ?? 'active';
    final isActive = status == 'active';

    final disk = plan['disk_limit'] ?? plan['disk'] ?? '0';
    final bandwidth = plan['bandwidth_limit'] ?? plan['bandwidth'] ?? '0';
    final ram = plan['ram_limit'];
    final db = plan['database_limit'] ?? '0';
    final domain = plan['domain_limit'] ?? '0';
    final subdomain = plan['subdomain_limit'] ?? '0';
    final ftp = plan['ftp_accounts_limit'] ?? '0';

    final planEmoji = name.toLowerCase().contains('dev')
        ? '⚡'
        : (name.toLowerCase().contains('pro') ||
                name.toLowerCase().contains('premium') ||
                name.toLowerCase().contains('business')
            ? '💼'
            : '📦');

    return Container(
      dartStyle: const DartStyle(
        padding: EdgeInsets.all(24),
        radius: 16,
        background: '#ffffff',
        border: Border(color: Color('#e2e8f0'), width: 1),
        shadow: Shadow(
          x: 0,
          y: 4,
          blur: 12,
          spread: 0,
          color: Color.rgba(0, 0, 0, 0.02),
        ),
        display: Display.flex,
        flexDirection: FlexDirection.column,
        gap: 16,
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        hover: DartStyle(
          transform: 'translateY(-3px)',
          border: Border(color: Color('#bfdbfe'), width: 1),
          shadow: Shadow(
            x: 0,
            y: 16,
            blur: 32,
            spread: -8,
            color: Color.rgba(37, 99, 235, 0.06),
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
                gap: 12,
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
                    background: '#eff6ff',
                    fontSize: 20,
                  ),
                  child: Text(planEmoji),
                ),
                Column(
                  dartStyle: const DartStyle(
                    display: Display.flex,
                    flexDirection: FlexDirection.column,
                    gap: 4,
                  ),
                  children: [
                    Text.strong(
                      name,
                      dartStyle: const DartStyle(
                        fontSize: 18,
                        fontWeight: 700,
                        color: Color('#0f172a'),
                      ),
                    ),
                    if (desc.isNotEmpty)
                      Text.span(
                        desc,
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
                background: isActive ? '#ecfdf5' : '#fef2f2',
                color: isActive ? '#059669' : '#dc2626',
                fontSize: 11,
                fontWeight: 700,
                textTransform: TextTransform.uppercase,
                letterSpacing: 0.5,
              ),
              child: Text(status),
            ),
          ],
        ),
        Grid(
          dartStyle: const DartStyle(
            gridTemplateColumns: 'repeat(auto-fit, minmax(110px, 1fr))',
            gap: 12,
            padding: EdgeInsets.symmetric(vertical: 12),
            borderTop: Border(color: Color('#f1f5f9'), width: 1),
            borderBottom: Border(color: Color('#f1f5f9'), width: 1),
          ),
          children: [
            LimitMetric(label: 'Disk', value: '$disk MB'),
            LimitMetric(label: 'Bandwidth', value: '$bandwidth MB'),
            LimitMetric(
                label: 'RAM',
                value: ram == null || ram.toString() == '0'
                    ? 'Unlimited'
                    : '$ram MB'),
            LimitMetric(label: 'Domains', value: '$domain'),
            LimitMetric(label: 'Subdomains', value: '$subdomain'),
            LimitMetric(label: 'Databases', value: '$db'),
            LimitMetric(label: 'FTP Accounts', value: '$ftp'),
          ],
        ),
        Row(
          dartStyle: const DartStyle(
            justifyContent: JustifyContent.between,
            alignItems: AlignItems.center,
          ),
          children: [
            Text.small(
              'ID: $id',
              dartStyle: const DartStyle(
                color: Color('#94a3b8'),
                fontFamily: 'monospace',
              ),
            ),
            if (isAdmin)
              Row(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  alignItems: AlignItems.center,
                  gap: 8,
                ),
                children: [
                  Button(
                    dartStyle: const DartStyle(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      radius: 8,
                      background: '#f8fafc',
                      color: '#475569',
                      fontSize: 13,
                      fontWeight: 600,
                      border: Border(color: Color('#cbd5e1'), width: 1),
                      cursor: Cursor.pointer,
                      hover: DartStyle(
                        background: '#f1f5f9',
                      ),
                    ),
                    onPressed: (_) {
                      _editingPlanId = id;
                      _createForm.setField('name', name);
                      _createForm.setField('description', desc);
                      _createForm.setField('disk_limit', disk.toString());
                      _createForm.setField(
                          'bandwidth_limit', bandwidth.toString());
                      _createForm.setField(
                          'ftp_accounts_limit', ftp.toString());
                      _createForm.setField('database_limit', db.toString());
                      _createForm.setField('domain_limit', domain.toString());
                      _createForm.setField(
                          'subdomain_limit', subdomain.toString());
                      _createForm.setField(
                          'ram_limit', ram == null ? '' : ram.toString());
                      _createForm.setField('status', status);
                      _formError = null;
                      _showModal = true;
                      setState(() {});
                    },
                    child: Text('Edit Plan'),
                  ),
                  Button(
                    dartStyle: const DartStyle(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      radius: 8,
                      background: '#fef2f2',
                      color: '#ef4444',
                      fontSize: 13,
                      fontWeight: 600,
                      border: Border(color: Color('#fecaca'), width: 1),
                      cursor: Cursor.pointer,
                      hover: DartStyle(
                        background: '#fee2e2',
                        color: '#dc2626',
                      ),
                    ),
                    onPressed: (_) => _handleDeletePlan(id),
                    child: Text('Delete Plan'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  FlintNode _buildPlanModal(bool isAdmin) {
    return Modal(
      open: _showModal,
      title: _editingPlanId == null
          ? 'Create Hosting Package'
          : 'Edit Hosting Package',
      onClose: (_) {
        _showModal = false;
        setState(() {});
      },
      child: Form(
        onSubmit: _handleFormSubmit,
        dartStyle: const DartStyle(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          gap: 16,
        ),
        children: [
          Container(
            dartStyle: const DartStyle(
              display: Display.flex,
              flexDirection: FlexDirection.column,
              gap: 16,
              maxHeight: '60vh',
              overflow: Overflow.auto,
              padding: EdgeInsets.only(right: 8),
            ),
            children: [
              TextField(
                label: 'Package Name *',
                name: 'name',
                controller: _createForm.controller('name'),
                placeholder: 'e.g. Developer Pro',
                required: true,
                disabled: _createForm.processing,
                inputStyle: const {
                  'border-radius': '10px',
                  'padding': '10px 12px',
                  'border': '1px solid #cbd5e1',
                  'background': '#f8fafc',
                  'font-size': '14px',
                },
              ),
              TextField(
                label: 'Description',
                name: 'description',
                controller: _createForm.controller('description'),
                placeholder: 'e.g. Best for production apps with high traffic',
                disabled: _createForm.processing,
                inputStyle: const {
                  'border-radius': '10px',
                  'padding': '10px 12px',
                  'border': '1px solid #cbd5e1',
                  'background': '#f8fafc',
                  'font-size': '14px',
                },
              ),
              Row(
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gridTemplateColumns: '1fr 1fr',
                  gap: 12,
                ),
                children: [
                  TextField(
                    label: 'Disk Limit (MB) *',
                    name: 'disk_limit',
                    controller: _createForm.controller('disk_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                  TextField(
                    label: 'Bandwidth Limit (MB) *',
                    name: 'bandwidth_limit',
                    controller: _createForm.controller('bandwidth_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                ],
              ),
              Row(
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gridTemplateColumns: '1fr 1fr',
                  gap: 12,
                ),
                children: [
                  TextField(
                    label: 'RAM Limit (MB)',
                    name: 'ram_limit',
                    controller: _createForm.controller('ram_limit'),
                    type: 'number',
                    placeholder: 'Unlimited',
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                  TextField(
                    label: 'FTP Accounts Limit *',
                    name: 'ftp_accounts_limit',
                    controller: _createForm.controller('ftp_accounts_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                ],
              ),
              Row(
                dartStyle: const DartStyle(
                  display: Display.grid,
                  gridTemplateColumns: '1fr 1fr 1fr',
                  gap: 12,
                ),
                children: [
                  TextField(
                    label: 'Databases *',
                    name: 'database_limit',
                    controller: _createForm.controller('database_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                  TextField(
                    label: 'Domains *',
                    name: 'domain_limit',
                    controller: _createForm.controller('domain_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                  TextField(
                    label: 'Subdomains *',
                    name: 'subdomain_limit',
                    controller: _createForm.controller('subdomain_limit'),
                    type: 'number',
                    required: true,
                    disabled: _createForm.processing,
                    inputStyle: const {
                      'border-radius': '10px',
                      'padding': '10px 12px',
                      'border': '1px solid #cbd5e1',
                      'background': '#f8fafc',
                      'font-size': '14px',
                    },
                  ),
                ],
              ),
              Select(
                label: 'Status',
                name: 'status',
                value: _createForm.string('status'),
                options: const [
                  SelectOption(label: 'Active', value: 'active'),
                  SelectOption(label: 'Inactive', value: 'inactive'),
                ],
                onChanged: (event) {
                  final val = (event as dynamic).target.value.toString();
                  _createForm.setField('status', val);
                  setState(() {});
                },
                disabled: _createForm.processing,
                selectProps: const {
                  'style':
                      'border-radius: 10px; padding: 10px 12px; border: 1px solid #cbd5e1; background: #f8fafc; font-size: 14px; width: 100%;'
                },
              ),
            ],
          ),
          if (_formError != null)
            Alert(
              title: 'Submission Failed',
              message: _formError!,
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
                  _showModal = false;
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
                loading: _createForm.processing,
                disabled: _createForm.processing,
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
                child: Text(_createForm.processing
                    ? 'Saving...'
                    : (_editingPlanId == null
                        ? 'Create Package'
                        : 'Save Changes')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleFormSubmit(Object event) async {
    if (event is web.Event) {
      event.preventDefault();
    }

    final name = _createForm.string('name').trim();
    final description = _createForm.string('description').trim();
    final diskLimit = _createForm.string('disk_limit').trim();
    final bandwidthLimit = _createForm.string('bandwidth_limit').trim();
    final ftpAccountsLimit = _createForm.string('ftp_accounts_limit').trim();
    final databaseLimit = _createForm.string('database_limit').trim();
    final domainLimit = _createForm.string('domain_limit').trim();
    final subdomainLimit = _createForm.string('subdomain_limit').trim();
    final ramLimit = _createForm.string('ram_limit').trim();
    final status = _createForm.string('status');

    final body = {
      'name': name,
      'description': description.isEmpty ? null : description,
      'disk_limit': diskLimit,
      'bandwidth_limit': bandwidthLimit,
      'ftp_accounts_limit': ftpAccountsLimit,
      'database_limit': databaseLimit,
      'domain_limit': domainLimit,
      'subdomain_limit': subdomainLimit,
      'ram_limit': ramLimit.isEmpty ? null : ramLimit,
      'status': status,
    };

    final submit = _createForm.submit(
      (_) {
        if (_editingPlanId == null) {
          return clientRouter.post<Map<String, dynamic>>('/plans', body: body);
        } else {
          return clientRouter
              .put<Map<String, dynamic>>('/plans/$_editingPlanId', body: body);
        }
      },
      onSuccess: (result) {
        _createForm.reset();
        plans.refresh();
        setState(() {
          _formError = null;
          _showModal = false;
        });
      },
      onError: (error) {
        setState(() {
          _formError = _friendlyError(error);
        });
      },
    );

    setState(() {
      _formError = null;
    });
    await submit;
    setState(() {});
  }

  Future<void> _handleDeletePlan(String id) async {
    final confirmed =
        web.window.confirm('Are you sure you want to delete this plan?');
    if (!confirmed) return;

    final response =
        await clientRouter.delete<Map<String, dynamic>>('/plans/$id');
    if (response.isError) {
      web.window.alert((response.error ?? 'Failed to delete plan.').toString());
      return;
    }

    plans.refresh();
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
