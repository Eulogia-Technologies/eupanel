import 'package:flint_ui/flint_ui.dart';
import 'package:universal_web/web.dart' as web;
import 'dashboard_page_topbar.dart';
import 'subscription_metric.dart';

class SubscriptionsView extends StatefulComponent {
  final String role;
  final ResourceController<List<FlintModelRecord>> plans;
  final ResourceController<List<FlintModelRecord>> subscriptions;

  SubscriptionsView({
    required this.role,
    required this.plans,
    required this.subscriptions,
  });

  final _subscriptionForm = useForm({
    'plan_id': '',
    'domain': '',
    'contact_email': '',
  });

  String? _subFormError;
  String? _credentialNotice;
  bool _showSubModal = false;

  @override
  void updateFrom(covariant SubscriptionsView next) {}

  @override
  View build() {
    return Column(
      children: [
        DashboardPageTopbar(
          title: 'Hosting Subscriptions',
          subtitle:
              'Manage active environments, credentials, and package limits',
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
                  _subscriptionForm.reset();
                  final plansList = plans.data ?? [];
                  if (plansList.isNotEmpty) {
                    _subscriptionForm.setField(
                        'plan_id', plansList.first.string('id') ?? '');
                  }
                  _subFormError = null;
                  _credentialNotice = null;
                  _showSubModal = true;
                  setState(() {});
                },
                child: Text('New Subscription'),
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
                onPressed: (_) => subscriptions.refresh(silent: true),
              ),
            ],
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
              title: 'Active Environments',
              description:
                  'Select your subscription to view details, FTP credentials, and cancel service.',
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
                subscriptions,
                (snapshot) {
                  final subs = snapshot.data ?? const <FlintModelRecord>[];
                  final plansList = plans.data ?? const <FlintModelRecord>[];

                  if (snapshot.isLoading && subs.isEmpty) {
                    return Container(
                      dartStyle: const DartStyle(
                        padding: EdgeInsets.all(24),
                        textAlign: TextAlign.center,
                      ),
                      child: Text('Loading subscriptions...'),
                    );
                  }

                  if (subs.isEmpty) {
                    return EmptyState(
                      title: snapshot.isError
                          ? 'Could not load subscriptions'
                          : 'No active subscriptions',
                      message: snapshot.isError
                          ? snapshot.error.toString()
                          : 'You don\'t have any active hosting subscriptions. Create a new subscription package using the button above.',
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
                          title: 'Showing cached subscriptions',
                          message: snapshot.error.toString(),
                          tone: Tone.warning,
                        ),
                      for (final sub in subs)
                        _buildSubscriptionCard(sub, plansList, role),
                    ],
                  );
                },
              ),
            ),
            if (_credentialNotice != null)
              Alert(
                title: 'Generated login details',
                message: _credentialNotice!,
                tone: Tone.success,
              ),
          ],
        ),
        if (_showSubModal) _buildSubModal(),
      ],
    );
  }

  FlintNode _buildSubscriptionCard(
      FlintModelRecord sub, List<FlintModelRecord> plansList, String role) {
    final planId = sub.string('plan_id') ?? '';
    FlintModelRecord? plan;
    for (final p in plansList) {
      if (p.string('id') == planId) {
        plan = p;
        break;
      }
    }
    final planName = plan?.string('name') ?? 'Hosting Plan ($planId)';

    final status = sub.string('status') ?? 'pending';
    final provStatus = sub.string('provisioning_status') ?? 'pending';
    final subId = sub.string('id') ?? '';
    final sysUsername = sub.string('system_username') ?? 'pending';
    final ftpUsername = sub.string('ftp_username') ?? 'pending';
    final ftpPassword = sub.string('ftp_password') ?? '********';
    final homeDir = sub.string('home_directory') ?? 'pending';
    final primaryDomain = sub.string('primary_domain') ?? '';
    final provLog = sub.string('provisioning_log') ?? '';

    final isFailed = provStatus == 'failed';
    final isProvisioning =
        provStatus == 'provisioning' || provStatus == 'pending';
    final isCancelled = status == 'cancelled';

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
    } else if (isCancelled) {
      statusLabel = 'Cancelled';
      statusBg = '#f1f5f9';
      statusColor = '#475569';
    }

    final host =
        primaryDomain.isNotEmpty ? primaryDomain : web.window.location.hostname;

    final envEmoji = planName.toLowerCase().contains('pro') ||
            planName.toLowerCase().contains('business')
        ? '⚡'
        : '🚀';

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
                    background: '#f0fdf4',
                    fontSize: 20,
                  ),
                  child: Text(envEmoji),
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
                          primaryDomain.isNotEmpty ? primaryDomain : planName,
                          dartStyle: const DartStyle(
                            fontSize: 18,
                            fontWeight: 700,
                            color: Color('#0f172a'),
                          ),
                        ),
                        Text.span(
                          'Subscription',
                          dartStyle: const DartStyle(
                            fontSize: 12,
                            color: Color('#64748b'),
                            background: '#f1f5f9',
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            radius: 4,
                          ),
                        ),
                      ],
                    ),
                    Text.span(
                      primaryDomain.isNotEmpty
                          ? '$planName | ID: $subId'
                          : 'ID: $subId',
                      dartStyle: const DartStyle(
                        fontSize: 12,
                        color: Color('#94a3b8'),
                        fontFamily: 'monospace',
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
        Grid(
          dartStyle: const DartStyle(
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: 12,
            padding: EdgeInsets.symmetric(vertical: 8),
            borderTop: Border(color: Color('#f1f5f9'), width: 1),
            borderBottom: Border(color: Color('#f1f5f9'), width: 1),
          ),
          children: [
            SubscriptionMetric(
                label: 'FTP / SFTP Host', value: host, copyable: true),
            SubscriptionMetric(
                label: 'System Username', value: sysUsername, copyable: true),
            SubscriptionMetric(label: 'Home Directory', value: homeDir),
            SubscriptionMetric(
                label: 'FTP Username', value: ftpUsername, copyable: true),
            SubscriptionMetric(
                label: 'FTP Password', value: ftpPassword, copyable: true),
          ],
        ),
        if (isFailed && provLog.isNotEmpty)
          Alert(
            title: 'Provisioning Log',
            message: provLog,
            tone: Tone.danger,
          ),
        Row(
          dartStyle: const DartStyle(
            justifyContent: JustifyContent.end,
            alignItems: AlignItems.center,
          ),
          children: [
            if (!isCancelled)
              Button(
                dartStyle: const DartStyle(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                onPressed: (_) => _handleCancelSubscription(subId),
                child: Text('Cancel Subscription'),
              ),
          ],
        ),
      ],
    );
  }

  FlintNode _buildSubModal() {
    return Modal(
      open: _showSubModal,
      title: 'New Hosting Subscription',
      onClose: (_) {
        _showSubModal = false;
        setState(() {});
      },
      child: Form(
        onSubmit: _handleSubSubmit,
        dartStyle: const DartStyle(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          gap: 16,
        ),
        children: [
          Select(
            label: 'Select Service Plan *',
            name: 'plan_id',
            value: _subscriptionForm.string('plan_id'),
            options: [
              for (final plan in (plans.data ?? []))
                SelectOption(
                  label:
                      '${plan.string('name') ?? 'Plan'} - \$${plan.string('price') ?? '0'}/mo',
                  value: plan.string('id') ?? '',
                ),
            ],
            onChanged: (event) {
              final val = (event as dynamic).target.value.toString();
              _subscriptionForm.setField('plan_id', val);
              setState(() {});
            },
            disabled: _subscriptionForm.processing,
            selectProps: const {
              'style':
                  'border-radius: 10px; padding: 10px 12px; border: 1px solid #cbd5e1; background: #f8fafc; font-size: 14px; width: 100%;'
            },
          ),
          TextField(
            label: 'Primary Domain *',
            name: 'domain',
            controller: _subscriptionForm.controller('domain'),
            placeholder: 'example.com',
            required: true,
            disabled: _subscriptionForm.processing,
            inputStyle: const {
              'border-radius': '10px',
              'padding': '10px 12px',
              'border': '1px solid #cbd5e1',
              'background': '#f8fafc',
              'font-size': '14px',
            },
          ),
          TextField(
            label: 'Contact Email',
            name: 'contact_email',
            controller: _subscriptionForm.controller('contact_email'),
            type: 'email',
            placeholder: 'client@example.com',
            disabled: _subscriptionForm.processing,
            inputStyle: const {
              'border-radius': '10px',
              'padding': '10px 12px',
              'border': '1px solid #cbd5e1',
              'background': '#f8fafc',
              'font-size': '14px',
            },
          ),
          if (_subFormError != null)
            Alert(
              title: 'Subscription Failed',
              message: _subFormError!,
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
                  _showSubModal = false;
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
                loading: _subscriptionForm.processing,
                disabled: _subscriptionForm.processing,
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
                child: Text(_subscriptionForm.processing
                    ? 'Provisioning...'
                    : 'Subscribe Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubSubmit(Object event) async {
    if (event is web.Event) {
      event.preventDefault();
    }

    final planId = _subscriptionForm.string('plan_id').trim();
    final domain = _subscriptionForm.string('domain').trim().toLowerCase();
    final contactEmail = _subscriptionForm.string('contact_email').trim();
    if (planId.isEmpty) {
      setState(() {
        _subFormError = 'Please select a hosting package.';
      });
      return;
    }
    if (domain.isEmpty) {
      setState(() {
        _subFormError = 'Please enter the primary domain.';
      });
      return;
    }

    final submit = _subscriptionForm.submit(
      (_) => clientRouter.post<Map<String, dynamic>>('/subscriptions', body: {
        'plan_id': planId,
        'domain': domain,
        if (contactEmail.isNotEmpty) 'contact_email': contactEmail,
      }),
      onSuccess: (result) {
        _credentialNotice = _formatCredentialNotice(result.data);
        _subscriptionForm.reset();
        subscriptions.refresh();
        setState(() {
          _subFormError = null;
          _showSubModal = false;
        });
      },
      onError: (error) {
        setState(() {
          _subFormError = _friendlyError(error);
        });
      },
    );

    setState(() {
      _subFormError = null;
    });
    await submit;
    setState(() {});
  }

  String _formatCredentialNotice(Object? result) {
    final payload = _asMap(result);
    final data = _asMap(payload['data']);
    final panel = _asMap(data['panel_login']);
    final ftp = _asMap(data['ftp']);

    final panelUsername = panel['username']?.toString() ?? 'unknown';
    final panelPassword = panel['password']?.toString() ?? 'not returned';
    final ftpUsername = ftp['username']?.toString() ?? 'pending';
    final ftpPassword = ftp['password']?.toString() ?? 'pending';
    final ftpHost = ftp['host']?.toString() ?? 'pending';

    return 'Panel username: $panelUsername | Panel password: $panelPassword | FTP host: $ftpHost | FTP username: $ftpUsername | FTP password: $ftpPassword';
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return const {};
  }

  Future<void> _handleCancelSubscription(String id) async {
    final confirmed = web.window.confirm(
        'Are you sure you want to cancel this subscription? This will delete all files and databases!');
    if (!confirmed) return;

    final response =
        await clientRouter.delete<Map<String, dynamic>>('/subscriptions/$id');
    if (response.isError) {
      web.window.alert(
          (response.error ?? 'Failed to cancel subscription.').toString());
      return;
    }

    subscriptions.refresh();
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
