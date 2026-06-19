import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class SslPage extends StatelessComponent {
  SslPage({required this.certificates});

  final ResourceController<List<FlintModelRecord>> certificates;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'SSL Certificates',
      subtitle: 'Let\'s Encrypt certificates issued for hosted websites',
      resource: certificates,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No SSL certificates',
      emptyMessage: 'SSL certificates will appear after domain issuance.',
    );
  }

  static const _columns = [
    TableColumn(key: 'domain', label: 'Domain'),
    TableColumn(key: 'provider', label: 'Provider'),
    TableColumn(key: 'status', label: 'Status'),
    TableColumn(key: 'expires', label: 'Expires'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'domain': record.string('domain') ?? '-',
      'provider': record.string('provider') ?? 'letsencrypt',
      'status': StatusPill(status: record.string('status') ?? 'pending'),
      'expires':
          record.string('expiresAt') ?? record.string('expires_at') ?? '-',
    });
  }
}
