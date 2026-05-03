import 'package:drift/drift.dart' hide Column;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tax_constants.dart';
import '../../../core/extensions/currency_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/calculators/tax_calculator.dart';
import '../../providers/tax_providers.dart';
import '../../providers/transaction_providers.dart';

class IncomeTaxScreen extends ConsumerStatefulWidget {
  const IncomeTaxScreen({super.key});

  @override
  ConsumerState<IncomeTaxScreen> createState() => _IncomeTaxScreenState();
}

class _IncomeTaxScreenState extends ConsumerState<IncomeTaxScreen> {
  final _salaryCtrl = TextEditingController();
  final _dividendCtrl = TextEditingController();
  bool _synced = false;

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _dividendCtrl.dispose();
    super.dispose();
  }

  TaxBreakdown _calculate() {
    final salary = double.tryParse(_salaryCtrl.text) ?? 0;
    final dividends = double.tryParse(_dividendCtrl.text) ?? 0;
    return const TaxCalculator().calculate(
        salaryIncome: salary, dividendIncome: dividends);
  }

  @override
  Widget build(BuildContext context) {
    // Pre-populate salary from income transactions (once)
    if (!_synced) {
      final income = ref.watch(totalIncomeProvider).valueOrNull;
      if (income != null && income > 0 && _salaryCtrl.text.isEmpty) {
        _salaryCtrl.text = income.toStringAsFixed(2);
        _synced = true;
      }
    }

    final taxYear = ref.watch(currentTaxYearProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Income & Tax $taxYear/${(taxYear + 1).toString().substring(2)}'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Manual Entries'),
            Tab(text: 'ISA & CGT'),
          ]),
        ),
        body: TabBarView(children: [
          _OverviewTab(
            salaryCtrl: _salaryCtrl,
            dividendCtrl: _dividendCtrl,
            calculate: _calculate,
          ),
          _ManualEntriesTab(),
          const _IsaCgtTab(),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({
    required this.salaryCtrl,
    required this.dividendCtrl,
    required this.calculate,
  });

  final TextEditingController salaryCtrl;
  final TextEditingController dividendCtrl;
  final TaxBreakdown Function() calculate;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  @override
  void initState() {
    super.initState();
    widget.salaryCtrl.addListener(() => setState(() {}));
    widget.dividendCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.calculate();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _inputSection(context),
        const SizedBox(height: 16),
        _TaxSummaryCard(breakdown: breakdown)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.06, curve: Curves.easeOut),
        const SizedBox(height: 16),
        _TaxDonutChart(breakdown: breakdown)
            .animate(delay: 150.ms)
            .fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _inputSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: widget.salaryCtrl,
              decoration: const InputDecoration(
                  labelText: 'Salary / Employment Income',
                  prefixText: '£'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.dividendCtrl,
              decoration: const InputDecoration(
                  labelText: 'Dividend Income (optional)', prefixText: '£'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _TaxSummaryCard extends StatelessWidget {
  const _TaxSummaryCard({required this.breakdown});
  final TaxBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tax Breakdown 2025/26',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _row(context, 'Gross Income', breakdown.grossIncome),
            _row(context, 'Personal Allowance',
                -TaxConstants.personalAllowance, subtle: true),
            _row(context, 'Taxable Income', breakdown.salaryTaxableIncome,
                subtle: true),
            const Divider(),
            _row(context, 'Income Tax (20%/40%/45%)', breakdown.incomeTax,
                color: AppColors.danger),
            _row(context, 'National Insurance', breakdown.nationalInsurance,
                color: AppColors.warning),
            if (breakdown.dividendTax > 0)
              _row(context, 'Dividend Tax', breakdown.dividendTax,
                  color: AppColors.warning),
            _row(context, 'Total Tax', breakdown.totalTax,
                color: AppColors.danger, bold: true),
            const Divider(),
            _row(context, 'Take-Home Pay', breakdown.netIncome,
                color: AppColors.success, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, double amount,
      {Color? color, bool bold = false, bool subtle = false}) {
    final style = TextStyle(
      color: subtle
          ? Theme.of(context).textTheme.bodySmall?.color
          : color,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: subtle ? 12 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount.abs().formatGBP(), style: style),
        ],
      ),
    );
  }
}

class _TaxDonutChart extends StatelessWidget {
  const _TaxDonutChart({required this.breakdown});
  final TaxBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.grossIncome <= 0) return const SizedBox.shrink();

    final sections = [
      PieChartSectionData(
        value: breakdown.netIncome,
        color: AppColors.success,
        title: 'Take-home',
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        radius: 60,
      ),
      PieChartSectionData(
        value: breakdown.incomeTax,
        color: AppColors.danger,
        title: 'Tax',
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        radius: 60,
      ),
      PieChartSectionData(
        value: breakdown.nationalInsurance,
        color: AppColors.warning,
        title: 'NI',
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        radius: 60,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Income Split',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(enabled: false),
              )),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                _legend(AppColors.success, 'Take-home'),
                _legend(AppColors.danger, 'Income Tax'),
                _legend(AppColors.warning, 'NI'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Manual Entries
// ---------------------------------------------------------------------------

class _ManualEntriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(taxEntriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 64),
                    SizedBox(height: 16),
                    Text('No manual entries.',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      'Add income sources like freelance, rental, benefits, etc.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final total = entries.fold<double>(0, (s, e) => s + e.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total manual income',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(total.formatGBP(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red,
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => ref
                          .read(taxNotifierProvider.notifier)
                          .delete(entry.id),
                      child: ListTile(
                        title: Text(entry.description),
                        subtitle: Text(
                            '${entry.entryType} • ${entry.effectiveDate.formatShort()}'),
                        trailing: Text(
                          entry.amount.formatGBP(),
                          style: TextStyle(
                            color: entry.amount >= 0
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate(delay: (i * 40).ms).fadeIn(duration: 300.ms);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EntryFormSheet(ref: ref),
    );
  }
}

class _EntryFormSheet extends StatefulWidget {
  const _EntryFormSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<_EntryFormSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'income';
  DateTime _date = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final taxYear = widget.ref.read(currentTaxYearProvider);
    final companion = TaxEntriesTableCompanion(
      taxYear: Value('$taxYear/${(taxYear + 1).toString().substring(2)}'),
      entryType: Value(_type),
      amount: Value(double.tryParse(_amountCtrl.text) ?? 0),
      description: Value(_descCtrl.text.trim()),
      effectiveDate: Value(_date),
    );
    await widget.ref.read(taxNotifierProvider.notifier).upsert(companion);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Entry',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration:
                  const InputDecoration(labelText: 'Amount', prefixText: '£'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Enter amount' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'income', label: Text('Income')),
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'benefit', label: Text('Benefit')),
              ],
              selected: {_type},
              onSelectionChanged: (s) =>
                  setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${_date.formatMedium()}'),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — ISA & CGT
// ---------------------------------------------------------------------------

class _IsaCgtTab extends StatelessWidget {
  const _IsaCgtTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          icon: Icons.account_balance_rounded,
          title: 'ISA Allowance 2025/26',
          value: TaxConstants.isaAllowance.formatGBP(),
          subtitle:
              'You can save up to ${TaxConstants.isaAllowance.formatGBP()} per tax year in an ISA completely tax-free.',
          color: AppColors.primary,
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.trending_up_rounded,
          title: 'Capital Gains Tax Exemption',
          value: TaxConstants.cgtExemption.formatGBP(),
          subtitle:
              'Gains up to ${TaxConstants.cgtExemption.formatGBP()} are exempt from CGT. Above this: 18% (basic rate) or 24% (higher rate) on residential property; 10%/20% on other assets.',
          color: AppColors.success,
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.payments_rounded,
          title: 'Dividend Allowance',
          value: TaxConstants.dividendAllowance.formatGBP(),
          subtitle:
              'The first ${TaxConstants.dividendAllowance.formatGBP()} of dividends is tax-free. Above this: 8.75% (basic), 33.75% (higher), 39.35% (additional).',
          color: AppColors.warning,
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
