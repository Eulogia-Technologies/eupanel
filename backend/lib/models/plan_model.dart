import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Plan extends Model<Plan> {
  Plan() : super(() => Plan());

  String? get name => getAttribute("name");
  String? get description => getAttribute("description");
  int? get diskLimit => getAttribute("disk_limit");
  int? get bandwidthLimit => getAttribute("bandwidth_limit");
  int? get ftpAccountsLimit => getAttribute("ftp_accounts_limit");
  int? get databaseLimit => getAttribute("database_limit");
  int? get domainLimit => getAttribute("domain_limit");
  double? get price => getAttribute("price");
  String? get status => getAttribute("status");

  @override
  Table get table => Table(
        name: 'plans',
        columns: [
          Column(name: 'name', type: ColumnType.string, length: 100),
          Column(name: 'description', type: ColumnType.text, isNullable: true),
          Column(name: 'disk_limit', type: ColumnType.integer),
          Column(name: 'bandwidth_limit', type: ColumnType.integer),
          Column(name: 'ftp_accounts_limit', type: ColumnType.integer, defaultValue: 1),
          Column(name: 'database_limit', type: ColumnType.integer, defaultValue: 1),
          Column(name: 'domain_limit', type: ColumnType.integer, defaultValue: 1),
          Column(name: 'price', type: ColumnType.double, isNullable: true),
          Column(name: 'status', type: ColumnType.string, length: 20, defaultValue: 'active'),
        ],
      );
}
