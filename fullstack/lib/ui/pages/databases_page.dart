import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class DatabasesPage extends StatelessComponent {
  DatabasesPage({required this.databases});

  final ResourceController<List<FlintModelRecord>> databases;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'Databases',
      subtitle: 'MySQL databases provisioned across customer environments',
      resource: databases,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No databases provisioned',
      emptyMessage: 'Databases created from subscriptions will appear here.',
    );
  }

  static const _columns = [
    TableColumn(key: 'name', label: 'Database'),
    TableColumn(key: 'engine', label: 'Engine'),
    TableColumn(key: 'username', label: 'User'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'name': record.string('name') ?? '-',
      'engine': record.string('engine') ?? 'mysql',
      'username': record.string('username') ?? '-',
      'status': _statusPill(record.string('status') ?? 'active'),
    });
  }

  View _statusPill(String status) {
    return StatusPill(status: status);
  }
}
