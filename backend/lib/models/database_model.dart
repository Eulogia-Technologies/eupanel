import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class DatabaseModel extends Model<DatabaseModel> {
  DatabaseModel() : super(() => DatabaseModel());

  @override
  Table get table => Table(
        name: 'databases',
        columns: [
          Column(name: 'siteId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'serverId', type: ColumnType.string, length: 255),
          Column(name: 'engine', type: ColumnType.string, length: 30),
          Column(name: 'name', type: ColumnType.string, length: 255),
          Column(name: 'username', type: ColumnType.string, length: 255),
          Column(name: 'password', type: ColumnType.string, length: 255),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'active'),
        ],
      );
}
