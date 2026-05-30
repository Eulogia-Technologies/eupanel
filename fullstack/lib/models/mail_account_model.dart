import 'package:flint_dart/model.dart';
import 'package:flint_dart/schema.dart';

class MailAccount extends Model<MailAccount> {
  MailAccount() : super(() => MailAccount());

  @override
  Table get table => Table(
        name: 'mail_accounts',
        columns: [
          Column(name: 'siteId', type: ColumnType.string, length: 255, isNullable: true),
          Column(name: 'domain', type: ColumnType.string, length: 255),
          Column(name: 'email', type: ColumnType.string, length: 255, isUnique: true),
          Column(name: 'password', type: ColumnType.string, length: 255),
          Column(name: 'status', type: ColumnType.string, length: 30, defaultValue: 'active'),
          Column(name: 'forwardTo', type: ColumnType.string, length: 255, isNullable: true),
        ],
      );
}

