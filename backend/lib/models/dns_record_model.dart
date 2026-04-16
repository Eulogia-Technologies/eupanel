import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class DnsRecord extends Model<DnsRecord> {
  DnsRecord() : super(() => DnsRecord());

  @override
  Table get table => Table(
        name: 'dns_records',
        columns: [
          Column(name: 'zoneId', type: ColumnType.string, length: 255),
          Column(name: 'name', type: ColumnType.string, length: 255),
          Column(name: 'type', type: ColumnType.string, length: 20),
          Column(name: 'content', type: ColumnType.string, length: 255),
          Column(name: 'ttl', type: ColumnType.integer, defaultValue: 3600),
          Column(name: 'priority', type: ColumnType.integer, isNullable: true),
        ],
      );
}
