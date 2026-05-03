import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// t212_providers.g.dart will be generated; reference by name after build_runner
// ignore: directives_ordering
import '../../providers/t212_providers.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isDemo = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(saveT212ApiKeyProvider.notifier).save(_controller.text.trim(), demo: _isDemo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
      context.pop();
    }
  }

  Future<void> _clear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove API Key?'),
        content: const Text('Your Trading 212 data will no longer sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(saveT212ApiKeyProvider.notifier).clear();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(saveT212ApiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trading 212 API Key')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your Trading 212 API key.\n\n'
                'Get it from: Trading 212 app → Settings → API (Beta).',
              ),
              const SizedBox(height: 8),
              const Text(
                'Your key is stored in the device secure keystore and never leaves your device.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controller,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Paste your T212 API key here',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'API key cannot be empty';
                  if (v.trim().length < 8) return 'Key seems too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Demo / Practice account'),
                subtitle: const Text('Use demo.trading212.com instead of live'),
                value: _isDemo,
                onChanged: (v) => setState(() => _isDemo = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: saveState.isLoading ? null : _save,
                child: saveState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Key'),
              ),
              const SizedBox(height: 12),
              ref.watch(t212ApiKeyProvider).valueOrNull?.isNotEmpty == true
                  ? OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove API Key'),
                    )
                  : const SizedBox.shrink(),
              if (saveState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    saveState.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
