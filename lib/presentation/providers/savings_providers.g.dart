// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$savingsGoalsHash() => r'36bb7a3558946359277191c297e86068b378998d';

/// See also [savingsGoals].
@ProviderFor(savingsGoals)
final savingsGoalsProvider =
    AutoDisposeStreamProvider<List<SavingsGoalsTableData>>.internal(
  savingsGoals,
  name: r'savingsGoalsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$savingsGoalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SavingsGoalsRef
    = AutoDisposeStreamProviderRef<List<SavingsGoalsTableData>>;
String _$savingsNotifierHash() => r'eb886988addec8fad09284c6ff449944c39072ac';

/// See also [SavingsNotifier].
@ProviderFor(SavingsNotifier)
final savingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SavingsNotifier, void>.internal(
  SavingsNotifier.new,
  name: r'savingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SavingsNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
