import 'package:flint_ui/flint_ui.dart';

import '../components/enterprise_records_view.dart';

class BackupsPage extends StatelessComponent {
  BackupsPage({required this.backups});

  final ResourceController<List<FlintModelRecord>> backups;

  @override
  View build() {
    return EnterpriseRecordsView(
      title: 'Backups',
      subtitle: 'Backup jobs, restore points, file paths, and storage sizes',
      resource: backups,
      columns: _columns,
      rowBuilder: _row,
      emptyTitle: 'No backups yet',
      emptyMessage: 'Backup jobs will appear here after they are requested.',
    );
  }

  static const _columns = [
    TableColumn(key: 'siteId', label: 'Site'),
    TableColumn(key: 'status', label: 'Status'),
    TableColumn(key: 'size', label: 'Size'),
    TableColumn(key: 'filePath', label: 'File'),
  ];

  TableRowData _row(FlintModelRecord record) {
    return TableRowData(cells: {
      'siteId': record.string('siteId') ?? '-',
      'status': StatusPill(status: record.string('status') ?? 'pending'),
      'size': _formatBytes(record['sizeBytes']),
      'filePath': record.string('filePath') ?? '-',
    });
  }

  String _formatBytes(Object? value) {
    final bytes = int.tryParse(value?.toString() ?? '');
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
