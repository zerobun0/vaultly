import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

class TransactionsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get externalId => text().nullable()();

  TextColumn get sourceBank => text()();

  IntColumn get accountId => integer().nullable().references(AccountsTable, #id)();

  IntColumn get categoryId => integer().nullable().references(CategoriesTable, #id)();

  TextColumn get merchantName => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  RealColumn get amount => real()();

  TextColumn get currency => text().withDefault(const Constant('GBP'))();

  DateTimeColumn get transactionDate => dateTime()();

  DateTimeColumn get postedDate => dateTime().nullable()();

  BoolColumn get isTransfer => boolean().withDefault(const Constant(false))();

  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}