import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class SiteRuntime extends Model<SiteRuntime> {
  SiteRuntime() : super(() => SiteRuntime());

  @override
  Table get table => Table(
        name: 'site_runtime',
        columns: [
          Column(name: 'siteId', type: ColumnType.string, length: 255),
          Column(name: 'runtime', type: ColumnType.string, length: 50),
          Column(name: 'version', type: ColumnType.string, length: 50),
          Column(name: 'startCommand', type: ColumnType.string, length: 255),
          Column(name: 'port', type: ColumnType.integer),
          Column(name: 'serviceName', type: ColumnType.string, length: 255),
        ],
      );
}
