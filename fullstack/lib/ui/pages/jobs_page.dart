import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class JobsPage extends StatelessComponent {
  JobsPage({required this.jobs});

  final ResourceController<List<FlintModelRecord>> jobs;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'Provisioning Jobs',
      subtitle: 'Queue status for agents, backups, databases, and deployments',
      resource: jobs,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No jobs in the queue',
      emptyMessage: 'Provisioning work will appear here as jobs are created.',
    );
  }

  static const _columns = [
    TableColumn(key: 'type', label: 'Type'),
    TableColumn(key: 'target', label: 'Target'),
    TableColumn(key: 'serverId', label: 'Server'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'type': record.string('type') ?? '-',
      'target':
          '${record.string('targetType') ?? '-'} / ${record.string('targetId') ?? '-'}',
      'serverId': record.string('serverId') ?? '-',
      'status': StatusPill(status: record.string('status') ?? 'pending'),
    });
  }
}
