import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Backup extends Model<Backup> {
  Backup() : super(() => Backup());

  @override
  Table get table => Table(
        name: 'backups',
        columns: [
          Column(name: 'siteId', type: ColumnType.string, length: 255),
          Column(name: 'jobId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'filePath', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'pending'),
          Column(name: 'sizeBytes', type: ColumnType.integer, isNullable: true),
        ],
      );
}
