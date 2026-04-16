import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Job extends Model<Job> {
  Job() : super(() => Job());

  @override
  Table get table => Table(
        name: 'jobs',
        columns: [
          Column(name: 'type', type: ColumnType.string, length: 100),
          Column(name: 'status', type: ColumnType.string, length: 20, defaultValue: 'pending'),
          Column(name: 'targetType', type: ColumnType.string, length: 100, isNullable: true),
          Column(name: 'targetId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'serverId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'payload', type: ColumnType.json, isNullable: true),
          Column(name: 'logs', type: ColumnType.text, isNullable: true),
        ],
      );
}
