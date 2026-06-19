import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class DnsPage extends StatelessComponent {
  DnsPage({required this.zones});

  final ResourceController<List<FlintModelRecord>> zones;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'DNS Zones',
      subtitle: 'PowerDNS zones for hosted domains and nameserver records',
      resource: zones,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No DNS zones',
      emptyMessage: 'DNS zones will be created when domains are provisioned.',
    );
  }

  static const _columns = [
    TableColumn(key: 'domain', label: 'Domain'),
    TableColumn(key: 'provider', label: 'Provider'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'domain': record.string('domain') ?? '-',
      'provider': record.string('provider') ?? 'powerdns',
      'status': StatusPill(status: record.string('status') ?? 'active'),
    });
  }
}
