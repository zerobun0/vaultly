// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appThemeModeNotifierHash() =>
    r'b41bb4668e9741eb63cd8c547ec30b9644d9158d';

/// See also [AppThemeModeNotifier].
@ProviderFor(AppThemeModeNotifier)
final appThemeModeNotifierProvider =
    AsyncNotifierProvider<AppThemeModeNotifier, ThemeMode>.internal(
  AppThemeModeNotifier.new,
  name: r'appThemeModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appThemeModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppThemeModeNotifier = AsyncNotifier<ThemeMode>;
String _$biometricLockNotifierHash() =>
    r'7226569d02bed377fd224f28c1d3fff4f572f994';

/// See also [BiometricLockNotifier].
@ProviderFor(BiometricLockNotifier)
final biometricLockNotifierProvider =
    NotifierProvider<BiometricLockNotifier, bool>.internal(
  BiometricLockNotifier.new,
  name: r'biometricLockNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricLockNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BiometricLockNotifier = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
