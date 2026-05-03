// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTaxYearHash() => r'23b63eac0ec5da421872818e6cde7ac81cecd1b7';

/// See also [currentTaxYear].
@ProviderFor(currentTaxYear)
final currentTaxYearProvider = Provider<int>.internal(
  currentTaxYear,
  name: r'currentTaxYearProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTaxYearHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTaxYearRef = ProviderRef<int>;
String _$taxEntriesHash() => r'b7ae3f3c2d3da0b16fecf0d5b7c6a308efd13e5a';

/// See also [taxEntries].
@ProviderFor(taxEntries)
final taxEntriesProvider =
    AutoDisposeStreamProvider<List<TaxEntriesTableData>>.internal(
  taxEntries,
  name: r'taxEntriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$taxEntriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TaxEntriesRef = AutoDisposeStreamProviderRef<List<TaxEntriesTableData>>;
String _$taxNotifierHash() => r'7fdd925e36f510e908dc168e474b95c694183f2f';

/// See also [TaxNotifier].
@ProviderFor(TaxNotifier)
final taxNotifierProvider =
    AutoDisposeAsyncNotifierProvider<TaxNotifier, void>.internal(
  TaxNotifier.new,
  name: r'taxNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$taxNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TaxNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
