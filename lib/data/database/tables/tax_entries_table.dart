import 'package:drift/drift.dart';

class TaxEntriesTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get taxYear => text()();

  TextColumn get entryType => text()();

  RealColumn get amount => real()();

  TextColumn get description => text()();

  DateTimeColumn get effectiveDate => dateTime()();

  TextColumn get source => text().withDefault(const Constant('manual'))();

  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}