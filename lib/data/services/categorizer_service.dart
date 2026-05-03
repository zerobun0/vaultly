import '../parsers/bank_parser_interface.dart';
import '../parsers/keyword_map.dart';

class CategorizerService {
  const CategorizerService();

  String categorizeMerchant(String merchantName, {double? amount}) {
    final name = merchantName.toLowerCase();

    for (final entry in KeywordMap.keywordMap.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      if (pattern.hasMatch(name)) {
        return entry.value;
      }
    }

    return 'uncategorized';
  }

  // Bulk categorize parsed transactions
  List<ParsedBankTransaction> categorizeTransactions(List<ParsedBankTransaction> txs) {
    return txs.map((t) {
      final cat = categorizeMerchant(t.merchantName, amount: t.amount);
      return ParsedBankTransaction(
        externalId: t.externalId,
        sourceBank: t.sourceBank,
        transactionDate: t.transactionDate,
        postedDate: t.postedDate,
        merchantName: t.merchantName,
        description: t.description,
        amount: t.amount,
        currency: t.currency,
        category: cat,
        isTransfer: t.isTransfer,
      );
    }).toList(growable: false);
  }
}
