import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/extensions/currency_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../presentation/providers/t212_providers.dart';
import 'widgets/cash_summary_card.dart';
import 'widgets/portfolio_position_tile.dart';

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Investments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Portfolio'),
              Tab(text: 'Orders'),
              Tab(text: 'Dividends'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PortfolioTab(),
            _OrdersTab(),
            _DividendsTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Portfolio
// ---------------------------------------------------------------------------

class _PortfolioTab extends ConsumerWidget {
  const _PortfolioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyAsync = ref.watch(t212ApiKeyProvider);

    return apiKeyAsync.when(
      loading: () => const _ShimmerLoading(),
      error: (e, _) => _ErrorCard(
        message: e.toString(),
        onRetry: () => ref.invalidate(t212ApiKeyProvider),
      ),
      data: (key) {
        if (key == null || key.isEmpty) {
          return const _ConnectCard();
        }
        return const _PortfolioData();
      },
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  size: 56,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect Trading 212',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your Trading 212 API key to view your portfolio, '
                  'order history, and dividend data.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.push('/settings/api-key'),
                  child: const Text('Add API Key'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioData extends ConsumerWidget {
  const _PortfolioData();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAsync = ref.watch(t212CashProvider);
    final portfolioAsync = ref.watch(t212PortfolioProvider);

    // Show shimmer while either is loading
    if (cashAsync.isLoading || portfolioAsync.isLoading) {
      return const _ShimmerLoading();
    }

    // Check for auth errors
    final cashError = cashAsync.error;
    final portfolioError = portfolioAsync.error;
    if (cashError != null || portfolioError != null) {
      final err = cashError ?? portfolioError;
      final isAuth = err is AuthException ||
          err.toString().toLowerCase().contains('auth') ||
          err.toString().toLowerCase().contains('401');
      return _ErrorCard(
        message: isAuth
            ? 'Invalid API key. Please re-enter your Trading 212 API key.'
            : (err?.toString() ?? 'An error occurred.'),
        onRetry: () => context.push('/settings/api-key'),
        retryLabel: isAuth ? 'Update API Key' : 'Retry',
      );
    }

    final cash = cashAsync.value;
    final portfolio = portfolioAsync.value;

    final positions = portfolio?.positions ?? [];
    return ListView.builder(
      itemCount: positions.isEmpty ? 2 : positions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return cash == null
              ? const SizedBox.shrink()
              : CashSummaryCard(cash: cash)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOut);
        }
        if (positions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No positions in portfolio.')),
          );
        }
        return PortfolioPositionTile(position: positions[index - 1])
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Orders
// ---------------------------------------------------------------------------

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(t212OrderHistoryProvider);
    final theme = Theme.of(context);

    return ordersAsync.when(
      loading: () => const _ShimmerLoading(),
      error: (e, _) => _ErrorCard(
        message: e.toString(),
        onRetry: () => ref.invalidate(t212OrderHistoryProvider),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No order history',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final isBuy =
                order.type.toUpperCase().contains('BUY');
            final badgeColor = isBuy ? AppColors.success : AppColors.danger;
            return ListTile(
              title: Text(
                order.ticker,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                order.dateExecuted?.formatShort() ?? '—',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isBuy ? 'BUY' : 'SELL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.filledQuantity.toStringAsFixed(4)} · '
                    '${order.filledValue.formatGBP()}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 — Dividends
// ---------------------------------------------------------------------------

class _DividendsTab extends ConsumerWidget {
  const _DividendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dividendsAsync = ref.watch(t212DividendHistoryProvider);
    final theme = Theme.of(context);

    return dividendsAsync.when(
      loading: () => const _ShimmerLoading(),
      error: (e, _) => _ErrorCard(
        message: e.toString(),
        onRetry: () => ref.invalidate(t212DividendHistoryProvider),
      ),
      data: (dividends) {
        if (dividends.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No dividends received yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final total =
            dividends.fold<double>(0, (sum, d) => sum + d.amount);

        return ListView.builder(
          itemCount: dividends.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Dividends',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          total.formatGBP(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final dividend = dividends[index - 1];
            return ListTile(
              title: Text(
                dividend.ticker,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                dividend.paidOn?.formatShort() ?? '—',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                dividend.amount.formatGBP(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: shimmer / error widgets
// ---------------------------------------------------------------------------

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerBox(
          height: index == 0 ? 120 : 64,
          borderRadius: 12,
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height, this.borderRadius = 8});

  final double height;
  final double borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    _colorAnim = ColorTween(
      begin: isDark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFE0E0E0),
      end: isDark
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFF5F5F5),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (context, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: _colorAnim.value,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
