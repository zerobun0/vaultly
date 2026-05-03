import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/trading212_service.dart';
import '../../core/errors/app_exceptions.dart';

part 't212_providers.g.dart';

const _storage = FlutterSecureStorage();
const _keyName = 't212_api_key';
const _demoKeyName = 't212_is_demo';

@Riverpod(keepAlive: true)
Future<String?> t212ApiKey(T212ApiKeyRef ref) async {
  return _storage.read(key: _keyName);
}

@Riverpod(keepAlive: true)
Future<bool> t212IsDemo(T212IsDemoRef ref) async {
  final val = await _storage.read(key: _demoKeyName);
  return val == 'true';
}

@Riverpod(keepAlive: true)
Future<Trading212Service?> t212Service(T212ServiceRef ref) async {
  final key = await ref.watch(t212ApiKeyProvider.future);
  if (key == null || key.isEmpty) return null;
  final demo = await ref.watch(t212IsDemoProvider.future);
  return Trading212Service(key, demo: demo);
}

@riverpod
Future<T212Portfolio?> t212Portfolio(T212PortfolioRef ref) async {
  final service = await ref.watch(t212ServiceProvider.future);
  if (service == null) return null;
  try {
    return await service.getPortfolio();
  } on AuthException {
    return null;
  }
}

@riverpod
Future<T212Cash?> t212Cash(T212CashRef ref) async {
  final service = await ref.watch(t212ServiceProvider.future);
  if (service == null) return null;
  try {
    return await service.getCash();
  } on AuthException {
    return null;
  }
}

@riverpod
Future<List<T212Order>> t212OrderHistory(T212OrderHistoryRef ref) async {
  final service = await ref.watch(t212ServiceProvider.future);
  if (service == null) return [];
  try {
    return await service.getOrderHistory();
  } on AuthException {
    return [];
  }
}

@riverpod
Future<List<T212Dividend>> t212DividendHistory(T212DividendHistoryRef ref) async {
  final service = await ref.watch(t212ServiceProvider.future);
  if (service == null) return [];
  try {
    return await service.getDividendHistory();
  } on AuthException {
    return [];
  }
}

@riverpod
class SaveT212ApiKey extends _$SaveT212ApiKey {
  @override
  Future<void> build() async {}

  Future<void> save(String key, {bool demo = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _storage.write(key: _keyName, value: key);
      await _storage.write(key: _demoKeyName, value: demo.toString());
      ref.invalidate(t212ApiKeyProvider);
      ref.invalidate(t212IsDemoProvider);
      ref.invalidate(t212ServiceProvider);
      ref.invalidate(t212PortfolioProvider);
      ref.invalidate(t212CashProvider);
      ref.invalidate(t212OrderHistoryProvider);
      ref.invalidate(t212DividendHistoryProvider);
    });
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _storage.delete(key: _keyName);
      ref.invalidate(t212ApiKeyProvider);
      ref.invalidate(t212ServiceProvider);
    });
  }
}
