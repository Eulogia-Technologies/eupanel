import 'package:flint_ui/flint_ui.dart';

import 'dashboard_page_topbar.dart';

class EnterpriseRecordsView extends StatelessComponent {
  EnterpriseRecordsView({
    required this.title,
    required this.subtitle,
    required this.resource,
    required this.columns,
    required this.rowBuilder,
    this.emptyTitle = 'No records found',
    this.emptyMessage = 'There is no data in this workspace yet.',
    this.actions,
  });

  final String title;
  final String subtitle;
  final ResourceController<List<FlintModelRecord>> resource;
  final List<TableColumn> columns;
  final TableRowData Function(FlintModelRecord record) rowBuilder;
  final String emptyTitle;
  final String emptyMessage;
  final Object? actions;

  @override
  View build() {
    return Column(
      children: [
        DashboardPageTopbar(
          title: title,
          subtitle: subtitle,
          actions: Row(
            dartStyle: const DartStyle(
              display: Display.flex,
              alignItems: AlignItems.center,
              gap: 8,
            ),
            children: [
              if (actions != null) toFlintNode(actions),
              Button(
                child: 'Refresh',
                dartStyle: _refreshButtonStyle,
                onPressed: (_) => resource.refresh(silent: true),
              ),
            ],
          ),
        ),
        ResourceView<List<FlintModelRecord>>(
          resource,
          (snapshot) {
            final records = snapshot.data ?? const <FlintModelRecord>[];

            return Panel(
              title: title,
              description: _panelDescription(records.length, snapshot),
              dartStyle: _panelStyle,
              child: Column(
                dartStyle: const DartStyle(
                  display: Display.flex,
                  flexDirection: FlexDirection.column,
                  gap: 16,
                ),
                children: [
                  if (snapshot.isError)
                    Alert(
                      title: 'Showing cached data',
                      message: snapshot.error.toString(),
                      tone: Tone.warning,
                    ),
                  DataTable(
                    columns: columns,
                    rows: [
                      for (final record in records) rowBuilder(record),
                    ],
                    loading: snapshot.isLoading && records.isEmpty,
                    emptyState: EmptyState(
                      title: emptyTitle,
                      message: emptyMessage,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _panelDescription(
      int count, ResourceSnapshot<List<FlintModelRecord>> snapshot) {
    final noun = count == 1 ? 'record' : 'records';
    if (snapshot.updatedAt == null) return '$count $noun loaded from EuPanel.';
    return '$count $noun loaded from live EuPanel data.';
  }
}

class StatusPill extends StatelessComponent {
  StatusPill({required this.status});

  final String status;

  @override
  View build() {
    final normalized = status.toLowerCase();
    final bg = switch (normalized) {
      'active' || 'success' || 'completed' => '#ecfdf5',
      'running' || 'pending' => '#eff6ff',
      'failed' || 'error' || 'cancelled' => '#fef2f2',
      _ => '#f8fafc',
    };
    final color = switch (normalized) {
      'active' || 'success' || 'completed' => '#047857',
      'running' || 'pending' => '#1d4ed8',
      'failed' || 'error' || 'cancelled' => '#b91c1c',
      _ => '#475569',
    };

    return Container(
      dartStyle: DartStyle(
        display: Display.inlineFlex,
        alignItems: AlignItems.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        radius: 999,
        background: bg,
        color: color,
        fontSize: 11,
        fontWeight: 800,
        textTransform: TextTransform.uppercase,
      ),
      child: Text(status),
    );
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
    color: Color.rgba(0, 0, 0, 0.02),
  ),
);

const _refreshButtonStyle = DartStyle(
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
);
