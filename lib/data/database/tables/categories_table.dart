import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get slug => text()();

  TextColumn get colorHex => text().withDefault(const Constant('#6C63FF'))();

  TextColumn get iconName => text().withDefault(const Constant('category'))();

  IntColumn get parentCategoryId => integer().nullable()();

  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}