import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parsers/parser_factory.dart';
import '../data/services/categorizer_provider.dart';

class CategorizerScreen extends ConsumerStatefulWidget {
  const CategorizerScreen({super.key});

  @override
  ConsumerState<CategorizerScreen> createState() => _CategorizerScreenState();
}

class _CategorizerScreenState extends ConsumerState<CategorizerScreen> {
  late final TextEditingController _csvController;
  List<Map<String, String>> _results = [];

  static const String _sampleCsv = '''Transaction ID,Date,Money In,Money Out,Type,Name,Description,Currency,Category
tx1,27/04/2026,,12.34,,Tesco Superstore,Groceries,GBP,
tx2,27/04/2026,,7.50,,Netflix UK,Subscription,GBP,
''';

  @override
  void initState() {
    super.initState();
    _csvController = TextEditingController(text: _sampleCsv);
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  void _resetResults() {
    setState(() {
      _results = [];
    });
  }

  void _runSampleParse() {
    final parser = const ParserFactory().create('monzo');
    final parsed = parser.parse(_csvController.text);
    final txs = ref.read(categorizerProvider).categorizeTransactions(parsed);

    setState(() {
      _results = txs.map((t) => {
        'id': t.externalId,
        'merchant': t.merchantName,
        'amount': t.amount.toString(),
        'category': t.category ?? 'uncategorized',
      }).toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Vaultly'),
        actions: [
          IconButton(
            tooltip: 'Reset sample data',
            onPressed: _results.isEmpty ? null : _resetResults,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F1EA), Color(0xFFF9F7F2)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: _AmbientBlob(color: colorScheme.primary.withValues(alpha: 0.10), size: 180),
            ),
            Positioned(
              top: 110,
              left: -50,
              child: _AmbientBlob(color: colorScheme.secondary.withValues(alpha: 0.10), size: 140),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(onRunSample: _runSampleParse),
                    const SizedBox(height: 16),
                    Text(
                      'CSV input',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    _CsvInputCard(
                      controller: _csvController,
                      onLoadSample: () {
                        setState(() {
                          _csvController.text = _sampleCsv;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Parsed',
                            value: _results.length.toString(),
                            icon: Icons.receipt_long_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Categories',
                            value: _results.map((r) => r['category']).whereType<String>().toSet().length.toString(),
                            icon: Icons.local_offer_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transaction preview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (_results.isEmpty)
                      _EmptyStateCard(colorScheme: colorScheme)
                    else
                      ..._results.map((result) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransactionCard(result: result),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onRunSample});

  final VoidCallback onRunSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Transaction intelligence',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Categorize bank transactions with a single tap.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Paste a Monzo CSV below and run the sample parser to see merchant categories appear immediately.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onRunSample,
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('Run sample parse'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F766E),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _CsvInputCard extends StatelessWidget {
  const _CsvInputCard({required this.controller, required this.onLoadSample});

  final TextEditingController controller;
  final VoidCallback onLoadSample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Drop in a Monzo CSV export or tweak the sample data.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              minLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Paste CSV data here',
                filled: true,
                fillColor: const Color(0xFFF7F7F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onLoadSample,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Load sample'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Ready to parse'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_rounded, size: 34, color: colorScheme.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'No transactions loaded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the action above to parse sample Monzo data and see categories appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.result});

  final Map<String, String> result;

  @override
  Widget build(BuildContext context) {
    final category = result['category'] ?? 'uncategorized';
    final color = _categoryColor(category, Theme.of(context).colorScheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.shopping_bag_rounded, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['merchant'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Amount: ${result['amount']} · ID: ${result['id']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _CategoryChip(label: category, color: color),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

Color _categoryColor(String category, ColorScheme colorScheme) {
  switch (category.toLowerCase()) {
    case 'groceries':
      return const Color(0xFF0F766E);
    case 'subscriptions':
      return const Color(0xFF4F46E5);
    case 'transport':
      return const Color(0xFFEA580C);
    case 'shopping':
      return const Color(0xFF7C3AED);
    case 'travel':
      return const Color(0xFF2563EB);
    default:
      return colorScheme.primary;
  }
}
