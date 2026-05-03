import 'package:drift/drift.dart';

import '../database/app_database.dart';

class TransactionRepository {
  const TransactionRepository(this._db);

  final AppDatabase _db;

  /// Watch all transactions within [start]..[end] ordered by date descending.
  Stream<List<TransactionsTableData>> watchByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (_db.select(_db.transactionsTable)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerOrEqualValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Insert a single transaction and return the generated id.
  Future<int> insertTransaction(TransactionsTableCompanion companion) {
    return _db.into(_db.transactionsTable).insert(companion);
  }

  /// Bulk insert a list of transactions.
  Future<void> insertAll(List<TransactionsTableCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAll(_db.transactionsTable, companions);
    });
  }

  /// Insert or skip if the externalId already exists.
  /// Returns the row id (existing or newly inserted).
  Future<int> upsertByExternalId(TransactionsTableCompanion companion) async {
    final extId = companion.externalId;
    if (extId.present && extId.value != null) {
      final existing = await (_db.select(_db.transactionsTable)
            ..where((t) => t.externalId.equals(extId.value!))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) return existing.id;
    }
    return _db.into(_db.transactionsTable).insert(companion);
  }

  /// Returns true if no row with [externalId] exists yet.
  Future<bool> isNewExternalId(String externalId) async {
    final existing = await (_db.select(_db.transactionsTable)
          ..where((t) => t.externalId.equals(externalId))
          ..limit(1))
        .getSingleOrNull();
    return existing == null;
  }

  /// Sum of negative amounts (expenses) excluding transfers.
  Stream<double> watchTotalSpend(DateTime start, DateTime end) {
    final query = _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions_table '
      'WHERE transaction_date >= ? AND transaction_date <= ? '
      'AND amount < 0 AND is_transfer = 0',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
      readsFrom: {_db.transactionsTable},
    );
    return query.watchSingle().map((row) => row.read<double>('total'));
  }

  /// Sum of positive amounts (income) excluding transfers.
  Stream<double> watchTotalIncome(DateTime start, DateTime end) {
    final query = _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total '
      'FROM transactions_table '
      'WHERE transaction_date >= ? AND transaction_date <= ? '
      'AND amount > 0 AND is_transfer = 0',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
      readsFrom: {_db.transactionsTable},
    );
    return query.watchSingle().map((row) => row.read<double>('total'));
  }

  /// Update the category for a given transaction.
  Future<void> updateCategory(int transactionId, int categoryId) async {
    await (_db.update(_db.transactionsTable)
          ..where((t) => t.id.equals(transactionId)))
        .write(
      TransactionsTableCompanion(
        categoryId: Value(categoryId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete a transaction by id.
  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactionsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Returns a map of category name → sum of absolute spend for the period.
  Stream<Map<String, double>> watchSpendByCategory(
    DateTime start,
    DateTime end,
  ) {
    final query = _db.customSelect(
      'SELECT c.name AS category_name, COALESCE(SUM(ABS(t.amount)), 0) AS total '
      'FROM transactions_table t '
      'LEFT JOIN categories_table c ON c.id = t.category_id '
      'WHERE t.transaction_date >= ? AND t.transaction_date <= ? '
      'AND t.amount < 0 AND t.is_transfer = 0 '
      'GROUP BY t.category_id',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
      readsFrom: {_db.transactionsTable, _db.categoriesTable},
    );
    return query.watch().map((rows) {
      final result = <String, double>{};
      for (final row in rows) {
        final name = row.read<String?>('category_name') ?? 'Uncategorized';
        final total = row.read<double>('total');
        result[name] = total;
      }
      return result;
    });
  }
}
