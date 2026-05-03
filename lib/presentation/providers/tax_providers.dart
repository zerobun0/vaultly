import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import 'repository_providers.dart';

part 'tax_providers.g.dart';

// ---------------------------------------------------------------------------
// Current UK tax year
// UK tax year runs 6 Apr – 5 Apr. e.g. 2025 means the 2025/26 year.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
int currentTaxYear(CurrentTaxYearRef ref) {
  final now = DateTime.now();
  // After 5 April the new tax year has started.
  if (now.month > 4 || (now.month == 4 && now.day >= 6)) {
    return now.year;
  }
  return now.year - 1;
}

// ---------------------------------------------------------------------------
// Tax entries stream for the current tax year
// ---------------------------------------------------------------------------

@riverpod
Stream<List<TaxEntriesTableData>> taxEntries(TaxEntriesRef ref) {
  final taxYear = ref.watch(currentTaxYearProvider);
  return ref.watch(taxRepositoryProvider).watchByTaxYear(taxYear);
}

// ---------------------------------------------------------------------------
// Tax notifier – upsert / delete
// ---------------------------------------------------------------------------

@riverpod
class TaxNotifier extends _$TaxNotifier {
  @override
  Future<void> build() async {}

  Future<void> upsert(TaxEntriesTableCompanion companion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(taxRepositoryProvider).upsert(companion),
    );
  }

  Future<void> delete(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(taxRepositoryProvider).delete(id),
    );
  }
}
