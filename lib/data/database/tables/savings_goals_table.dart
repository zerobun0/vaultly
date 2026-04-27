import 'package:drift/drift.dart';

class SavingsGoalsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get targetAmount => real()();

  RealColumn get currentAmount => real().withDefault(const Constant(0))();

  DateTimeColumn get targetDate => dateTime().nullable()();

  TextColumn get iconName => text().withDefault(const Constant('savings'))();

  TextColumn get notes => text().nullable()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}