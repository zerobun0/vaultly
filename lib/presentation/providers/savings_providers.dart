import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import 'repository_providers.dart';

part 'savings_providers.g.dart';

// ---------------------------------------------------------------------------
// All savings goals stream
// ---------------------------------------------------------------------------

@riverpod
Stream<List<SavingsGoalsTableData>> savingsGoals(SavingsGoalsRef ref) {
  return ref.watch(savingsRepositoryProvider).watchAll();
}

// ---------------------------------------------------------------------------
// Savings notifier – upsert / updateProgress / markCompleted / delete
// ---------------------------------------------------------------------------

@riverpod
class SavingsNotifier extends _$SavingsNotifier {
  @override
  Future<void> build() async {}

  Future<void> upsert(SavingsGoalsTableCompanion companion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsRepositoryProvider).upsert(companion),
    );
  }

  Future<void> updateProgress(int id, double newAmount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsRepositoryProvider).updateProgress(id, newAmount),
    );
  }

  Future<void> markCompleted(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsRepositoryProvider).markCompleted(id),
    );
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(savingsRepositoryProvider).delete(id),
    );
  }
}
