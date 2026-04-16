import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Server extends Model<Server> {
  Server() : super(() => Server());

  @override
  Table get table => Table(
        name: 'servers',
        columns: [
          Column(name: 'name', type: ColumnType.string, length: 255),
          Column(name: 'host', type: ColumnType.string, length: 255),
          Column(name: 'port', type: ColumnType.integer, defaultValue: 22),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'active'),
          Column(name: 'agentVersion', type: ColumnType.string, isNullable: true),
          Column(name: 'lastHeartbeatAt', type: ColumnType.timestamp, isNullable: true),
        ],
      );
}
