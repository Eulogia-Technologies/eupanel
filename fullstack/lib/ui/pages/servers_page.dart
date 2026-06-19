import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class ServersPage extends StatelessComponent {
  ServersPage({required this.servers});

  final ResourceController<List<FlintModelRecord>> servers;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'Servers',
      subtitle: 'Connected agent nodes, hostnames, and heartbeat state',
      resource: servers,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No servers registered',
      emptyMessage: 'Add server agents to start provisioning environments.',
    );
  }

  static const _columns = [
    TableColumn(key: 'name', label: 'Server'),
    TableColumn(key: 'host', label: 'Host'),
    TableColumn(key: 'agent', label: 'Agent'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'name': record.string('name') ?? '-',
      'host': record.string('host') ?? '-',
      'agent': record.string('agent_version') ??
          record.string('agentVersion') ??
          '-',
      'status': StatusPill(status: record.string('status') ?? 'active'),
    });
  }
}
