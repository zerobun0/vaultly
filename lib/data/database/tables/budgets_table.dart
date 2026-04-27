import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';

class BudgetsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get categoryId => integer().references(CategoriesTable, #id)();

  IntColumn get accountId => integer().nullable().references(AccountsTable, #id)();

  TextColumn get periodType => text()();

  RealColumn get amount => real()();

  DateTimeColumn get periodStart => dateTime()();

  DateTimeColumn get periodEnd => dateTime().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}