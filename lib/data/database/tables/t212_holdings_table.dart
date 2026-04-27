import 'package:drift/drift.dart';

import 'accounts_table.dart';

class T212HoldingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get symbol => text()();

  TextColumn get name => text()();

  RealColumn get quantity => real()();

  RealColumn get averagePrice => real()();

  RealColumn get currentPrice => real()();

  RealColumn get marketValue => real()();

  TextColumn get currency => text().withDefault(const Constant('GBP'))();

  IntColumn get accountId => integer().nullable().references(AccountsTable, #id)();

  DateTimeColumn get asOfDate => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}