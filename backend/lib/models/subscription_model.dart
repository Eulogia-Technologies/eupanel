import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class Subscription extends Model<Subscription> {
  Subscription() : super(() => Subscription());

  String? get userId => getAttribute("user_id");
  String? get planId => getAttribute("plan_id");
  String? get serverId => getAttribute("server_id");
  String? get systemUsername => getAttribute("system_username");
  String? get ftpUsername => getAttribute("ftp_username");
  String? get ftpPassword => getAttribute("ftp_password");
  String? get homeDirectory => getAttribute("home_directory");
  String? get status => getAttribute("status");
  String? get provisioningStatus => getAttribute("provisioning_status");
  String? get provisioningLog => getAttribute("provisioning_log");

  @override
  Table get table => Table(
        name: 'subscriptions',
        columns: [
          Column(
            name: 'user_id',
            type: ColumnType.string,
            length: 36,
            // comment: 'FK → users.id',
          ),
          Column(
            name: 'plan_id',
            type: ColumnType.string,
            length: 36,
            // comment: 'FK → plans.id',
          ),
          Column(
            name: 'server_id',
            type: ColumnType.string,
            length: 36,
            isNullable: true,
            //comment: 'FK → servers.id — which server this subscription lives on',
          ),
          Column(
            name: 'system_username',
            type: ColumnType.string,
            length: 64,
            isUnique: true,
            //comment: 'Linux system username on the server',
          ),
          Column(
            name: 'ftp_username',
            type: ColumnType.string,
            length: 64,
            isNullable: true,
          ),
          Column(
            name: 'home_directory',
            type: ColumnType.string,
            length: 255,
            isNullable: true,
            //comment: '/home/{system_username}',
          ),
          Column(
            name: 'status',
            type: ColumnType.string,
            length: 20,
            defaultValue: 'pending',
            //comment: 'pending | active | suspended | cancelled',
          ),
          Column(
            name: 'provisioning_status',
            type: ColumnType.string,
            length: 20,
            defaultValue: 'pending',
            //comment: 'pending | provisioning | success | failed',
          ),
          Column(
            name: 'provisioning_log',
            type: ColumnType.text,
            isNullable: true,
            //comment: 'Last provisioning output for debugging',
          ),
        ],
      );
}
