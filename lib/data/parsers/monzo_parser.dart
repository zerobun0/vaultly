import 'package:csv/csv.dart';

import 'bank_parser_interface.dart';

class MonzoParser implements BankParserInterface {
  const MonzoParser();

  @override
  String get sourceBank => 'monzo';

  @override
  List<ParsedBankTransaction> parse(String contents) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(contents.trim());

    if (rows.isEmpty) {
      return <ParsedBankTransaction>[];
    }

    final headers = rows.first.map((value) => value.toString()).toList(growable: false);
    final transactions = <ParsedBankTransaction>[];

    for (final row in rows.skip(1)) {
      if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        continue;
      }

      final values = <String, String>{};
      for (var index = 0; index < headers.length && index < row.length; index++) {
        values[headers[index]] = row[index]?.toString().trim() ?? '';
      }

      final transactionId = values['Transaction ID'] ?? '';
      if (transactionId.isEmpty) {
        continue;
      }

      final dateText = values['Date'] ?? '';
      final transactionDate = DateTime.parse(_normalizeDate(dateText));
      final moneyIn = _parseAmount(values['Money In']);
      final moneyOut = _parseAmount(values['Money Out']);
      final amount = moneyIn != 0 ? moneyIn : -moneyOut;
      final type = values['Type'] ?? '';

      transactions.add(
        ParsedBankTransaction(
          externalId: transactionId,
          sourceBank: sourceBank,
          transactionDate: transactionDate,
          postedDate: transactionDate,
          merchantName: values['Name']?.isNotEmpty == true ? values['Name']! : values['Description'] ?? '',
          description: values['Description']?.isNotEmpty == true ? values['Description']! : values['Name'] ?? '',
          amount: amount,
          currency: values['Currency']?.isNotEmpty == true ? values['Currency']! : 'GBP',
          category: values['Category'],
          isTransfer: type == 'pot_transfer',
        ),
      );
    }

    return transactions;
  }

  String _normalizeDate(String dateText) {
    final parts = dateText.split('/');
    if (parts.length != 3) {
      throw FormatException('Invalid Monzo date: $dateText');
    }

    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  double _parseAmount(String? text) {
    if (text == null || text.isEmpty) {
      return 0;
    }

    return double.parse(text.replaceAll(',', '.'));
  }
}