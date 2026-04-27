import 'package:drift/drift.dart';

import 'categories_table.dart';

class MerchantRulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get merchantPattern => text()();

  IntColumn get categoryId => integer().references(CategoriesTable, #id)();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}