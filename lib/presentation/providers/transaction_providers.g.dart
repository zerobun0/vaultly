// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionsHash() => r'f2e44e5b18c0f91bf8f8d6b447585416712fc0e4';

/// See also [transactions].
@ProviderFor(transactions)
final transactionsProvider =
    AutoDisposeStreamProvider<List<TransactionsTableData>>.internal(
  transactions,
  name: r'transactionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$transactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionsRef
    = AutoDisposeStreamProviderRef<List<TransactionsTableData>>;
String _$totalSpendHash() => r'9f2ccb0a4cc18102f27ed6743f8d40c39734f3f7';

/// See also [totalSpend].
@ProviderFor(totalSpend)
final totalSpendProvider = AutoDisposeStreamProvider<double>.internal(
  totalSpend,
  name: r'totalSpendProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$totalSpendHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalSpendRef = AutoDisposeStreamProviderRef<double>;
String _$totalIncomeHash() => r'00d34c45ef2dea6b2d0fb1b0530bee96955b4df0';

/// See also [totalIncome].
@ProviderFor(totalIncome)
final totalIncomeProvider = AutoDisposeStreamProvider<double>.internal(
  totalIncome,
  name: r'totalIncomeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$totalIncomeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalIncomeRef = AutoDisposeStreamProviderRef<double>;
String _$spendByCategoryHash() => r'956a5987ad788f6613cf6af75e6f4e4f36438ffe';

/// See also [spendByCategory].
@ProviderFor(spendByCategory)
final spendByCategoryProvider =
    AutoDisposeStreamProvider<Map<String, double>>.internal(
  spendByCategory,
  name: r'spendByCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spendByCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SpendByCategoryRef = AutoDisposeStreamProviderRef<Map<String, double>>;
String _$selectedDateRangeHash() => r'6d694639090143ce20825ff86186f01f70e41bd2';

/// See also [SelectedDateRange].
@ProviderFor(SelectedDateRange)
final selectedDateRangeProvider =
    AutoDisposeNotifierProvider<SelectedDateRange, DateTimeRange>.internal(
  SelectedDateRange.new,
  name: r'selectedDateRangeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedDateRangeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDateRange = AutoDisposeNotifier<DateTimeRange>;
String _$importTransactionsHash() =>
    r'7a68a121c19fd255c75e52c8c2abddac59568595';

/// See also [ImportTransactions].
@ProviderFor(ImportTransactions)
final importTransactionsProvider =
    AutoDisposeAsyncNotifierProvider<ImportTransactions, int>.internal(
  ImportTransactions.new,
  name: r'importTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$importTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ImportTransactions = AutoDisposeAsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
