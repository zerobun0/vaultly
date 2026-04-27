import 'package:drift/drift.dart';

class AccountsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get institution => text().withDefault(const Constant(''))();

  TextColumn get accountType => text()();

  TextColumn get currency => text().withDefault(const Constant('GBP'))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}