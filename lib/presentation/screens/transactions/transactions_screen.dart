import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/currency_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/database/app_database.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/transaction_list_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _searchVisible = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Filter state
  bool _showIncome = true;
  bool _showExpenses = true;
  bool _showTransfers = true;
  Set<int> _selectedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        showIncome: _showIncome,
        showExpenses: _showExpenses,
        showTransfers: _showTransfers,
        selectedCategories: _selectedCategories,
        onApply: ({
          required bool showIncome,
          required bool showExpenses,
          required bool showTransfers,
          required Set<int> selectedCategories,
          DateTimeRange? dateRange,
        }) {
          if (dateRange != null) {
            ref
                .read(selectedDateRangeProvider.notifier)
                .update(dateRange);
          }
          setState(() {
            _showIncome = showIncome;
            _showExpenses = showExpenses;
            _showTransfers = showTransfers;
            _selectedCategories = selectedCategories;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  List<TransactionsTableData> _applyClientFilters(
      List<TransactionsTableData> txs) {
    return txs.where((tx) {
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !tx.merchantName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      // Income/expense toggle
      if (tx.isIncome && !_showIncome) return false;
      if (!tx.isIncome && !_showExpenses) return false;
      // Transfer toggle
      if (tx.isTransfer && !_showTransfers) return false;
      // Category filter
      if (_selectedCategories.isNotEmpty &&
          (tx.categoryId == null ||
              !_selectedCategories.contains(tx.categoryId))) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<DateTime, List<TransactionsTableData>> _groupByDate(
      List<TransactionsTableData> txs) {
    final map = <DateTime, List<TransactionsTableData>>{};
    for (final tx in txs) {
      final day = tx.transactionDate.startOfDay;
      map.putIfAbsent(day, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.search_off_rounded : Icons.search_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/import'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Import', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search bar
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _searchVisible
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search merchants...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Transaction list
          Expanded(
            child: txAsync.when(
              loading: () => const _ShimmerList(),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              data: (txs) {
                final filtered = _applyClientFilters(txs);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    onImport: () => context.go('/import'),
                  );
                }
                final grouped = _groupByDate(filtered);
                final sortedDays = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final dayTxs = grouped[day]!;
                    final dailyTotal =
                        dayTxs.fold<double>(0, (s, t) => s + t.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DayHeader(date: day, dailyTotal: dailyTotal),
                        ...List.generate(
                          dayTxs.length,
                          (txIndex) => TransactionListTile(
                                  transaction: dayTxs[txIndex])
                              .animate(
                                  delay: ((index + txIndex) * 40).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: -0.04, curve: Curves.easeOut),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day header
// ---------------------------------------------------------------------------

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.dailyTotal});

  final DateTime date;
  final double dailyTotal;

  @override
  Widget build(BuildContext context) {
    final isPositive = dailyTotal >= 0;
    String label;
    if (date.isToday) {
      label = 'Today';
    } else if (date.isYesterday) {
      label = 'Yesterday';
    } else {
      label = date.formatMedium();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            dailyTotal.formatGBPSigned(),
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading placeholder
// ---------------------------------------------------------------------------

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.3 + (_anim.value * 0.4);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity * 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: opacity * 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: opacity * 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity * 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Import a CSV to get started',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import CSV'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

typedef _FilterApplyCallback = void Function({
  required bool showIncome,
  required bool showExpenses,
  required bool showTransfers,
  required Set<int> selectedCategories,
  DateTimeRange? dateRange,
});

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.showIncome,
    required this.showExpenses,
    required this.showTransfers,
    required this.selectedCategories,
    required this.onApply,
  });

  final bool showIncome;
  final bool showExpenses;
  final bool showTransfers;
  final Set<int> selectedCategories;
  final _FilterApplyCallback onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _showIncome;
  late bool _showExpenses;
  late bool _showTransfers;
  late Set<int> _selectedCategories;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _showIncome = widget.showIncome;
    _showExpenses = widget.showExpenses;
    _showTransfers = widget.showTransfers;
    _selectedCategories = Set.from(widget.selectedCategories);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month),
            end: now,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.cardDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Date range
            const Text('Date Range',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickDateRange(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(
                _dateRange == null
                    ? 'Current month (default)'
                    : '${_dateRange!.start.formatShort()} – ${_dateRange!.end.formatShort()}',
              ),
            ),
            const SizedBox(height: 20),

            // Income / Expense toggles
            const Text('Type',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Income'),
                  selected: _showIncome,
                  onSelected: (v) => setState(() => _showIncome = v),
                  selectedColor: AppColors.success.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.success,
                  labelStyle: TextStyle(
                      color: _showIncome ? AppColors.success : Colors.white70),
                ),
                FilterChip(
                  label: const Text('Expenses'),
                  selected: _showExpenses,
                  onSelected: (v) => setState(() => _showExpenses = v),
                  selectedColor: AppColors.danger.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.danger,
                  labelStyle: TextStyle(
                      color:
                          _showExpenses ? AppColors.danger : Colors.white70),
                ),
                FilterChip(
                  label: const Text('Transfers'),
                  selected: _showTransfers,
                  onSelected: (v) => setState(() => _showTransfers = v),
                  selectedColor: AppColors.warning.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.warning,
                  labelStyle: TextStyle(
                      color: _showTransfers
                          ? AppColors.warning
                          : Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onApply(
                  showIncome: _showIncome,
                  showExpenses: _showExpenses,
                  showTransfers: _showTransfers,
                  selectedCategories: _selectedCategories,
                  dateRange: _dateRange,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
