import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SavingsRepository {
  const SavingsRepository(this._db);

  final AppDatabase _db;

  /// Watch all savings goals ordered by creation date.
  Stream<List<SavingsGoalsTableData>> watchAll() {
    return (_db.select(_db.savingsGoalsTable)
          ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
        .watch();
  }

  /// Insert or replace a savings goal.
  Future<void> upsert(SavingsGoalsTableCompanion companion) async {
    await _db
        .into(_db.savingsGoalsTable)
        .insertOnConflictUpdate(companion);
  }

  /// Update the currentAmount for a savings goal.
  Future<void> updateProgress(int id, double newAmount) async {
    await (_db.update(_db.savingsGoalsTable)
          ..where((g) => g.id.equals(id)))
        .write(
      SavingsGoalsTableCompanion(
        currentAmount: Value(newAmount),
      ),
    );
  }

  /// Mark a savings goal as completed.
  Future<void> markCompleted(int id) async {
    await (_db.update(_db.savingsGoalsTable)
          ..where((g) => g.id.equals(id)))
        .write(
      const SavingsGoalsTableCompanion(
        isCompleted: Value(true),
      ),
    );
  }

  /// Hard delete a savings goal by id.
  Future<void> delete(int id) async {
    await (_db.delete(_db.savingsGoalsTable)
          ..where((g) => g.id.equals(id)))
        .go();
  }
}
