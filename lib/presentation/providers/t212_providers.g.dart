// GENERATED CODE - DO NOT MODIFY BY HAND

part of 't212_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$t212ApiKeyHash() => r'38a91cb8ea4213694d03a9477589dd658e7dc94b';

/// See also [t212ApiKey].
@ProviderFor(t212ApiKey)
final t212ApiKeyProvider = FutureProvider<String?>.internal(
  t212ApiKey,
  name: r't212ApiKeyProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$t212ApiKeyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212ApiKeyRef = FutureProviderRef<String?>;
String _$t212IsDemoHash() => r'6f582eb0c49b12bc168254ade45b6ba62ce92359';

/// See also [t212IsDemo].
@ProviderFor(t212IsDemo)
final t212IsDemoProvider = FutureProvider<bool>.internal(
  t212IsDemo,
  name: r't212IsDemoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$t212IsDemoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212IsDemoRef = FutureProviderRef<bool>;
String _$t212ServiceHash() => r'642800d8c937a43da6c2320c763074e8c112c34f';

/// See also [t212Service].
@ProviderFor(t212Service)
final t212ServiceProvider = FutureProvider<Trading212Service?>.internal(
  t212Service,
  name: r't212ServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$t212ServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212ServiceRef = FutureProviderRef<Trading212Service?>;
String _$t212PortfolioHash() => r'9e81c3f31fcf7069cb553cd2eb7e8a32273c4987';

/// See also [t212Portfolio].
@ProviderFor(t212Portfolio)
final t212PortfolioProvider =
    AutoDisposeFutureProvider<T212Portfolio?>.internal(
  t212Portfolio,
  name: r't212PortfolioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$t212PortfolioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212PortfolioRef = AutoDisposeFutureProviderRef<T212Portfolio?>;
String _$t212CashHash() => r'4d06e1515e53c2d91b86e339566dd1ed7b3e5092';

/// See also [t212Cash].
@ProviderFor(t212Cash)
final t212CashProvider = AutoDisposeFutureProvider<T212Cash?>.internal(
  t212Cash,
  name: r't212CashProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$t212CashHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212CashRef = AutoDisposeFutureProviderRef<T212Cash?>;
String _$t212OrderHistoryHash() => r'e00229ce260eeec42f60d3cf675ac7886e02728a';

/// See also [t212OrderHistory].
@ProviderFor(t212OrderHistory)
final t212OrderHistoryProvider =
    AutoDisposeFutureProvider<List<T212Order>>.internal(
  t212OrderHistory,
  name: r't212OrderHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$t212OrderHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212OrderHistoryRef = AutoDisposeFutureProviderRef<List<T212Order>>;
String _$t212DividendHistoryHash() =>
    r'ac2e84da333b79d08556177f44504213fb4d8a6a';

/// See also [t212DividendHistory].
@ProviderFor(t212DividendHistory)
final t212DividendHistoryProvider =
    AutoDisposeFutureProvider<List<T212Dividend>>.internal(
  t212DividendHistory,
  name: r't212DividendHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$t212DividendHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef T212DividendHistoryRef
    = AutoDisposeFutureProviderRef<List<T212Dividend>>;
String _$saveT212ApiKeyHash() => r'7ee349fb8be288c48cad3838ddd8f8a17fd36f04';

/// See also [SaveT212ApiKey].
@ProviderFor(SaveT212ApiKey)
final saveT212ApiKeyProvider =
    AutoDisposeAsyncNotifierProvider<SaveT212ApiKey, void>.internal(
  SaveT212ApiKey.new,
  name: r'saveT212ApiKeyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saveT212ApiKeyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SaveT212ApiKey = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
