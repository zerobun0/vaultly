import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/biometric_service.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/theme_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/theme/app_theme_dark.dart';

class VaultlyApp extends ConsumerWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(appThemeModeNotifierProvider);
    final themeMode = themeModeAsync.valueOrNull ?? ThemeMode.dark;

    return MaterialApp.router(
      title: 'Vaultly',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppThemeDark.dark(),
      themeMode: themeMode,
      builder: (context, child) => _BiometricGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _BiometricGate extends ConsumerStatefulWidget {
  const _BiometricGate({required this.child});
  final Widget child;

  @override
  ConsumerState<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<_BiometricGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  static const _lockTimeout = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final at = _backgroundedAt;
    if (at == null) return;
    final elapsed = DateTime.now().difference(at);
    if (elapsed < _lockTimeout) return;

    final enabled = await BiometricService.instance.isEnabled();
    if (!enabled) return;

    ref.read(biometricLockNotifierProvider.notifier).lock();
    final authed = await BiometricService.instance.authenticate();
    if (authed && mounted) {
      ref.read(biometricLockNotifierProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(biometricLockNotifierProvider);

    if (locked) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 64),
              const SizedBox(height: 16),
              const Text('Vaultly is locked'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                onPressed: () async {
                  final authed = await BiometricService.instance.authenticate();
                  if (authed && mounted) {
                    ref.read(biometricLockNotifierProvider.notifier).unlock();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
