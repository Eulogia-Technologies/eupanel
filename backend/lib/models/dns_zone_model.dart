import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class DnsZone extends Model<DnsZone> {
  DnsZone() : super(() => DnsZone());

  @override
  Table get table => Table(
        name: 'dns_zones',
        columns: [
          Column(name: 'domain', type: ColumnType.string, length: 255, isUnique: true),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'active'),
          Column(name: 'provider', type: ColumnType.string, length: 100, defaultValue: 'powerdns'),
        ],
      );
}
