import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Domain extends Model<Domain> {
  Domain() : super(() => Domain());

  String? get subscriptionId => getAttribute("subscription_id");
  String? get domain => getAttribute("domain");
  String? get rootPath => getAttribute("root_path");
  String? get nginxConfigPath => getAttribute("nginx_config_path");
  String? get sslStatus => getAttribute("ssl_status");
  String? get status => getAttribute("status");
  String? get provisioningLog => getAttribute("provisioning_log");

  @override
  Table get table => Table(
        name: 'domains',
        columns: [
          Column(
            name: 'subscription_id',
            type: ColumnType.string,
            length: 36,
            comment: 'FK → subscriptions.id',
          ),
          Column(
            name: 'domain',
            type: ColumnType.string,
            length: 253,
            isUnique: true,
          ),
          Column(
            name: 'root_path',
            type: ColumnType.string,
            length: 255,
            comment: '/home/{system_username}/public_html',
          ),
          Column(
            name: 'nginx_config_path',
            type: ColumnType.string,
            length: 255,
            isNullable: true,
            comment: '/etc/nginx/sites-available/{domain}',
          ),
          Column(
            name: 'ssl_status',
            type: ColumnType.string,
            length: 20,
            defaultValue: 'pending',
            comment: 'pending | active | failed',
          ),
          Column(
            name: 'status',
            type: ColumnType.string,
            length: 20,
            defaultValue: 'pending',
            comment: 'pending | active | failed',
          ),
          Column(
            name: 'provisioning_log',
            type: ColumnType.text,
            isNullable: true,
          ),
        ],
      );
}
