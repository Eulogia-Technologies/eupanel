import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Site extends Model<Site> {
  Site() : super(() => Site());

  @override
  Table get table => Table(
        name: 'sites',
        columns: [
          Column(name: 'serverId', type: ColumnType.string, length: 255),
          Column(name: 'userId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'domain', type: ColumnType.string, length: 255, isUnique: true),
          Column(name: 'runtime', type: ColumnType.string, length: 50),
          Column(name: 'runtimeVersion', type: ColumnType.string, length: 50),
          Column(name: 'rootPath', type: ColumnType.string, length: 255),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'provisioning'),
        ],
      );
}
