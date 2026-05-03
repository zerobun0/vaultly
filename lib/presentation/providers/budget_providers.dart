import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import 'repository_providers.dart';

part 'budget_providers.g.dart';

// ---------------------------------------------------------------------------
// Active budgets stream
// ---------------------------------------------------------------------------

@riverpod
Stream<List<BudgetsTableData>> activeBudgets(ActiveBudgetsRef ref) {
  return ref.watch(budgetRepositoryProvider).watchActive();
}

// ---------------------------------------------------------------------------
// Budget notifier – upsert / delete
// ---------------------------------------------------------------------------

@riverpod
class BudgetNotifier extends _$BudgetNotifier {
  @override
  Future<void> build() async {}

  Future<void> upsert(BudgetsTableCompanion companion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).upsert(companion),
    );
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(budgetRepositoryProvider).delete(id),
    );
  }
}
