import 'package:drift/drift.dart';

import '../database/app_database.dart';

class TaxRepository {
  const TaxRepository(this._db);

  final AppDatabase _db;

  /// Watch all tax entries for the given tax year (e.g. 2025 for 2025/26).
  /// The [taxYear] column is stored as a string such as "2025/26".
  Stream<List<TaxEntriesTableData>> watchByTaxYear(int taxYear) {
    final yearLabel = '$taxYear/${(taxYear + 1).toString().substring(2)}';
    return (_db.select(_db.taxEntriesTable)
          ..where((t) => t.taxYear.equals(yearLabel))
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveDate)]))
        .watch();
  }

  /// Insert or replace a tax entry.
  Future<void> upsert(TaxEntriesTableCompanion companion) async {
    await _db
        .into(_db.taxEntriesTable)
        .insertOnConflictUpdate(companion);
  }

  /// Hard delete a tax entry by id.
  Future<void> delete(int id) async {
    await (_db.delete(_db.taxEntriesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}
