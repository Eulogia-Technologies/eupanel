import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class SslCertificate extends Model<SslCertificate> {
  SslCertificate() : super(() => SslCertificate());

  @override
  Table get table => Table(
        name: 'ssl_certificates',
        columns: [
          Column(name: 'siteId', type: ColumnType.string, length: 255),
          Column(name: 'domain', type: ColumnType.string, length: 255),
          Column(name: 'provider', type: ColumnType.string, length: 100, defaultValue: 'letsencrypt'),
          Column(name: 'status', type: ColumnType.string, defaultValue: 'pending'),
          Column(name: 'expiresAt', type: ColumnType.timestamp, isNullable: true),
        ],
      );
}
