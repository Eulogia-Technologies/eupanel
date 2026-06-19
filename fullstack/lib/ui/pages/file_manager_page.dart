import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class FileManagerPage extends StatelessComponent {
  FileManagerPage({required this.sites});

  final ResourceController<List<FlintModelRecord>> sites;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'File Manager',
      subtitle: 'Hosted site document roots and runtime file locations',
      resource: sites,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No site files yet',
      emptyMessage:
          'Site file roots will appear after a website is provisioned.',
    );
  }

  static const _columns = [
    TableColumn(key: 'domain', label: 'Domain'),
    TableColumn(key: 'rootPath', label: 'Document Root'),
    TableColumn(key: 'runtime', label: 'Runtime'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'domain': record.string('domain') ?? '-',
      'rootPath':
          record.string('rootPath') ?? record.string('root_path') ?? '-',
      'runtime': record.string('runtime') ?? 'php',
      'status': StatusPill(status: record.string('status') ?? 'provisioning'),
    });
  }
}
