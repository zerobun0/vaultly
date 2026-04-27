class ParsedBankTransaction {
  const ParsedBankTransaction({
    required this.externalId,
    required this.sourceBank,
    required this.transactionDate,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.description,
    this.postedDate,
    this.category,
    this.isTransfer = false,
  });

  final String externalId;
  final String sourceBank;
  final DateTime transactionDate;
  final DateTime? postedDate;
  final String merchantName;
  final String description;
  final double amount;
  final String currency;
  final String? category;
  final bool isTransfer;
}

abstract class BankParserInterface {
  String get sourceBank;

  List<ParsedBankTransaction> parse(String contents);
}