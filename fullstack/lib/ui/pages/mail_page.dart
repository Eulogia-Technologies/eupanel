import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class MailPage extends StatelessComponent {
  MailPage({required this.mail});

  final ResourceController<List<FlintModelRecord>> mail;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'Mail Accounts',
      subtitle: 'Mailbox identities and forwarding status for hosted domains',
      resource: mail,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No mail accounts',
      emptyMessage: 'Mailboxes created for hosted domains will appear here.',
    );
  }

  static const _columns = [
    TableColumn(key: 'email', label: 'Email'),
    TableColumn(key: 'domain', label: 'Domain'),
    TableColumn(key: 'forwardTo', label: 'Forward To'),
    TableColumn(key: 'status', label: 'Status'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'email': record.string('email') ?? '-',
      'domain': record.string('domain') ?? '-',
      'forwardTo': record.string('forwardTo') ?? '-',
      'status': StatusPill(status: record.string('status') ?? 'active'),
    });
  }
}
