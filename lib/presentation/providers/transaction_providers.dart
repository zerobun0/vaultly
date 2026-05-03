import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import '../../data/parsers/bank_parser_interface.dart';
import '../../data/services/categorizer_service.dart';
import 'repository_providers.dart';

part 'transaction_providers.g.dart';

// ---------------------------------------------------------------------------
// Selected date range – defaults to current calendar month
// ---------------------------------------------------------------------------

@riverpod
class SelectedDateRange extends _$SelectedDateRange {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999, 999);
    return DateTimeRange(start: start, end: end);
  }

  void update(DateTimeRange range) => state = range;
}

// ---------------------------------------------------------------------------
// Transactions stream
// ---------------------------------------------------------------------------

@riverpod
Stream<List<TransactionsTableData>> transactions(TransactionsRef ref) {
  final range = ref.watch(selectedDateRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchByDateRange(range.start, range.end);
}

// ---------------------------------------------------------------------------
// Total spend stream
// ---------------------------------------------------------------------------

@riverpod
Stream<double> totalSpend(TotalSpendRef ref) {
  final range = ref.watch(selectedDateRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTotalSpend(range.start, range.end);
}

// ---------------------------------------------------------------------------
// Total income stream
// ---------------------------------------------------------------------------

@riverpod
Stream<double> totalIncome(TotalIncomeRef ref) {
  final range = ref.watch(selectedDateRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTotalIncome(range.start, range.end);
}

// ---------------------------------------------------------------------------
// Spend by category stream
// ---------------------------------------------------------------------------

@riverpod
Stream<Map<String, double>> spendByCategory(SpendByCategoryRef ref) {
  final range = ref.watch(selectedDateRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchSpendByCategory(range.start, range.end);
}

// ---------------------------------------------------------------------------
// Import transactions notifier
// ---------------------------------------------------------------------------

@riverpod
class ImportTransactions extends _$ImportTransactions {
  @override
  Future<int> build() async => 0;

  /// Categorize, deduplicate by externalId, and insert [parsed] transactions.
  /// Returns the number of rows actually inserted (duplicates skipped).
  Future<int> importAll(List<ParsedBankTransaction> parsed) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      const categorizer = CategorizerService();
      final categorized = categorizer.categorizeTransactions(parsed);
      final repo = ref.read(transactionRepositoryProvider);

      // Deduplicate within the batch by externalId.
      final unique = <String, ParsedBankTransaction>{};
      for (final tx in categorized) {
        unique.putIfAbsent(tx.externalId, () => tx);
      }

      int inserted = 0;
      for (final tx in unique.values) {
        // Check DB before inserting so we can count true new rows.
        final isNew = await repo.isNewExternalId(tx.externalId);

        final companion = TransactionsTableCompanion.insert(
          externalId: Value(tx.externalId),
          sourceBank: tx.sourceBank,
          merchantName: tx.merchantName,
          description: Value(tx.description),
          amount: tx.amount,
          currency: Value(tx.currency),
          transactionDate: tx.transactionDate,
          postedDate: Value(tx.postedDate),
          isTransfer: Value(tx.isTransfer),
          isIncome: Value(tx.amount > 0),
        );

        await repo.upsertByExternalId(companion);
        if (isNew) inserted++;
      }

      return inserted;
    });

    state = result;
    return result.value ?? 0;
  }
}
