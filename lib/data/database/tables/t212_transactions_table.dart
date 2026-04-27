import 'package:drift/drift.dart';

import 'accounts_table.dart';

class T212TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get externalId => text().nullable()();

  TextColumn get transactionType => text()();

  TextColumn get symbol => text().nullable()();

  RealColumn get quantity => real().withDefault(const Constant(0))();

  RealColumn get price => real().withDefault(const Constant(0))();

  RealColumn get amount => real()();

  TextColumn get currency => text().withDefault(const Constant('GBP'))();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get description => text().withDefault(const Constant(''))();

  IntColumn get accountId => integer().nullable().references(AccountsTable, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}