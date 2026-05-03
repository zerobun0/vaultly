import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/currency_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../data/parsers/bank_parser_interface.dart';
import '../../../data/parsers/parser_factory.dart';
import '../../providers/transaction_providers.dart';

// ---------------------------------------------------------------------------
// Import state enum
// ---------------------------------------------------------------------------

enum _ImportState { idle, parsing, previewing, importing, done, error }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String? _selectedBank;
  String? _csvContent;
  List<ParsedBankTransaction>? _parsedRows;
  _ImportState _importState = _ImportState.idle;
  String? _errorMessage;
  int? _importedCount;

  void _reset() {
    setState(() {
      _selectedBank = null;
      _csvContent = null;
      _parsedRows = null;
      _importState = _ImportState.idle;
      _errorMessage = null;
      _importedCount = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null) return;

      final file = result.files.single;
      String content;
      if (file.path != null) {
        content = File(file.path!).readAsStringSync();
      } else if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else {
        setState(() {
          _importState = _ImportState.error;
          _errorMessage = 'Could not read file — no path or bytes available.';
        });
        return;
      }

      setState(() {
        _csvContent = content;
        // Reset downstream state when a new file is picked
        _parsedRows = null;
        if (_importState != _ImportState.idle) {
          _importState = _ImportState.idle;
        }
      });
    } catch (e) {
      setState(() {
        _importState = _ImportState.error;
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _parse() async {
    if (_selectedBank == null || _csvContent == null) return;
    setState(() => _importState = _ImportState.parsing);

    try {
      final parser = const ParserFactory().create(_selectedBank!);
      final rows = parser.parse(_csvContent!);
      setState(() {
        _parsedRows = rows;
        _importState = _ImportState.previewing;
      });
    } on ParseException catch (e) {
      setState(() {
        _importState = _ImportState.error;
        _errorMessage = e.message;
      });
    } on AppException catch (e) {
      setState(() {
        _importState = _ImportState.error;
        _errorMessage = e.toString();
      });
    } catch (e) {
      setState(() {
        _importState = _ImportState.error;
        _errorMessage = 'Parse error: $e';
      });
    }
  }

  Future<void> _importAll() async {
    if (_parsedRows == null) return;
    setState(() => _importState = _ImportState.importing);

    try {
      final count = await ref
          .read(importTransactionsProvider.notifier)
          .importAll(_parsedRows!);
      setState(() {
        _importedCount = count;
        _importState = _ImportState.done;
      });
    } catch (e) {
      setState(() {
        _importState = _ImportState.error;
        _errorMessage = 'Import failed: $e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/transactions');
            }
          },
        ),
        title: const Text(
          'Import CSV',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: switch (_importState) {
          _ImportState.done => _DoneView(
              count: _importedCount ?? 0,
              onViewTransactions: () => context.go('/transactions'),
              onImportAnother: _reset,
            ),
          _ImportState.error => _ErrorView(
              message: _errorMessage ?? 'An unknown error occurred.',
              onTryAgain: () => setState(() {
                _importState = _ImportState.idle;
                _errorMessage = null;
              }),
            ),
          _ImportState.importing => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Importing...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          _ => _StepsView(
              selectedBank: _selectedBank,
              csvContent: _csvContent,
              parsedRows: _parsedRows,
              importState: _importState,
              onBankSelected: (bank) => setState(() {
                _selectedBank = bank;
                _parsedRows = null;
                _importState = _ImportState.idle;
              }),
              onPickFile: _pickFile,
              onPreview: _parse,
              onImportAll: _importAll,
            ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Steps view (idle / parsing / previewing)
// ---------------------------------------------------------------------------

class _StepsView extends StatelessWidget {
  const _StepsView({
    required this.selectedBank,
    required this.csvContent,
    required this.parsedRows,
    required this.importState,
    required this.onBankSelected,
    required this.onPickFile,
    required this.onPreview,
    required this.onImportAll,
  });

  final String? selectedBank;
  final String? csvContent;
  final List<ParsedBankTransaction>? parsedRows;
  final _ImportState importState;
  final ValueChanged<String> onBankSelected;
  final VoidCallback onPickFile;
  final VoidCallback onPreview;
  final VoidCallback onImportAll;

  static const _supportedBanks = [
    ('monzo', 'Monzo', true),
    ('starling', 'Starling', false),
    ('revolut', 'Revolut', false),
    ('barclays', 'Barclays', false),
  ];

  @override
  Widget build(BuildContext context) {
    final isParsing = importState == _ImportState.parsing;
    final isPreviewing = importState == _ImportState.previewing;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Step 1: Pick bank ────────────────────────────────────────────────
        const _SectionHeader(number: 1, title: 'Select your bank'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (id, label, enabled) in _supportedBanks)
              Tooltip(
                message: enabled ? '' : 'Coming soon',
                child: ChoiceChip(
                  label: Text(label),
                  selected: selectedBank == id,
                  onSelected: enabled ? (_) => onBankSelected(id) : null,
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    color: enabled
                        ? (selectedBank == id
                            ? AppColors.primary
                            : Colors.white70)
                        : Colors.white24,
                    fontWeight: selectedBank == id
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  checkmarkColor: AppColors.primary,
                  disabledColor: Colors.white10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Step 2: Pick file ────────────────────────────────────────────────
        const _SectionHeader(number: 2, title: 'Pick CSV file'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onPickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: csvContent != null
                    ? AppColors.success
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          icon: Icon(
            csvContent != null
                ? Icons.check_circle_rounded
                : Icons.upload_file_rounded,
            color: csvContent != null ? AppColors.success : Colors.white70,
          ),
          label: Text(
            csvContent != null ? 'File loaded — tap to change' : 'Pick CSV file',
          ),
        ),
        const SizedBox(height: 28),

        // ── Step 3: Preview ──────────────────────────────────────────────────
        if (selectedBank != null && csvContent != null) ...[
          const _SectionHeader(number: 3, title: 'Preview'),
          const SizedBox(height: 12),
          if (!isPreviewing && !isParsing)
            ElevatedButton(
              onPressed: onPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Preview transactions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (isParsing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          if (isPreviewing && parsedRows != null) ...[
            _PreviewTable(rows: parsedRows!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onImportAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Import All (${parsedRows!.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview table
// ---------------------------------------------------------------------------

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});

  final List<ParsedBankTransaction> rows;

  @override
  Widget build(BuildContext context) {
    final transfers = rows.where((r) => r.isTransfer).length;
    final preview = rows.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found ${rows.length} transactions'
                  '${transfers > 0 ? ' ($transfers transfers excluded from totals)' : ''}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Preview rows (max 20)
        ...preview.map(
          (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.merchantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.transactionDate.formatShort(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    r.amount.formatGBPSigned(),
                    style: TextStyle(
                      color: r.amount >= 0
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (rows.length > 20) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '… and ${rows.length - 20} more',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Done view
// ---------------------------------------------------------------------------

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.count,
    required this.onViewTransactions,
    required this.onImportAnother,
  });

  final int count;
  final VoidCallback onViewTransactions;
  final VoidCallback onImportAnother;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                    width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Imported $count transaction${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your transactions are ready to view.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onImportAnother,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Import Another'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onTryAgain});

  final String message;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.danger, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.25)),
              ),
              child: Text(
                message,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
