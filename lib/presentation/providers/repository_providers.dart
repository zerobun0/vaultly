import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/savings_repository.dart';
import '../../data/repositories/tax_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(TransactionRepositoryRef ref) {
  return TransactionRepository(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(BudgetRepositoryRef ref) {
  return BudgetRepository(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
SavingsRepository savingsRepository(SavingsRepositoryRef ref) {
  return SavingsRepository(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
TaxRepository taxRepository(TaxRepositoryRef ref) {
  return TaxRepository(ref.watch(databaseProvider));
}
