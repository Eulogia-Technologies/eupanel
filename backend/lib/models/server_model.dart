import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Server extends Model<Server> {
  Server() : super(() => Server());

  String? get name => getAttribute("name");
  String? get host => getAttribute("host");
  String? get status => getAttribute("status");
  String? get agentPort => getAttribute("agent_port");
  String? get agentSecret => getAttribute("agent_secret");

  @override
  Table get table => Table(
        name: 'servers',
        columns: [
          Column(name: 'name', type: ColumnType.string, length: 255),
          Column(name: 'host', type: ColumnType.string, length: 255),
          Column(
              name: 'status', type: ColumnType.string, defaultValue: 'active'),
          Column(
            name: 'agent_port',
            type: ColumnType.string,
            length: 10,
            defaultValue: '7820',
            //    comment: 'EuPanel agent HTTP port',
          ),
          Column(
            name: 'agent_secret',
            type: ColumnType.string,
            isNullable: true,
            // comment: 'Shared secret for agent authentication',
          ),
          Column(
              name: 'agent_version', type: ColumnType.string, isNullable: true),
          Column(
              name: 'last_heartbeat_at',
              type: ColumnType.timestamp,
              isNullable: true),
        ],
      );
}
