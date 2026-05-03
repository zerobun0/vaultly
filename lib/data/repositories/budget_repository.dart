import 'package:drift/drift.dart';

import '../database/app_database.dart';

class BudgetRepository {
  const BudgetRepository(this._db);

  final AppDatabase _db;

  /// Watch all active budgets.
  Stream<List<BudgetsTableData>> watchActive() {
    return (_db.select(_db.budgetsTable)
          ..where((b) => b.isActive.equals(true))
          ..orderBy([(b) => OrderingTerm.asc(b.periodStart)]))
        .watch();
  }

  /// Insert or replace a budget.
  Future<void> upsert(BudgetsTableCompanion companion) async {
    await _db
        .into(_db.budgetsTable)
        .insertOnConflictUpdate(companion);
  }

  /// Hard delete a budget by id.
  Future<void> delete(int id) async {
    await (_db.delete(_db.budgetsTable)..where((b) => b.id.equals(id))).go();
  }
}
