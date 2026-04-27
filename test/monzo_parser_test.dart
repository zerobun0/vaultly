import 'package:flutter_test/flutter_test.dart';

import 'package:vaultly/data/parsers/monzo_parser.dart';

void main() {
  const parser = MonzoParser();

  test('parses Monzo CSV rows into signed transactions', () {
    const csv = '''Transaction ID,Date,Time,Type,Name,Emoji,Category,Amount,Currency,Local amount,Local currency,Notes and #tags,Description,Money Out,Money In,Balance
txn_1,01/04/2026,08:00,card_payment,Tesco,🛒,Groceries,-12.34,GBP,-12.34,GBP,,Tesco purchase,12.34,,1000.00
txn_2,02/04/2026,09:15,pot_transfer,My Pot,🏦,Transfers,50.00,GBP,50.00,GBP,,Pot top up,,50.00,1050.00
''';

    final transactions = parser.parse(csv);

    expect(transactions, hasLength(2));

    final first = transactions[0];
    expect(first.externalId, 'txn_1');
    expect(first.sourceBank, 'monzo');
    expect(first.transactionDate, DateTime(2026, 4, 1));
    expect(first.merchantName, 'Tesco');
    expect(first.description, 'Tesco purchase');
    expect(first.amount, closeTo(-12.34, 0.0001));
    expect(first.currency, 'GBP');
    expect(first.category, 'Groceries');
    expect(first.isTransfer, isFalse);

    final second = transactions[1];
    expect(second.externalId, 'txn_2');
    expect(second.amount, closeTo(50.0, 0.0001));
    expect(second.isTransfer, isTrue);
  });
}