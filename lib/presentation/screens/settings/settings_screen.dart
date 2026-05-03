import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/theme_providers.dart';
import '../../../data/services/biometric_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(appThemeModeNotifierProvider);
    final currentMode = themeAsync.valueOrNull ?? ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeName(currentMode)),
            trailing: DropdownButton<ThemeMode>(
              value: currentMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(appThemeModeNotifierProvider.notifier).setMode(mode);
                }
              },
            ),
          ),
          const Divider(),
          const _SectionHeader('Security'),
          _BiometricTile(),
          const Divider(),
          const _SectionHeader('Trading 212'),
          ListTile(
            leading: const Icon(Icons.vpn_key_rounded),
            title: const Text('API Key'),
            subtitle: const Text('Connect your Trading 212 account'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/api-key'),
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Vaultly'),
            subtitle: Text('v1.0.0 — offline-first personal finance'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('All data stays on your device. Zero telemetry.'),
          ),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'Dark',
        ThemeMode.light => 'Light',
        ThemeMode.system => 'System',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _BiometricTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends ConsumerState<_BiometricTile> {
  bool _available = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = BiometricService.instance;
    final available = await svc.isAvailable();
    final enabled = await svc.isEnabled();
    if (mounted) setState(() { _available = available; _enabled = enabled; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) {
      return const ListTile(
        leading: Icon(Icons.fingerprint_rounded),
        title: Text('Biometric Lock'),
        subtitle: Text('Not available on this device'),
        enabled: false,
      );
    }
    return SwitchListTile(
      secondary: const Icon(Icons.fingerprint_rounded),
      title: const Text('Biometric Lock'),
      subtitle: const Text('Require biometrics after 60 s in background'),
      value: _enabled,
      onChanged: (val) async {
        if (val) {
          final authed = await BiometricService.instance.authenticate();
          if (!authed) return;
        }
        await BiometricService.instance.setEnabled(val);
        if (mounted) setState(() => _enabled = val);
      },
    );
  }
}
