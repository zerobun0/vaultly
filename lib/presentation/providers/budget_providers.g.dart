// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeBudgetsHash() => r'31bfcf6aaab057904fb3379abd692b41506c8ccc';

/// See also [activeBudgets].
@ProviderFor(activeBudgets)
final activeBudgetsProvider =
    AutoDisposeStreamProvider<List<BudgetsTableData>>.internal(
  activeBudgets,
  name: r'activeBudgetsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeBudgetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveBudgetsRef = AutoDisposeStreamProviderRef<List<BudgetsTableData>>;
String _$budgetNotifierHash() => r'956d5511b506cad533d61f5bff3cd76d9fb74be1';

/// See also [BudgetNotifier].
@ProviderFor(BudgetNotifier)
final budgetNotifierProvider =
    AutoDisposeAsyncNotifierProvider<BudgetNotifier, void>.internal(
  BudgetNotifier.new,
  name: r'budgetNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$budgetNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BudgetNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
